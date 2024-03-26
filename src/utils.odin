package octo

import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"
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
