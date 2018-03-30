package suite03

import (
	"testing"

	"harbor-api-testing/envs"
)

//TestRun : Start to run the case
func TestRun(t *testing.T) {
	//Initialize env
	if err := envs.ErrandSmokeTestEnv.Load(); err != nil {
		t.Fatal(err.Error())
	}

	suite := ErrandSmokeTestSuite{}
	report := suite.Run(&envs.ErrandSmokeTestEnv)
	report.Print()
	if report.IsFail() {
		t.Fail()
	}
}
