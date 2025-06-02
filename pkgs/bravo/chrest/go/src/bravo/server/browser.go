package server

import (
	"bytes"
	"encoding/json"
	"io"
	"os"

	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
	"code.linenisgreat.com/zit/go/zit/src/charlie/ohio"
)

func WriteToBrowser(m interface{}) (n int64, err error) {
	w := os.Stdout

	var b []byte

	if b, err = json.Marshal(m); err != nil {
		err = errors.Wrap(err)
		return
	}

	i := int32(len(b))
	// TODO overflow safe

	var n1 int
	n1, err = ohio.WriteFixedInt32(w, i)
	n += int64(n1)

	if err != nil {
		err = errors.Wrap(err)
		return
	}

	n1, err = ohio.WriteAllOrDieTrying(w, b)
	n += int64(n1)

	if err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func ReadFromBrowser(m interface{}) (n int64, err error) {
	r := os.Stdin

	var ml int32

	var n1 int
	n1, ml, err = ohio.ReadFixedInt32(r)
	n += int64(n1)

	if err != nil {
		err = errors.Wrap(err)
		return
	}

	var b bytes.Buffer

	var n2 int64
	n2, err = io.CopyN(&b, r, int64(ml))
	n += n2

	if err != nil {
		err = errors.Wrap(err)
		return
	}

	err = json.Unmarshal(b.Bytes(), &m)
	if err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}
