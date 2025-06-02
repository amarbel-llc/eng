package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"io"
	"net"
	"net/http"
	"os"
	"sync"
	"syscall"

	"code.linenisgreat.com/chrest/go/src/bravo/client"
	"code.linenisgreat.com/chrest/go/src/bravo/config"
	"code.linenisgreat.com/chrest/go/src/charlie/browser_items"
	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
)

func CmdItemsPut(c config.Config) (err error) {
	addFlagsOnce.Do(ClientAddFlags)
	flag.Parse()

	var socks []string

	if socks, err = c.GetAllSockets(); err != nil {
		err = errors.Wrap(err)
		return
	}

	var body bytes.Buffer

	if _, err = io.Copy(&body, os.Stdin); err != nil {
		err = errors.Wrap(err)
		return
	}

	wg := errors.MakeWaitGroupParallel()
	responses := make(map[string]browser_items.RequestPayloadPut, len(socks))

	var l sync.Mutex

	for _, sock := range socks {
		wg.Do(
			func() (err error) {
				var req *http.Request

				if req, err = http.NewRequest(
					"PUT",
					"/items",
					bytes.NewReader(body.Bytes()),
				); err != nil {
					err = errors.Wrap(err)
					return
				}

				var response browser_items.RequestPayloadPut

				if response, err = cmdItemsPutOne(sock, req); err != nil {
					if errors.IsErrno(err, syscall.ECONNREFUSED) {
						if err = os.Remove(sock); err != nil {
							err = errors.Wrap(err)
							return
						}
					} else {
						err = errors.Wrap(err)
						return
					}
				}

				l.Lock()
				responses[sock] = response
				l.Unlock()

				return
			},
		)
	}

	if err = wg.GetError(); err != nil {
		err = errors.Wrap(err)
		return
	}

	var response browser_items.RequestPayloadPut

	for _, oneResponse := range responses {
		response.Added = append(response.Added, oneResponse.Added...)
		response.Deleted = append(response.Deleted, oneResponse.Deleted...)
		response.Focused = append(response.Focused, oneResponse.Focused...)
	}

	enc := json.NewEncoder(os.Stdout)

	if err = enc.Encode(response); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func cmdItemsPutOne(
	sock string,
	req *http.Request,
) (payload browser_items.RequestPayloadPut, err error) {
	var conn net.Conn

	if conn, err = net.Dial("unix", sock); err != nil {
		err = errors.Wrap(err)
		return
	}

	var resp *http.Response

	if resp, err = client.ResponseFromRequest(req, conn); err != nil {
		err = errors.Wrapf(err, "Socket: %q", sock)
		return
	}

	if resp.StatusCode >= 400 {
		err = errors.Errorf("http error: %s", http.StatusText(resp.StatusCode))
		return
	}

	rc := resp.Body
	defer errors.DeferredCloser(&err, rc)

	dec := json.NewDecoder(rc)

	if err = dec.Decode(&payload); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}
