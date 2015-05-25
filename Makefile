.PHONY: build
build: css posts
	bundle exec jekyll build

.PHONY: css
css: css/main.css

css/main.css: _scss/*.scss
	bundle exec sass --scss --compass --sourcemap=none _scss/main.scss $@

.PHONY: posts
posts: _posts/2015-05-21-refactoring-in-ruby-in-haskell.md

_posts/2015-05-21-refactoring-in-ruby-in-haskell.md: downloads/refactoring_1.lhs
	echo "---" > $@
	echo "title: Refactoring in Ruby in Haskell" >> $@
	echo "layout: post" >> $@
	echo "tags: code haskell ruby" >> $@
	echo "---" >> $@
	echo "" >> $@
	pandoc -f markdown_github+lhs+strikeout -t markdown_github downloads/refactoring_1.lhs | sed "s/sourceCode$$/haskell/;" >> $@
