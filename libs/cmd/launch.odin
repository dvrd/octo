package cmd

import "core:c"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "libs:failz"

StatusCode :: enum {
	Ok,
	Error,
	Usage,
}

launch :: proc(args: []string) -> bool {
	cmd: CmdRunner
	defer close(&cmd)

	if !init(&cmd, args) { return false }
	if !run(&cmd) { return false }
	return wait(&cmd)
}
