package query

import "code.linenisgreat.com/zit/go/src/echo/ids"

type pinnedObjectId struct {
	ids.Sigil
	ObjectId
}
