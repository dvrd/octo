package octo

import "core:fmt"
import "core:os"
import "libs:ansi"
import "libs:cmd"
import "libs:failz"

run_package :: proc() {
	using failz

	pwd := os.get_current_directory()

	build_package()
	bin_path :=
		len(os.args) > 2 && os.args[2] == "--release" \
		? get_bin_path(pwd, "release") \
		: get_bin_path(pwd)

	info("%s `%s`", ansi.colorize("Running", {0, 210, 80}), bin_path)
	catch(!cmd.launch({bin_path}), "Failed to run the package")
}
