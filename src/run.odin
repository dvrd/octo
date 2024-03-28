package octo

import "core:fmt"
import "core:os"
import "libs:ansi"
import "libs:cmd"

run_package :: proc() {
	pwd := os.get_current_directory()
	build_package()
	bin_path :=
		len(os.args) > 2 && os.args[2] == "--release" \
		? get_bin_path(pwd, "release") \
		: get_bin_path(pwd)
	info(fmt.tprintf("%s `%s`", ansi.colorize("Running", {0, 210, 80}), bin_path))
	cmd.launch({bin_path})
}
