# Notes

My notes on various topics. Use on your own risk.

## macOS

Use TouchID as sudo password

```bash
sudo sed -i '' '2s/^/auth       sufficient     pam_tid.so\\n/' /etc/pam.d/sudo
```

## Asdf

Remember to reshim after installing a new version of asdf[^2]:

    rm -rf ~/.asdf/shims
    asdf reshim

Not doing this may results in tools installed with asdf not being found.

## Git

Update all the submodules to the latest commit on their default branch:

    git submodule foreach 'git fetch origin; git checkout $(git rev-parse --abbrev-ref HEAD); git reset --hard origin/$(git rev-parse --abbrev-ref HEAD); git submodule update --recursive; git clean -dfx'

## Vim

When updating Go version rememper to update go packages[^1]:

    :GoUpdateBinaries

[^1]: https://github.com/fatih/vim-go/issues/3434
[^2]: https://github.com/asdf-vm/asdf/issues/531
