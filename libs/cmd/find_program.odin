package cmd

import "core:fmt"
import "core:os"
import "core:strings"
import "libs:failz"

find_program :: proc(target: string) -> (string, bool) #optional_ok {
	using failz

	sb := strings.builder_make()
	env_path := os.get_env("PATH")
	dirs := strings.split(env_path, ":")

	if len(dirs) == 0 {
		warn(msg = "missing $PATH environment variable")
		return "", false
	}

	for dir in dirs {
		if !os.is_dir(dir) || strings.contains(dir, "sbin") do continue

		fd, err := os.open(dir)
		defer os.close(fd)

		if err != os.ERROR_NONE {
			warn(Errno(err), fmt.tprintf("found issue opening directory (%s): ", dir))
			continue
		}

		fis: []os.File_Info
		defer os.file_info_slice_delete(fis)

		fis, err = os.read_dir(fd, -1)
		if err != os.ERROR_NONE {
			warn(Errno(err), fmt.tprintf("found issue reading directory (%s): ", dir))
			continue
		}

		for fi in fis {
			if fi.name == target {
				strings.write_string(&sb, fi.fullpath)
				return strings.to_string(sb), true
			}
		}
	}

	return "", false
}
