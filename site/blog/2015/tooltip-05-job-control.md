# Tooltip #5: Job Control in bash

<date>2015-08-28</date>
<tags>tooltip</date>

This is one of those features that fills a role which is almost always better filled by some other more powerful tool, but can nonetheless help you out in a pinch, or is at least a good thing to know about.

You know you can run commands in the background in your shell, right? That thing where a README or tutorial will tell you to run a command with a trailing `&`, so you can run other commands in the same shell while that command's doing its own thing? That little feature fits in with a small group of shell builtins which all work together and collectively do 'job control'.

## The commands ##

The job control commands are `fg`, `bg`, and `jobs`. The other supplementary features are that trailing `&` and the `^Z` key.

### Trailing `&` ###

This one you probably know. If you follow a command with a `&` at the very end, it will run in the background. No matter how long the program takes to exit, you will immediately see a prompt where you can go on typing commands in the exact same shell environment. If it prints anything, that output will have a little battle with your prompt until you intervene.

### `^Z` ###

If you start a command, and realize it's not going to exit as quickly as you thought it would, you have a few options. You might reach for the humane instruments of quick process death, `^D` to feed an EOF to its stdin, or `^C` to send it a 'INT' interrupt signal. Another option is to hit `^Z`, which functions more like cryogenically freezing the process.

### `jobs` ###

The `jobs` command will show you all the things you have in the background for your current shell session, which includes everything you ran with a trailing `&`, and everything you stopped with `^Z`. The output of this command will show you something like this.

```
[1]+  Stopped                 sleep 3
[2]-  Running                 sleep 3 &
```

Here, the job will be 'Running' if it's active and in the background, and 'Stopped' if it's been stopped with `^Z`.

Also, you can dereference one of those job numbers using `%` with the `kill` command.

```bash
$ kill %1

[1]+  Stopped                 sleep 3
$ jobs
[1]+  Terminated: 15          sleep 3
```

### `fg` ###

You can bring one of those background jobs listed in `jobs` back into the foreground with `fg`. You can pass `fg` a job number if you've got multiple in the background, otherwise it will default to the last job you interacted with (marked by the `+` in the jobs output). This will automatically resume the job if it's in the 'Stopped' state.

### `bg` ###

The `bg` command will take a job that's in the 'Stopped' state and resume it, but keep it in the background.

Since the `^Z` key will _stop_ a job, taking a job running in the foreground to running in the background takes two steps: first, you hit `^Z`, then you do a `bg`.

## The caveats ##

These job control features are built into the shell, and are associated with a specific shell session (as far as I know). Typically, if you think you'll need multiple things running at once before actually kicking off a command, you should reconsider your options before reaching for these rather primitive shell features. I hear `tmux` is a pretty good option (but still haven't learned much of it myself :/ ).

Also, a program is free to do whatever it wants in response to a `SIGTSTP`, the signal sent to a process when you hit `^Z`. Sometimes a program will misbehave in strange ways. Sometimes it will so expected-but-unfortunate things like kill a download that you actually wanted to keep running in the background.

_However_, one thing that background jobs are more consistently useful for is to keep an editor like `vim` open on a file in the background. To move from a foreground editor back to the shell you opened it in, hit `^Z`, and you can move back into your editor exactly where you left off with a `fg`.

## Related ##

I found this article called ["The TTY Demystified"](http://www.linusakesson.net/programming/tty/) to be _super_ interesting and helpful to understand some of these strange job control mechanisms (and more). It goes through an abridged history of why all the layers of software that make up a terminal work and interact the way they do, and into detail on how the mechanisms actually work, and what about them is user-configurable. Highly recommended!
