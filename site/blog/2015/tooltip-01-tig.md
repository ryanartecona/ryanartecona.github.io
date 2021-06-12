Tooltip #1: tig
============================================

<date>2015-06-12</date>
<tags>tooltip</tags>

[`tig`](http://jonas.nitro.dk/tig/manual.html) is one of my favorites. It's basically an interactive git console that you can run in your terminal. The manual I linked has lots of good examples, but here's a fast track to usefulness.

Install with `brew install tig`.

If you call `tig` with no arguments, it will give you a prettified log view for your current branch. In the log view, you can navigate up or down with arrows or with j/k, and scroll up or down in full pages with `^u` and `^d`. If you hit `Enter` on a commit, it will bring up a second panel below with a prettified diff of that commit. The focus will then be on that window, so when you're done you can hit `q` to dismiss the diff panel. You can use `Tab` to move focus between the visible panels when there are multiple, like when you have the diff panel and log panel open.

If you open tig with `tig status`, or you hit the `s` key while it's open, you will get an interactive status view. In this view, you can use `u` to stage or unstage changes for whole files. If you hit `Enter` on one of the files, you will get a diff panel for the changes in that file. Inside that diff panel, you can use `u` to stage specific chunks, or `\` to split a chunk, or even `1` to stage individual lines! When you're done staging, you can use `C` to commit (this will use the `$EDITOR` you have set in your shell, which may or may not be what you want). It's a significant improvement on `git commit -p`, which is already decent.

At any point, you can bring up the full list of hotkeys with h, and you can dismiss the current view with q. If you dismiss the view that tig opened with, tig will exit, or you can force an exit with Q. If you study that list of hotkeys, you will learn how to switch between branches with the refs view (`r`), navigate the directory tree with the tree view (`t`), or search through the repo with the grep view (`g`). There's a lot to love!


