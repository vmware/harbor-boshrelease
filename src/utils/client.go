package main

import (
	"bytes"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"math/rand"
	"net/http"
	"os"
	"strings"
	"time"
)

const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

var seededRand *rand.Rand = rand.New(rand.NewSource(time.Now().UnixNano()))

// UAAProfile - uaa config info
type UAAProfile struct {
	Scope                []string `json:"scope"`
	ClientID             string   `json:"client_id"`
	ClientSecret         string   `json:"client_secret"`
	ResourceIds          []string `json:"resource_ids"`
	AuthorizedGrantTypes []string `json:"authorized_grant_types"`
	RedirectURI          []string `json:"redirect_uri"`
	Authorities          []string `json:"authorities"`
	TokenSalt            string   `json:"token_salt"`
	Autoapprove          bool     `json:"autoapprove"`
	Name                 string   `json:"name"`
	Allowedproviders     []string `json:"allowedproviders,omitempty"`
}

var trace = false

// Trace - print trace info when verbose is enabled
func Trace(info interface{}) {
	if trace {
		fmt.Println(info)
	}
}

// ConfigClient - config client
type ConfigClient struct {
	client    *http.Client
	harborUrl string
	username  string
	password  string
}

func newConfigClient(client *http.Client, harborUrl string, username string, password string) *ConfigClient {
	return &ConfigClient{client: client, harborUrl: harborUrl, username: username, password: password}
}

func main() {

	// Usage:
	// Print the uaa configure json with token_salt:
	// utils --show-uaa --uaa-json /data/secret/keys/uaa.json
	// Configure the uaa setting in Harbor with current uaa.json
	// utils -config-uaa -harbor-server https://10.186.197.207 -password Harbor12345 -uaa-server https://api.pks.local  -verify-cert
	// Configure the oidc setting in Harbor with current uaa.json
	// utils -config-oidc -harbor-server https://10.186.197.207 -password Harbor12345 -uaa-server https://api.pks.local  -verify-cert

	isShowUAA := flag.Bool("show-uaa", false, "Display UAA json which add token salt info")
	trustedCA := flag.String("trusted-ca", "/var/vcap/jobs/harbor/config/ca.crt", "Trusted certificate")
	insecure := flag.Bool("insecure", false, "insecure")
	isConfigUAA := flag.Bool("config-uaa", false, "Config UAA")
	isConfigOIDC := flag.Bool("config-oidc", false, "Config OIDC")
	harborServerUrl := flag.String("harbor-server", "", "Harbor server url to configure")
	uaaJsonPath := flag.String("uaa-json", "/var/vcap/jobs/harbor/config/uaa.json", "uaa json file path")
	password := flag.String("password", "", "password to configure harbor")
	tokenSaltFile := flag.String("salt-file", "/data/secret/keys/uaa_token_salt", "uaa token salt file")
	uaaServer := flag.String("uaa-server", "", "UAA server to authenticate")
	verifyCert := flag.Bool("verify-cert", false, "Verify cert")
	// verbose is used for debugging, dump all information to console
	verbose := flag.Bool("verbose", false, "Display verbose info")

	flag.Parse()

	trace = *verbose

	if *isShowUAA {
		uaaProf, err := parseJsonFile(*uaaJsonPath)
		checkError(err)
		uaaProf.TokenSalt = readTokenSalt(*tokenSaltFile)
		Trace("token salt is changed to " + uaaProf.TokenSalt)
		content, err := json.Marshal(uaaProf)
		checkError(err)
		fmt.Print(string(content))
		os.Exit(0)
	}

	checkParameter(harborServerUrl, password, uaaServer)
	client := createHttpClient(*trustedCA, *insecure)
	c := newConfigClient(client, *harborServerUrl, "admin", *password)
	uaaProf, err := parseJsonFile(*uaaJsonPath)
	checkError(err)
	if *isConfigOIDC {
		err = c.configOIDC(uaaProf, *uaaServer, *verifyCert)
	}

	if *isConfigUAA {
		err = c.configUAA(uaaProf, *uaaServer, *verifyCert)

	}
	checkError(err)
	os.Exit(0)
}

func checkParameter(harborServerUrl, password, uaaServer *string) {
	if len(*harborServerUrl) == 0 {
		Trace("Please provide server url to configure")
		os.Exit(1)
	}
	if len(*password) == 0 {
		Trace("need to provide admin password to configure")
		os.Exit(1)
	}
	if len(*uaaServer) == 0 {
		Trace("Need to provide the uaa server info")
		os.Exit(1)
	}
}

func checkError(err error) {
	if err != nil {
		Trace(err)
		os.Exit(1)
	}
}

func parseJsonFile(jsonPath string) (*UAAProfile, error) {
	var profile UAAProfile
	content, err := ioutil.ReadFile(jsonPath)
	if err != nil {
		return nil, err
	}
	err = json.Unmarshal(content, &profile)
	if err != nil {
		return nil, err
	}
	return &profile, nil
}

func readTokenSalt(tokenSaltFile string) string {
	var token string
	_, err := os.Stat(tokenSaltFile)
	if os.IsNotExist(err) {
		token, err = tokenSalt(tokenSaltFile)
		checkError(err)
		return token
	}
	content, err := ioutil.ReadFile(tokenSaltFile)
	checkError(err)
	token = string(content)
	if strings.TrimSpace(token) == "" {
		token, err = tokenSalt(tokenSaltFile)
		checkError(err)
	}
	return token
}

func tokenSalt(tokenSaltFile string) (string, error) {
	token := randString(8)
	err := ioutil.WriteFile(tokenSaltFile, []byte(token), 0644)
	if err != nil {
		return "", nil
	}
	return token, nil
}

func stringWithCharset(length int, charset string) string {
	b := make([]byte, length)
	for i := range b {
		b[i] = charset[seededRand.Intn(len(charset))]
	}
	return string(b)
}

func randString(length int) string {
	return stringWithCharset(length, charset)
}

func createHttpClient(caCertFile string, insecure bool) *http.Client {
	// Get the SystemCertPool, continue with an empty pool on error
	rootCAs, _ := x509.SystemCertPool()
	if rootCAs == nil {
		rootCAs = x509.NewCertPool()
	}
	// Read in the cert file
	if !insecure {
		certs, err := ioutil.ReadFile(caCertFile)
		if os.IsNotExist(err) {
			Trace(fmt.Sprintf("The cert file is not found %v, ignore it", caCertFile))
		} else {
			// Append our cert to the system pool
			if ok := rootCAs.AppendCertsFromPEM(certs); !ok {
				Trace("No certs appended, using system certs only")
			}
		}
	}

	// Trust the augmented cert pool in our client
	config := &tls.Config{
		InsecureSkipVerify: insecure,
		RootCAs:            rootCAs,
	}
	tr := &http.Transport{TLSClientConfig: config}
	return &http.Client{Transport: tr}
}

func (c *ConfigClient) configHarborWithSetting(setting map[string]interface{}) error {
	url := c.harborUrl + "/api/v2.0/configurations"
	method := "PUT"
	payload, err := json.Marshal(setting)
	checkError(err)
	req, err := http.NewRequest(method, url, bytes.NewReader(payload))
	checkError(err)
	req.SetBasicAuth(c.username, c.password)
	req.Header.Add("Content-Type", "application/json")
	res, err := c.client.Do(req)
	checkError(err)
	defer res.Body.Close()
	body, err := ioutil.ReadAll(res.Body)
	checkError(err)
	Trace(fmt.Sprintf("Response code %v\n", res.StatusCode))
	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("failed to send request to %v, response code %v", url, res.StatusCode)
	}
	Trace("request content is " + string(body) + "\n")
	return nil
}

func (c *ConfigClient) configOIDC(setting *UAAProfile, uaaUrl string, verifyCert bool) error {
	s := map[string]interface{}{
		"auth_mode":          "oidc_auth",
		"oidc_endpoint":      strings.ToLower(uaaUrl) + "/oauth/token",
		"oidc_name":          "uaa",
		"oidc_client_id":     setting.ClientID,
		"oidc_client_secret": setting.ClientSecret,
		"oidc_scope":         strings.Join(setting.Scope, ","),
		"oidc_verify_cert":   verifyCert,
	}

	return c.configHarborWithSetting(s)
}

func (c *ConfigClient) configUAA(setting *UAAProfile, uaaUrl string, verifyCert bool) error {
	s := map[string]interface{}{
		"auth_mode":         "uaa_auth",
		"uaa_endpoint":      strings.ToLower(uaaUrl),
		"uaa_client_id":     setting.ClientID,
		"uaa_client_secret": setting.ClientSecret,
		"uaa_verify_cert":   verifyCert,
	}
	return c.configHarborWithSetting(s)
}
