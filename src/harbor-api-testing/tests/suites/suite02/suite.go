package suite02

import (
	"github.com/vmware/harbor-boshrelease/src/harbor-api-testing/envs"
	"github.com/vmware/harbor-boshrelease/src/harbor-api-testing/lib"
	"github.com/vmware/harbor-boshrelease/src/harbor-api-testing/tests/suites/base"
)

//Steps of suite01:
//  s0: Get systeminfo
//  s1: create project
//  s2: assign ldap user "mike" as developer
//  s3: push a busybox image to project
//  s4: pull image from project
//  s5: remove "mike" from project member list
//  s6: pull image from project [FAIL]
//  s7: remove repository busybox
//  s8: delete project

//ConcourseCiSuite02 : For harbor ldap journey in concourse pipeline
type ConcourseCiSuite02 struct {
	base.ConcourseCiSuite
}

//Run : Run a group of cases
func (ccs *ConcourseCiSuite02) Run(onEnvironment *envs.Environment) *lib.Report {
	report := &lib.Report{}

	//s0
	sys := lib.NewSystemUtil(onEnvironment.RootURI(), onEnvironment.Hostname, onEnvironment.HTTPClient)
	if err := sys.GetSystemInfo(); err != nil {
		report.Failed("GetSystemInfo", err)
	} else {
		report.Passed("GetSystemInfo")
	}

	//s1
	pro := lib.NewProjectUtil(onEnvironment.RootURI(), onEnvironment.HTTPClient)
	if err := pro.CreateProject(onEnvironment.TestingProject, false); err != nil {
		report.Failed("CreateProject", err)
	} else {
		report.Passed("CreateProject")
	}

	//s2
	if err := pro.AssignRole(onEnvironment.TestingProject, onEnvironment.Account); err != nil {
		report.Failed("AssignRole", err)
	} else {
		report.Passed("AssignRole")
	}

	//s3
	if err := ccs.PushImage(onEnvironment); err != nil {
		report.Failed("pushImage", err)
	} else {
		report.Passed("pushImage")
	}

	//s4
	if err := ccs.PullImage(onEnvironment); err != nil {
		report.Failed("pullImage[1]", err)
	} else {
		report.Passed("pullImage[1]")
	}

	//s5
	if err := pro.RevokeRole(onEnvironment.TestingProject, onEnvironment.Account); err != nil {
		report.Failed("RevokeRole", err)
	} else {
		report.Passed("RevokeRole")
	}

	//s6
	if err := ccs.PullImage(onEnvironment); err != nil {
		report.Failed("pullImage[2]", err)
	} else {
		report.Passed("pullImage[2]")
	}

	//s7
	img := lib.NewImageUtil(onEnvironment.RootURI(), onEnvironment.HTTPClient)
	if err := img.DeleteRepo(onEnvironment.TestingProject, onEnvironment.ImageName); err != nil {
		report.Failed("DeleteRepo", err)
	} else {
		report.Passed("DeleteRepo")
	}

	//s8
	if err := pro.DeleteProject(onEnvironment.TestingProject); err != nil {
		report.Failed("DeleteProject", err)
	} else {
		report.Passed("DeleteProject")
	}

	return report
}
