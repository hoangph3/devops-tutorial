SHELL := /bin/bash

IMAGE ?= flask-app
VERSION ?= 0.0.1

echo:
	@echo $(IMAGE):$(VERSION)

build:
	docker build -t $(IMAGE):$(VERSION) jobs/flask
