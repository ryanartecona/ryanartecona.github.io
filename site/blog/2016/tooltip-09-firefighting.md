<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-generate-toc again -->
**Table of Contents**

- [Firefighting](#firefighting)
    - [What processes are using which resources?](#what-processes-are-using-which-resources)
        - [`ps`](#ps)
        - [`htop`](#htop)
    - [What's taking up disk space?](#whats-taking-up-disk-space)
        - [`df`](#df)
        - [`du`](#du)
        - [Drilling down to a runaway log file](#drilling-down-to-a-runaway-log-file)
    - [What files or connections is a thing holding open?](#what-files-or-connections-is-a-thing-holding-open)
    - [Log file spelunking](#log-file-spelunking)
        - [`tail -f` and friends](#tail--f-and-friends)
        - [Where to look](#where-to-look)
    - [Networking](#networking)
        - [What IP does this host resolve to?](#what-ip-does-this-host-resolve-to)
        - [Is that box even reachable?](#is-that-box-even-reachable)

<!-- markdown-toc end -->

# Tooltip #9: Firefighting

<date>2016-03-10</date>
<tags>tooltip</date>

Ding! Errors just spiked. App's down. The ENOMEMs have arrived, and they're not happy. _Shit's broke_.

You look around, and everyone who was _just here_ who could definitely deal with it have suddenly all vanished. Welp. What now?

## What processes are using which resources? ##

There's `ps` for simply listing processes, and `top` and `htop` for a richer, more interactive take on your process table.

### `ps` ###

The `ps` command by default only lists processes owned by the current user and run from a terminal. It also doesn't display the user associated with each process. To list all processes and include a user column in the output, do this.

```bash
ps aux
```

From there, you can pipe to `grep` to find processes run by a certain user or containing a particular command or argument. For anything more explorative, you probably want to jump straight to `htop`.

### `htop` ###

Running htop is easy enough.

```bash
htop
```

But there's some serious wizardry buried in that simple command.

The first view you'll see looks roughly like `top`, but with colors. Arrow keys move you up and down in the process listing or will scroll you left and right to see long process names. The `Page Up` and `Page Down` keys will let you scroll pages at a time. Those are `fn+↑` and `fn+↓` on OS X.

The `h` key will show you a key binding cheat sheet. Everything else here is there, so remember that if you forget everything else!

A `t` will toggle a tree view, a `u` will let you filter the list for a specific user, and a `k` will let you send any signal you want to that process. Signalling defaults to `TERM`, so `k RET` will (should) kill the process under cursor. You can even use `SPC` to select a bunch of processes and hit `k` to send the same signal to all of them!

You can click on each column heading to set the sort column, and you can search process names with `/`.

If you need to dig deeper, `l` will show you every file descriptor that process has open (via `lsof`), and `s` will fire up `strace` (Linux only) to show you every system call that process is making! That `lsof` listing may be slow, but shouldn't be particularly expensive to generate; on the other hand, `strace` may slow down the traced program significantly (depending on how frequently it makes syscalls; see ["strace Wow Much Syscall"](http://www.brendangregg.com/blog/2014-05-11/strace-wow-much-syscall.html) for details), so just be cautious tracing in production where you can't afford a performance hit.

Just be aware that `htop` may not have access to all the information it wants, depending on your user's permissions. If you've got root, it's usually best to `sudo htop`.

## What's taking up disk space? ##

If you `ls -l` a file, it will show you its size; but if you `ls -l` a directory, its size will always be `4096`! Why? The `ls` command shows you the size of each item's _inode_ in the filesystem, which for a directory does not include the size of its contents.

To explore disk usage, you probably want some combination of `df` and `du`.

### `df` ###

The `df` command will show you a summary of how much space is used vs. free for each currently mounted filesystem. Units are kilobytes by default, so you usually want `df -h` to get units rounded and shown in MB, GB, etc.

### `du` ###

The `du` command knows how to compute total disk usage for the contents of directories. 

Given a directory, `du` will recurse down all descendent files and subdirectories and get the disk usage of each. With no other options specified, it will print the size on disk of _every file_ descendent from that directory, which is usually not what you want. You must give it a _depth_ option to tell it how many levels of directories you want a summary for, so `du -d1 /` will show you the total size of all contents of only root level directories.

Units are kilobytes by default here too, so you usually want human-readable `du -hd1 <path>`.

### Drilling down to a runaway log file ###

Uh oh! Disk is full on an app box.

1. Starting out, do a preliminary `df` to see how much space on which filesystem is used up.

2. For the offending filesystem, do a `du -hd1` with the filesystem's listed _mount point_ (e.g. `du -hd1 /`). If you see a bunch of `cannot read directory ...: Permission denied` errors, and your user has root privileges, retry with `sudo`.

3. In all likelihood, one of the listed results is much larger than the others. If it's a file, you found the offender! If it's a directory, do another `du -hd1` at that directory, and go to (3).

4. If you found and deleted or truncated an overlarge file, check the results of a fresh `df` against the one from (1) to be sure it took.

Here's one caveat. Space on disk for a file can't be freed until no program is using it anymore. When you delete a file, new programs can't open it, but existing ones may still have it open! Sometimes in (4) you can not find what's taking up space, or you can find and delete it but see that space isn't immediately recovered in `df`, and this can be why. (For example, when mysql creates a temporary file in its `tmpdir`, it immediately deletes it, but keeps the descriptor open, so that only it can use it, and so that its space is automatically freed if mysql happens to exit uncleanly. See `man 2 unlink` for more info.) 

If this is the case, `du` is of no more use. That brings me to `lsof`.

## What files or connections is a thing holding open? ##

The job of `lsof` is to _list open files_. Since, on Unix, everything is a file (descriptor), `lsof` can dump out quite a lot of useful information about a running process. It's one of my favorites.

An `lsof` with no options will list _every open file descriptor_ for _everything running_, which is almost surely not what you want.

You can give `lsof` a pid or list of comma-separated pids to filter output for.

```bash
# Bash's $$ expands to the its own current process id
lsof -p $$
```

You can give it a network specification to filter connections for only open connections which match.

```bash
# open connections on port 443
lsof -i :443

# the same thing, specifying the default port for https (see /etc/services for a full list)
lsof -i :https

# all TCP connections
lsof -i TCP

# all IPv4 TCP connections on localhost mysql port (3306)
lsof -i 4TCP@localhost:mysql
```

You can even ask it for all open files which have since been deleted!

```bash
# list all files with fewer than 1 link, i.e. all deleted (unlinked) files
lsof +L1
```

One quirk about `lsof` is that filter options are _disjunctive_ (logical _or_) by default. To specify filters as _conjunctive_ instead, use `-a` (for _and_).

```bash
# all file descriptors which are TCP connections, or which are owned by pid 1337
lsof -i TCP -p 1337

# all TCP connections of only pid 1337
lsof -i TCP -a -p 1337
```

Fun fact: dynamically linked libraries, for the purposes of inspection with `lsof`, are just normal file descriptors! So, for example, you can see every running process dynamically linked against openssl like so.

```bash
sudo lsof | grep libssl | less
```

## Log file spelunking ##

If we're honest, who cares about logs? Filled with well-intended `INFO` lines grasping for relevance and `WARN`s with arguably decent advice never heeded, logs are most often like my collection of mugs, which started that time I told my mom I liked coffee, and which has grown every gift-oriented holiday since by 1 or 2 bright pink ones with hearts on them or ones with the ingenuine grins of my own immediate family printed on them, all rarely, if ever, used.

Still, sometimes you just don't have better options.

### `tail -f` and friends ###

You've likely already used `tail -f thing.log`. Just remember you can `tail` multiple files at once, and it works well with shell globbing, like so.

```bash
tail -f /opt/apps/*/shared/log/*.log
```

You can also use `less +F` for `tail -f`-like behavior (or `less +G` to scroll to the end without following). The notable difference when used with multiple log files, though, is that `tail -f` will intersperse the output of each to stdout, where `less +F` keeps the files separate, and you have to `:n` or `:p` to flip between them.

### Where to look ###

Besides app logs, you're likely to find log files for other system programs like mysql or nginx in `/var/log`, at least in Ubuntu. One extra special log file is `/var/log/syslog`, which is an aggregate log of some other low level processes. If something's broken at the system level, chances are something will point to it in the syslog.

If, on the other hand, you're doing some manual maintenance on a server, always remember that you can `oops_lol_broken.sh | tee fixup.log` to save all output to a file for later. There's nothing worse than _just knowing_ those few output lines you need right now are _just beyond_ the edge of your scrollback. (Bonus: if you have the `moreutils` package installed, you can pipe to `ts` to get timestamped log lines for anything which doesn't already have them!)

## Networking ##

_Networks, man_. Can't live with 'em, can't live without 'em.

### What IP does this host resolve to? ###

To see what your DNS resolver has on record for a domain name, `dig` is (usually) your friend.

```bash
dig google.com
```

That will give you the DNS A records for that domain, as reported by one of your DNS servers. To get a different type of record, just supply it after the domain. To show all records, use the special type `ANY`.

```bash
# email SPF records and such
dig google.com TXT
# I want it all
dig google.com ANY
```

Note that `dig` will reach out to a DNS server _every time_, which may not necessarily be the source of DNS resolution that your program sees. Notably, `nscd` (name service caching daemon) is a weird fish that _hooks into glibc directly_ to inject cached DNS responses, with its own configurable TTL _separate_ from any TTL respected by the DNS server itself. To see a bit more accurately what your program sees, use `getent` (Linux only).

```bash
getent hosts google.com
```

### Is that box even reachable? ###

You've almost definitely used `ping`.

```bash
ping google.com
```

If you need to script it, you probably want to specify a max number of attempts to avoid that infinite loop.

```bash
ping -c1 google.com
```

One thing to keep in mind is that `ping` uses the ICMP protocol. Sometimes ICMP traffic is disabled by a server (so that it's less discoverable, usually), so a `ping` to an otherwise reachable address may still fail. If you suspect that, or if you need to test a specific port for connectivity, you might try a `telnet` instead.

```bash
telnet google.com 80
```

Bonus points if you can type out a valid HTTP request from memory (I couldn't quite)!

On the rare occasion a remote IP turns out to _not_ be reachable, but both endpoints seem properly configured, then it's time to break out the `traceroute` to see all the hops between A and B.

```bash
traceroute google.com
```

The `traceroute` program also uses ICMP to send out its probes, so the same ICMP-maybe-disabled caveat as `ping` applies here too.
