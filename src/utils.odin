package octo

import "core:fmt"
import "core:os"
import "core:strings"
import cmd "libs:command"
import "libs:failz"

INFO :: " \x1B[34m\x1B[0m "
END :: "\x1b[0m"
BOLD :: "\x1b[1m"

info :: proc(msg: string) {fmt.println(INFO, msg)}

write_to_file :: proc(path: string, content: string) {
	using failz

	fd, err := os.open(
		path,
		os.O_WRONLY | os.O_CREATE,
		os.S_IRUSR | os.S_IWUSR | os.S_IRGRP | os.S_IROTH,
	)
	bail(Errno(err))

	defer os.close(fd)

	_, err = os.write_string(fd, content)
	bail(Errno(err))
}

bold :: proc(str: string) -> string {
	return strings.concatenate({BOLD, str, END})
}

get_bin_path :: proc(pwd: string, build_path := "/debug") -> string {
	using failz

	pwd_info, err := os.stat(pwd)
	bail(Errno(err))

	target_path := strings.concatenate({pwd, "/target"})
	if os.exists(target_path) {bail(Errno(os.make_directory(target_path)))}

	build_path := strings.concatenate({target_path, build_path})
	if os.exists(build_path) {bail(Errno(os.make_directory(build_path)))}

	return strings.concatenate({build_path, "/", pwd_info.name})
}

make_project_dir :: proc(proj_name: string) -> string {
	using failz

	pwd := os.get_current_directory()
	proj_path := strings.concatenate({pwd, "/", proj_name})
	if os.exists(proj_path) {
		warn(msg = fmt.tprintf("Directory %s already exists", bold(proj_name)))
	} else {
		bail(Errno(os.make_directory(proj_path)))
	}
	return proj_path
}

make_ols_file :: proc(proj_path: string) -> string {
	using failz

	ols_path := strings.concatenate({proj_path, "/", OLS_FILE})
	if os.exists(ols_path) {
		warn(msg = fmt.tprintf("Config %s already exists", bold(OLS_FILE)))
	} else {
		write_to_file(ols_path, OLS_TEMPLATE)
	}

	return ols_path
}

make_src_dir :: proc(proj_path: string) -> string {
	using failz

	src_path := strings.concatenate({proj_path, "/src"})
	if os.exists(src_path) {
		warn(msg = fmt.tprintf("Directory %s already exists", bold("src")))
	} else {
		bail(Errno(os.make_directory(src_path)))
	}
	return src_path
}

make_main_file :: proc(src_path: string, proj_name: string) -> string {
	using failz
	main_path := strings.concatenate({src_path, "/", MAIN_FILE})
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
		return
	}

	_, err := cmd.popen("git init", false, 0)
	bail(err && !os.exists(".git"), "Failed to initialize git repository")
	write_to_file(GITIGNORE_FILE, GITIGNORE_TEMPLATE)
}
