package command

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"

StatusCode :: enum {
	Ok,
	Error,
	Usage,
}

ERROR :: "\x1B[31m\x1b[0m"
WARNING :: " \x1B[38;2;255;210;0m\x1b[0m "

launch :: proc(args: []string) -> StatusCode {
	wpid: Pid
	status: u32

	cmd_path, ok := find_program(args[0])
	if !ok {
		fmt.eprintln(WARNING, "Command not found:", args[0])
		return .Error
	}

	pid, err := fork();if err != os.ERROR_NONE {
		fmt.eprintln(ERROR, "fork:", ERROR_MSG[err])
		return .Error
	}

	if (pid == 0) {
		err = exec(cmd_path, args[1:]);if err != os.ERROR_NONE {
			fmt.eprintfln("%v ERROR: [%s] %s", WARNING, args[0], ERROR_MSG[err])
			return .Error
		}
		fmt.eprintln(WARNING, "execve: NO ERRORS")
		os.exit(0)
	}

	wpid, _ = waitpid(pid, &status, {.WUNTRACED})

	return wpid == pid && WIFEXITED(status) ? .Ok : .Error
}
