package ohio

import (
	"io"
	"unicode/utf8"

	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
)

func TeeRuneScanner(
	runeReader io.RuneScanner,
	writer io.Writer,
) teeRuneScanner {
	return teeRuneScanner{
		runeScanner: runeReader,
		writer:      writer,
	}
}

type teeRuneScanner struct {
	runeScanner io.RuneScanner
	writer      io.Writer
}

func (tee teeRuneScanner) UnreadRune() error {
	return errors.Errorf("not supported")
}

func (tee teeRuneScanner) ReadRune() (r rune, size int, err error) {
	r, size, err = tee.runeScanner.ReadRune()

	b := make([]byte, utf8.UTFMax)
	n := utf8.EncodeRune(b, r)

	if n != size {
		err = errors.Join(
			err,
			errors.Errorf("read rune size does not match encoded size. expected %d, but got %d", size, n),
		)

		return
	}

	if err != nil {
		err = errors.Wrap(err)
	}

	if _, errWrite := tee.writer.Write(b[:n]); errWrite != nil {
		err = errors.Join(err, errors.Wrap(errWrite))
		return
	}

	return
}
