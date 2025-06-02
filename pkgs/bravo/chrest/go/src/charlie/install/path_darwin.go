package install

import (
	"code.linenisgreat.com/chrest/go/src/alfa/browser"
	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
)

func GetUserPath(b browser.Browser) string {
	switch b {
	case browser.Chrome:
		return "Library/Application Support/Google/Chrome/NativeMessagingHosts"

	case browser.Chromium:
		return "Library/Application Support/Chromium/NativeMessagingHosts"

	case browser.Firefox:
		return "Library/Application Support/Mozilla/NativeMessagingHosts"

	default:
		panic(errors.Errorf("unsupported browser: %s", b))
	}
}
