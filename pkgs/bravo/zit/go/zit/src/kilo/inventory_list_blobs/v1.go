package inventory_list_blobs

import (
	"bufio"
	"fmt"
	"io"

	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
	"code.linenisgreat.com/zit/go/zit/src/alfa/interfaces"
	"code.linenisgreat.com/zit/go/zit/src/bravo/pool"
	"code.linenisgreat.com/zit/go/zit/src/charlie/ohio"
	"code.linenisgreat.com/zit/go/zit/src/echo/ids"
	"code.linenisgreat.com/zit/go/zit/src/foxtrot/builtin_types"
	"code.linenisgreat.com/zit/go/zit/src/juliett/sku"
	"code.linenisgreat.com/zit/go/zit/src/kilo/box_format"
)

type V1 struct {
	V1ObjectCoder
}

func (v V1) GetListFormat() sku.ListFormat {
	return v
}

func (v V1) GetType() ids.Type {
	return ids.MustType(builtin_types.InventoryListTypeV1)
}

func (format V1) WriteObjectToOpenList(
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

func (format V1) writeObjectListItemToWriter(
	object *sku.Transacted,
	writer interfaces.WriterAndStringWriter,
) (n int64, err error) {
	if object.Metadata.Sha().IsNull() {
		err = errors.ErrorWithStackf("empty sha: %q", sku.String(object))
		return
	}

	if n, err = format.EncodeTo(object, writer); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func (s V1) WriteInventoryListBlob(
	o sku.Collection,
	w1 io.Writer,
) (n int64, err error) {
	bw := bufio.NewWriter(w1)
	defer errors.DeferredFlusher(&err, bw)

	var n1 int64

	for sk := range o.All() {
		n1, err = s.writeObjectListItemToWriter(sk, bw)
		n += n1

		if err != nil {
			err = errors.Wrap(err)
			return
		}
	}

	return
}

func (s V1) WriteInventoryListObject(
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

func (format V1) ReadInventoryListObject(
	reader io.Reader,
) (n int64, object *sku.Transacted, err error) {
	object = sku.GetTransactedPool().Get()

	if n, err = format.DecodeFrom(object, reader); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

type V1StreamCoder struct {
	V1
}

func (coder V1StreamCoder) DecodeFrom(
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

func (s V1) AllInventoryListBlobSkus(
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

func (s V1) StreamInventoryListBlobSkus(
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

type V1ObjectCoder struct {
	Box *box_format.BoxTransacted
}

func (coder V1ObjectCoder) EncodeTo(
	object *sku.Transacted,
	writer io.Writer,
) (n int64, err error) {
	bufferedWriter := ohio.BufferedWriter(writer)
	defer pool.FlushBufioWriterAndPut(&err, bufferedWriter)

	var n1 int64
	var n2 int

	n1, err = coder.Box.EncodeStringTo(object, bufferedWriter)
	n += n1

	if err != nil {
		err = errors.Wrap(err)
		return
	}

	n2, err = fmt.Fprintf(bufferedWriter, "\n")
	n += int64(n2)

	if err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func (coder V1ObjectCoder) DecodeFrom(
	object *sku.Transacted,
	reader io.Reader,
) (n int64, err error) {
	bufferedReader := ohio.BufferedReader(reader)
	defer pool.GetBufioReader().Put(bufferedReader)

	if n, err = coder.Box.ReadStringFormat(object, bufferedReader); err != nil {
		err = errors.Wrap(err)
		return
	}

	if err = object.CalculateObjectShas(); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

type V1IterDecoder struct {
	V1
}

func (coder V1IterDecoder) DecodeFrom(
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
