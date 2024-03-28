package octo

import "core:c/libc"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "libs:ansi"
import "libs:cmd"
import "libs:failz"

info :: proc(msg: string) {fmt.println(failz.INFO, msg)}

debug :: proc(msg: string) {
	when ODIN_DEBUG {
		fmt.println(failz.DEBUG, msg)
	}
}

prompt :: proc(sb: ^strings.Builder, msg: string, default := "") {
	fmt.printf("%s %s", failz.PROMPT, msg)
	for c := libc.getchar(); c != '\n'; c = libc.getchar() {
		strings.write_rune(sb, rune(c))
	}
	if strings.builder_len(sb^) == 0 {
		strings.write_string(sb, default)
	}
}

bold :: proc(str: string) -> string {
	return strings.concatenate({ansi.BOLD, str, ansi.END})
}

get_bin_path :: proc(pwd: string, build_path := "debug") -> string {
	using failz

	pwd_info, err := os.stat(pwd)
	catch(Errno(err))

	target_path := filepath.join({pwd, "target"})
	if !os.exists(target_path) {catch(Errno(os.make_directory(target_path)))}

	build_path := filepath.join({target_path, build_path})
	if !os.exists(build_path) {catch(Errno(os.make_directory(build_path)))}

	return filepath.join({build_path, pwd_info.name})
}

make_project_dir :: proc(proj_name: string) -> string {
	using failz

	pwd := os.get_current_directory()
	proj_path := filepath.join({pwd, proj_name})
	if os.exists(proj_path) {
		warn(msg = fmt.tprintf("Directory %s already exists", bold(proj_name)))
	} else {
		catch(Errno(os.make_directory(proj_path)))
	}
	return proj_path
}

make_ols_file :: proc(proj_path: string) -> string {
	using failz

	ols_path := filepath.join({proj_path, OLS_FILE})
	if os.exists(ols_path) {
		warn(msg = fmt.tprintf("Config %s already exists", bold(OLS_FILE)))
	} else {
		write_to_file(ols_path, OLS_TEMPLATE)
	}

	return ols_path
}

parse_dependency :: proc(uri: string) -> (string, string, string) {
	git_info, name := filepath.split(uri)
	server, owner := filepath.split(git_info)
	return server, owner, name
}

make_octo_file :: proc(proj_path: string, proj_name: string) -> string {
	using failz

	octo_config_path := filepath.join({proj_path, OCTO_CONFIG_FILE})
	if os.exists(octo_config_path) {
		warn(msg = fmt.tprintf("Config %s already exists", bold(OCTO_CONFIG_FILE)))
	} else {
		user_email, ok := cmd.popen("git config --global user.email", read_size = 128)
		if ok {user_email = strings.trim_space(user_email)}

		user_name: string
		user_name, ok = cmd.popen("git config --global user.name", read_size = 128)
		if ok {user_name = strings.trim_space(user_name)}

		description: strings.Builder
		prompt(&description, "Enter a description: ")

		git_server: strings.Builder
		prompt(
			&git_server,
			fmt.tprintf(
				"Enter your git server: %s",
				ansi.colorize("(default: github)", {120, 120, 120}),
			),
			"github.com",
		)

		git_user: strings.Builder
		prompt(&git_user, "Enter your git user: ")

		owner := ok ? fmt.tprintf("%s<%s>", user_name, user_email) : ""
		write_to_file(
			octo_config_path,
			fmt.tprintf(
				OCTO_CONFIG_TEMPLATE,
				proj_name,
				owner,
				"0.1.0",
				strings.to_string(description),
				strings.to_string(git_server),
				strings.to_string(git_user),
				proj_name,
			),
		)
	}

	return octo_config_path
}

make_src_dir :: proc(proj_path: string) -> string {
	using failz

	src_path := filepath.join({proj_path, "/src"})
	if os.exists(src_path) {
		warn(msg = fmt.tprintf("Directory %s already exists", bold("src")))
	} else {
		catch(Errno(os.make_directory(src_path)))
	}
	return src_path
}

make_main_file :: proc(src_path: string, proj_name: string) -> string {
	using failz
	main_path := filepath.join({src_path, MAIN_FILE})
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
	catch(err && !os.exists(".git"), "Failed to initialize git repository")
	write_to_file(GITIGNORE_FILE, GITIGNORE_TEMPLATE)
}
