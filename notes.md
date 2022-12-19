# Notes

My notes on various topics. Use on your own risk.

## Git

Update all the submodules to the latest commit on their default branch:

    git submodule foreach 'git fetch origin; git checkout $(git rev-parse --abbrev-ref HEAD); git reset --hard origin/$(git rev-parse --abbrev-ref HEAD); git submodule update --recursive; git clean -dfx'

## Vim

When updating Go version rememper to update go packages:

    :GoUpdateBinaries

