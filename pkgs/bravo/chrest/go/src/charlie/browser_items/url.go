package browser_items

import (
	"net/url"

	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
)

type Url struct {
	url url.URL
}

func (u *Url) Set(v string) (err error) {
	if err = u.url.UnmarshalBinary([]byte(v)); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func (u Url) String() string {
	return u.url.String()
}

func (u Url) Url() url.URL {
	return u.url
}

func (u Url) MarshalText() (b []byte, err error) {
	if b, err = u.url.MarshalBinary(); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func (u *Url) UnmarshalText(b []byte) (err error) {
	if err = u.url.UnmarshalBinary(b); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}
