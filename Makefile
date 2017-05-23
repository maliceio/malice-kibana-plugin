REPO=malice
NAME=kibana-plugin
VERSION=$(shell jq -r '.version' package.json)
MESSAGE?="New release"

docker: ## Build a new image
	@echo "===> Buidling Image"
	docker build -t $(REPO)/$(NAME):$(VERSION) --build-arg VERSION=$(VERSION) .

build: docker ## Build kibana plugin using npm
	@echo "===> Building Plugin"
	docker run -d --name kpbuild -v `pwd`:/home/kibana/plugin $(REPO)/$(NAME):$(VERSION); sleep 10
	docker exec -it kpbuild bash -c "cd ../plugin && npm run build"; sleep 5
	docker rm -f kpbuild

size: ## Update docker image SIZE in README
	sed -i.bu 's/docker%20image-.*-blue/docker%20image-$(shell docker images --format "{{.Size}}" $(REPO)/$(NAME):$(VERSION)| cut -d' ' -f1)%20MB-blue/' README.md

release: ## Create a new release
	@echo "===> Creating Release"
	git tag -a ${VERSION} -m ${MESSAGE}
	git push origin ${VERSION}

test: ## Test docker image
	@echo "===> Testing Plugin"
	docker run -d --name kpbuild -v `pwd`:/home/kibana/plugin -p 9200:9200 $(REPO)/$(NAME):$(VERSION); sleep 30
	docker exec -it kpbuild bash -c "/entrypoint.sh && npm run makelogs"
	docker rm -f kpbuild

# Absolutely awesome: http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

.PHONY: build size tags test
