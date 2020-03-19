package models

//Project : For /api/v2.0/projects
type Project struct {
	Name     string    `json:"project_name"`
	Metadata *Metadata `json:"metadata, omitempty"`
}

//Metadata : Metadata for project
type Metadata struct {
	AccessLevel string `json:"public"`
}

//ExistingProject : For /api/v2.0/projects?name=***
type ExistingProject struct {
	Name string `json:"name"`
	ID   int    `json:"project_id"`
}
