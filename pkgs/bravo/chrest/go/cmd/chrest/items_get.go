package main

import (
	"encoding/json"
	"flag"
	"io"
	"net"
	"net/http"
	"os"
	"syscall"

	"code.linenisgreat.com/chrest/go/src/bravo/client"
	"code.linenisgreat.com/chrest/go/src/bravo/config"
	"code.linenisgreat.com/chrest/go/src/charlie/browser_items"
	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
	"code.linenisgreat.com/zit/go/zit/src/bravo/ui"
)

func CmdItemsGet(c config.Config) (err error) {
	addFlagsOnce.Do(ClientAddFlags)
	flag.Parse()

	var socks []string

	if socks, err = c.GetAllSockets(); err != nil {
		err = errors.Wrap(err)
		return
	}

	var req *http.Request

	if req, err = http.NewRequest(
		"GET",
		"/items",
		nil,
	); err != nil {
		err = errors.Wrap(err)
		return
	}

	wg := errors.MakeWaitGroupParallel()
	chItems := make(chan browser_items.Item)

	for _, sock := range socks {
		wg.Do(
			func() (err error) {
				if err = cmdItemsGetOne(sock, req, chItems); err != nil {
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

				return
			},
		)
	}

	chDoneWriting := make(chan struct{})
	go func() {
		defer close(chDoneWriting)

		ui.Out().Print("[")

		first := true
		for item := range chItems {
			var itemJson []byte

			if itemJson, err = json.Marshal(item); err != nil {
				err = errors.Wrap(err)
				return
			}

			if first {
				ui.Out().Printf("%s", itemJson)
				first = false
			} else {
				ui.Out().Printf(",%s", itemJson)
			}
		}

		ui.Out().Print("]")
	}()

	if err = wg.GetError(); err != nil {
		err = errors.Wrap(err)
		return
	}

	close(chItems)
	<-chDoneWriting

	// cmdJq := exec.Command("jq")
	// cmdJq.Stdin = resp.Body
	// cmdJq.Stdout = os.Stdout

	// // TODO error message when jq is missing
	// if err = cmdJq.Run(); err != nil {
	// 	if errors.IsBrokenPipe(err) {
	// 		err = nil
	// 	} else {
	// 		err = errors.Wrap(err)
	// 	}

	// 	return
	// }

	return
}

func cmdItemsGetOne(
	sock string,
	req *http.Request,
	chItems chan<- browser_items.Item,
) (err error) {
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

	// read first bracket
	{
		var t json.Token

		if t, err = dec.Token(); err == io.EOF {
			err = errors.Wrap(io.ErrUnexpectedEOF)
		} else if err != nil {
			err = errors.Wrap(err)
			return
		}

		delim, ok := t.(json.Delim)

		if !ok {
			err = errors.Errorf("expected json.Delim but got %T", t)
			return
		}

		if delim != '[' {
			err = errors.Errorf("expected json.Delim to be '[' but got %s", delim)
			return
		}
	}

	for dec.More() {
		var item browser_items.Item

		if err = dec.Decode(&item); err != nil {
			err = errors.Wrap(err)
			return
		}

		chItems <- item
	}

	// read last bracket
	{
		var t json.Token

		if t, err = dec.Token(); err == io.EOF {
			err = errors.Wrap(io.ErrUnexpectedEOF)
		} else if err != nil {
			err = errors.Wrap(err)
			return
		}

		delim, ok := t.(json.Delim)

		if !ok {
			err = errors.Errorf("expected json.Delim but got %T", t)
			return
		}

		if delim != ']' {
			err = errors.Errorf("expected json.Delim to be ']' but got %s", delim)
			return
		}
	}

	return
}
