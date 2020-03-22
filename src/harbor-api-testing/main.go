package main

import (
	"fmt"
	"os"

	"github.com/vmware/harbor-boshrelease/src/harbor-api-testing/envs"
	"github.com/vmware/harbor-boshrelease/src/harbor-api-testing/tests/suites/suite03"
)

//Execute suites from command
func main() {
	//Run errand smoke test
	if err := runErrandSmokeTest(); err != nil {
		fmt.Printf("%s\n", err.Error())
		os.Exit(1)
	}
}

//Run errand test suite
func runErrandSmokeTest() error {
	//Override paths of cert and key
	smokeTestEnv := envs.ErrandSmokeTestEnv

	//Initialize env
	if err := smokeTestEnv.Load(); err != nil {
		return err
	}

	suite := suite03.ErrandSmokeTestSuite{}
	report := suite.Run(&smokeTestEnv)
	report.Print()
	if report.IsFail() {
		return fmt.Errorf("%s", "ErrandSmokeTestSuite: FAILED")
	}

	return nil
}
