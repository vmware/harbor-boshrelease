package models

//SystemInfo : For GET /api/v2.0/systeminfo
type SystemInfo struct {
	AuthMode    string `json:"auth_mode"`
	RegistryURL string `json:"registry_url"`
}
