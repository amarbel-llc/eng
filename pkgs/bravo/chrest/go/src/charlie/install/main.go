package install

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"path"
	"path/filepath"
	"slices"
	"strings"

	"code.linenisgreat.com/chrest/go/src/alfa/browser"
	"code.linenisgreat.com/chrest/go/src/bravo/config"
	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
	"code.linenisgreat.com/zit/go/zit/src/charlie/files"
)

type IdSet struct {
	browser.Browser
	Ids []string
}

func (is IdSet) String() string {
	var sb strings.Builder

	for i, v := range is.Ids {
		if i > 0 {
			sb.WriteRune(',')
			sb.WriteString(v)
		}
	}

	return sb.String()
}

func (is *IdSet) Set(v string) (err error) {
	is.Ids = append(is.Ids, v)
	return
}

func (is IdSet) GetDefaultId() string {
	switch is.Browser {
	case browser.Chrome, browser.Chromium:
		return "faeaeoifckcedjniagocclagdbbkifgo"

	case browser.Firefox:
		return "chrest@code.linenisgreat.com"

	default:
		panic(errors.Errorf("unsupported browser: %s", is.Browser))
	}
}

type (
	JSONCommon struct {
		Name        string `json:"name"`
		Description string `json:"description"`
		Path        string `json:"path"`
		Type        string `json:"type"`
	}

	JSONFirefox struct {
		JSONCommon
		AllowedExtensions []string `json:"allowed_extensions"`
	}

	JSONChromeOrChromium struct {
		JSONCommon
		AllowedOrigins []string `json:"allowed_origins"`
	}
)

func (is *IdSet) Install(c config.Config) (loc string, ij any, err error) {
	dir := path.Join(
		c.Home,
		GetUserPath(is.Browser),
	)

	loc = path.Join(
		dir,
		"com.linenisgreat.code.chrest.json",
	)

	if loc, err = filepath.Abs(loc); err != nil {
		err = errors.Wrap(err)
		return
	}

	var f *os.File

	if f, err = files.OpenReadWrite(loc); err != nil {
		err = errors.Wrap(err)
		return
	}

	br := bufio.NewReader(f)
	dec := json.NewDecoder(br)

	defer errors.DeferredCloser(&err, f)

	serverPath := c.ServerPath()

	is.Ids = append(is.Ids, is.GetDefaultId())

	common := JSONCommon{
		Name:        "com.linenisgreat.code.chrest",
		Description: "HTTP or socket server for management",
		Path:        serverPath,
		Type:        "stdio",
	}

	switch is.Browser {
	case browser.Chrome, browser.Chromium:
		var existing JSONChromeOrChromium

		if err = dec.Decode(&existing); err != nil {
			if errors.IsEOF(err) {
				err = nil
			} else {
				err = errors.Wrap(err)
				return
			}
		}

		for _, id := range is.Ids {
			existing.AllowedOrigins = append(
				existing.AllowedOrigins,
				fmt.Sprintf("chrome-extension://%s/", id),
			)
		}

		slices.Sort(existing.AllowedOrigins)
		existing.AllowedOrigins = slices.Compact(existing.AllowedOrigins)

		existing.JSONCommon = common
		ij = existing

	case browser.Firefox:
		var existing JSONFirefox

		if err = dec.Decode(&existing); err != nil {
			if errors.IsEOF(err) {
				err = nil
			} else {
				err = errors.Wrap(err)
				return
			}
		}

		existing.AllowedExtensions = append(existing.AllowedExtensions, is.Ids...)
		slices.Sort(existing.AllowedExtensions)
		existing.AllowedExtensions = slices.Compact(existing.AllowedExtensions)

		existing.JSONCommon = common
		ij = existing

	default:
		err = errors.Errorf("unsupported browser: %s", is.Browser)
		return
	}

	var b []byte

	if b, err = json.Marshal(ij); err != nil {
		err = errors.Wrap(err)
		return
	}

	if err = os.MkdirAll(dir, 0o700); err != nil {
		err = errors.Wrap(err)
		return
	}

	if err = os.WriteFile(loc, b, 0o666); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}
