package models

//Endpoint : For /api/v2.0/targets
type Endpoint struct {
	Endpoint string `json:"endpoint"`
	Name     string `json:"name"`
	Username string `json:"username"`
	Password string `json:"password"`
	Type     int    `json:"type"`
}
