package browser

import (
	"strings"

	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
)

type Browser string

const (
	Chrome   Browser = "chrome"
	Chromium Browser = "chromium"
	Firefox  Browser = "firefox"
)

func (b *Browser) String() string {
	return string(*b)
}

func (b *Browser) Set(v string) (err error) {
	v0 := v

  b1 := Browser(strings.TrimSpace(strings.ToLower(v)))

	switch b1 {
	case Chrome:
	case Chromium:
	case Firefox:

	case "":
		return

	default:
		err = errors.Errorf("unsupported browser: %q", v0)
		return
	}

  *b = b1

	return
}

func (b *Browser) MarshalText() (t []byte, err error) {
	t = []byte(b.String())
	return
}

func (b *Browser) UnmarshalText(t []byte) (err error) {
	if err = b.Set(string(t)); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}
