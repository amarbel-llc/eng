package store_config

import (
	"code.linenisgreat.com/zit/go/src/alfa/errors"
	"code.linenisgreat.com/zit/go/src/alfa/interfaces"
	"code.linenisgreat.com/zit/go/src/echo/ids"
	"code.linenisgreat.com/zit/go/src/golf/config_mutable_blobs"
	"code.linenisgreat.com/zit/go/src/lima/typed_blob_store"
)

type mutable_config_blob struct {
	typedConfigBlobStore typed_blob_store.Config
	config_mutable_blobs.Blob
}

func (k *mutable_config_blob) loadMutableConfigBlob(
	mutableConfigType ids.Type,
	blobSha interfaces.Sha,
) (err error) {
	if k.Blob, _, err = k.typedConfigBlobStore.ParseTypedBlob(
		mutableConfigType,
		blobSha,
	); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}
