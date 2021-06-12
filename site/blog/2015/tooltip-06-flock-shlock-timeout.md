# Tooltip #6: flock, shlock & timeout #

<date>2015-10-16</date>
<tags>tooltip</tags>

Have you ever seen a cron job somehow take longer than expected? Have you ever opened a `top` and been surprised to find a sad little cluster of hung cron jobs? Have those jobs ever happened to contend for a shared resource, such that if only a _single_ job took too long, they would all slow down and result in a _multi-cron pileup_?

I have.

Have you ever hesitated for a brief moment before running a command and wondered "what happens if someone else starts one of these before mine finishes? something bad?", then realize you wouldn't even know how to protect this command from multiple simultaneous invocations anyway, and finally,  defeated by the awfulness of software, let out an audible sigh and run the potentially disasterous command the way you were going to anyway? 

I _totally_ haven't. Nope. Definitely not yesterday.

## Put a mutex in your filesystem ##

The good news is there's hope. The general strategy isn't even all that complicated, conceptually.

To protect a shared resource in a way that only allows one actor to _do something_ with it at any given time, one reliable strategy is to make that actor acquire a lock first, and release the lock after use.

It's no different here! Linux's `flock(1)` command will wrap a command by first acquiring a lock via a file, and afterward releasing the lock by deleting the file.

Since OS X doesn't have `flock(1)` _the command_ (though it has `flock(2)` _the syscall_...), `flock` isn't exactly great for use inside portable scripts. In OS X you have to use `shlock` to achieve the same effect, which uses a similar locking mechanism, but is more difficult to use.

### `flock` in Linux ###

So you have a command which you want at most one copy of running at any time.

```bash
deploy-to-prod --big-data --hot-swap all --force
```

Wrap it with `flock`, specifying the name of the file to use for the lock.

```bash
flock /tmp/deploy-to-prod.lock deploy-to-prod --big-data --hot-swap all --force
```

Everything works the same as otherwise if the lock doesn't exist when the command is run. If it does, the default configuration will _wait_ to acquire the lock, and then start the wrapped command.

You can tell `flock` to _bail out early_ instead of waiting to acquire the lock, if you want.

```bash
flock --nonblock /tmp/deploy-to-prod.lock deploy-to-prod --big-data --hot-swap all --force
```

This is better for the `cron` use case, since you know the command will eventually be retried if it can't do its thing immediately.

You can alternatively tell `flock` to wait for the lock up to a timeout threshold, and if the lock still hasn't come available, to exit with an error code `1`.

```bash
flock --wait 4.5 /tmp/deploy-to-prod.lock deploy-to-prod --big-data --hot-swap all --force
```

This will let `flock` wait up to 4.5 seconds, or otherwise fail.

### `shlock` in OS X ###

Unfortunately, `flock(1)` doesn't exist in OS X, only Linux and BSD. There's [this stated 'portable' version](https://github.com/discoteq/flock), but it doesn't looks like it has many users. _Caveat executor_.

What _is_ available in OS X is a related tool called `shlock`. It's meant to be used in a script, so it doesn't simply wrap a command.

```bash
#!/usr/bin/env bash
lckfile=/tmp/foo.lock
if shlock -f ${lckfile} -p $$
then
  deploy-to-prod --first grip_it --then rip_it
  rm ${lckfile}
else
  echo Lock ${lckfile} already held by `cat ${lckfile}`
fi
```

As you might guess by the different name, `shlock` achieves an effect similar to `flock`, but via a different mechanism. Most notably, you have to explicitly give it the PID of the process which is to be considered the acquirer of the lock (via `-p $$` in bash), and you have to manually `rm` the lockfile when you're done with it. Also, `shlock` always exits immediately, akin to the `--nonblock` flag in flag, leaving any wait/timeout behavior up to the user.

### The manpage behind the curtain ###

The `flock(1)` command wraps the `flock(2)` system call with a nice interface. The `flock(2)` syscall works by assigning locks to _file descriptors_. The `flock(1)` command essentially opens a file descriptor for the lock file you point it at, acquires an `flock(2)` on it, and then keeps that file descriptor open and locked while your command runs.

Judging by the warning signs in the respective man pages, it seems this mechanism can make some environments tricky to use with `flock`. Specifically, `fork`ing a process after the parent acquires an `flock` on a file descriptor means the child effectively inherits that lock, by way of inheriting its associated file descriptor. Conversely, opening two file descriptors to the same file and `flock`ing each will behave the same as two separate processes attempting to acquire `flock`s on that file, since the file descriptors are distinct. Also, the presence of the lock file _does not_ imply some process currently has an `flock` on it; the file stays around after the lock is released.

The `shlock` in OS X works very differently under the hood. To acquire an `shlock` is to write the calling process's PID to that file, and to release the lock is to simply delete the file. The `shlock` command takes care of checking if the currently written PID actually corresponds to a currently running process, and will happily acquire the lock itself if that process is nowhere to be found. This guards against a process dying before releasing a lock. The atomicity of acquiring an `shlock` is guaranteed by `link(2)` instead of `flock(2)`.

This actually makes for far fewer caveats for `shlock` than `flock`, since whole processes and PIDs are easier to track and manage than individual file descriptors.

## A complementary `timeout` ##

Even with the protection of a mutex lock for any command, your computer might still be exposed to a particularly unsavory situation wherein a command launches, acquires an `flock` or `shlock`, and then _hangs_, never to exit nor to release the lock!

For this malady a pretty decent remedy is a good, old fashioned `timeout`, which does exactly what it sounds like. Combined with an `flock` or `shlock`, you can be sure _at most 1_ of a command ever run simultaneously, and that no bad run will be allowed to keep the lock for _too_ long.

```bash
flock --wait 600 /tmp/deploy-to-prod.lock timeout 60m deploy-to-prod --exec **/*
```

Here, `flock` waits up to 10 minutes to acquire the `/tmp/deploy-to-prod.lock`. If the lock is acquired, `timeout` waits up to an hour for the command to exit naturally, or it will kill it with a `TERM` signal.

Note that since `timeout` is part of GNU coreutils, on OS X you will need a `brew install coreutils`, after which it will be installed with a _g_ prefix as `gtimeout`.
