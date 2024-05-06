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

usage :: proc(condition: bool, msg: string, args: ..any) {
	if condition {
		fmt.printfln(msg, ..args)
		os.exit(1)
	}
}

info :: proc(msg: string, args: ..any) {
	fmt.println(failz.INFO, fmt.tprintf(msg, ..args))
}

debug :: proc(msg: string, args: ..any) {
	is_debug := os.get_env("OCTO_DEBUG") == "true"
	if is_debug do fmt.println(failz.DEBUG, fmt.tprintf(msg, ..args))
}

prompt :: proc(sb: ^strings.Builder, msg: string, default := "") {
	fmt.printf("%s %s %s", failz.PROMPT, msg, ansi.colorize(default, {255, 210, 210}))
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

make_octo_file :: proc(proj_path: string) {
	using failz

	octo_pkg_path := filepath.join({proj_path, OCTO_PKG_FILE})
	if os.exists(octo_pkg_path) {
		warn(msg = fmt.tprintf("Config %s already exists", bold(OLS_FILE)))
	} else {
		pkg_name := filepath.base(proj_path)
		pkg := get_pkg_from_args(pkg_name)
		contents := fmt.tprintf(OCTO_PKG_TEMPLATE, pkg.name, pkg.host, pkg.owner)
		write_to_file(octo_pkg_path, contents)
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
		contents := fmt.tprintf(MAIN_TEMPLATE, strings.to_snake_case(proj_name))
		write_to_file(main_path, contents)
	}
}

init_git :: proc() {
	using failz

	if os.exists(".git") {
		warn(msg = "Git repository already exists")
		return
	}

	catch(Errno(os.make_directory(".git")))
	catch(Errno(os.make_directory(".git/objects")))
	catch(Errno(os.make_directory(".git/refs")))
	write_to_file(".git/HEAD", "ref: refs/heads/main\n")
	info("Initialized git directory")
	write_to_file(GITIGNORE_FILE, GITIGNORE_TEMPLATE)
}
