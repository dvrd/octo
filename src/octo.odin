package octo

import "core:fmt"
import "core:io"
import "core:mem"
import "core:os"
import "core:path/filepath"
import "core:strings"
import cmd "libs:command"
import "libs:failz"

main :: proc() {
	using failz

	bail(len(os.args) < 2, USAGE)

	switch command := os.args[1]; command {
	case "new":
		bail(len(os.args) < 3, NEW_USAGE)
		proj_name := os.args[2]
		bail(proj_name == "help", NEW_USAGE)

		proj_path := make_project_dir(proj_name)
		err := os.set_current_directory(proj_path)
		bail(Errno(err))

		ols_path := make_ols_file(proj_path)
		src_path := make_src_dir(proj_path)
		main_path := make_main_file(src_path, proj_name)
		init_git()

		info(fmt.tprintf("Created binary (application) `%s` package", proj_name))
	case "init":
		pwd := os.get_current_directory()
		pwd_info, err := os.stat(pwd)
		bail(Errno(err))

		ols_path := make_ols_file(pwd)
		src_path := make_src_dir(pwd)
		main_path := make_main_file(src_path, pwd_info.name)
		init_git()

		info(fmt.tprintf("Created binary (application) package"))
	case "run":
		pwd := os.get_current_directory()
		has_dependencies := os.exists(filepath.join({pwd, "/libs"}))
		collections := has_dependencies ? "-collection:libs=libs" : ""
		bin_path := get_bin_path(pwd)
		cmd.launch({"odin", "run", "src", collections, fmt.tprintf("-out:%s", bin_path), "-debug"})
	case "build":
		pwd := os.get_current_directory()
		has_dependencies := os.exists(filepath.join({pwd, "/libs"}))
		collections := has_dependencies ? "-collection:libs=libs" : ""
		bin_path := get_bin_path(pwd)
		cmd.launch(
			{"odin", "build", "src", collections, fmt.tprintf("-out:%s", bin_path), "-debug"},
		)
	case "release":
		pwd := os.get_current_directory()
		has_dependencies := os.exists(filepath.join({pwd, "/libs"}))
		collections := has_dependencies ? "-collection:libs=libs" : ""
		bin_path := get_bin_path(pwd, "/release")
		out_bin := fmt.tprintf("-out:%s", bin_path)
		cmd.launch({"odin", "build", "src", collections, out_bin, "-o:speed"})
	case "install":
		pwd := os.get_current_directory()
		bin_path := get_bin_path(pwd, "/release")
		target_path := "/usr/local/bin"
		cmd.launch({"sudo", "ln", "-s", bin_path, target_path})
	case "add":
		bail(len(os.args) < 3, ADD_USAGE)
		pkg_name := os.args[2]
		bail(pkg_name == "help", ADD_USAGE)
		home := os.get_env("HOME")
		pwd := os.get_current_directory()

		libs_path := filepath.join({pwd, "/libs"})
		if !os.exists(libs_path) {
			bail(Errno(os.make_directory(libs_path)))
		}

		local_pkg_path := filepath.join({libs_path, "/", pkg_name})
		if os.exists(local_pkg_path) {os.exit(0)}

		registry_pkg_path := filepath.join({home, REGISTRY_DIR, pkg_name})
		if os.is_dir(registry_pkg_path) {
			copy_dir(registry_pkg_path, local_pkg_path)
			info(fmt.tprintf("Added package `%s`", pkg_name))
		} else {
			bail(Errno(os.make_directory(registry_pkg_path)))
		}
	case:
		fmt.println(USAGE)
		os.exit(1)
	}
}
