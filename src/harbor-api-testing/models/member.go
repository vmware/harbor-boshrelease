package models

//Member : For /api/v2.0/projects/:pid/members
type Member struct {
	UserName string `json:"username"`
	Roles    []int  `json:"roles"`
}
