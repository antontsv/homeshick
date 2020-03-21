homeshick [![Build Status](https://img.shields.io/travis/andsens/homeshick/development.svg?label=origin)](https://travis-ci.org/andsens/homeshick) [![Build Status](https://img.shields.io/travis/antontsv/homeshick.svg?label=antontsv%20fork)](https://travis-ci.org/antontsv/homeshick)
=========

Small utility to help manage your dotfiles.

**Note:** this is a fork, for original repo and install instrustions go to [andsens/homeshick](https://github.com/andsens/homeshick).

Install
-------

homeshick is installed to your own home directory and does not require root privileges to be installed.
```sh
# Clone repository:
git clone https://github.com/antontsv/homeshick.git $HOME/.homesick/repos/homeshick

# Source homeshick command into your shell:
source "$HOME/.homesick/repos/homeshick/homeshick.sh"
```

See full example of homeshick installation from this fork and it's use in https://git.io/install.files

Changes in this fork
--------------------
* Allow files to be linked from root of repository, not just from `home/`:

    This mode be done by setting up `HOMESHICK_USE_CASTLE_ROOT=true`

    Extra files can be ignored if declared via `HOMESHICK_IGNORE` variable

    ```bash
    # example use with cloning mode set to root of cloned repo:
    HOMESHICK_USE_CASTLE_ROOT=true \
    HOMESHICK_IGNORE="LICENSE,README.md,/.gitmodules" \
    homeshick clone --batch "https://github.com/antontsv/home.bin.git"
    ```

* Includes `verify-commit` binary for optional checks of commit signatures after `homeshick pull` command