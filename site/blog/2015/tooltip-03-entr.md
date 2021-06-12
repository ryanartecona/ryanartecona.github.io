# Tooltip #3: entr

<date>2015-07-10</date>
<tags>tooltip</tags>

There's nothing quite like tightening up your feedback loop between changing code and observing a program's changed behavior to help you become and stay focused.

There are lots of tools out there meant to help with special cases of this, like `guard`, but setting them up can be a bit inconvenient. Knowing this, some of the more mature build tools and test runners have `--watch` options _built in_ to make it easy to rerun a command whenever any of its depended upon files change, but there, if you want a file change to trigger a command that the tool doesn't know how to run, you're left with configuring a general purpose file watcher.

## Enter `entr` ##

The [`entr`](http://entrproject.org/) utility is everything I wanted `guard` to be. It is one of those tools that's never anything but a pleasure to use. It fills a specific role, it's reliable, and it has an absolutely minimal set of options (3!).

You use the CLI by piping into it a list of files you want it to watch, and you give it a command to run each time it notices a file has changed.

    ls **/*.rb | entr rake spec

Nice! You can give it `-c` option to clear the screen before running each command, to effectively anchor short output to the top of the terminal window. The `-r` option tells it to kill and rerun the command in case it hasn't exited by the time it sees the next file change, which is useful for things like opening a REPL or restarting a dev server.

    ls **/*.rb | entr -r bundle exec foreman start

You can tell `entr` to give your command a path to the file that changed with `/_`.

    ls **/*.rb | entr echo /_ changed

## Examples ##

The project page linked above and the manpage included with the tool itself both have great examples, but I'll mix a couple of those with a couple of my own here.

To watch any file checked into your `git` repo:

    git ls-tree -r HEAD --name-only | entr -r rake spec

This one's so handy I have an alias `git ls` in my `~/.gitconfig` for it.

    [alias]
      ls = ls-tree -r HEAD --name-only

If your current task is scoped to certain files and you only want to run their tests, you can.

    find app -name 'media*.rb' | entr rspec spec/**/media*.rb

I just found this when writing this post, but it looks like with [chrome-cli](https://github.com/prasmussen/chrome-cli) it is dead simple to reload the current tab.

    brew install chrome-cli
    find . -name '*.sass' -or -name '*.coffee' | entr chrome-cli reload

You can only give `entr` a single command, but you can mux multiple commands into a single string argument to your favorite shell.

    git ls | entr -cr fish -c "rake spec; or say 'red alert! red alert!'"

That's it for my examples! The ultimate example on the project page uses `entr` to send a key to a `tmux` pane running `vim` to reload a `vimdiff` session, but I haven't taken it nearly that far yet.
