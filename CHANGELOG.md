# k8s-jenkins-agent-integration Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v1.1.0] - 2026-03-12
### Added
- [#1] Add rbac to create secrets. Ci users can use this to create docker registry credentials. The Kubernetes plugin does not offer this.
### Removed
- Component-patch-template with Jenkins agent image as it is no longer needed.
  - Agent images can now be used via the aforementioned credentials.

## [v1.0.0] - 2026-01-19

### Added
- Namespaces for Jenkins agents
- NetworkPolicies for Jenkins agents
- RBAC for Jenkins agents
- Gatekeeper policies to assign Jenkins agents to specific nodes
- Kyverno policy to assign Jenkins agents to specific nodes