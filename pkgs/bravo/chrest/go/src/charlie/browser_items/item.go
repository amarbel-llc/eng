package browser_items

type Item struct {
	Id         ItemId `json:"id"`
	Url        Url    `json:"url"`
	Date       string `json:"date"`
	Title      string `json:"title"`
	ExternalId string `json:"external_id"` // external to the browser, so for us, it's actually our id
}


