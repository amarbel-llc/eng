package store_fs

import (
	"code.linenisgreat.com/zit/go/src/alfa/errors"
	"code.linenisgreat.com/zit/go/src/alfa/interfaces"
	"code.linenisgreat.com/zit/go/src/charlie/files"
)

type OpenFiles struct{}

func (c OpenFiles) Run(
	ph interfaces.FuncIter[string],
	args ...string,
) (err error) {
	if len(args) == 0 {
		return
	}

	if err = files.OpenFiles(args...); err != nil {
		err = errors.Wrapf(err, "%q", args)
		return
	}

	v := "opening files"

	if err = ph(v); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}
