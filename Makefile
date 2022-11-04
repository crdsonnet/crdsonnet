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
