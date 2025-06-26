package ids

import "code.linenisgreat.com/zit/go/src/delta/catgut"

type Field struct {
	key, value catgut.String
}

func (f *Field) SetCatgutString(v *catgut.String) (err error) {
	return
}
