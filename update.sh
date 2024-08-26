#!/bin/bash

# find potential updates for all packages in external/

set -e

PREFER_TAGS=${PREFER_TAGS:-1}

EXTERNAL_DIR=${EXTERNAL_DIR:-external}
EXTERNAL_DIR=$(realpath external)

if ! [ "$PREFER_TAGS" -eq 0 ]; then
    PREFER_TAGS=1
fi

echo "Checking for updates to this repository and $EXTERNAL_DIR/* (PREFER_TAGS=$PREFER_TAGS)"

git fetch --quiet
git submodule update --init --recursive --quiet

for package in "$(realpath .)" "$EXTERNAL_DIR"/*; do
    if [ -d "$package" ]; then
        if [ -f "$package/.git" ] || [ -d "$package/.git" ]; then
            git -C "$package" fetch --quiet
            git -C "$package" fetch --tags --quiet

            # get HEAD commit hash
            HEAD=$(git -C "$package" rev-parse HEAD)
            # get remote HEAD commit hash
            REMOTE_HEAD=$(git -C "$package" rev-parse origin/HEAD)

            HEAD_TAG=$(git -C "$package" tag --points-at HEAD | head -n 1)

            if [ "$HEAD" != "$REMOTE_HEAD" ] || [ -z "$HEAD_TAG" ]; then
                # count commits behind/ahead
                COMMITS=$(git -C "$package" rev-list --count HEAD..origin/HEAD)
                if [ "$PREFER_TAGS" -eq 0 ] || [ -z "$(git -C "$package" tag)" ]; then
                    if [ "$HEAD" != "$REMOTE_HEAD" ]; then
                        echo "Potential update for $package: $HEAD -> $REMOTE_HEAD ($COMMITS commits ahead of $(git -C "$package" tag --points-at HEAD | awk '{print "tag " $1 " (HEAD)";succ=1;exit}END{if (!succ) print "HEAD"}'))"
                        echo "  switch to origin/HEAD? [y/N]"
                        read -r response </dev/tty
                        if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
                            git -C "$package" checkout origin/HEAD && echo "  Updated to origin/HEAD"
                        fi
                    else
                        echo "No updates for $package (HEAD at $HEAD)"
                    fi
                else
                    echo "Looking for tags for $package (HEAD$(test -n "$HEAD_TAG" && echo " (tag $HEAD_TAG)") at $HEAD)"

                    if git -C "$package" tag >/dev/null; then
                        TAGS=0
                        SAME_TAGS=0
                        for tag in $(git -C "$package" tag --contains HEAD --sort=-creatordate); do
                            COMMIT=$(git -C "$package" rev-list -n 1 "$tag")
                            TAGS=$((TAGS + 1))
                            if [ "$COMMIT" != "$HEAD" ]; then
                                echo "  $tag ($(git -C "$package" rev-list --count HEAD.."$tag") commits ahead of HEAD; $(git -C "$package" diff --shortstat HEAD "$tag"))"

                                echo "  switch to $tag? [y/N]"
                                read -r response </dev/tty
                                if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
                                    git -C "$package" checkout "$tag" && echo "  Updated to $tag"
                                    break
                                fi
                            else
                                SAME_TAGS=$((SAME_TAGS + 1))
                            fi
                        done

                        if [ "$TAGS" -eq "$SAME_TAGS" ] && [ "$TAGS" -ne 0 ]; then
                            echo "  No newer tags available"
                        elif [ "$TAGS" -eq 0 ]; then
                            # try past tags
                            for tag in $(git -C "$package" tag --sort=-creatordate); do
                                COMMIT=$(git -C "$package" rev-list -n 1 "$tag")
                                TAGS=$((TAGS + 1))
                                if [ "$COMMIT" != "$HEAD" ]; then
                                    echo "  $tag ($(git -C "$package" rev-list --count "$tag"..HEAD) commits behind of HEAD; $(git -C "$package" diff --shortstat HEAD "$tag"))"

                                    echo "  switch to $tag? [y/N]"
                                    read -r response </dev/tty
                                    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
                                        git -C "$package" checkout "$tag" && echo "  Downgraded to $tag"
                                        break
                                    fi
                                fi
                            done
                        fi
                        if [ "$TAGS" -eq 0 ]; then
                            echo "  No tags available"
                        fi
                    fi
                fi
            else
                echo "No updates for $package"
            fi
        else
            echo "Skipping $package" # possible extension: check for updates in other ways
        fi
    fi
done
