package cmd

import "core:c"
import "core:os"
import "libs:failz"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else when ODIN_OS == .Linux {
	foreign import lib "system:c"
}

foreign lib {
	@(link_name = "waitpid")
	_unix_waitpid :: proc(pid: pid_t, stat_loc: ^c.uint, options: c.uint) -> pid_t ---
}

waitpid :: proc "contextless" (
	pid: Pid,
	status: ^u32,
	options: Wait_Options,
) -> (
	Pid,
	failz.Errno,
) {
	ret := _unix_waitpid(cast(i32)pid, status, transmute(u32)options)
	return Pid(ret), failz.Errno(os.get_last_error())
}

