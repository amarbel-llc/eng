package commands

import (
	"flag"

	"code.linenisgreat.com/zit/go/zit/src/delta/config_immutable"
	"code.linenisgreat.com/zit/go/zit/src/golf/command"
	"code.linenisgreat.com/zit/go/zit/src/papa/command_components"
)

func init() {
	command.Register("init", &Init{})
}

type Init struct {
	next bool
	command_components.Genesis
}

func (cmd *Init) SetFlagSet(flagSet *flag.FlagSet) {
	cmd.Genesis.SetFlagSet(flagSet)
	flagSet.BoolVar(&cmd.next, "next", false, "use the next store version instead of the current")
}

func (cmd *Init) Run(req command.Request) {
	repoId := req.PopArg("repo-id")

	if cmd.next {
		cmd.Config.StoreVersion = config_immutable.StoreVersionNext
	}

	req.AssertNoMoreArgs()
	cmd.OnTheFirstDay(req, repoId)
}
