package suite01

import (
	"github.com/vmware/harbor-boshrelease/src/harbor-api-testing/envs"
	"github.com/vmware/harbor-boshrelease/src/harbor-api-testing/lib"
	"github.com/vmware/harbor-boshrelease/src/harbor-api-testing/tests/suites/base"
)

//Steps of suite01:
//  s0: Get systeminfo
//  s1: create project
//  s2: create user "cody"
//  s3: assign cody as developer
//  s4: push a busybox image to project
//  s5: pull image from project
//  s6: remove "cody" from project member list
//  s7: pull image from project [FAIL]
//  s8: remove repository busybox
//  s9: delete project
//  s10: delete user

//ConcourseCiSuite01 : For harbor journey in concourse pipeline
type ConcourseCiSuite01 struct {
	base.ConcourseCiSuite
}

//Run : Run a group of cases
func (ccs *ConcourseCiSuite01) Run(onEnvironment *envs.Environment) *lib.Report {
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
	usr := lib.NewUserUtil(onEnvironment.RootURI(), onEnvironment.HTTPClient)
	if err := usr.CreateUser(onEnvironment.Account, onEnvironment.Password); err != nil {
		report.Failed("CreateUser", err)
	} else {
		report.Passed("CreateUser")
	}

	//s3
	if err := pro.AssignRole(onEnvironment.TestingProject, onEnvironment.Account); err != nil {
		report.Failed("AssignRole", err)
	} else {
		report.Passed("AssignRole")
	}

	//s4
	if err := ccs.PushImage(onEnvironment); err != nil {
		report.Failed("pushImage", err)
	} else {
		report.Passed("pushImage")
	}

	//s5
	if err := ccs.PullImage(onEnvironment); err != nil {
		report.Failed("pullImage[1]", err)
	} else {
		report.Passed("pullImage[1]")
	}

	//s6
	if err := pro.RevokeRole(onEnvironment.TestingProject, onEnvironment.Account); err != nil {
		report.Failed("RevokeRole", err)
	} else {
		report.Passed("RevokeRole")
	}

	//s7
	if err := ccs.PullImage(onEnvironment); err != nil {
		report.Failed("pullImage[2]", err)
	} else {
		report.Passed("pullImage[2]")
	}

	//s8
	img := lib.NewImageUtil(onEnvironment.RootURI(), onEnvironment.HTTPClient)
	if err := img.DeleteRepo(onEnvironment.TestingProject, onEnvironment.ImageName); err != nil {
		report.Failed("DeleteRepo", err)
	} else {
		report.Passed("DeleteRepo")
	}

	//s9
	if err := pro.DeleteProject(onEnvironment.TestingProject); err != nil {
		report.Failed("DeleteProject", err)
	} else {
		report.Passed("DeleteProject")
	}

	//s10
	if err := usr.DeleteUser(onEnvironment.Account); err != nil {
		report.Failed("DeleteUser", err)
	} else {
		report.Passed("DeleteUser")
	}

	return report
}
