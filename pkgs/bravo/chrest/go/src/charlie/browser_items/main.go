package browser_items

import (
	"bufio"
	"context"
	"net"
	"net/http"
	"sync"

	"code.linenisgreat.com/chrest/go/src/bravo/config"
	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
)

type BrowserProxy struct {
	config.Config
}

// TODO refactor common out
func (b BrowserProxy) Get(
	ctx context.Context,
	req BrowserRequestGet,
) (resp HTTPResponseWithRequestPayloadGet, err error) {
	var httpReq *http.Request

	if httpReq, err = req.MakeHTTPRequest(ctx); err != nil {
		err = errors.Wrap(err)
		return
	}

	if resp.Response, err = b.httpRequestForDefaultBrowser(
		ctx,
		httpReq,
	); err != nil {
		err = errors.Wrap(err)
		return
	}

	defer errors.DeferredCloser(&err, resp.Response.Body)

	if err = resp.parseResponse(); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

// TODO refactor common out
func (b BrowserProxy) GetAll(
	ctx context.Context,
	req BrowserRequestGet,
) (resp HTTPResponseWithRequestPayloadGet, err error) {
	var socks []string

	if socks, err = b.GetAllSockets(); err != nil {
		err = errors.Wrap(err)
		return
	}

	wg := errors.MakeWaitGroupParallel()

	var l sync.Mutex

	for _, sock := range socks {
		wg.Do(
			func() (err error) {
				var httpReq *http.Request

				if httpReq, err = req.MakeHTTPRequest(ctx); err != nil {
					err = errors.Wrap(err)
					return
				}

				var oneResponse HTTPResponseWithRequestPayloadGet

				if oneResponse.Response, err = b.httpRequestFor(
					ctx,
					httpReq,
					sock,
				); err != nil {
					err = errors.Wrap(err)
					return
				}

				defer errors.DeferredCloser(&err, oneResponse.Response.Body)

				if err = oneResponse.parseResponse(); err != nil {
					err = errors.Wrap(err)
					return
				}

				l.Lock()
				defer l.Unlock()

				resp.RequestPayloadGet = append(
					resp.RequestPayloadGet,
					oneResponse.RequestPayloadGet...,
				)

				return
			},
		)
	}

	if err = wg.GetError(); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

// TODO refactor common out
func (b BrowserProxy) Put(
	ctx context.Context,
	req BrowserRequestPut,
) (resp HTTPResponseWithRequestPayloadPut, err error) {
	var httpReq *http.Request

	if httpReq, err = req.MakeHTTPRequest(ctx); err != nil {
		err = errors.Wrap(err)
		return
	}

	if resp.Response, err = b.httpRequestForDefaultBrowser(
		ctx,
		httpReq,
	); err != nil {
		err = errors.Wrap(err)
		return
	}

	defer errors.DeferredCloser(&err, resp.Response.Body)

	if err = resp.parseResponse(); err != nil {
		err = errors.Wrapf(err, "Request: %#v", httpReq)
		err = errors.Wrapf(err, "Request Payload: %#v", req)
		return
	}

	return
}

// TODO refactor common out
func (b BrowserProxy) PutAll(
	ctx context.Context,
	req BrowserRequestPut,
) (resp HTTPResponseWithRequestPayloadPut, err error) {
	var socks []string

	if socks, err = b.GetAllSockets(); err != nil {
		err = errors.Wrap(err)
		return
	}

	wg := errors.MakeWaitGroupParallel()

	var l sync.Mutex

	for _, sock := range socks {
		wg.Do(
			func() (err error) {
				var httpReq *http.Request

				if httpReq, err = req.MakeHTTPRequest(ctx); err != nil {
					err = errors.Wrap(err)
					return
				}

				var oneResponse HTTPResponseWithRequestPayloadPut

				if oneResponse.Response, err = b.httpRequestFor(
					ctx,
					httpReq,
					sock,
				); err != nil {
					err = errors.Wrap(err)
					return
				}

				defer errors.DeferredCloser(&err, oneResponse.Response.Body)

				if err = oneResponse.parseResponse(); err != nil {
					err = errors.Wrap(err)
					return
				}

				l.Lock()
				defer l.Unlock()

				resp.RequestPayloadPut.Added = append(
					resp.RequestPayloadPut.Added,
					oneResponse.RequestPayloadPut.Added...,
				)

				resp.RequestPayloadPut.Deleted = append(
					resp.RequestPayloadPut.Deleted,
					oneResponse.RequestPayloadPut.Deleted...,
				)

				return
			},
		)
	}

	if err = wg.GetError(); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func (b BrowserProxy) httpRequestForDefaultBrowser(
	ctx context.Context,
	httpReq *http.Request,
) (resp *http.Response, err error) {
	var sock string
	if sock, err = b.GetSocketPathForBrowserId(b.DefaultBrowser); err != nil {
		err = errors.Wrap(err)
		return
	}

	if resp, err = b.httpRequestFor(ctx, httpReq, sock); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func (b BrowserProxy) httpRequestFor(
	ctx context.Context,
	httpReq *http.Request,
	sock string,
) (resp *http.Response, err error) {
	httpReq = httpReq.WithContext(ctx)

	var dialer net.Dialer

	var conn net.Conn

	if conn, err = dialer.DialContext(ctx, "unix", sock); err != nil {
		err = errors.Wrap(err)
		return
	}

	{
		chDone := make(chan struct{})

		go func() {
			defer close(chDone)

			if err = httpReq.Write(conn); err != nil {
				err = errors.Wrap(err)
				return
			}
		}()

		select {
		case <-ctx.Done():
			err = errors.Errorf("timed out writing to socket: %q", sock)

		case <-chDone:
		}
	}

	{
		chDone := make(chan struct{})

		go func() {
			defer close(chDone)

			if resp, err = http.ReadResponse(bufio.NewReader(conn), httpReq); err != nil {
				err = errors.Wrap(err)
				return
			}
		}()

		select {
		case <-ctx.Done():
			err = errors.Errorf("timed out reading from socket: %q", sock)

		case <-chDone:
		}
	}

	return
}
