package client

import (
	"bufio"
	"context"
	"encoding/json"
	"io"
	"net"
	"net/http"
	"time"

	"code.linenisgreat.com/chrest/go/src/bravo/config"
	"code.linenisgreat.com/chrest/go/src/bravo/server"
	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
)

type BrowserProxy struct {
	config.Config
}

type BrowserRequest struct {
	config.BrowserId

	Method string
	Path   string
	Body   io.ReadCloser
}

type ResponseWithParsedJSONBody struct {
	*http.Response
	ParsedJSONBody server.JSONAnything
}

func (b BrowserProxy) Request(
	req BrowserRequest,
) (resp ResponseWithParsedJSONBody, err error) {
	var httpReq *http.Request

	if httpReq, err = http.NewRequest(
		req.Method,
		req.Path,
		req.Body,
	); err != nil {
		err = errors.Wrap(err)
		return
	}

	if resp, err = b.HTTPRequest(httpReq, req); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func (b BrowserProxy) HTTPRequest(
	httpReq *http.Request,
	req BrowserRequest,
) (resp ResponseWithParsedJSONBody, err error) {
	ctx, cancel := context.WithDeadline(
		context.Background(),
		// TODO add default timeout to Config
		time.Now().Add(time.Duration(1e9)),
	)

	defer cancel()

	if resp, err = b.HTTPRequestWithContext(ctx, httpReq, req); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

// TODO figure out which method retunrs err == io.EOF and set err to nil
func (b BrowserProxy) HTTPRequestWithContext(
	ctx context.Context,
	httpReq *http.Request,
	req BrowserRequest,
) (resp ResponseWithParsedJSONBody, err error) {
	var sock string
	if sock, err = b.GetSocketPathForBrowserId(req.BrowserId); err != nil {
		err = errors.Wrap(err)
		return
	}

	var dialer net.Dialer

	var conn net.Conn

	if conn, err = dialer.DialContext(ctx, "unix", sock); err != nil {
		err = errors.Wrap(err)
		return
	}

	if err = httpReq.Write(conn); err != nil {
		err = errors.Wrap(err)
		return
	}

	if resp.Response, err = http.ReadResponse(bufio.NewReader(conn), httpReq); err != nil {
		err = errors.Wrap(err)
		return
	}

	// TODO handle response status

	if resp.Body == nil || resp.ContentLength == 0 {
		return
	}

	dec := json.NewDecoder(bufio.NewReader(resp.Body))

	if req.Path == "/items" {
		var items []BrowserItem

		if err = dec.Decode(&items); err != nil {
			err = errors.Wrapf(
				err,
				"Url: %s, Request: %#v, Response: %#v",
				httpReq.URL,
				httpReq,
				resp.Response,
			)

			return
		}

		resp.ParsedJSONBody = items
	} else {
		if err = dec.Decode(&resp.ParsedJSONBody); err != nil {
			err = errors.Wrapf(
				err,
				"Url: %s, Request: %#v, Response: %#v",
				httpReq.URL,
				httpReq,
				resp.Response,
			)

			return
		}
	}

	return
}

func ResponseFromReader(
	httpRequestReader io.Reader,
	conn net.Conn,
) (resp *http.Response, err error) {
	var req *http.Request

	if req, err = http.ReadRequest(bufio.NewReader(httpRequestReader)); err != nil {
		err = errors.Errorf("failed to read request: %w", err)
		return
	}

	if resp, err = ResponseFromRequest(
		req,
		conn,
	); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func ResponseFromRequest(
	req *http.Request,
	conn net.Conn,
) (resp *http.Response, err error) {
	if err = req.Write(conn); err != nil {
		err = errors.Errorf("failed to write to socket: %w", err)
		return
	}

	if resp, err = http.ReadResponse(bufio.NewReader(conn), req); err != nil {
		err = errors.Errorf("failed to read response: %w", err)
		return
	}

	return
}
