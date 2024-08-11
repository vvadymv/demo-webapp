VERSION=$(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)
APP=$(shell basename $(shell git remote get-url origin) | sed 's/\.git$$//')
REGISTRY=gcr.io/k8s-k3s-430300

lint:
	@echo golint

test:
	@echo go test -v

build: get format 
	@echo go build -o kbot -v -ldflags "-X=github.com/vvadymv/kbot/cmd.appVersion=${VERSION}"

image:
	docker build . -t ${REGISTRY}/${APP}:${VERSION}

push:
	docker push ${REGISTRY}/${APP}:${VERSION}

getversion:
	@echo Version: ${VERSION}
	@echo APP: ${APP}

clean:
	docker image rmi ${REGISTRY}/${APP}:${VERSION}

