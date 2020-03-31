package suite03

import (
	"fmt"
	"harbor-api-testing/envs"
	"harbor-api-testing/lib"
	"harbor-api-testing/tests/suites/base"
)

//Steps of suite03:
//  s0: Get systeminfo
//  s1: create project
//  s2: push a busybox image to project (admin)
//  s3: pull image from project (admin)
//  s4: remove repository busybox
//  s5: delete project

//ErrandSmokeTestSuite : Verify deployment within errand job
type ErrandSmokeTestSuite struct {
	base.ConcourseCiSuite
}

//Run : Run a group of cases
func (ests *ErrandSmokeTestSuite) Run(onEnvironment *envs.Environment) *lib.Report {
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
	if err := ests.pushLocalImage(onEnvironment); err != nil {
		report.Failed("pushImage", err)
	} else {
		report.Passed("pushImage")
	}

	//s3
	if err := ests.PullImage(onEnvironment); err != nil {
		report.Failed("pullImage[1]", err)
	} else {
		report.Passed("pullImage[1]")
	}

	//s4
	img := lib.NewImageUtil(onEnvironment.RootURI(), onEnvironment.HTTPClient)
	if err := img.DeleteRepo(onEnvironment.TestingProject, onEnvironment.ImageName); err != nil {
		report.Failed("DeleteRepo", err)
	} else {
		report.Passed("DeleteRepo")
	}

	//s5
	if err := pro.DeleteProject(onEnvironment.TestingProject); err != nil {
		report.Failed("DeleteProject", err)
	} else {
		report.Passed("DeleteProject")
	}

	return report
}

//PushImage : Push local image to the registry
func (ests *ErrandSmokeTestSuite) pushLocalImage(onEnvironment *envs.Environment) error {
	docker := onEnvironment.DockerClient
	if err := docker.Status(); err != nil {
		return err
	}

	//Local existing image
	imagePulling := fmt.Sprintf("%s:%s", onEnvironment.ImageName, onEnvironment.ImageTag)
	imagePushing := fmt.Sprintf("%s/%s/%s:%s",
		onEnvironment.Hostname,
		onEnvironment.TestingProject,
		onEnvironment.ImageName,
		onEnvironment.ImageTag)

	if err := docker.Tag(imagePulling, imagePushing); err != nil {
		return err
	}

	if err := docker.Login(onEnvironment.Account, onEnvironment.Password, onEnvironment.Hostname); err != nil {
		return err
	}

	if err := docker.Push(imagePushing); err != nil {
		return err
	}

	return nil
}
