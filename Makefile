.PHONY: dev
dev:
	bundle exec sass --watch _scss:css --scss --compass --sourcemap=none &
	bundle exec jekyll serve
