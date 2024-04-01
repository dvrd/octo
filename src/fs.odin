package octo

import "core:bytes"
import "core:c"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:slice"
import "core:strings"
import "libs:ansi"
import "libs:cmd"
import "libs:failz"

foreign import lib "system:System.framework"
foreign lib {
	@(link_name = "symlink")
	_unix_symlink :: proc(name1: [^]c.char, name2: [^]c.char) -> c.int ---
}

link :: proc(src, target: string) -> bool {
	using failz

	if os.is_dir(src) || os.is_dir(target) {
		debug("source or target is a directory")
		return false
	}

	debug("Linking %v to %v", src, target)
	src := transmute([]c.char)src
	target := transmute([]c.char)target

	if _unix_symlink(raw_data(src), raw_data(target)) == -1 {
		warn(Errno(os.get_last_error()), fmt.tprintf("symlink: (%s)", target))
		return false
	}

	return true
}

write_to_file :: proc(path: string, content: string) {
	using failz

	debug("Writing to file: %s", path)
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
	failz.Error,
) {
	f, errno := os.open(dir_name, os.O_RDONLY)
	if errno != os.ERROR_NONE {
		return nil, failz.SystemError{.DirectoryOpen, os.get_last_error_string()}
	}
	defer os.close(f)

	fis: []os.File_Info
	fis, errno = os.read_dir(f, -1, allocator)
	if errno != os.ERROR_NONE {
		return nil, failz.SystemError{.DirectoryRead, os.get_last_error_string()}
	}

	return fis, nil
}

FORBIDDEN_DIRS :: []string{".git", ".github", "examples", "build", "libs"}
copy_dir :: proc(
	from, to: string,
	allowed_filetypes: []string = {},
) -> (
	completed: bool,
	err: failz.Error,
) {
	using failz

	parent_dir, file_name := filepath.split(from)
	if slice.contains(FORBIDDEN_DIRS, file_name) {
		debug("Ignoring directory: %s", file_name)
		return false, nil
	}

	files := read_dir(from) or_return

	if !os.is_dir(to) {
		errno := os.make_directory(to)
		if errno != os.ERROR_NONE {
			return false, failz.SystemError{.DirectoryCreate, os.get_last_error_string()}
		}
	}

	children_copied := 0
	for file in files {
		copy_to := filepath.join({to, file.name})

		if file.is_dir {
			completed := copy_dir(file.fullpath, copy_to, allowed_filetypes) or_return
			if completed {children_copied += 1}
			continue
		}

		file_split := strings.split(file.name, ".")
		filetype := len(file_split) == 2 ? file_split[1] : "unknown"
		if len(allowed_filetypes) == 0 || slice.contains(allowed_filetypes, filetype) {
			copy_file_with_mode(from = file.fullpath, to = copy_to, mode = file.mode) or_return
			children_copied += 1
		} else {
			debug(
				"ignoring %s, [%s] files are not allowed",
				file.name,
				ansi.colorize(filetype, {255, 120, 120}),
			)
		}
	}

	if children_copied == 0 {
		debug("removing directory (%s) since it is empty", ansi.colorize(to, {255, 120, 120}))
		remove_dir(to)
		return false, nil
	}

	return true, nil
}

remove_dir :: proc(dir: string) -> failz.Error {
	using failz

	files := read_dir(dir) or_return

	for file in files {
		if file.is_dir {
			remove_dir(file.fullpath) or_return
			continue
		}

		debug("Removing file: %s", file.fullpath)
		if os.remove(file.fullpath) != os.ERROR_NONE {
			return failz.SystemError{.FileRemove, os.get_last_error_string()}
		}
	}

	debug("Removing directory: %s", dir)
	if os.remove(dir) != os.ERROR_NONE {
		return failz.SystemError{.DirectoryRemove, os.get_last_error_string()}
	}

	return nil
}
