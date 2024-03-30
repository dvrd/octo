# Octo

Octo is a bespoke package manager for Odin that is meant to be opinionated and comfortable

### Limitations
* **Currently** only supports MacOS (Should work in Linux too but haven't tested)
* The packages are just getting copied around atm
* Haven't added a way for the system to automatically download dependencies
* No real build flexibility (idea is to integrate @DragonPopse [odin-build](https://github.com/DragosPopse/odin-build))

### Installation

```bash
git clone https://github.com/dvrd/octo
cd octo
make install
```

### Available commands

```bash
$ octo new <package_name>
$ octo init
$ octo run
$ octo build
$ octo install
$ octo build --release
$ octo add <package_name>
$ octo remove <package_name>
```
