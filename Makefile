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
	cd crdsonnet/ && \
	jsonnet -S -J vendor example/json_schema_static.libsonnet | jsonnetfmt - > example/json_schema_static_output.libsonnet

crdsonnet/example/json_schema_very_simple_validate.libsonnet.output:
	cd crdsonnet/ && \
	jsonnet -J vendor example/json_schema_very_simple_validate.libsonnet 2> example/json_schema_very_simple_validate.libsonnet.output

.PHONY: fmt
fmt:
	@find . -path './.git' -prune -o -name 'vendor' -prune -o -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
		xargs -n 1 -- jsonnetfmt --no-use-implicit-plus -i
