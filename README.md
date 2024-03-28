# Octo

Octo is a bespoke package manager for Odin that is meant to be opinionated and comfortable

### Limitations
* **Currently** only supports MacOS
* The packages are just getting copied around atm
* Haven't added a way for the system to automatically download dependencies
* No real build flexibility (idea is to integrate @DragonPopse [odin-build](https://github.com/DragosPopse/odin-build))

### Available commands

```bash
$ octo new <package_name>
$ octo init
$ octo run
$ octo build
$ octo build --release
$ octo add <package_name>
$ octo remove <package_name>
```
