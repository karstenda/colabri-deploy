.PHONY: help validate build-gke build-minikube deploy-gke deploy-minikube status teardown-gke teardown-minikube

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

validate: ## Validate all YAML files
	@echo "Validating YAML files..."
	@python3 -c "import yaml, sys, glob; files = glob.glob('kubernetes/**/*.yaml', recursive=True); [yaml.safe_load(open(f)) for f in files if not f.endswith('.example')]; print('✓ All YAML files are valid')"

build-gke: ## Build GKE manifests with kustomize
	@echo "Building GKE manifests..."
	@kubectl kustomize kubernetes/overlays/gke

build-minikube: ## Build Minikube manifests with kustomize
	@echo "Building Minikube manifests..."
	@kubectl kustomize kubernetes/overlays/minikube

deploy-minikube: ## Deploy to Minikube
	@cd scripts && ./deploy-minikube.sh

deploy-gke: ## Deploy to GKE (requires PROJECT_ID, CLUSTER_NAME, REGION env vars)
	@cd scripts && ./deploy-gke.sh $(PROJECT_ID) $(CLUSTER_NAME) $(REGION)

setup-gke: ## Setup GKE cluster (requires PROJECT_ID, CLUSTER_NAME, REGION env vars)
	@cd scripts && ./setup-gke-cluster.sh $(PROJECT_ID) $(CLUSTER_NAME) $(REGION)

status: ## Show deployment status
	@cd scripts && ./status.sh

teardown-minikube: ## Remove deployment from Minikube
	@cd scripts && ./teardown.sh minikube

teardown-gke: ## Remove deployment from GKE
	@cd scripts && ./teardown.sh gke

test-scripts: ## Test all shell scripts for syntax errors
	@echo "Testing shell scripts..."
	@for script in scripts/*.sh; do \
		echo "Checking $$script..."; \
		bash -n $$script || exit 1; \
	done
	@echo "✓ All scripts are valid"

clean: ## Clean temporary files
	@echo "Cleaning temporary files..."
	@rm -rf tmp/ temp/
	@echo "✓ Cleaned"
