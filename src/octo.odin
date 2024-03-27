package octo

import "core:fmt"
import "core:io"
import "core:mem"
import "core:os"
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
		has_dependencies := os.exists(strings.concatenate({pwd, "/libs"}))
		collections := has_dependencies ? "-collection:libs=libs" : ""
		bin_path := get_bin_path(pwd)
		cmd.launch({"odin", "run", "src", collections, fmt.tprintf("-out:%s", bin_path), "-debug"})
	case "build":
		pwd := os.get_current_directory()
		has_dependencies := os.exists(strings.concatenate({pwd, "/libs"}))
		collections := has_dependencies ? "-collection:libs=libs" : ""
		bin_path := get_bin_path(pwd)
		cmd.launch(
			{"odin", "build", "src", collections, fmt.tprintf("-out:%s", bin_path), "-debug"},
		)
	case "release":
		pwd := os.get_current_directory()
		has_dependencies := os.exists(strings.concatenate({pwd, "/libs"}))
		collections := has_dependencies ? "-collection:libs=libs" : ""
		bin_path := get_bin_path(pwd, "/release")
		cmd.launch(
			{"odin", "build", "src", collections, fmt.tprintf("-out:%s", bin_path), "-o:speed"},
		)
	case "install":
		pwd := os.get_current_directory()
		bin_path := get_bin_path(pwd, "/release")
		cmd.launch({"sudo", "ln", "-s", bin_path, "/usr/local/bin"})
	case:
		fmt.println(USAGE)
		os.exit(1)
	}
}
