NHOST_PATH=packages/nhost_dart/test/test_backend/

# The Nhost CLI used to drive the test backend. The version pinned by flake.nix
# (1.33.0) ships a traefik that speaks Docker API 1.24, which a modern daemon
# rejects, so no routers are discovered and every request 404s. Override it:
#
#   make dev-env-up NHOST=/opt/homebrew/bin/nhost
NHOST?=nhost


.PHONY: dev-env-up
dev-env-up:
	cd $(NHOST_PATH) && $(NHOST) up


.PHONY: dev-env-down
dev-env-down:
	cd $(NHOST_PATH) && $(NHOST) down --volumes


.PHONY: test-integration
test-integration:
	cd packages/nhost_dart && flutter test --concurrency=1 --reporter=expanded


.PHONY: check
check:
	dart run melos run analyze
	dart run melos run test


.PHONY: format
format:
	dart format .
