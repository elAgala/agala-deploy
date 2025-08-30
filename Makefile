DOCKER_REGISTRY = ghcr.io
DOCKER_REPO = elagala/agala-deploy
DOCKER_TAG = v2.0.0-nightly.4
DOCKER_IMAGE = $(DOCKER_REGISTRY)/$(DOCKER_REPO):$(DOCKER_TAG)

build:
	@echo "Building Docker image: $(DOCKER_IMAGE)"
	docker build -t $(DOCKER_IMAGE) .

run-local:
	@echo "Building Docker image: $(DOCKER_IMAGE)"
	docker build -t ansible-1password:local .
	op inject --in-file .env --out-file .env.resolved -f && \
	docker run --rm -it \
		--env-file .env.resolved \
		-v ./deploy:/app/deploy \
		ansible-1password:local && \
	rm .env.resolved

push:
	@echo "Pushing Docker image: $(DOCKER_IMAGE)"
	docker push $(DOCKER_IMAGE)

build-and-push: build push

test-vars:
	@echo "Testing variable parsing with .env.test"
	docker build -t ansible-1password:local .
	docker run --rm \
		--env-file .env \
		ansible-1password:local

clean:
	@echo "Removing local Docker image: $(DOCKER_IMAGE)"
	docker rmi $(DOCKER_IMAGE)

