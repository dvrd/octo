package octo

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "libs:ansi"
import "libs:cmd"
import "libs:failz"

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

copy_file_with_mode :: proc(from, to: string, mode: os.File_Mode) -> failz.Error {
	file_handle, errno := os.open(to, os.O_CREATE | os.O_RDWR, int(mode))
	if errno != os.ERROR_NONE {
		return failz.SystemError{.FileOpen, os.get_last_error_string()}
	}
	defer os.close(file_handle)

	file_contents, success := os.read_entire_file(from)
	if !success {
		return failz.SystemError{.FileRead, os.get_last_error_string()}
	}
	defer delete(file_contents)

	_, errno = os.write(file_handle, file_contents)
	if errno != os.ERROR_NONE {
		return failz.SystemError{.FileOpen, os.get_last_error_string()}
	}

	return nil
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

copy_dir :: proc(from, to: string) -> failz.Error {
	using failz
	debug(fmt.tprint("Copying directory:", from, "to:", to))

	files, errno := read_dir(from)
	if errno != os.ERROR_NONE {
		return failz.SystemError{.DirectoryRead, os.get_last_error_string()}
	}

	if !os.is_dir(to) {
		errno = os.make_directory(to)
		if errno != os.ERROR_NONE {
			return failz.SystemError{.DirectoryCreate, os.get_last_error_string()}
		}
	}

	for file in files {
		copy_to := filepath.join({to, file.name})

		if file.is_dir {
			copy_dir(file.fullpath, copy_to) or_return
			continue
		}

		copy_file_with_mode(from = file.fullpath, to = copy_to, mode = file.mode) or_return
	}

	return nil
}

remove_dir :: proc(dir: string) -> failz.Error {
	using failz

	files, errno := read_dir(dir)
	if errno != os.ERROR_NONE {
		return failz.SystemError{.DirectoryRead, os.get_last_error_string()}
	}

	for file in files {
		if file.is_dir {
			remove_dir(file.fullpath) or_return
			continue
		}

		debug(fmt.tprint("Removing file:", file.fullpath))
		if os.remove(file.fullpath) != os.ERROR_NONE {
			return failz.SystemError{.FileRemove, os.get_last_error_string()}
		}
	}

	debug(fmt.tprint("Removing directory:", dir))
	if os.remove(dir) != os.ERROR_NONE {
		return failz.SystemError{.DirectoryRemove, os.get_last_error_string()}
	}

	return nil
}
