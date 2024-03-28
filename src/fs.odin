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

copy_file_with_mode :: proc(from, to: string, mode: os.File_Mode) -> failz.Error {
	file_handle, errno := os.open(to, os.O_CREATE | os.O_RDWR, int(mode))
	if errno != os.ERROR_NONE {
		return failz.Errno(errno)
	}
	file_contents, success := os.read_entire_file(from)
	if !success {
		return failz.SystemError{.FileIO, os.get_last_error_string()}
	}
	defer delete(file_contents)

	_, errno = os.write(file_handle, file_contents)
	if errno != os.ERROR_NONE {
		return failz.Errno(errno)
	}
	defer os.close(file_handle)

	return nil
}

copy_dir :: proc(from, to: string) -> failz.Error {
	using failz

	files, errno := read_dir(from)
	if errno != os.ERROR_NONE {
		return failz.Errno(errno)
	}

	if !os.is_dir(to) {
		os.make_directory(to)
	}

	for file in files {
		copy_to := filepath.join({to, file.name})
		defer delete(copy_to)

		if file.is_dir {
			copy_dir(file.fullpath, copy_to) or_return
		}

		copy_file_with_mode(from = file.fullpath, to = copy_to, mode = file.mode) or_return
	}

	return nil
}
