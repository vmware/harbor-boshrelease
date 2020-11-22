package base

import (
	"fmt"
	"strings"

	"github.com/vmware/harbor-boshrelease/src/harbor-api-testing/envs"
	"github.com/vmware/harbor-boshrelease/src/harbor-api-testing/lib"
)

//ConcourseCiSuite : Provides some base cases
type ConcourseCiSuite struct{}

//Run cases
//Not implemented
func (ccs *ConcourseCiSuite) Run(onEnvironment *envs.Environment) *lib.Report {
	return &lib.Report{}
}

//PushImage : Push image to the registry
func (ccs *ConcourseCiSuite) PushImage(onEnvironment *envs.Environment) error {
	docker := onEnvironment.DockerClient
	if err := docker.Status(); err != nil {
		return err
	}

	imagePulling := fmt.Sprintf("%s:%s", onEnvironment.ImageName, onEnvironment.ImageTag)
	if err := docker.Pull(imagePulling); err != nil {
		return err
	}

	if err := docker.Login(onEnvironment.Account, onEnvironment.Password, onEnvironment.Hostname); err != nil {
		return err
	}

	imagePushing := fmt.Sprintf("%s/%s/%s:%s",
		onEnvironment.Hostname,
		onEnvironment.TestingProject,
		onEnvironment.ImageName,
		onEnvironment.ImageTag)

	if err := docker.Tag(imagePulling, imagePushing); err != nil {
		return err
	}

	if err := docker.Push(imagePushing); err != nil {
		return err
	}

	return nil
}

//PullImage : Pull image from registry
func (ccs *ConcourseCiSuite) PullImage(onEnvironment *envs.Environment) error {
	docker := onEnvironment.DockerClient
	if err := docker.Status(); err != nil {
		return err
	}

	if err := docker.Login(onEnvironment.Account, onEnvironment.Password, onEnvironment.Hostname); err != nil {
		return err
	}

	imagePulling := fmt.Sprintf("%s/%s/%s:%s",
		onEnvironment.Hostname,
		onEnvironment.TestingProject,
		"busybox",
		onEnvironment.ImageTag)
	if err := docker.Pull(imagePulling); err != nil {
		if strings.EqualFold("exit status 1", err.Error()) {
			return nil
		}
		return err
	}

	return nil
}
