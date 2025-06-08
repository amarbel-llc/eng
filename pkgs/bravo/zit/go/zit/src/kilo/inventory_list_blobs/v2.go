package inventory_list_blobs

import (
	"bufio"
	"fmt"
	"io"

	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
	"code.linenisgreat.com/zit/go/zit/src/alfa/interfaces"
	"code.linenisgreat.com/zit/go/zit/src/bravo/pool"
	"code.linenisgreat.com/zit/go/zit/src/charlie/ohio"
	"code.linenisgreat.com/zit/go/zit/src/charlie/repo_signing"
	"code.linenisgreat.com/zit/go/zit/src/delta/config_immutable"
	"code.linenisgreat.com/zit/go/zit/src/delta/sha"
	"code.linenisgreat.com/zit/go/zit/src/echo/ids"
	"code.linenisgreat.com/zit/go/zit/src/foxtrot/builtin_types"
	"code.linenisgreat.com/zit/go/zit/src/juliett/sku"
	"code.linenisgreat.com/zit/go/zit/src/kilo/box_format"
)

type V2 struct {
	V2ObjectCoder
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

	bufferedWriter := ohio.BufferedWriter(list.Mover)
	defer pool.GetBufioWriter().Put(bufferedWriter)

	if n, err = format.EncodeTo(
		object,
		bufferedWriter,
	); err != nil {
		err = errors.Wrap(err)
		return
	}

	if err = bufferedWriter.Flush(); err != nil {
		err = errors.Wrap(err)
		return
	}

	list.LastTai = object.GetTai()
	list.Len += 1

	return
}

func (format V2) WriteInventoryListBlob(
	skus sku.Collection,
	bufferedWriter *bufio.Writer,
) (n int64, err error) {
	var n1 int64

	for sk := range skus.All() {
		n1, err = format.EncodeTo(sk, bufferedWriter)
		n += n1

		if err != nil {
			err = errors.Wrap(err)
			return
		}
	}

	return
}

func (s V2) WriteInventoryListObject(
	object *sku.Transacted,
	bufferedWriter *bufio.Writer,
) (n int64, err error) {
	var n1 int64
	var n2 int

	n1, err = s.Box.EncodeStringTo(object, bufferedWriter)
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

func (format V2) ReadInventoryListObject(
	reader *bufio.Reader,
) (n int64, object *sku.Transacted, err error) {
	object = sku.GetTransactedPool().Get()

	if n, err = format.DecodeFrom(object, reader); err != nil {
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
	bufferedReader *bufio.Reader,
) (n int64, err error) {
	for {
		object := sku.GetTransactedPool().Get()
		defer sku.GetTransactedPool().Put(object)

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

		if err = output(object); err != nil {
			err = errors.Wrapf(err, "Object: %s", sku.String(object))
			return
		}
	}

	return
}

func (s V2) AllInventoryListBlobSkus(
	reader *bufio.Reader,
) interfaces.SeqError[*sku.Transacted] {
	return interfaces.MakeSeqErrorWithError[*sku.Transacted](
		errors.ErrNotImplemented,
	)
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

func (format V2) StreamInventoryListBlobSkus(
	bufferedReader *bufio.Reader,
	output interfaces.FuncIter[*sku.Transacted],
) (err error) {
	for {
		object := sku.GetTransactedPool().Get()
		// TODO Fix upstream issues with repooling
		// defer sku.GetTransactedPool().Put(object)

		if _, err = format.Box.ReadStringFormat(
			object,
			bufferedReader,
		); err != nil {
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
	Box                    *box_format.BoxTransacted
	ImmutableConfigPrivate config_immutable.ConfigPrivate
}

func (coder V2ObjectCoder) EncodeTo(
	object *sku.Transacted,
	bufferedWriter *bufio.Writer,
) (n int64, err error) {
	if object.Metadata.Sha().IsNull() {
		err = errors.ErrorWithStackf("empty sha: %q", sku.String(object))
		return
	}

	shaWriter := sha.MakeWriter(bufferedWriter)

	var n1 int64
	var n2 int

	n1, err = coder.Box.EncodeStringTo(object, shaWriter)
	n += n1

	if err != nil {
		err = errors.Wrap(err)
		return
	}

	// write signature box
	{
		sh := sha.Make(shaWriter.GetShaLike())
		defer sha.GetPool().Put(sh)

		key := coder.ImmutableConfigPrivate.GetPrivateKey()

		var sig string

		if sig, err = repo_signing.SignBase64(key, sh.GetShaBytes()); err != nil {
			err = errors.Wrap(err)
			return
		}

		object.Signature = sig

		n2, err = fmt.Fprintf(bufferedWriter, ":%s\n", sig)
		n += int64(n2)

		if err != nil {
			err = errors.Wrap(err)
			return
		}
	}

	n2, err = fmt.Fprintf(bufferedWriter, "\n")
	n += int64(n2)

	if err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func (coder V2ObjectCoder) DecodeFrom(
	object *sku.Transacted,
	bufferedReader *bufio.Reader,
) (n int64, err error) {
	shaWriter := sha.MakeWriter(nil)
	teeReader := ohio.TeeRuneScanner(bufferedReader, shaWriter)

	if n, err = coder.Box.ReadStringFormat(object, teeReader); err != nil {
		if err == io.EOF {
			err = nil

			if n == 0 {
				return
			}
		} else {
			err = errors.Wrap(err)
			return
		}
	}

	// TODO read signature box
	// if err = repo_signing.VerifyBase64Signature(
	// 	roundTripper.PublicKey,
	// 	nonceBytes,
	// 	response.Header.Get(headerChallengeResponse),
	// ); err != nil {
	// 	err = errors.Wrap(err)
	// 	return
	// }
	// sh := sha.Make(shaWriter.GetShaLike())

	// if object.Signature, err = bufferedReader.ReadString('\n'); err != nil {
	// 	err = errors.Wrap(err)
	// 	return
	// }

	// object.Signature = strings.TrimPrefix(
	// 	strings.TrimSuffix(object.Signature, "\n"),
	// 	":",
	// )

	// ui.Debug().Print(sh, object.Signature)

	// if len(object.Signature) == 0 {
	// 	err = errors.Errorf("signature missing for %s", sku.String(object))
	// 	return
	// }

	// if err = repo_signing.VerifyBase64Signature(
	// 	coder.ImmutableConfigPrivate.GetPublicKey(),
	// 	sh.GetShaBytes(),
	// 	object.Signature,
	// ); err != nil {
	// 	err = errors.Wrap(err)
	// 	return
	// }

	if err = object.CalculateObjectShas(); err != nil {
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
	bufferedReader *bufio.Reader,
) (n int64, err error) {
	for {
		object := sku.GetTransactedPool().Get()
		// TODO Fix upstream issues with repooling
		// defer sku.GetTransactedPool().Put(object)

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
