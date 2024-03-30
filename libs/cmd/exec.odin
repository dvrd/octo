package cmd

import "base:runtime"
import "core:os"
import "core:strings"
import "core:testing"
import "libs:failz"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else when ODIN_OS == .Linux {
	foreign import lib "system:c"
}

foreign lib {
	@(link_name = "execve")
	_unix_execve :: proc(path: cstring, argv: [^]cstring, envp: [^]cstring) -> int ---
}

exec :: proc(path: string, args: []string = {}) -> failz.Errno {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)

	args_cstrs := make([^]cstring, len(args) + 2, context.temp_allocator)
	args_cstrs[0] = strings.clone_to_cstring(path, context.temp_allocator)
	for i := 0; i < len(args); i += 1 {
		args_cstrs[i + 1] = strings.clone_to_cstring(args[i], context.temp_allocator)
	}

	#no_bounds_check env: [^]cstring = &runtime.args__[len(runtime.args__) + 1]

	_unix_execve(path_cstr, args_cstrs, env)

	return failz.Errno(os.get_last_error())
}
