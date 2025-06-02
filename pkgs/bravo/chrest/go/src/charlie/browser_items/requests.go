package browser_items

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"strings"

	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
)

type RequestPayloadPut struct {
	Deleted []Item `json:"deleted"`
	Added   []Item `json:"added"`
	Focused []Item `json:"focused"`
}

type RequestPayloadGet []Item

type (
	BrowserRequestGet struct{}
	BrowserRequestPut RequestPayloadPut
)

func (BrowserRequestGet) MakeHTTPRequest(
	ctx context.Context,
) (req *http.Request, err error) {
	if req, err = http.NewRequestWithContext(
		ctx,
		"GET",
		"/items",
		nil,
	); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func (br BrowserRequestPut) MakeHTTPRequest(
	ctx context.Context,
) (req *http.Request, err error) {
	b := bytes.NewBuffer(nil)

	if req, err = http.NewRequestWithContext(
		ctx,
		"PUT",
		"/items",
		io.NopCloser(b),
	); err != nil {
		err = errors.Wrap(err)
		return
	}

	enc := json.NewEncoder(b)

	if err = enc.Encode(br); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

type HTTPResponseWithRequestPayloadPut struct {
	*http.Response
	RequestPayloadPut
}

func (resp *HTTPResponseWithRequestPayloadPut) parseResponse() (err error) {
	var sb strings.Builder
	dec := json.NewDecoder(io.TeeReader(resp.Response.Body, &sb))

	if err = dec.Decode(&resp.RequestPayloadPut); err != nil {
		err = errors.Wrapf(err, "Response: %q", sb.String())
		return
	}

	return
}

type HTTPResponseWithRequestPayloadGet struct {
	*http.Response
	RequestPayloadGet
}

func (resp *HTTPResponseWithRequestPayloadGet) parseResponse() (err error) {
	dec := json.NewDecoder(resp.Response.Body)

	if err = dec.Decode(&resp.RequestPayloadGet); err != nil {
		err = errors.Wrapf(err, "Response: %#v", resp)
		return
	}

	return
}
