package inventory_list_blobs

import (
	"bufio"
	"fmt"
	"io"

	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
	"code.linenisgreat.com/zit/go/zit/src/alfa/interfaces"
	"code.linenisgreat.com/zit/go/zit/src/delta/sha"
	"code.linenisgreat.com/zit/go/zit/src/echo/ids"
	"code.linenisgreat.com/zit/go/zit/src/foxtrot/builtin_types"
	"code.linenisgreat.com/zit/go/zit/src/juliett/sku"
	"code.linenisgreat.com/zit/go/zit/src/kilo/box_format"
)

type V2 struct {
	Box *box_format.BoxTransacted
}

func (v V2) GetListFormat() sku.ListFormat {
	return v
}

func (v V2) GetType() ids.Type {
	return ids.MustType(builtin_types.InventoryListTypeV2)
}

func (format V2) WriteObjectToOpenList(
	object *sku.Transacted,
	list *sku.OpenList,
) (n int64, err error) {
	if !list.LastTai.Less(object.GetTai()) {
		err = errors.Errorf(
			"object order incorrect. Last: %s, current: %s",
			list.LastTai,
			object.GetTai(),
		)

		return
	}

	if n, err = format.writeObjectListItemToWriter(
		object,
		list.Mover,
	); err != nil {
		err = errors.Wrap(err)
		return
	}

	list.LastTai = object.GetTai()
	list.Len += 1

	return
}

func (format V2) writeObjectListItemToWriter(
	object *sku.Transacted,
	writer interfaces.ShaWriter,
) (n int64, err error) {
	if object.Metadata.Sha().IsNull() {
		err = errors.ErrorWithStackf("empty sha: %q", sku.String(object))
		return
	}

	var n1 int64

	n1, err = format.Box.EncodeStringTo(object, writer)
	n += n1

	if err != nil {
		err = errors.Wrap(err)
		return
	}

	// TODO write signature

	var n2 int
	n2, err = fmt.Fprintf(writer, "\n")
	n += int64(n2)

	if err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func (s V2) WriteInventoryListBlob(
	skus sku.Collection,
	writer io.Writer,
) (n int64, err error) {
	bufferedWriter := bufio.NewWriter(writer)
	defer errors.DeferredFlusher(&err, bufferedWriter)

	shaWriter := sha.MakeWriter(bufferedWriter)

	var n1 int64

	for sk := range skus.All() {
		n1, err = s.writeObjectListItemToWriter(sk, shaWriter)
		n += n1

		if err != nil {
			err = errors.Wrap(err)
			return
		}
	}

	return
}

func (s V2) WriteInventoryListObject(
	o *sku.Transacted,
	w1 io.Writer,
) (n int64, err error) {
	bw := bufio.NewWriter(w1)
	defer errors.DeferredFlusher(&err, bw)

	var n1 int64
	var n2 int

	n1, err = s.Box.EncodeStringTo(o, bw)
	n += n1

	if err != nil {
		err = errors.Wrap(err)
		return
	}

	n2, err = fmt.Fprintf(bw, "\n")
	n += int64(n2)

	if err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func (s V2) ReadInventoryListObject(
	r1 io.Reader,
) (n int64, o *sku.Transacted, err error) {
	o = sku.GetTransactedPool().Get()

	r := bufio.NewReader(r1)

	if n, err = s.Box.ReadStringFormat(o, r); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

type V2StreamCoder struct {
	V2
}

func (coder V2StreamCoder) DecodeFrom(
	output interfaces.FuncIter[*sku.Transacted],
	reader io.Reader,
) (n int64, err error) {
	bufferedReader := bufio.NewReader(reader)

	for {
		o := sku.GetTransactedPool().Get()

		if _, err = coder.Box.ReadStringFormat(o, bufferedReader); err != nil {
			if errors.IsEOF(err) {
				err = nil
				break
			} else {
				err = errors.Wrap(err)
				return
			}
		}

		if err = o.CalculateObjectShas(); err != nil {
			err = errors.Wrap(err)
			return
		}

		if err = output(o); err != nil {
			err = errors.Wrapf(err, "Object: %s", sku.String(o))
			return
		}
	}

	return
}

func (s V2) AllInventoryListBlobSkus(
	reader io.Reader,
) interfaces.SeqError[*sku.Transacted] {
	return interfaces.MakeSeqErrorWithError[*sku.Transacted](errors.ErrNotImplemented)
	// return func(yield func(*sku.Transacted, error) bool) {
	// 	bufferedReader := bufio.NewReader(reader)

	// 	for {
	// 		object := sku.GetTransactedPool().Get()

	// 		if _, err = s.Box.ReadStringFormat(object, bufferedReader); err != nil {
	// 			if errors.IsEOF(err) {
	// 				err = nil
	// 				break
	// 			} else {
	// 				err = errors.Wrap(err)
	// 				return
	// 			}
	// 		}

	// 		if err = object.CalculateObjectShas(); err != nil {
	// 			err = errors.Wrap(err)
	// 			return
	// 		}

	// 		if err = output(object); err != nil {
	// 			err = errors.Wrapf(err, "Object: %s", sku.String(object))
	// 			return
	// 		}
	// 	}

	// 	return
	// }
}

func (s V2) StreamInventoryListBlobSkus(
	reader io.Reader,
	output interfaces.FuncIter[*sku.Transacted],
) (err error) {
	bufferedReader := bufio.NewReader(reader)

	for {
		object := sku.GetTransactedPool().Get()

		if _, err = s.Box.ReadStringFormat(object, bufferedReader); err != nil {
			if errors.IsEOF(err) {
				err = nil
				break
			} else {
				err = errors.Wrap(err)
				return
			}
		}

		if err = object.CalculateObjectShas(); err != nil {
			err = errors.Wrap(err)
			return
		}

		if err = output(object); err != nil {
			err = errors.Wrapf(err, "Object: %s", sku.String(object))
			return
		}
	}

	return
}

type V2ObjectCoder struct {
	V2
}

func (s V2ObjectCoder) EncodeTo(
	o *sku.Transacted,
	w1 io.Writer,
) (n int64, err error) {
	bw := bufio.NewWriter(w1)
	defer errors.DeferredFlusher(&err, bw)

	var n1 int64
	var n2 int

	n1, err = s.Box.EncodeStringTo(o, bw)
	n += n1

	if err != nil {
		err = errors.Wrap(err)
		return
	}

	n2, err = fmt.Fprintf(bw, "\n")
	n += int64(n2)

	if err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func (s V2ObjectCoder) DecodeFrom(
	o *sku.Transacted,
	r1 io.Reader,
) (n int64, err error) {
	r := bufio.NewReader(r1)

	if n, err = s.Box.ReadStringFormat(o, r); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

type V2IterDecoder struct {
	V2
}

func (coder V2IterDecoder) DecodeFrom(
	yield func(*sku.Transacted) bool,
	reader io.Reader,
) (n int64, err error) {
	bufferedReader := bufio.NewReader(reader)

	for {
		object := sku.GetTransactedPool().Get()

		if _, err = coder.Box.ReadStringFormat(object, bufferedReader); err != nil {
			if errors.IsEOF(err) {
				err = nil
				break
			} else {
				err = errors.Wrap(err)
				return
			}
		}

		if err = object.CalculateObjectShas(); err != nil {
			err = errors.Wrap(err)
			return
		}

		if !yield(object) {
			return
		}
	}

	return
}
