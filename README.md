# Octo

O[din]C[code]T[transport]O[perator] is a bespoke package manager for Odin that is meant to be opinionated and comfortable (for me).
The concept is to maintain grain control of the process with some ergonomics. The more barebones the better, and lots of loggin.
The program is just doing what I would do manually without magic.

### Limitations
* **Currently** only supports MacOS (Should work in Linux too but haven't tested)
* Not managing dependencies of dependencies. (Not sure I will)
* Versions are not being tracked (yet)

Octo expects the following file structure:
* octo.pkg
* ols.json
* src (optional, the default builder uses this if present)
* libs (optional, the default builder uses this if present)
* target (all builds get generated to this directory)

My custom is having all dependencies in a `lib` folder and my own logic in `src`
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
This will bootstrap the binary in the `$HOME/.octo` directory and add the `registry.json` (Which I haven't really done anything with yet)

You should add it to your path afterwards. I use `zsh` so I just append it to my `.zshrc` in the home directory
```bash
echo "PATH=$HOME/.octo:$PATH" >> "$HOME/.zshrc"
```
I like nerd-font-icons so if have them installed, if you want to see them you can set `FAILZ_ICONS_ENABLED` to `true` and they'll show up

### Available commands
```bash
$ octo new <package_name>
$ octo init
$ octo run <BUILD_TARGET>
$ octo build <BUILD_TARGET>
$ octo release
$ octo install
$ octo ls
$ octo list
$ octo add <optional:SERVER>/<optional:OWNER>/<PKG>
$ octo update <PKG>
$ octo rm <PKG>
```

The build system works through the `octo.pkg` it only receives parameters that are available already in `odin build`. For example:
```json
release: {
  src: "src",
  collections: {
    libs: "libs"
  },
  optim: "speed",
  separate_modules: true
}
```
translantes to:
```bash
odin build src -collection:libs=libs -o:speed -use-separate-modules -out:target/release/<name_of_the_app>
```
