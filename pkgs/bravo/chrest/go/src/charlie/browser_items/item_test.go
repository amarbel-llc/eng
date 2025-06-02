package browser_items

import (
	"encoding/json"
	"strings"
	"testing"

	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
	"code.linenisgreat.com/zit/go/zit/src/bravo/test_logz"
)

func TestMain(m *testing.M) {
	errors.SetTesting()
	m.Run()
}

// TODO fix this test
func TestJSONMarshalUnmarshal(t1 *testing.T) {
	t := test_logz.T{T: t1}

	jsonString := `
  {
    "date": "2024-09-11T20:51:31.655Z",
    "id": {
      "browser": {
        "browser": "firefox",
        "id": "ddog"
      },
      "id": "jBlIt0RX6whu",
      "type": "history"
    },
    "title": "wallaby",
    "url": "https://wallaby.com"
  }
  `

	var item Item
	dec := json.NewDecoder(strings.NewReader(jsonString))
	err := dec.Decode(&item)
	t.AssertNoError(err)

	var sb strings.Builder
	enc := json.NewEncoder(&sb)
	err = enc.Encode(&item)
	t.AssertNoError(err)

	// actual := sb.String()
	// expected := "{\"id\":{\"browser\":{\"browser\":\"firefox\",\"id\":\"ddog\"},\"type\":\"history\",\"id\":\"jBlIt0RX6whu\"},\"url\":{\"string\":\"https://wallaby.com\",\"parts\":{\"Scheme\":\"\",\"Opaque\":\"\",\"User\":null,\"Host\":\"\",\"Path\":\"\",\"RawPath\":\"\",\"OmitHost\":false,\"ForceQuery\":false,\"RawQuery\":\"\",\"Fragment\":\"\",\"RawFragment\":\"\"}},\"date\":\"2024-09-11T20 31.655Z\",\"title\":\"wallaby\",\"external_id\":\"\"}\n"

	// t.AssertEqual(expected, actual)
}
