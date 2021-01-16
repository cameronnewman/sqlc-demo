
SHA1				:= $(shell git rev-parse --verify HEAD)
SHA1_SHORT			:= $(shell git rev-parse --verify --short HEAD)
VERSION				:= $(shell cat VERSION.txt)
INTERNAL_BUILD_ID	:= $(shell [ -z "${BUILDKITE_BUILD_NUMBER}" ] && echo "0" || echo ${BUILDKITE_BUILD_NUMBER})
PWD					:= $(shell pwd)
VERSION_HASH		:= ${VERSION}.${INTERNAL_BUILD_ID}-${SHA1_SHORT}

GOLANG_BUILD_IMAGE	:= golang:1.15.6
BASE_IMAGE			:= scratch
GOLANG_LINT_IMAGE	:= golangci/golangci-lint:v1.33.0

PROJECT					?= demo
APP						?= demo
ENVIRONMENT 			?= local

#TF Global vars
TF_DOCKER_WORKDIR	:= /opt/tf
TF_DIRECTORY        := ${TF_DOCKER_WORKDIR}/infrastructure/resources


.DEFAULT_GOAL		:= build

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Returns a list of all the make goals
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

#
# BASE goals
#

.PHONY: version
version:
	@echo "$$(date) - Setting build to Version: v$(VERSION_HASH)" 


.PHONY: generate
generate: go-generate go-sql-generate ## BASE goal - Runs all generate commands
	@echo "$$(date) - Finished all 'generate'  commands"

.PHONY: fmt
fmt: go-fmt ## BASE goal - Runs all format commands
	@echo "$$(date) - Finished all 'format' commands"


.PHONY: lint
lint: go-lint ## BASE goal - Runs all lint commands
	@echo "$$(date) - Finished all 'lint' commands"


.PHONY: test
test: go-test  ## BASE goal - Runs all test commands
	@echo "$$(date) - Finished all 'test' commands"

.PHONY: build
build: version check-APP go-build  ## BASE goal - Runs all build commands
	@echo "$$(date) - Finished all 'build' commands"

#
#  /end BASE goals
#

#
# golang goals fmt, lint, test, build & publish (prefixed with 'go-')
#

.PHONY: go-sql-generate
go-sql-generate:   ## Runs `sqlc generate` within a docker container.
	@echo "$$(date) - Running 'sqlc generate'"

	docker run --rm \
	-v $(PWD):/usr/src/app \
	-w /usr/src/app kjconroy/sqlc \
	generate

	@echo "$$(date) - Completed 'sqlc generate'"

.PHONY: go-generate
go-generate: ## Runs `go generate` within a docker container
	@echo "$$(date) - Running 'go generate'"

ifeq ($(ENVIRONMENT),local)
	go generate ./...
else

	docker run --rm \
	-v $(PWD):/usr/src/app \
	-w /usr/src/app \
	$(GOLANG_BUILD_IMAGE) \
	go generate ./...

endif

	@echo "$$(date) - Completed 'go generate'"

.PHONY: go-fmt
go-fmt: ## Runs `go fmt` within a docker container
	@echo "$$(date) - Running 'go fmt'"

ifeq ($(ENVIRONMENT),local)
	go fmt ./...
else

	docker run --rm \
	-v $(PWD):/usr/src/app \
	-w /usr/src/app \
	$(GOLANG_BUILD_IMAGE) \
	go fmt ./...

endif

	@echo "$$(date) - Completed 'go fmt'"

.PHONY: go-lint
go-lint: ## Runs `golangci-lint run` with more than 60 different linters using golangci-lint within a docker container.
	@echo "$$(date) - Running 'golangci-lint run'"
	
ifeq ($(ENVIRONMENT),local)
	golangci-lint run
else
	docker run --rm \
	-e GOPACKAGESPRINTGOLISTERRORS=1 \
	-e GO111MODULE=on \
	-e GOGC=100 \
	-v $(PWD):/usr/src/app \
	-w /usr/src/app \
	$(GOLANG_LINT_IMAGE) \
	golangci-lint run

endif

	@echo "$$(date) - Completed 'golangci-lint run'"

.PHONY: go-test
go-test: ## Runs `go test` within a docker container
	@echo "$$(date) - Running 'go test'"

ifeq ($(ENVIRONMENT),local)
	go test -cover -coverprofile=coverage.txt -v -p 8 -count=1 ./...
else

	docker run --rm \
	-v $(PWD):/usr/src/app \
	-w /usr/src/app \
	$(GOLANG_BUILD_IMAGE) \
	go test -cover -coverprofile=coverage.txt -v -p 8 -count=1 ./...

endif

	@echo "$$(date) - Completed 'go test'"

.PHONY: go-build
go-build: go-generate go-sql-generate ## Runs the build in a multi-stage docker img, requires APP var to be set
	@echo "$$(date) - Building golang app $(APP)"

	docker build \
	--tag=$(APP):$(SHA1) \
	--tag=$(APP):latest \
	--build-arg BUILD_IMAGE=$(GOLANG_BUILD_IMAGE) \
	--build-arg BASE_IMAGE=$(BASE_IMAGE) \
	--build-arg VERSION=$(VERSION_HASH) \
	--build-arg APP=$(APP) \
	--file cmd/$(APP)/Dockerfile .
	
	@echo "$$(date) - Completed building golang app $(APP)"

#
#  /end golang goals
#

#
# :kludge: Need to clean-up this section
#

.PHONY: run
run: check-APP go-generate go-sql-generate go-fmt go-lint ## Runs the app local within a docker container, requires APP var to be set
ifeq ($(ENVIRONMENT),local)
	go run -x -ldflags "-X main.version=$(VERSION_HASH)" cmd/$(APP)/main.go
else
	@echo "Starting the app"
	docker run -it --rm \
	-e DB_CON="host=host.docker.internal port=54321 user=postgres password=postgres dbname=postgres sslmode=disable" \
	-p 8435:8435 \
	-v $(PWD):/usr/src/app \
	-w /usr/src/app \
	$(GOLANG_BUILD_IMAGE) \
	go run -v -ldflags "-X main.version=$(VERSION_HASH)" cmd/$(APP)/main.go
endif

#
# Local Stack goals
#

.PHONY: stack-up
stack-up: ## Starts a local Stack
	@echo "Starting the local stack"
	docker-compose -f stack.yml up -d

.PHONY: stack-down
stack-down: ## Stops the local Stack
	@echo "Stopping local stack"
	docker-compose -f stack.yml down


#
# Utils
#

check-RESOURCE: ## Check that the $RESOURCE ENV variable is set. Only needed for terraform commands
ifndef RESOURCE
	$(error RESOURCE is undefined)
endif

check-ENVIRONMENT: ## Check that the $ENVIRONMENT ENV variable is set. Only needed for terraform commands
ifndef ENVIRONMENT
	$(error ENVIRONMENT is undefined)
endif

check-APP: ## Check that the $APP ENV variable is set. Needed for golang and ui commands
ifndef APP
	$(error APP is undefined)
endif
