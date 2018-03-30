package client

import "os/exec"
import "strings"
import "errors"
import "bufio"
import "fmt"
import "io/ioutil"

const (
	dockerCmd = "docker"
)

//DockerClient : Run docker commands
type DockerClient struct {
	//The host sock of docker listening: unix:///var/docker
	Host string
}

//Status : Check if docker daemon is there
func (dc *DockerClient) Status() error {
	args := []string{"version"}

	return dc.runCommand(dockerCmd, dc.arguments(args))
}

//Pull : Pull image
func (dc *DockerClient) Pull(image string) error {
	if len(strings.TrimSpace(image)) == 0 {
		return errors.New("Empty image")
	}

	args := []string{"pull", image}

	return dc.runCommandWithOutputs(dockerCmd, dc.arguments(args))
}

//Tag :Tag image
func (dc *DockerClient) Tag(source, target string) error {
	if len(strings.TrimSpace(source)) == 0 ||
		len(strings.TrimSpace(target)) == 0 {
		return errors.New("Empty images")
	}

	args := []string{"tag", source, target}

	return dc.runCommandWithOutputs(dockerCmd, dc.arguments(args))
}

//Push : push image
func (dc *DockerClient) Push(image string) error {
	if len(strings.TrimSpace(image)) == 0 {
		return errors.New("Empty image")
	}

	args := []string{"push", image}

	return dc.runCommandWithOutputs(dockerCmd, dc.arguments(args))
}

//Login : Login docker
func (dc *DockerClient) Login(userName, password string, uri string) error {
	if len(strings.TrimSpace(userName)) == 0 ||
		len(strings.TrimSpace(password)) == 0 {
		return errors.New("Invlaid credential")
	}

	args := []string{"login", "-u", userName, "-p", password, uri}

	return dc.runCommandWithOutputs(dockerCmd, dc.arguments(args))
}

func (dc *DockerClient) runCommand(cmdName string, args []string) error {
	return exec.Command(cmdName, args...).Run()
}

func (dc *DockerClient) runCommandWithOutput(cmdName string, args []string) error {
	cmd := exec.Command(cmdName, args...)
	cmdReader, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}

	scanner := bufio.NewScanner(cmdReader)
	go func() {
		for scanner.Scan() {
			fmt.Printf("%s out | %s\n", cmdName, scanner.Text())
		}
	}()

	if err = cmd.Start(); err != nil {
		return err
	}

	if err = cmd.Wait(); err != nil {
		return err
	}

	return nil
}

func (dc *DockerClient) runCommandWithOutputs(cmdName string, args []string) error {
	cmd := exec.Command(cmdName, args...)
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}

	stderr, err := cmd.StderrPipe()
	if err != nil {
		return err
	}

	if err = cmd.Start(); err != nil {
		return err
	}

	output, err := ioutil.ReadAll(stdout)
	if err != nil {
		return err
	}
	if len(output) > 0 {
		fmt.Printf("[%s] OUT: %s", cmdName, output)
	}

	errData, _ := ioutil.ReadAll(stderr)
	if len(errData) > 0 {
		fmt.Printf("[%s] ERROR: %s", cmdName, errData)
	}

	if err = cmd.Wait(); err != nil {
		return err
	}

	return nil
}

func (dc *DockerClient) arguments(args []string) []string {
	argList := []string{}
	if len(strings.TrimSpace(dc.Host)) > 0 {
		argList = append(argList, fmt.Sprintf("-H %s", dc.Host))
	}

	if len(args) > 0 {
		argList = append(argList, args...)
	}

	return argList
}
