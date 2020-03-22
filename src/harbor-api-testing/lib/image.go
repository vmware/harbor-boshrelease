package lib

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/vmware/harbor-boshrelease/src/harbor-api-testing/client"
	"github.com/vmware/harbor-boshrelease/src/harbor-api-testing/models"
)

const (
	// MimeTypeNativeReport defines the mime type for native report
	MimeTypeNativeReport = "application/vnd.scanner.adapter.vuln.report.harbor+json; version=1.0"
)

//ImageUtil : For repository and tag functions
type ImageUtil struct {
	rootURI       string
	testingClient *client.APIClient
}

//NewImageUtil : Constructor
func NewImageUtil(rootURI string, httpClient *client.APIClient) *ImageUtil {
	if len(strings.TrimSpace(rootURI)) == 0 || httpClient == nil {
		return nil
	}

	return &ImageUtil{
		rootURI:       rootURI,
		testingClient: httpClient,
	}
}

//DeleteRepo : Delete repo
func (iu *ImageUtil) DeleteRepo(projectName, repoName string) error {
	if len(strings.TrimSpace(repoName)) == 0 {
		return errors.New("Empty repo name for deleting")
	}
	url := fmt.Sprintf("%s/api/v2.0/projects/%s/repositories/%s/_self", iu.rootURI, projectName, repoName)
	if err := iu.testingClient.Delete(url); err != nil {
		return err
	}

	return nil
}

//ScanTag :Scan a tag
func (iu *ImageUtil) ScanTag(projectName, repoName, sha256 string) error {
	if len(strings.TrimSpace(repoName)) == 0 {
		return errors.New("Empty repo name for scanning")
	}
	url := fmt.Sprintf("%s/api/v2.0/projects//%s/repositories/%s/artifacts/%s/scan", iu.rootURI, projectName, repoName, sha256)

	if err := iu.testingClient.Post(url, nil); err != nil {
		return err
	}

	tk := time.NewTicker(1 * time.Second)
	defer tk.Stop()
	done := make(chan bool)
	errchan := make(chan error)
	resultURL := fmt.Sprintf("%s/api/v2.0/projects/%s/repositories/%s/artifacts/%s?with_scan_overview=true", iu.rootURI, projectName, repoName, sha256)
	go func() {
		for range tk.C {
			data, err := iu.testingClient.Get(resultURL)
			if err != nil {
				errchan <- err
				return
			}
			var tag models.Tag
			if err = json.Unmarshal(data, &tag); err != nil {
				errchan <- err
				return
			}

			if tag.ScanOverview != nil {
				summary, ok := tag.ScanOverview[MimeTypeNativeReport]
				if ok && summary.Status == "Success" {
					done <- true
				}
			}
		}
	}()

	select {
	case <-done:
		return nil
	case <-time.After(20 * time.Second):
		return errors.New("Scan timeout after 30 seconds")
	}
}

//GetRepos : Get repos in the project
func (iu *ImageUtil) GetRepos(projectName string) ([]models.Repository, error) {
	if len(strings.TrimSpace(projectName)) == 0 {
		return nil, errors.New("Empty project name for getting repos")
	}

	proUtil := NewProjectUtil(iu.rootURI, iu.testingClient)
	pid := proUtil.GetProjectID(projectName)
	if pid == -1 {
		return nil, fmt.Errorf("Failed to get project ID with name %s", projectName)
	}

	url := fmt.Sprintf("%s%s%d", iu.rootURI, "/api/v2.0/repositories?project_id=", pid)
	data, err := iu.testingClient.Get(url)
	if err != nil {
		return nil, err
	}

	var repos []models.Repository
	if err = json.Unmarshal(data, &repos); err != nil {
		return nil, err
	}

	return repos, nil
}

//GetArtifacts ... get artifact in current repo
func (iu *ImageUtil) GetArtifacts(projectName, repoName string) ([]models.Artifact, error) {
	if len(projectName) == 0 || len(repoName) == 0 {
		return nil, errors.New("project name and reponame can not be empty")
	}
	url := fmt.Sprintf("%s/api/v2.0/projects/%s/repositories/%s/artifacts?with_tag=true&with_scan_overview=true&with_label=true", iu.rootURI, projectName, repoName)
	var artifacts []models.Artifact
	artifactData, err := iu.testingClient.Get(url)
	if err != nil {
		return nil, err
	}
	if err = json.Unmarshal(artifactData, &artifacts); err != nil {
		return nil, err
	}
	return artifacts, nil
}
