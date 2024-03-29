package command

import "core:fmt"
import "core:os"
import "core:strings"

find_program :: proc(target: string) -> (string, bool) #optional_ok {
	sb := strings.builder_make()
	env_path := os.get_env("PATH")
	dirs := strings.split(env_path, ":")

	if len(dirs) == 0 {
		fmt.eprintln(ERROR, "missing $PATH environment variable")
		return "", false
	}

	for dir in dirs {
		fd, err := os.open(dir)
		defer os.close(fd)

		if err != os.ERROR_NONE {
			continue
		}

		fis: []os.File_Info
		defer os.file_info_slice_delete(fis)

		fis, _ = os.read_dir(fd, -1)

		for fi in fis {
			if fi.name == target {
				strings.write_string(&sb, fi.fullpath)
				return strings.to_string(sb), true
			}
		}
	}

	return "", false
}
