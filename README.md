# Octo

**Currently broken builds don't output errors**

Octo is a bespoke package manager for Odin that is meant to be opinionated and comfortable.
The concept is to maintain grain control of the process with some ergonomics.
The program is just doing what I would do manually without magic

### Limitations
* **Currently** only supports MacOS (Should work in Linux too but haven't tested)
* Not managing dependencies of dependencies. (Not sure I will)
* No real build flexibility (idea is to integrate @DragonPopse [odin-build](https://github.com/DragosPopse/odin-build))

Octo expects the following file structure:
* octo.pkg
* ols.json
* src
* libs
* target

All folders in libs are automatically added as part of the `libs` collection
```odin
import "libs:<some dependency>"
```

### Packages
Packages are downloaded to `$HOME/.octo` folder and then copied to your project `libs`.
To avoid unnecessary files only `odin` source files or static/shared libraries are copied

### Installation

```bash
git clone https://github.com/dvrd/octo
cd octo
make install
```

I like nerd-font-icons so if have them installed and want to see them you can set `FAILZ_ICONS_ENABLED` to `true` and they'll show up

### Available commands

```bash
$ octo new <package_name>
$ octo init
$ octo run
$ octo build
$ octo install
$ octo ls
$ octo list
$ octo build --release
$ octo add <server:default=github.com>/<owner>/<package_name>
$ octo remove <package_name>
```

