package main

import (
	"fmt"
	"io"
	"os"
	"syscall"
	"time"

	"code.linenisgreat.com/chrest/go/src/bravo/config"
	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
	"code.linenisgreat.com/zit/go/zit/src/bravo/ui"
)

func CmdReloadExtension(c config.Config) (err error) {
	var exe string

	if exe, err = os.Executable(); err != nil {
		err = errors.Wrap(err)
		return
	}

	os.Args = []string{exe, "POST", "/runtime/reload"}

	fmt.Println("reloading server")

	if err = CmdClient(c); err != nil {
		if errors.Is(err, io.ErrUnexpectedEOF) {
			err = nil
		} else {
			err = errors.Wrap(err)
			return
		}
	}

	os.Args[1] = "GET"

	for {
		fmt.Println("waiting for server to come back up")

		if err = CmdClient(c); err != nil {
			if errors.Is(err, io.ErrUnexpectedEOF) {
				err = nil
				time.Sleep(1e8)
				continue
			} else if errors.IsErrno(err, syscall.ECONNREFUSED) {
				ui.Err().Print("Browser failed to restart extension. It will need to be restarted manually.")
				err = nil
				return
			} else {
				err = errors.Wrap(err)
				return
			}
		}

		break
	}

	return
}
