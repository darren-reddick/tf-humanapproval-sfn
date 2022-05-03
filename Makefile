FUNCTIONS = $(shell find lambda -type d -maxdepth 1 -mindepth 1 ! -name utils -exec basename "{}" \;)
GO111MODULE = on
REGION ?= eu-west-1

.PHONY: build build-% deploy

build: $(addprefix build-,$(FUNCTIONS))

build-%:
	env GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o bin/$*Handler lambda/$*/main.go

deploy: build
	$(MAKE) -C terraform deploy