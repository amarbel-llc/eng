package store_version

import (
	"strconv"

	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
	"code.linenisgreat.com/zit/go/zit/src/alfa/interfaces"
	"code.linenisgreat.com/zit/go/zit/src/bravo/values"
)

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

func MakeStoreVersion(sv interfaces.StoreVersion) StoreVersion {
	return StoreVersion(values.Int(sv.GetInt()))
}

type StoreVersion values.Int

func StoreVersionEquals(
	a interfaces.StoreVersion,
	others ...interfaces.StoreVersion,
) bool {
	for _, other := range others {
		if a.GetInt() == other.GetInt() {
			return true
		}
	}

	return false
}

func StoreVersionLess(a, b interfaces.StoreVersion) bool {
	return a.GetInt() < b.GetInt()
}

func StoreVersionLessOrEqual(a, b interfaces.StoreVersion) bool {
	return a.GetInt() <= b.GetInt()
}

func StoreVersionGreater(a, b interfaces.StoreVersion) bool {
	return a.GetInt() > b.GetInt()
}

func StoreVersionGreaterOrEqual(a, b interfaces.StoreVersion) bool {
	return a.GetInt() >= b.GetInt()
}

func (a StoreVersion) Less(b interfaces.StoreVersion) bool {
	return StoreVersionLess(a, b)
}

func (a StoreVersion) LessOrEqual(b interfaces.StoreVersion) bool {
	return StoreVersionLessOrEqual(a, b)
}

func (a StoreVersion) String() string {
	return values.Int(a).String()
}

func (a StoreVersion) GetInt() int {
	return values.Int(a).Int()
}

func (v *StoreVersion) Set(p string) (err error) {
	var i uint64

	if i, err = strconv.ParseUint(p, 10, 16); err != nil {
		err = errors.Wrap(err)
		return
	}

	*v = StoreVersion(i)

	if StoreVersionCurrent.Less(v) {
		err = errors.Wrap(ErrFutureStoreVersion{StoreVersion: v})
		return
	}

	return
}

// func (v *StoreVersion) ReadFromFile(
// 	p string,
// ) (err error) {
// 	if err = v.ReadFromFileOrVersion(p, StoreVersionCurrent); err != nil {
// 		err = errors.Wrap(err)
// 		return
// 	}

// 	return
// }

// func (v *StoreVersion) ReadFromFileOrVersion(
// 	p string,
// 	alternative StoreVersion,
// ) (err error) {
// 	var b []byte

// 	var f *os.File

// 	if f, err = files.Open(p); err != nil {
// 		if errors.IsNotExist(err) {
// 			*v = alternative
// 			err = nil
// 		} else {
// 			err = errors.Wrap(err)
// 		}

// 		return
// 	}

// 	if b, err = io.ReadAll(f); err != nil {
// 		err = errors.Wrap(err)
// 		return
// 	}

// 	if err = v.Set(string(b)); err != nil {
// 		err = errors.Wrap(err)
// 		return
// 	}

// 	return
// }
