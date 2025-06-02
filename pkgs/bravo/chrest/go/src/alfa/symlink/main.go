package symlink

import (
	"os"

	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
)

func Symlink(oldPath, newPath string) (err error) {
	if _, err = os.Lstat(newPath); err == nil {
		if err = os.Remove(newPath); err != nil {
			err = errors.Wrap(err)
			return
		}
	}

	if err = os.Symlink(oldPath, newPath); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}
