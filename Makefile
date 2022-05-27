SHA := $(shell git rev-parse HEAD)
THIS_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
VERSION_REGEX = [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*[^\" ]*
VERSION := $(shell cat package.json | jq -r .version)

TMP = 'tmp'
REMOTE = origin
BRANCH = gh-pages
BIN = node_modules/.bin
PWD = $(shell pwd | sed -e 's/[\/&]/\\&/g')

all:
	@echo "Installing packages"
	@yarn install --depth=100 --loglevel=error
	@yarn link &>/dev/null

clean: FORCE
	@rm -rf dist
	@rm -rf ${TMP}

build: clean dist dist/swig.min.js
	@echo "Built to ./dist/"

dist:
	@mkdir -p $@

dist/swig.js:
	@echo "Building $@..."
	@cat $^ > $@

dist/swig.min.js:
	@echo "Building $@..."
	@${BIN}/uglifyjs $^ --comments -c warnings=false -m --source-map dist/swig.js.map > $@

tests := $(shell find ./tests -name '*.test.js' ! -path "*node_modules/*")
reporter = dot
opts =
test:
	@${BIN}/mocha --check-leaks --reporter ${reporter} ${opts} ${tests}

out = tests/coverage.html
cov-reporter = html-cov
coverage:
ifeq (${cov-reporter}, travis-cov)
	@${BIN}/mocha ${opts} ${tests} --require blanket -R ${cov-reporter}
else
	@echo "@${BIN}/mocha ${opts} ${tests} --require blanket -R ${cov-reporter} > ${out}"
	@${BIN}/mocha ${opts} ${tests} --require blanket -R ${cov-reporter} > ${out}
	@sed -i .bak -e "s/${PWD}//g" ${out}
	@rm ${out}.bak
	@echo
	@echo "Built Report to ${out}"
	@echo
endif

docs/coverage.html: FORCE
	@echo "Building $@..."
	@make coverage out=$@

gh-pages: clean build build-docs
	@mkdir -p ${TMP}/js
	@mkdir -p docs/css
	@rm -f docs/coverage.html
	@${BIN}/lessc --yui-compress --include-path=docs/less docs/less/swig.less docs/css/swig.css
	@${BIN}/still docs -o ${TMP} -i "layout" -i "json" -i "less" -v
	@make coverage out=${TMP}/coverage.html
	@cp dist/swig.* ${TMP}/js/
	@git checkout ${BRANCH}
	@cp -r ${TMP}/* ./
	@rm -rf ${TMP}
ifeq (${THIS_BRANCH}, master)
	@git add .
	@git commit -n -am "Automated build from ${SHA}"
	@git push ${REMOTE} ${BRANCH}
	@git checkout ${THIS_BRANCH}
	@git clean -f -d docs/
endif

FORCE:

.PHONY: all version \
	build build-docs \
	test lint coverage \
	docs gh-pages
