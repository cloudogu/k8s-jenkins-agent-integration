ARTIFACT_ID=k8s-jenkins-agent-integration
VERSION=1.0.0

MAKEFILES_VERSION=10.5.0
REGISTRY_NAMESPACE?=k8s
HELM_REPO_ENDPOINT=k3ces.local:30099

include build/make/variables.mk
include build/make/clean.mk
include build/make/self-update.mk
include build/make/k8s-component.mk

.PHONY: component-release
component-release: ## Interactively starts the release workflow.
	@echo "Starting git flow release..."
	@build/make/release.sh component