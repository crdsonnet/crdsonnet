.PHONY: test
test:
	cd test && jb install
	@RESULT=0; \
	for f in $$(find test -name 'vendor' -prune -o -name 'test_*.jsonnet' -print); do \
		echo "$$f"; \
		jsonnet -J test/vendor "$$f"; \
		RESULT=$$(($$RESULT + $$?)); \
	done; \
	exit $$RESULT

.PHONY: docs
docs:
	jsonnet \
		-J crdsonnet/vendor \
		-S -c -m docs \
		-e '(import "github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet").render(import "crdsonnet/main.libsonnet")'

crdsonnet/example/json_schema_static_output.libsonnet:
	jsonnet -S -J crdsonnet/vendor json_schema_static.libsonnet | jsonnetfmt - > crdsonnet/example/json_schema_static_output.libsonnet
