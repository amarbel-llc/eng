package main

import (
	"os"
	"syscall"

	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
	"code.linenisgreat.com/zit/go/zit/src/bravo/ui"
	"code.linenisgreat.com/zit/go/zit/src/quebec/commands"
)

func main() {
	var exitStatus int

	for {
		ctx := errors.MakeContextDefault()

		ctx.SetCancelOnSignals(
			syscall.SIGTERM,
			syscall.SIGINT,
			syscall.SIGHUP,
		)

		if err := ctx.Run(
			func(ctx errors.Context) {
				commands.Run(ctx, os.Args...)
			},
		); err != nil {
			var signal errors.Signal

			if errors.As(err, &signal) {
				ui.Err().Print(err)
				break
			}

			exitStatus = 1

			var helpful errors.Helpful

			if errors.As(err, &helpful) {
				errors.PrintHelpful(ui.Err(), helpful)
				break
			}

			var normalError errors.StackTracer

			if errors.As(err, &normalError) && !normalError.ShouldShowStackTrace() {
				ui.Err().Printf("\n\nzit failed with error:\n%s", normalError.Error())
			} else {
				ui.Err().Printf("\n\nzit failed with error:\n%s", err)
			}
		}

		break
	}

	os.Exit(exitStatus)
}
