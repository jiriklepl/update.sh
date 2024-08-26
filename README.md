# update.sh

This script updates the git submodule repositories and attempts to checkout the latest tag (release).

The goal of the script is to help people keep their git submodules as recent as possible.

## Getting started

Just copy the script to your repository and all should work.

## How it works

The script goes through all git repositories in the `/external` directory in your project.

If it find a newer tag for one of the repositories (defaults to the newest one), it asks the user if they want to checkout this version:

```sh
Looking for tags for <REPOSITORY_PATH> (HEAD at <COMMIT_NUMBER>)
  <TAG_NAME> (<N> commits behind of HEAD; <F> files changed, <I> insertions(+), <D> deletions(-))
  switch to <TAG_NAME>? [y/N]
```

The user can then either type `y` to confirm or `N` (or just press enter) to skip this tag.

The script will then do the same for each tag going back in history.

### If it does not find any newer tag

The script looks at the HEAD (the current state) and if it corresponds to a tag, it moves on to the next external repository.

If the HEAD is not at a tag, the script attempts to downgrade the repository to the nearest tag (otherwise, same as in the previous section).

### I don't care about tags

If you set `PREEFER_TAGS=0` (or you hard-code it in the script this way), the script always asks whether the user whether they want to checkout the current state of the `origin` of the repository.

### A repository has no tags

Then, the script acts as if the user specified `PREFER_TAGS=0` and attempts to checkout the newest commit in the `origin`.

## The script misses a critical feature

Write a github issue or make a pull request.
