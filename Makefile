DOCKER_REGISTRY = ghcr.io
DOCKER_REPO = elagala/agala-deploy
DOCKER_TAG = v3.0.0
DOCKER_IMAGE = $(DOCKER_REGISTRY)/$(DOCKER_REPO):$(DOCKER_TAG)

build:
	@echo "Building Docker image: $(DOCKER_IMAGE)"
	docker build -t $(DOCKER_IMAGE) .

run-local:
	@echo "Building Docker image: $(DOCKER_IMAGE)"
	docker build -t agala-deploy:local .
	docker run --rm -it \
		--env-file .env \
		-v ./deploy:/app/deploy \
		agala-deploy:local

push:
	@echo "Pushing Docker image: $(DOCKER_IMAGE)"
	docker push $(DOCKER_IMAGE)

build-and-push: build push

test-vars:
	@echo "Testing variable parsing with .env"
	docker build -t agala-deploy:local .
	docker run --rm \
		--env-file .env \
		agala-deploy:local

clean:
	@echo "Removing local Docker image: $(DOCKER_IMAGE)"
	docker rmi $(DOCKER_IMAGE)

