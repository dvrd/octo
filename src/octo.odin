package octo

import "core:fmt"
import "core:io"
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
		pwd_info, err := os.stat(pwd)
		bail(Errno(err))

		target_path := strings.concatenate({pwd, "/target"})
		if os.exists(target_path) {bail(Errno(os.make_directory(target_path)))}

		debug_path := strings.concatenate({target_path, "/debug"})
		if os.exists(debug_path) {bail(Errno(os.make_directory(debug_path)))}

		bin_path := strings.concatenate({debug_path, "/", pwd_info.name})
		cmd.exec(fmt.tprintf("odin run src -collection:libs=libs -out:%s -debug", bin_path))
	case "build":
		pwd := os.get_current_directory()
		pwd_info, err := os.stat(pwd)
		bail(Errno(err))

		target_path := strings.concatenate({pwd, "/target"})
		if os.exists(target_path) {bail(Errno(os.make_directory(target_path)))}

		debug_path := strings.concatenate({target_path, "/debug"})
		if os.exists(debug_path) {bail(Errno(os.make_directory(debug_path)))}

		bin_path := strings.concatenate({debug_path, "/", pwd_info.name})
		cmd.exec(fmt.tprintf("odin build src -collection:libs=libs -out:%s -debug", bin_path))
	case "release":
		pwd := os.get_current_directory()
		pwd_info, err := os.stat(pwd)
		bail(Errno(err))

		target_path := strings.concatenate({pwd, "/target"})
		if os.exists(target_path) {bail(Errno(os.make_directory(target_path)))}

		release_path := strings.concatenate({target_path, "/release"})
		if os.exists(release_path) {bail(Errno(os.make_directory(release_path)))}

		bin_path := strings.concatenate({release_path, "/", pwd_info.name})
		cmd.exec(fmt.tprintf("odin build src -collection:libs=libs -out:%s -o:speed", bin_path))
	case:
		fmt.println(USAGE)
		os.exit(1)
	}
}

make_project_dir :: proc(proj_name: string) -> string {
	using failz

	pwd := os.get_current_directory()
	proj_path := strings.concatenate({pwd, "/", proj_name, "/"})
	if os.exists(proj_path) {
		warn(msg = fmt.tprintf("Directory %s already exists", bold(proj_name)))
	} else {
		bail(Errno(os.make_directory(proj_path)))
	}
	return proj_path
}

make_ols_file :: proc(proj_path: string) -> string {
	using failz

	ols_path := strings.concatenate({proj_path, OLS_FILE})
	if os.exists(ols_path) {
		warn(msg = fmt.tprintf("Config %s already exists", bold(OLS_FILE)))
	} else {
		write_to_file(ols_path, OLS_TEMPLATE)
	}

	return ols_path
}

make_src_dir :: proc(proj_path: string) -> string {
	using failz

	src_path := strings.concatenate({proj_path, "src/"})
	if os.exists(src_path) {
		warn(msg = fmt.tprintf("Directory %s already exists", bold("src")))
	} else {
		bail(Errno(os.make_directory(src_path)))
	}
	return src_path
}

make_main_file :: proc(src_path: string, proj_name: string) -> string {
	using failz
	main_path := strings.concatenate({src_path, MAIN_FILE})
	if os.exists(main_path) {
		warn(msg = fmt.tprintf("File %s already exists", bold(MAIN_FILE)))
	} else {
		write_to_file(main_path, fmt.tprintf(MAIN_TEMPLATE, proj_name))
	}
	return main_path
}

init_git :: proc() {
	using failz

	if os.exists(".git") {
		warn(msg = "Git repository already exists")
	}

	_, err := cmd.exec("git init", false, 0)
	bail(err, "Failed to initialize git repository")
	write_to_file(GITIGNORE_FILE, GITIGNORE_TEMPLATE)
}
