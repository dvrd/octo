package octo

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "libs:ansi"
import "libs:failz"

remove_package :: proc() {
	using failz

	usage(len(os.args) < 3, REMOVE_USAGE)
	usage(os.args[2] == "help", REMOVE_USAGE)

	dep_name := os.args[2]
	info("%s `%s` from dependencies", ansi.colorize("Removing", {0, 210, 80}), dep_name)

	pwd := os.get_current_directory()
	libs_path := filepath.join({pwd, "libs"})
	bail(!os.exists(libs_path), "%s dependency library", ansi.colorize("Missing", {0, 210, 80}))

	local_pkg_path := filepath.join({libs_path, dep_name})
	if !os.exists(local_pkg_path) do return

	catch(remove_dir(local_pkg_path))
}
