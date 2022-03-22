cnf ?= .env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

# Get the latest tag
TAG=$(shell git describe --tags --abbrev=0)
GIT_COMMIT=$(shell git log -1 --format=%h)
PACKER_VERSION=latest

.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

#Commands
packer: ## packer console
	@docker run -it --rm \
		-v $$PWD:/app \
		-v $$HOME/.ssh/id_rsa:/root/.ssh/id_rsa \
		-w /app/ \
		-e AWS_ACCESS_KEY_ID=$$AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY=$$AWS_SECRET_ACCESS_KEY \
		-e AWS_DEFAULT_REGION=$$AWS_DEFAULT_REGION \
		--entrypoint "" \
		matheusmazzoni/packer:$(PACKER_VERSION) sh
