package command

import "base:runtime"
import "core:c"
import "core:os"
import "core:strings"
foreign import libc "system:System.framework"

foreign libc {
	@(link_name = "readlink")
	_unix_readlink :: proc(path: cstring, buf: ^byte, bufsiz: c.size_t) -> c.ssize_t ---
}

readlink :: proc(path: string) -> (string, os.Errno) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == context.allocator)
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)

	bufsz: uint = 256
	buf := make([]byte, bufsz)
	for {
		rc := _unix_readlink(path_cstr, &(buf[0]), bufsz)
		if rc == -1 {
			delete(buf)
			return "", os.Errno(os.get_last_error())
		} else if rc == int(bufsz) {
			// NOTE(laleksic, 2021-01-21): Any cleaner way to resize the slice?
			bufsz *= 2
			delete(buf)
			buf = make([]byte, bufsz)
		} else {
			return strings.string_from_ptr(&buf[0], rc), os.ERROR_NONE
		}
	}
}
