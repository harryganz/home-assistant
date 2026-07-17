.DEFAULT_GOAL := help

.PHONY: help install run

help: ## Show this list of available tasks
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

install: ## Install external dependencies (podman, podman-compose, make) and create .env
	./install.sh
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created .env from .env.example — edit it before running 'make run'."; \
	else \
		echo ".env already exists, leaving it as-is."; \
	fi

run: ## Bring up the cluster (podman-compose up -d)
	podman-compose up -d
