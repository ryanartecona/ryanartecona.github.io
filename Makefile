SHELL=/bin/bash

GENERATED_POSTS := \
	site/blog/2015/refactoring-in-ruby-in-haskell.md

.PHONY: build
build: posts site/css/main.css
	# use a custom build of soupault until released https://github.com/dmbaturin/soupault/issues/35
	# soupault
	./soupault

.PHONY: clean
clean:
	rm -f ${GENERATED_POSTS}
	rm -f site/css/main.css
	git submodule update --remote --init
	rm -rf _site
	mkdir -p _site
	echo "gitdir: ../.git/modules/_site" > _site/.git

HOST := 127.0.0.1
PORT := 8000
.PHONY: watch
watch: posts site/css/main.css
	git ls-files | entr -cr bash -c "sleep 1; make build; echo; cd _site && exec python -m http.server --bind ${HOST} ${PORT}"

# Because of how github pages work, I keep config, scss, and other source files
# in the develop branch, and the master branch is just the rendered _site/
# directory.
#
# To "deploy" from the develop branch, just do a clean build of _site/, then
# make a commit inside it and push master to origin.
#
REVISION = $(shell git rev-parse HEAD)
GIT_SITE = git -C _site/
deploy: clean build
	@git diff --quiet --ignore-submodules=all HEAD || { \
	  echo "ERROR: Dirty working directory detected" ;\
	  git diff --ignore-submodules=all --stat HEAD ;\
	  exit 1 ;\
	}
	${GIT_SITE} fetch -a
	${GIT_SITE} checkout origin/master
	# reset local master to current origin/master, in case of unpulled changes
	${GIT_SITE} checkout -B master
	# add, display, and commit all changes
	${GIT_SITE} add -A
	${GIT_SITE} diff HEAD --stat
	${GIT_SITE} commit -m "Deploy from develop branch at ${REVISION}"
	${GIT_SITE} push origin
	# update inner submodule in outer develop tree
	git add _site/
	git diff --staged
	git commit -m "Deploy to master"

posts: ${GENERATED_POSTS}

site/blog/2015/refactoring-in-ruby-in-haskell.md: site/downloads/refactoring_1.lhs
	mkdir -p $$(dirname $@)
	pandoc -f markdown+lhs+strikeout -t commonmark site/downloads/refactoring_1.lhs | sed "s/sourceCode$$/haskell/;" >> $@

site/css/main.css: css/main.scss $(shell find css -name '_*.scss')
	mkdir -p $$(dirname $@)
	sassc $< $@ 
