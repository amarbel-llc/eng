package stream_index2

import "code.linenisgreat.com/zit/go/zit/src/alfa/errors"

var errConcurrentPageAccess = errors.New("concurrent page access")

func MakeErrConcurrentPageAccess() error {
	return errors.WrapSkip(2, errConcurrentPageAccess)
}
