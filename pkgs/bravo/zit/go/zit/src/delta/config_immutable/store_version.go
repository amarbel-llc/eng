package config_immutable

import (
	"io"
	"os"

	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
	"code.linenisgreat.com/zit/go/zit/src/bravo/values"
	"code.linenisgreat.com/zit/go/zit/src/charlie/files"
	"code.linenisgreat.com/zit/go/zit/src/delta/store_version"
)

type StoreVersion = store_version.StoreVersion

const currentVersion = 9

var (
	// TODO search for references
	StoreVersionV1      = StoreVersion(values.Int(1))
	StoreVersionV3      = StoreVersion(values.Int(3))
	StoreVersionV4      = StoreVersion(values.Int(4))
	StoreVersionV6      = StoreVersion(values.Int(6))
	StoreVersionV7      = StoreVersion(values.Int(7))
	StoreVersionV8      = StoreVersion(values.Int(8))
	StoreVersionV9      = StoreVersion(values.Int(9))
	StoreVersionCurrent = StoreVersionV9
	StoreVersionNext    = StoreVersion(values.Int(currentVersion + 1))
)

func ReadFromFile(
	v *StoreVersion,
	p string,
) (err error) {
	if err = ReadFromFileOrVersion(v, p, StoreVersionCurrent); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func ReadFromFileOrVersion(
	v *StoreVersion,
	p string,
	alternative StoreVersion,
) (err error) {
	var b []byte

	var f *os.File

	if f, err = files.Open(p); err != nil {
		if errors.IsNotExist(err) {
			*v = alternative
			err = nil
		} else {
			err = errors.Wrap(err)
		}

		return
	}

	if b, err = io.ReadAll(f); err != nil {
		err = errors.Wrap(err)
		return
	}

	if err = v.Set(string(b)); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}
