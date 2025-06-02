package client

import (
	"fmt"
	"net/url"
	"strings"

	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
)

type BrowserItem struct {
	Id         BrowserItemId `json:"id"`
	Url        string        `json:"url"`
	Date       string        `json:"date"`
	Title      string        `json:"title"`
	ExternalId string        `json:"external-id"` // external to the browser, so for us, it's actually our id
}

func (i BrowserItem) GetUrl() (u *url.URL, err error) {
	ur := i.Url

	if ur == "" {
		err = errors.Errorf("empty url")
		return
	}

	if u, err = url.Parse(ur); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

type BrowserId struct {
	Browser string `json:"browser"`
	Pid     string `json:"pid"`
}

func (bi BrowserId) String() string {
	var sb strings.Builder

	sb.WriteString("browser")

	if bi.Browser == "" {
		return sb.String()
	}

	fmt.Fprintf(&sb, "-%s", bi.Browser)

	if bi.Pid == "" {
		return sb.String()
	}

	fmt.Fprintf(&sb, "-%s", bi.Pid)

	return sb.String()
}

type BrowserItemId struct {
	BrowserId BrowserId `json:"browser-id"`
	Id        string    `json:"id"`
	Type      string    `json:"type"`
}

func (bi BrowserItemId) String() string {
	return fmt.Sprintf("/%s/%s-%s", bi.BrowserId, bi.Type, bi.Id)
}
