export DOCKER_ORG ?= unionpos
export DOCKER_IMAGE ?= $(DOCKER_ORG)/application
export DOCKER_TAG ?= 20230615
export DOCKER_IMAGE_NAME ?= $(DOCKER_IMAGE):$(DOCKER_TAG)
export DOCKER_BUILD_FLAGS = --platform linux/amd64

-include $(shell curl -sSL -o .build-harness "https://raw.githubusercontent.com/unionpos/build-harness/master/templates/Makefile.build-harness"; echo .build-harness)

build: docker/build
.PHONY: build

## update readme documents
docs: readme/deps readme
.PHONY: docs

push:
	$(DOCKER) push $(DOCKER_IMAGE_NAME)
.PHONY: push

run:
	$(DOCKER) container run --rm --platform linux/amd64 \
		--publish "3000:3000" \
		--attach STDOUT ${DOCKER_IMAGE_NAME}
.PHONY: run

it:
	$(DOCKER) run -it --platform linux/amd64 ${DOCKER_IMAGE_NAME} /bin/bash
.PHONY: it
