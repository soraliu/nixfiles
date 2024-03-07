## Usages

- oh-my-zsh `git` plugin:

> TL;DR: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git

```sh
gaa         # git add --all

gb          # git branch
gba         # git branch --all

gco         # git checkout                                                          # T0
gcb         # git checkout -b                                                       # T0

gd          # git diff                                                              # T0
gst         # git status                                                            # T0

gcp         # git cherry-pick                                                       # T1
gcpa        # git cherry-pick --abort
gcpc        # git cherry-pick --continue

gclean      # git clean --interactive -d                                            # T2

gcam        # git commit --all --message                                            # T0
gca         # git commit --all --verbose
gca!        # git commit --all --verbose --amend
gcan!       # git commit --all --verbose --amend --no-edit                          # T0
gcans!      # git commit --all --verbose --amend --no-edit --signoff
gc!         # git commit --verbose --amend
gcn!        # git commit --verbose --amend --no-edit

gd          # git diff                                                              # T0
gdw         # git diff --word-diff                                                  # T1
gdca        # git diff --cached                                                     # T0
gdcw        # git diff --cached --word-diff                                         # T1
gdt         # git diff-tree --no-commit-id --name-only -r                           # T1
gdnolock    # git diff $@ ":(exclude)package-lock.json" ":(exclude)\*.lock"


glol        # g lg                                                                  # T0
glola                                                                               # T1
glg         # git log --stat                                                        # T0
glgp        # git log --stat --patch                                                # T0

gl          # git pull                                                              # T0
gpr         # git pull --rebase                                                     # T0
gpra        # git pull --rebase --autostash                                         # T1

gp          # git push                                                              # T0
gpsup       # git push --set-upstream origin $(git_current_branch)                  # T0
ggp         # git push origin $(current_branch)                                     # T0
gpf         # git push --force-with-lease --force-if-includes                       # T1
ggf         # git push --force origin $(current_branch)                             # T1
gpf!        # git push --force                                                      # T1

gstu        # git stash --include-untracked                                         # T0
gstp        # git stash pop                                                         # T1

gst         # git status                                                            # T0
gss         # git status --short                                                    # T0
gsb         # git status --short -b                                                 # T1

gta         # git tag --annotate                                                    # T1
gta -m      # git tag --annotate -m                                                 # T1
gta -f -m   # git tag --annotate -m                                                 # T1

gwip        # use this command when a branch does not finish, but you need to switch to another branch or just store these changes to avoid losing.
gunwip      # restore those changes
```

- git open

> TL;DR: https://github.com/paulirish/git-open?tab=readme-ov-file#examples

```sh
git open [remote-name] [branch-name]
    # Open the page for this branch on the repo website

git open -c
    # Open the current commit in the repo website

git open -i
    # If this branch is named like issue/#123, this will open the corresponding
    # issue in the repo website

git open -p
    # Only print the url at the terminal, but don't open it
```

