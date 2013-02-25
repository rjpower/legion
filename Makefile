all:
	./node_modules/.bin/iced -c -o lib/ src/
	find src -name '*.js' -exec cp {} lib/ \;

develop:
	npm install .

test:
	iced ./test/run_tests.iced

doc:
	docco `find src -name '*.iced' -o -name '*.js'`

.PHONY: test
