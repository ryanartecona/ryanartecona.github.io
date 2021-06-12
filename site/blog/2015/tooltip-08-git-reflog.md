# Tooltip #8: Git Reflog

<date>2015-11-20</date>
<tags>tooltip</tags>

#### or _Undo Whatever You Just Did To Your Branch That Made An Utter Mess_ ####

---

Okay. All you did was try to be a _good coworker_ and do a bit of cleanup on the commits in the branch you're ready to merge. A couple reworded commit messages, a rebase, a little manual conflict resolution, and _BOOM_ now git is complaining at you, the diff between master and HEAD is unintelligible, and you can't even get back to a working state because your working tree is dirty and the commits from your branch are now interspersed with junk from who knows where!

First, come down off that ledge. You don't have to `git checkout origin/mybranch` and redo work, there's no need to `reset --hard` anything, and _please_ try not to reach for the `cd ../ && rm -rf myproject && git clone ...`. We can get you help.

## Cleaning up ##

First things first. If there's unstaged stuff in your `git status` that doesn't belong, be sure to stash anything you want to keep, and then do a `git clean`.

There are 3 cleaning modes you have to pick from. The first is `-n` or `--dry-run`. The second is `-i` or `--interactive`, which will ask you whether or not you want to delete each unstaged file. If you're sure it's safe, you can instead give `-f` or `--force` to give git permission to delete it all. With `--force`, you may also need to give it `-d` which allows it to also delete whole unstaged directories.

If you're stuck in the middle of a rebase, a quick `git rebase --abort` is also in order.

## Backing out ##

Turns out, git tracks all the changes you make to _references_ which includes operations like creating or deleting a branch, stepping through a rebase, pulling, changing tags, etc. It keeps these in what's called the _reference log_ for a few months. The great thing is you can use this reflog to essentially _undo_ the types of changes that it tracks!

You can take a peek at these changes with `git reflog`. One of mine currently looks like this.

```
abac029 HEAD@{0}: checkout: moving from master to ryan/webpack
abac029 HEAD@{1}: rebase finished: returning to refs/heads/master
abac029 HEAD@{2}: pull --rebase: Add a couple AccountStats#play_vector specs
dd18c22 HEAD@{3}: pull --rebase: checkout dd18c229f314e8cdd9fc8acde5cf0f943f8a6c87
4e8a61f HEAD@{4}: merge ryan/stats-fix-perf: Fast-forward
f787611 HEAD@{5}: checkout: moving from ryan/stats-fix-perf to master
4e8a61f HEAD@{6}: commit (amend): Add a couple AccountStats#play_vector specs
fb932cb HEAD@{7}: commit: Add a couple AccountStats#play_vector specs
f787611 HEAD@{8}: checkout: moving from master to ryan/stats-fix-perf
f787611 HEAD@{9}: rebase finished: returning to refs/heads/master
f787611 HEAD@{10}: pull: checkout f787611d4ca8f1bc4dcf5ddd60c44646b9fd817b
59525d8 HEAD@{11}: checkout: moving from ryan/ios-support to master
6b379fa HEAD@{12}: rebase -i (finish): returning to refs/heads/ryan/ios-support
6b379fa HEAD@{13}: rebase -i (pick): get Doorkeeper setup to work with AFOAuth2Manager for iOS
59525d8 HEAD@{14}: rebase -i (start): checkout origin/master
...
```

You may not have done each of these manually, but they all directly or indirectly resulted from your git commands. For example, if you do an interactive rebase, each step will show up as a separate reflog entry, and the whole rebase operation will be bookended with `(start)` and `(finish)` (or `abort`) entries.

If you can glance through that reflog and identify the spot that represents the state of things before things went south, the only thing left to do is to reset to that spot! For example, given the reflog above, if I wanted to reset to just before I did that last `pull --rebase`, I'd run `git reset --hard HEAD@{4}`. That will the commits that your branches point to to whatever they pointed to at that time.

Note that doing a reset to some point in the reflog _is itself_ an operation that gets recorded in the reflog. This means running `git reset --hard HEAD@{4}` and then viewing `git reflog` will show a new entry at the top.

```
4e8a61f HEAD@{0}: reset: moving to HEAD@{4}
abac029 HEAD@{1}: checkout: moving from master to ryan/webpack
...
```

This has the _slightly_ unfortunate consequence that you can't just repeatedly run `git reset --hard HEAD@{1}` like you would hit a normal undo button, but also the _very_ fortunate property that you won't shoot yourself in the foot by resetting to the wrong reflog position and losing reflog history. Solace!
