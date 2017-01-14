HAKYLL=stack exec -- ra-hakyll

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

watch: stack-build posts
	${HAKYLL} watch

posts: post/2015-05-21-refactoring-in-ruby-in-haskell.md

post/2015-05-21-refactoring-in-ruby-in-haskell.md: downloads/refactoring_1.lhs
	echo "---" > $@
	echo "title: Refactoring in Ruby in Haskell" >> $@
	echo "layout: post" >> $@
	echo "tags: code haskell ruby" >> $@
	echo "---" >> $@
	echo "" >> $@
	pandoc -f markdown_github+lhs+strikeout -t markdown_github downloads/refactoring_1.lhs | sed "s/sourceCode$$/haskell/;" >> $@
