# Tooltip #2: Globbing

<date>2015-06-26</date>
<tags>tooltip</tags>

This week's tip about a couple of simple but powerful shell features that make working at the command line a bit less painful. For me personally they have contributed significantly to my transition from being all "the shell is slow and opaque, just give me a GUI with buttons" to wishing I could do everything in Emacs and my shell. Not that you should go my route, just that these things are pretty handy.

## Basic globbing ##

When you type a command into your shell and hit enter, your shell first looks for some special symbols and translates those into explicit arguments with which to call the program in your command. The special symbols are often collectively called glob patterns, the translation process is called glob expansion, and the whole system is just globbing. You can use this reference as a cheat sheet for Bash glob patterns, which are mostly supported in other modern shells.

Rather than describe them all, it's quicker to just see a demo.

<script id="asciicast-22527" src="https://asciinema.org/a/22527.js" async></script>

It's pretty easy to find more thorough guides by googling around, like [this one here](http://mywiki.wooledge.org/glob).

## Shell differences ##

I used Bash 4.3 in the demo, which is current. The bash installed with OSX is comparatively ancient, and doesn't support all the glob patterns used.

It's worth noting that some other shells go even further than bash with glob patterns, notably zsh and fish. In both of those, you can use a '*' in more places, and a '**' will expand not only directories but also files like '*'. For example, to match both `file.rb` and `subdir/file.rb`, zsh can use `**/*.rb`, and fish can use `**.rb`, but bash needs two separate patterns `*.rb **/*.rb`.

---

This came up from searching giphy for 'glob', and it looked relevant enough to include.

![glob](http://media.giphy.com/media/FfT6SLxVmfey4/giphy.gif)
