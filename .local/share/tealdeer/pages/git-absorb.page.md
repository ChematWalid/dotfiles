# git-absorb

> Automatic git commit fixup tool. Slices working changes into the commits that introduced them.
> More information: <https://github.com/tomyx/git-absorb>.

- Preview which commits working changes would be absorbed into (dry-run):
  `git-absorb --dry-run`

- Automatically absorb all staged and unstaged changes into historical commits:
  `git-absorb --and-rebase`

- Absorb changes only within the last N commits:
  `git-absorb --base {{HEAD~5}}`
