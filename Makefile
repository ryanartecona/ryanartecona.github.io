GENERATED_POSTS := \
	site/post/2015/05/21/refactoring-in-ruby-in-haskell.md

build: posts
	soupault

clean:
	rm ${GENERATED_POSTS}
	git submodule update --init
	rm -rf _site
	mkdir -p _site
	echo "gitdir: ../.git/modules/_site" > _site/.git

HOST := 127.0.0.1
PORT := 8000
watch: posts
	echo "noop watch"
	exit 1

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
	git add _site/
	git diff --staged
	git commit -m "Deploy to master"

posts: ${GENERATED_POSTS}

site/post/2015/05/21/refactoring-in-ruby-in-haskell.md: site/downloads/refactoring_1.lhs
	mkdir -p $$(dirname $@)
	echo "---" > $@
	echo "title: Refactoring in Ruby in Haskell" >> $@
	echo "layout: post" >> $@
	echo "tags: code haskell ruby" >> $@
	echo "---" >> $@
	echo "" >> $@
	pandoc -f markdown_github+lhs+strikeout -t markdown_github site/downloads/refactoring_1.lhs | sed "s/sourceCode$$/haskell/;" >> $@
