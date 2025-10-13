NHOST_PATH=packages/nhost_dart/test/test_backend/


.PHONY: dev-env-up
dev-env-up:
	cd $(NHOST_PATH) && nhost up


.PHONY: dev-env-down
dev-env-down:
	cd $(NHOST_PATH) && nhost down --volumes


.PHONY: check
check:
	dart run melos run analyze
	dart run melos run test


.PHONY: format
format:
	dart format .
