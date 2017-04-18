HAKYLL = stack exec -- ra-hakyll

build: stack-build posts
	${HAKYLL} build

stack-build:
	stack build

clean: stack-build
	${HAKYLL} clean
	git submodule update --init
	rm -rf _site
	mkdir -p _site
	echo "gitdir: ../.git/modules/_site" > _site/.git

HOST := 127.0.0.1
PORT := 8000
watch: stack-build posts
	${HAKYLL} watch --host ${HOST} --port ${PORT}

# Because of how github pages work, I keep hakyll, scss, and other source files
# in the develop branch, and the master branch is just the rendered _site/
# directory.
#
# To "deploy" from the develop branch, just do a clean build of _site/, then
# make a commit inside it and push master to origin.
#
REVISION = $(shell git rev-parse HEAD)
GIT_SITE = git -C _site/
deploy: stack-build clean build
	@git diff-index --quiet --ignore-submodules=dirty HEAD || { \
	  echo "ERROR: Dirty working directory detected" ;\
	  git diff-index --ignore-submodules=dirty --stat HEAD ;\
	  exit 1 ;\
	}
	${GIT_SITE} checkout master
	${GIT_SITE} add -A
	${GIT_SITE} diff HEAD --stat
	${GIT_SITE} commit -m "Deploy from develop branch at ${REVISION}"
	${GIT_SITE} push origin

posts: post/2015-05-21-refactoring-in-ruby-in-haskell.md

post/2015-05-21-refactoring-in-ruby-in-haskell.md: downloads/refactoring_1.lhs
	echo "---" > $@
	echo "title: Refactoring in Ruby in Haskell" >> $@
	echo "layout: post" >> $@
	echo "tags: code haskell ruby" >> $@
	echo "---" >> $@
	echo "" >> $@
	pandoc -f markdown_github+lhs+strikeout -t markdown_github downloads/refactoring_1.lhs | sed "s/sourceCode$$/haskell/;" >> $@
