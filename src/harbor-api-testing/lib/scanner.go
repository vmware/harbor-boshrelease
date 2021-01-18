package lib

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/vmware/harbor-boshrelease/src/harbor-api-testing/client"
	"strings"
)

type ScannerUtil struct {
	rootURI       string
	testingClient *client.APIClient
}

type Scanner struct {
	UUID      string `json:"uuid"`
	Name      string `json:"name"`
	IsDefault bool   `json:"is_default"`
}

func NewScannerUtil(rootURI string, httpClient *client.APIClient) *ScannerUtil {
	if len(strings.TrimSpace(rootURI)) == 0 || httpClient == nil {
		return nil
	}

	return &ScannerUtil{
		rootURI:       rootURI,
		testingClient: httpClient,
	}
}

func (su *ScannerUtil) GetScanners() ([]Scanner, error) {
	url := fmt.Sprintf("%v/api/v2.0/scanners", su.rootURI)
	data, err := su.testingClient.Get(url)
	if err != nil {
		return nil, err
	}
	var scanners []Scanner
	if err = json.Unmarshal(data, &scanners); err != nil {
		return nil, err
	}
	return scanners, nil
}

func (su *ScannerUtil) SetDefaultScannerToTrivy() error {
	scanners, err := su.GetScanners()
	if err != nil {
		return err
	}
	var trivyUUID string
	for _, s := range scanners {
		if strings.EqualFold(s.Name, "trivy") {
			trivyUUID = s.UUID
		}
	}
	if len(trivyUUID) == 0 {
		return errors.New("trivy scanner is not registered!")
	}
	return su.SetDefaultScanner(trivyUUID)
}

func (su *ScannerUtil) SetDefaultScanner(uuid string) error {
	url := fmt.Sprintf("%v/api/v2.0/scanners/%v", su.rootURI, uuid)
	payload := `{"is_default":true}`
	return su.testingClient.Patch(url, []byte(payload))
}
