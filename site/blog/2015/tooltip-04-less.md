# Tooltip #4: less

<date>2015-07-24</date>
<tags>tooltip</tags>

I've had to go poking around unfamiliar servers and reading man pages of unfamiliar commands more these last few weeks than previously, and I've grown very fond of [`less`](http://ss64.com/bash/less.html), the pager. It's not a very exciting tool, but you probably already use it at least as often as you view a man page, or maybe also inspect a log, and you probably use _less_ of its feature set than you'd find useful if you knew about them!

See what I did there? Expect plenty _more_ of that!

For starters, you can all the goods of this guide and more in `less --help` (which gets paged inside `less`, of course), or for the _less_ intimidated by overlong manuals with altogether too many historical details, in `man less` (also paged with itself, which is all the _more_ [oddly satisfying](https://www.reddit.com/r/oddlysatisfying)).

## The basics ##

If you haven't before, you can pipe the output of _any command ever_ into less completely bare, no flags required.

    (echo yippee && yes eeeeee) | less

This is why people love UNIX.

Also, remember you can always get to the help screen from inside `less` with the `h` key.

### Movement ###

Here's a table of movement commands!

| down       | up       | unit      |
|------------|----------|-----------|
| down arrow | up arrow | line      |
| ^f         | ^b       | page      |
| d          | u        | half-page |
| ^d         | ^u       | half-page |

I personally prefer `^d` and `^u`, since they're the same in vim. Also, if your logs have long lines, you can move left and right with the left/right arrow keys.

It's worth noting you can use `g` to jump to the beginning of the content, and `G` to jump to the end.

### Searching ###

Use `/` to search for something _below_ the top line in your screen, use `?` to search for something _before_. These can be regexes.

When you've got your search terms highlighted, use `n` to move to the next one, `N` to move to the previous one, and `ESC u` to remove the search highlight when you're done.

## The goodies ##

Here's the real stuff that prompted this week's tooltip.

### Stick to the end of output ###

Also known as the `tail -f` behavior. I call this mode 'sticky bottom' mode, but I don't think that's quite the official name.

In this mode, `less` will automatically scroll down to the end of input as new input rolls in, like `tail -f`. Unlike `tail -f`, this will (a) let you switch between this behavior and normal `less` behavior without leaving `less` (i.e. without modifying your previous `tail` command), which means you can alternate between exploring a log and live-viewing it, and (b) not let the log output overstay its welcome and hang around in your terminal's scrollback after `less` exits.

The one thing `tail -f` may be slightly more appropriate for is viewing multiple logs live at once, since `tail` will interpolate logs from different sources, where `less` forces you to switch between sources. I don't care though, because I never do that.

You can invoke `less` in this mode with `less +F`, and you can return to normal `less` mode with `^C`. To go from normal mode to sticky bottom mode, hit `F`.

### Marking & jumping ###

You can mark lines and jump to marked lines like you can in vi. The _more_ you know!

Mark a line with `m` followed by a lowercase letter, and jump to a marked line with `'` followed by that lowercase letter. For example, if I mark a line with `ma`, I can scroll and search around as much as I want, and later return to that line with `'a`.

### Other snacks ###

You can run a one-off command with `!`, like `!ls -la`.

You can set any of `less`'s command line flags from inside less, just by typing the flag.

You can toggle line numbers with `-N`.

You can toggle line wrapping with `-S`.

If you're `less`ing a file and decide you want to edit it, you can hit `v` to jump straight into your `$EDITOR` with that file.

If you're `less`ing the output of a command and decide you want to save it to a file, you can hit `s` to do so.

You can choose to show only lines matching a certain pattern with `&`. This is like a `| grep ...`, except you don't have to know what you're searching for before typing out your command! To return to showing all lines, just hit `&` again without giving it a pattern.

In conclusion, _less really is more_. Except when it comes to unix command puns.

---

Per usual, giphy had mostly questionable results for 'less' and 'more', so here's the cream of the crop for 'scroll'.

![scroll](http://media.giphy.com/media/xfCEOjlROkMne/giphy.gif)
