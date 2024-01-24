# Octo

Octo is a package manager for C that is meant to be opinionated and 
comfortable 

Configuration is done through Octo's toml file.

Right now it's a very simple tool.

`[package]`
* `name`    is self explanatory
* `edition` is used to set the C standard to build against
* `version` is only used to output upon compilation

### Available commands

```bash
$ octo new <package_name>
$ octo init     # should be done inside the directory to be initialized
$ octo build    # uses clang to build with all C files in the /src directory
$ octo run      # executes the binaries compiled inside /target/debug
```
