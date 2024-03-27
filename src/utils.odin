package octo

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "libs:ansi"
import cmd "libs:command"
import "libs:failz"

info :: proc(msg: string) {fmt.println(failz.INFO, msg)}

write_to_file :: proc(path: string, content: string) {
	using failz

	fd, err := os.open(
		path,
		os.O_WRONLY | os.O_CREATE,
		os.S_IRUSR | os.S_IWUSR | os.S_IRGRP | os.S_IROTH,
	)
	catch(Errno(err))

	defer os.close(fd)

	_, err = os.write_string(fd, content)
	catch(Errno(err))
}

read_dir :: proc(
	dir_name: string,
	allocator := context.temp_allocator,
) -> (
	[]os.File_Info,
	os.Errno,
) {
	f, err := os.open(dir_name, os.O_RDONLY)
	if err != 0 do return nil, err

	fis: []os.File_Info
	fis, err = os.read_dir(f, -1, allocator)
	os.close(f)

	if err != 0 do return nil, err
	return fis, 0
}

copy_file_with_mode :: proc(from, to: string, mode: os.File_Mode) {
	file_handle, error := os.open(to, os.O_CREATE | os.O_RDWR, int(mode))
	file_contents, success := os.read_entire_file(from)
	defer delete(file_contents)

	os.write(file_handle, file_contents)
	defer os.close(file_handle)
}

copy_dir :: proc(from, to: string) {
	using failz

	files, error := read_dir(from)
	catch(Errno(error))

	if !os.is_dir(to) {
		when ODIN_OS == .Windows {
			os.make_directory(to, {})
		} else when ODIN_OS == .Linux || ODIN_OS == .Darwin {
			os.make_directory(to)
		}
	}

	for file in files {
		copy_to := filepath.join({to, file.name})
		defer delete(copy_to)

		if file.is_dir {
			copy_dir(file.fullpath, copy_to)
		}

		copy_file_with_mode(from = file.fullpath, to = copy_to, mode = file.mode)
	}
}

bold :: proc(str: string) -> string {
	return strings.concatenate({ansi.BOLD, str, ansi.END})
}

get_bin_path :: proc(pwd: string, build_path := "/debug") -> string {
	using failz

	pwd_info, err := os.stat(pwd)
	catch(Errno(err))

	target_path := filepath.join({pwd, "/target"})
	if !os.exists(target_path) {catch(Errno(os.make_directory(target_path)))}

	build_path := filepath.join({target_path, build_path})
	if !os.exists(build_path) {catch(Errno(os.make_directory(build_path)))}

	return filepath.join({build_path, "/", pwd_info.name})
}

make_project_dir :: proc(proj_name: string) -> string {
	using failz

	pwd := os.get_current_directory()
	proj_path := filepath.join({pwd, "/", proj_name})
	if os.exists(proj_path) {
		warn(msg = fmt.tprintf("Directory %s already exists", bold(proj_name)))
	} else {
		catch(Errno(os.make_directory(proj_path)))
	}
	return proj_path
}

make_ols_file :: proc(proj_path: string) -> string {
	using failz

	ols_path := filepath.join({proj_path, "/", OLS_FILE})
	if os.exists(ols_path) {
		warn(msg = fmt.tprintf("Config %s already exists", bold(OLS_FILE)))
	} else {
		write_to_file(ols_path, OLS_TEMPLATE)
	}

	return ols_path
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
	main_path := filepath.join({src_path, "/", MAIN_FILE})
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
