package main

import (
	"testing"
)

func TestConfigHarborWithSetting(t *testing.T) {
	type args struct {
		harborUrl string
		setting   map[string]interface{}
		username  string
		password  string
	}
	tests := []struct {
		name    string
		args    args
		wantErr bool
	}{
		{"test normal", args{"https://10.186.197.207", map[string]interface{}{"auth_mode": "ldap_auth"}, "admin", "Harbor12345"}, false},
		{"test normal", args{"https://10.186.197.207", map[string]interface{}{"auth_mode": "ldap_auth"}, "admin", "1234"}, true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			client := createHttpClient("", true)
			c := newConfigClient(client, tt.args.harborUrl, "admin", tt.args.password)
			if err := c.configHarborWithSetting(tt.args.setting); (err != nil) != tt.wantErr {
				t.Errorf("configHarborWithSetting() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
