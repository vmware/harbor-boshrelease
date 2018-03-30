# Contributing to Harbor Bosh Release

The Harbor Bosh Release project team welcomes contributions from the community. If you wish to contribute code and you have not
signed our contributor license agreement (CLA), our bot will update the issue when you open a Pull Request. For any
questions about the CLA process, please refer to our [FAQ](https://cla.vmware.com/faq).

# Contribution flow

This is a rough outline of what a contributor's workflow looks like:

- Fork the repository on GitHub to your personal account.
- Create a topic branch from where you want to base your work.
- Make commits.
- Make sure your commit messages are in the proper format (see below).
- Push your changes to a topic branch in your fork of the repository.
- Test your changes locally.
- Submit a pull request.
- Your PR must receive approvals from component owners before merging.

Example:

``` shell
git checkout -b my-new-feature
git commit -a
git push origin my-new-feature
```

### Stay in sync with upstream

When your branch gets out of sync with the upstream/master branch, use the following to update it:

``` shell
git checkout my-new-feature
git fetch -a
git rebase upstream/master
git push origin my-new-feature
```

### Updating pull requests

If your PR fails to pass CI or needs changes based on code review, you'll most likely want to squash these changes into
existing commits.

If your pull request contains a single commit or your changes are related to the most recent commit, you can simply
amend the commit.

``` shell
git add .
git commit --amend
git push -f origin my-new-feature
```

If you need to squash changes into an earlier commit, you can use:

``` shell
git add .
git commit --fixup <commit>
git rebase -i --autosquash upstream/master
git push -f origin my-new-feature
```

Be sure to add a comment to the PR indicating your new changes are ready to review, as GitHub does not generate a
notification when you git push.

### Coding style

- Uses 2 spaces to replace a TAB.
- Try to limit column width to 120 characters for both code and markdown documents such as this doc.
- Add necessary comments in code. Code without comments is hard to read.

### Format of the Commit Message

We follow the conventions on [How to Write a Git Commit Message](http://chris.beams.io/posts/git-commit/).

Be sure to include any related GitHub issue references in the commit message. See
[GFM syntax](https://guides.github.com/features/mastering-markdown/#GitHub-flavored-markdown) for referencing
issues and commits.
