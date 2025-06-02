package main

import (
	"os"
	"syscall"

	"code.linenisgreat.com/chrest/go/src/bravo/config"
	"code.linenisgreat.com/chrest/go/src/bravo/server"
	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
	"code.linenisgreat.com/zit/go/zit/src/bravo/ui"
)

func CmdServer(c config.Config) (err error) {
	defer ui.Err().Print("shut down complete")

	ui.Err().Printf("args: %q", os.Args)

	if err = c.Read(); err != nil {
		err = errors.Wrap(err)
		return
	}

	ctx := errors.MakeContextDefault()
	ctx.SetCancelOnSignals(syscall.SIGTERM)

	if err := ctx.Run(
		func(ctx errors.Context) {
			srv := server.Server{
				Context: ctx,
			}

			srv.Initialize()
			srv.Serve()
		},
	); err != nil {
		var normalError errors.StackTracer

		if errors.As(err, &normalError) && !normalError.ShouldShowStackTrace() {
			ui.Err().Printf("%s", normalError.Error())
		} else {
			if err != nil {
				ui.Err().Print(err)
			}
		}
	}

	return
}
