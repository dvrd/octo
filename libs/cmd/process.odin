package cmd

import "base:runtime"
import "core:c"
import "core:c/libc"
import "core:fmt"
import "core:os"
import "core:strings"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else when ODIN_OS == .Linux {
	foreign import lib "system:c"
}

foreign lib {
	@(link_name = "popen")
	_unix_popen :: proc(command: cstring, mode: cstring) -> ^libc.FILE ---
	@(link_name = "pclose")
	_unix_pclose :: proc(stream: ^libc.FILE) -> int ---
}

popen :: proc(cmd: string, get_response := true, read_size := 4096) -> (out: string, ok: bool) {
	cmd_cstr := strings.clone_to_cstring(cmd)
	defer delete(cmd_cstr)
	file := _unix_popen(cmd_cstr, cstring("r"))

	ok = file != nil

	if ok && get_response {
		data := make([]u8, read_size)
		cstr := libc.fgets(cast(^byte)&data[0], i32(read_size), file)
		out = strings.clone_from_cstring(cstring(cstr))
		ok = cstr != nil
	}
	_unix_pclose(file)

	return
}
