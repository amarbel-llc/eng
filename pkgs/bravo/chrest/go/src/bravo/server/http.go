package server

import (
	"encoding/json"
	"io"
	"net/http"
	"os"

	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
	"code.linenisgreat.com/zit/go/zit/src/bravo/ui"
)

type (
	JSONAnything          = interface{}
	JSONObject            = map[string]JSONAnything
	JSONArray             = []JSONAnything
	ServerRequestJSONBody JSONObject
)

func NewRequest(in *http.Request, body JSONAnything) (out ServerRequestJSONBody) {
	out = map[string]interface{}{
		"type":   "http",
		"path":   in.URL.Path,
		"method": in.Method,
		"body":   body,
	}

	return
}

func (s *Server) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	ui.Err().Printf("received request: %s", req)

	enc := json.NewEncoder(w)

	dec := json.NewDecoder(req.Body)

	w.Header().Set("Content-Type", "application/json")

	var err error

	var m JSONAnything

	err = dec.Decode(&m)

	if err == io.EOF {
		err = nil
	}

	if err != nil {
		flushError(err, enc, w, req)
	}

	var n int64
	ui.Err().Print("will write to browser")
	n, err = WriteToBrowser(NewRequest(req, m))
	ui.Err().Printf("wrote %d bytes to browser", n)
	if err != nil {
		flushError(err, enc, w, req)
	}

	var res JSONObject

	// TODO handle case when extension is offline
	ui.Err().Print("will read from browser")
	n, err = ReadFromBrowser(&res)
	ui.Err().Printf("read %d bytes from browser", n)

	if errors.IsEOF(err) {
		flushError(
			errors.Errorf("extension service ffline"),
			enc,
			w,
			req,
		)
	}

	if err != nil && err != io.EOF {
		flushError(err, enc, w, req)
	}

	{
		msgType, ok := res["type"].(string)

		if !ok {
			flushServerError(
				errors.Errorf("expected response to have `type` key. Response: %q", res),
				enc,
				w,
				req,
			)

			return
		}

		switch msgType {
		case "http":
			break

		case "who-am-i":
			err := errors.Errorf("Received a request to restart with new browser id.")
			flushServerError(err, enc, w, req)

			s.CancelWithError(err)

			return

		default:
			err := errors.Errorf("unsupported message type: %q", msgType)
			flushServerError(err, enc, w, req)

			s.CancelWithError(err)

			return
		}
	}

	{
		headers, ok := res["headers"].(map[string]interface{})

		if !ok {
			flushServerError(
				errors.Errorf("expected %T but got %T", headers, res["headers"]),
				enc,
				w,
				req,
			)

			return
		}

		for k, v := range headers {
			vs, ok := v.(string)

			if !ok {
				flushServerError(
					errors.Errorf("expected %T but got %T", vs, v),
					enc,
					w,
					req,
				)
			}

			w.Header().Add(k, vs)
		}
	}

	w.WriteHeader(int(res["status"].(float64)))

	b, ok := res["body"]

	if !ok {
		return
	}

	switch bjo := b.(type) {
	case JSONObject:
		if len(bjo) == 0 {
			return
		}

	case []JSONObject:
		if len(bjo) == 0 {
			return
		}
	}

	err = enc.Encode(b)
	if err != nil {
		flushError(err, enc, w, req)
	}
}

func ServeHTTPDebug(w http.ResponseWriter, req *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	w.WriteHeader(http.StatusOK)

	enc := json.NewEncoder(w)
	env := os.Environ()

	err := enc.Encode(env)
	if err != nil {
		flushError(err, enc, w, req)
	}
}

func flushServerError(
	err error,
	enc *json.Encoder,
	w http.ResponseWriter,
	req *http.Request,
) {
	flushErrorGeneric(err, enc, w, req, http.StatusInternalServerError)
}

func flushError(
	err error,
	enc *json.Encoder,
	w http.ResponseWriter,
	req *http.Request,
) {
	flushErrorGeneric(err, enc, w, req, http.StatusBadRequest)
}

func flushErrorGeneric(
	err error,
	enc *json.Encoder,
	w http.ResponseWriter,
	req *http.Request,
	statusCode int,
) {
	w.WriteHeader(statusCode)

	type errResponse struct {
		Error string `json:"error"`
	}

	res := errResponse{
		Error: err.Error(),
	}

	err = enc.Encode(res)
	if err != nil {
		panic(err)
	}
}
