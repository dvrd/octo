# Octo

O[din]C[code]T[transport]O[perator] is a bespoke package manager for Odin that is meant to be opinionated and comfortable (for me).
The concept is to maintain grain control of the process with some ergonomics. The more barebones the better, and lots of loggin
The program is just doing what I would do manually without magic.

### Limitations
* ‼️ **Broken builds don't output errors**
* **Currently** only supports MacOS (Should work in Linux too but haven't tested)
* Not managing dependencies of dependencies. (Not sure I will)
* No real build flexibility (idea is to integrate @DragonPopse [odin-build](https://github.com/DragosPopse/odin-build))
* Versions are not being tracked (yet)

Octo expects the following file structure:
* octo.pkg
* ols.json
* src
* libs (optionals)
* target

All folders in libs are automatically added as part of the `libs` collection
```odin
import "libs:<some dependency>"
```

### Packages
Packages are downloaded to `$HOME/.octo` directory and then copied to your project `libs`.
To avoid unnecessary files only `odin` source files or static/shared libraries are copied

### Installation

```bash
git clone https://github.com/dvrd/octo
cd octo
make install
```
This will build and install the binary in the `$HOME/.octo` directory and add the `registry.json`

You should add it to your path afterwards. I use `zsh` so I just append it to my `.zshrc` in the home directory
```bash
echo "PATH=$HOME/.octo:$PATH" >> "$HOME/.zshrc"
```
I like nerd-font-icons so if have them installed, if want to see them you can set `FAILZ_ICONS_ENABLED` to `true` and they'll show up

### Available commands

```bash
$ octo new <package_name>
$ octo init
$ octo run
$ octo build
$ octo release
$ octo install
$ octo ls
$ octo list
$ octo build --release
$ octo add <optional:SERVER>/<optional:OWNER>/<PKG>
$ octo update <PKG>
$ octo rm <PKG>
```

