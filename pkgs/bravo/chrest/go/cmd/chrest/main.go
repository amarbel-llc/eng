package main

import (
	"log"
	"os"
	"sync"

	"code.linenisgreat.com/chrest/go/src/bravo/config"
	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
	"code.linenisgreat.com/zit/go/zit/src/bravo/ui"
)

var addFlagsOnce sync.Once

func init() {
	log.SetPrefix("chrest ")
}

func main() {
	if err := run(); err != nil {
		ui.Err().Print(err)
		os.Exit(1)
	}
}

func run() (err error) {
	var cmd string

	if len(os.Args) > 1 {
		cmd = os.Args[1]
	}

	for i, x := range os.Args {
		if x == cmd {
			os.Args = append(os.Args[:i], os.Args[i+1:]...)
			break
		}
	}

	var c config.Config

	if c, err = config.Default(); err != nil {
		err = errors.Wrap(err)
		return
	}

	switch cmd {
	default:
		if c, err = config.Default(); err != nil {
			err = errors.Wrap(err)
			return
		}

		if err = CmdServer(c); err != nil {
			err = errors.Wrap(err)
			return
		}

	case "reload-extension":
		if err = c.Read(); err != nil {
			err = errors.Wrap(err)
			return
		}

		if err = CmdReloadExtension(c); err != nil {
			err = errors.Wrap(err)
			return
		}

	case "client":
		if err = c.Read(); err != nil {
			err = errors.Wrap(err)
			return
		}

		if err = CmdClient(c); err != nil {
			err = errors.Wrap(err)
			return
		}

	case "items-get":
		if err = c.Read(); err != nil {
			err = errors.Wrap(err)
			return
		}

		if err = CmdItemsGet(c); err != nil {
			err = errors.Wrap(err)
			return
		}

	case "items-put":
		if err = c.Read(); err != nil {
			err = errors.Wrap(err)
			return
		}

		if err = CmdItemsPut(c); err != nil {
			err = errors.Wrap(err)
			return
		}

	case "init":
		if err = CmdInit(); err != nil {
			err = errors.Wrap(err)
			return
		}

		// TODO
		// case "demo":
		// 	if err = c.Read(); err != nil {
		// 		err = errors.Wrap(err)
		// 		return
		// 	}

		// err = CmdDemo(c)
	}

	return
}
