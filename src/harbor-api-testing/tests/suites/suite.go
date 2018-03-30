package suites

import (
	"harbor-api-testing/envs"
	"harbor-api-testing/lib"
)

//Suite : Run a group of test cases
type Suite interface {
	Run(onEnvironment envs.Environment) *lib.Report
}
