package sku

import (
	"strings"

	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
	"code.linenisgreat.com/zit/go/zit/src/alfa/interfaces"
	"code.linenisgreat.com/zit/go/zit/src/bravo/values"
	"code.linenisgreat.com/zit/go/zit/src/charlie/external_state"
	"code.linenisgreat.com/zit/go/zit/src/charlie/repo_signing"
	"code.linenisgreat.com/zit/go/zit/src/delta/config_immutable"
	"code.linenisgreat.com/zit/go/zit/src/delta/genres"
	"code.linenisgreat.com/zit/go/zit/src/delta/sha"
	"code.linenisgreat.com/zit/go/zit/src/echo/ids"
	"code.linenisgreat.com/zit/go/zit/src/golf/object_metadata"
	"code.linenisgreat.com/zit/go/zit/src/hotel/object_inventory_format"
)

type Transacted struct {
	ObjectId ids.ObjectId
	Metadata object_metadata.Metadata

	ExternalType ids.Type

	// TODO add support for querying the below
	RepoId           ids.RepoId
	State            external_state.State
	ExternalObjectId ids.ExternalObjectId
}

func (t *Transacted) GetSkuExternal() *Transacted {
	return t
}

func (t *Transacted) GetRepoId() ids.RepoId {
	return t.RepoId
}

func (t *Transacted) GetExternalObjectId() ids.ExternalObjectIdLike {
	return &t.ExternalObjectId
}

func (t *Transacted) GetExternalState() external_state.State {
	return t.State
}

func (transacted *Transacted) CloneTransacted() (b *Transacted) {
	b = GetTransactedPool().Get()
	TransactedResetter.ResetWith(b, transacted)
	return
}

func (t *Transacted) GetSku() *Transacted {
	return t
}

func (transacted *Transacted) SetFromTransacted(b *Transacted) (err error) {
	TransactedResetter.ResetWith(transacted, b)

	return
}

func (transacted *Transacted) Less(b *Transacted) bool {
	less := transacted.GetTai().Less(b.GetTai())

	return less
}

func (transacted *Transacted) GetTags() ids.TagSet {
	return transacted.Metadata.GetTags()
}

func (transacted *Transacted) AddTagPtr(e *ids.Tag) (err error) {
	if transacted.ObjectId.GetGenre() == genres.Tag &&
		strings.HasPrefix(transacted.ObjectId.String(), e.String()) {
		return
	}

	ek := transacted.Metadata.Cache.GetImplicitTags().KeyPtr(e)

	if transacted.Metadata.Cache.GetImplicitTags().ContainsKey(ek) {
		return
	}

	if err = transacted.GetMetadata().AddTagPtr(e); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func (transacted *Transacted) AddTagPtrFast(e *ids.Tag) (err error) {
	if err = transacted.GetMetadata().AddTagPtrFast(e); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func (transacted *Transacted) GetType() ids.Type {
	return transacted.Metadata.Type
}

func (transacted *Transacted) GetMetadata() *object_metadata.Metadata {
	return &transacted.Metadata
}

func (transacted *Transacted) GetTai() ids.Tai {
	return transacted.Metadata.GetTai()
}

func (transacted *Transacted) SetTai(t ids.Tai) {
	transacted.GetMetadata().Tai = t
}

func (transacted *Transacted) GetObjectId() *ids.ObjectId {
	return &transacted.ObjectId
}

func (transacted *Transacted) SetObjectIdLike(kl interfaces.ObjectId) (err error) {
	if err = transacted.ObjectId.SetWithIdLike(kl); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func (transacted *Transacted) EqualsAny(b any) (ok bool) {
	return values.Equals(transacted, b)
}

func (transacted *Transacted) Equals(b *Transacted) (ok bool) {
	if transacted.GetObjectId().String() != b.GetObjectId().String() {
		return
	}

	// TODO-P2 determine why object shas in import test differed
	// if !a.Metadata.Sha().Equals(b.Metadata.Sha()) {
	// 	return
	// }

	if !transacted.Metadata.Equals(&b.Metadata) {
		return
	}

	return true
}

func (s *Transacted) GetGenre() interfaces.Genre {
	return s.ObjectId.GetGenre()
}

func (s *Transacted) IsNew() bool {
	return s.Metadata.Mutter().IsNull()
}

func (s *Transacted) CalculateObjectShaDebug() (err error) {
	return s.calculateObjectSha(true)
}

func (s *Transacted) CalculateObjectShas() (err error) {
	return s.calculateObjectSha(false)
}

func (transacted *Transacted) makeShaCalcFunc(
	f func(object_inventory_format.FormatGeneric, object_inventory_format.FormatterContext) (*sha.Sha, error),
	of object_inventory_format.FormatGeneric,
	sh *sha.Sha,
) errors.Func {
	return func() (err error) {
		var actual *sha.Sha

		if actual, err = f(
			of,
			transacted,
		); err != nil {
			err = errors.Wrap(err)
			return
		}

		defer sha.GetPool().Put(actual)

		sh.ResetWith(actual)

		return
	}
}

func (transacted *Transacted) calculateObjectSha(debug bool) (err error) {
	f := object_inventory_format.GetShaForContext

	if debug {
		f = object_inventory_format.GetShaForContextDebug
	}

	wg := errors.MakeWaitGroupParallel()

	wg.Do(
		transacted.makeShaCalcFunc(
			f,
			object_inventory_format.Formats.MetadataObjectIdParent(),
			transacted.Metadata.Sha(),
		),
	)

	wg.Do(
		transacted.makeShaCalcFunc(
			f,
			object_inventory_format.Formats.Metadata(),
			&transacted.Metadata.SelfMetadata,
		),
	)

	wg.Do(
		transacted.makeShaCalcFunc(
			f,
			object_inventory_format.Formats.MetadataSansTai(),
			&transacted.Metadata.SelfMetadataWithoutTai,
		),
	)

	return wg.GetError()
}

func (transacted *Transacted) SetDormant(v bool) {
	transacted.Metadata.Cache.Dormant.SetBool(v)
}

func (transacted *Transacted) SetObjectSha(v interfaces.Sha) (err error) {
	return transacted.GetMetadata().Sha().SetShaLike(v)
}

func (transacted *Transacted) GetObjectSha() interfaces.Sha {
	return transacted.GetMetadata().Sha()
}

func (transacted *Transacted) GetBlobSha() interfaces.Sha {
	return &transacted.Metadata.Blob
}

func (transacted *Transacted) SetBlobSha(sh interfaces.Sha) error {
	return transacted.Metadata.Blob.SetShaLike(sh)
}

func (transacted *Transacted) GetKey() string {
	return ids.FormattedString(transacted.GetObjectId())
}

func (transacted *Transacted) Sign(
	config config_immutable.ConfigPrivate,
) (err error) {
	transacted.Metadata.RepoPubKey = config.GetPublicKey()

	sh := sha.Make(transacted.GetTai().GetShaLike())
	defer sha.GetPool().Put(sh)

	if transacted.Metadata.RepoSig, err = repo_signing.Sign(
		config.GetPrivateKey(),
		sh.GetShaBytes(),
	); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

type transactedLessorTaiOnly struct{}

func (transactedLessorTaiOnly) Less(a, b *Transacted) bool {
	return a.GetTai().Less(b.GetTai())
}

func (transactedLessorTaiOnly) LessPtr(a, b *Transacted) bool {
	return a.GetTai().Less(b.GetTai())
}

type transactedLessorStable struct{}

func (transactedLessorStable) Less(a, b *Transacted) bool {
	if result := a.GetTai().SortCompare(b.GetTai()); !result.Equal() {
		return result.Less()
	}

	return a.GetObjectId().String() < b.GetObjectId().String()
}

func (transactedLessorStable) LessPtr(a, b *Transacted) bool {
	return a.GetTai().Less(b.GetTai())
}

type transactedEqualer struct{}

func (transactedEqualer) Equals(a, b *Transacted) bool {
	return a.Equals(b)
}
