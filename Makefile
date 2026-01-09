SHELL := /bin/bash
BUILDPATH=$(CURDIR)
UTILS_PATH=/harbor-boshrelease/src/utils
UTILS_BIN_PATH=/harbor-boshrelease/make/config-utils
SMOKE_TEST_PATH=/harbor-boshrelease/src/harbor-api-testing
SMOKETEST_BIN_PATH=/harbor-boshrelease/make/smoke_test

# docker parameters
DOCKERCMD=$(shell which docker)

GOBUILDPATHINCONTAINER=/harbor-boshrelease
GOBUILDIMAGE=golang:1.14.7

compile_smoke_test:
	@echo "compiling binary for smoke_test..."
	@echo $(GOBUILDPATHINCONTAINER)
	@$(DOCKERCMD) run --rm -v $(BUILDPATH):$(GOBUILDPATHINCONTAINER) -w $(SMOKE_TEST_PATH) $(GOBUILDIMAGE) go build -o $(SMOKETEST_BIN_PATH)
	@echo "Done."

compile_config_utils:
	@echo "compiling binary for config_utils..."
	@echo $(GOBUILDPATHINCONTAINER)
	@$(DOCKERCMD) run --rm -v $(BUILDPATH):$(GOBUILDPATHINCONTAINER) -w $(UTILS_PATH) $(GOBUILDIMAGE) go build -o $(UTILS_BIN_PATH)
	@echo "Done."

all: compile_smoke_test compile_config_utils
