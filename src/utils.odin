package octo

import "base:runtime"
import "core:c"
import "core:c/libc"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "libs:ansi"
import "libs:cmd"
import "libs:failz"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else when ODIN_OS == .Linux {
	foreign import lib "system:c"
}
foreign lib {
	@(link_name = "setenv")
	_unix_setenv :: proc(key: cstring, value: cstring, overwrite: c.int) -> c.int ---
}

set_env :: proc(key, value: string) -> failz.Errno {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	key_cstring := strings.clone_to_cstring(key, context.temp_allocator)
	value_cstring := strings.clone_to_cstring(value, context.temp_allocator)
	res := _unix_setenv(key_cstring, value_cstring, 1)
	if res < 0 do return failz.Errno(os.get_last_error())
	return failz.Errno(os.ERROR_NONE)
}

info :: proc(msg: string) {fmt.println(failz.INFO, msg)}

debug :: proc(msg: string) {
	is_debug := os.get_env("OCTO_DEBUG") == "true"
	if is_debug do fmt.println(failz.DEBUG, msg)
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

make_ols_file :: proc(proj_path: string) {
	using failz

	ols_path := filepath.join({proj_path, OLS_FILE})
	if os.exists(ols_path) {
		warn(msg = fmt.tprintf("Config %s already exists", bold(OLS_FILE)))
	} else {
		write_to_file(ols_path, OLS_TEMPLATE)
	}
}

parse_dependency :: proc(uri: string) -> (string, string, string, bool) {
	uri := uri
	if strings.contains(uri, "://") {
		split_uri := strings.split(uri, "://")
		uri = split_uri[1]
	}
	parts := strings.split(uri, "/")
	if len(parts) == 1 {
		return "", "", parts[0], true
	}
	if len(parts) == 2 {
		return "", parts[1], parts[0], true
	}
	if len(parts) == 3 {
		return parts[2], parts[1], parts[0], true
	}
	return "", "", "", false
}

make_octo_file :: proc(proj_path: string, proj_name: string, uri := "") {
	using failz
	using strings

	octo_config_path := filepath.join({proj_path, OCTO_CONFIG_FILE})
	if os.exists(octo_config_path) {
		warn(msg = fmt.tprintf("Config %s already exists", bold(OCTO_CONFIG_FILE)))
	} else {
		user_email, ok := cmd.popen("git config --global user.email", read_size = 128)
		if ok {user_email = trim_space(user_email)}
		defer delete(user_email)

		user_name: string
		user_name, ok = cmd.popen("git config --global user.name", read_size = 128)
		if ok {user_name = trim_space(user_name)}
		defer delete(user_name)

		description: Builder
		prompt(&description, "Enter a description: ")
		defer builder_destroy(&description)

		git_server: Builder
		env_git_server: string
		found: bool
		defer builder_destroy(&git_server)
		env_git_server, found = os.lookup_env("OCTO_GIT_SERVER")
		if found {
			write_string(&git_server, env_git_server)
		} else {
			prompt(
				&git_server,
				fmt.tprintf(
					"Enter your git server: %s",
					ansi.colorize("(default: github)", {120, 120, 120}),
				),
				"github",
			)
			write_string(&git_server, ".com")
		}

		git_user: Builder
		env_git_user: string
		defer builder_destroy(&git_user)
		env_git_user, found = os.lookup_env("OCTO_GIT_USER")
		if found {
			write_string(&git_server, env_git_user)
		} else {
			prompt(&git_user, "Enter your git user: ")
		}

		owner := ok ? fmt.tprintf("%s<%s>", user_name, user_email) : ""
		write_to_file(
			octo_config_path,
			fmt.tprintf(
				OCTO_CONFIG_TEMPLATE,
				proj_name,
				owner,
				"0.1.0",
				to_string(description),
				to_string(git_server),
				to_string(git_user),
				proj_name,
			),
		)
	}
}

make_placeholder_octo_file :: proc(proj_path, server, owner, name: string) {
	using failz
	using strings

	octo_config_path := filepath.join({proj_path, OCTO_CONFIG_FILE})
	if os.exists(octo_config_path) {
		warn(msg = fmt.tprintf("Config %s already exists", bold(OCTO_CONFIG_FILE)))
	} else {
		write_to_file(
			octo_config_path,
			fmt.tprintf(OCTO_CONFIG_TEMPLATE, name, owner, "0.1.0", "", server, owner, name),
		)
	}
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

make_main_file :: proc(src_path: string, proj_name: string) {
	using failz
	main_path := filepath.join({src_path, MAIN_FILE})
	if os.exists(main_path) {
		warn(msg = fmt.tprintf("File %s already exists", bold(MAIN_FILE)))
	} else {
		write_to_file(main_path, fmt.tprintf(MAIN_TEMPLATE, proj_name))
	}
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
