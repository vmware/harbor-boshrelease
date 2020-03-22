package models

//Member : For /api/v2.0/projects/:pid/members
type Member struct {
	MemberUser *MemUser `json:"member_user,omitempty"`
	RoleID     int      `json:"role_id,omitempty"`
}

// MemUser ...
type MemUser struct {
	UserName string `json:"username"`
}

//ExistingMember : For GET /api/projects/20/members
type ExistingMember struct {
	MID    int    `json:"id"`
	Name   string `json:"entity_name"`
	RoleID int    `json:"role_id"`
}
