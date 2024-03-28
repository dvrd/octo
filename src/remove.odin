package octo

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "libs:ansi"
import "libs:failz"

remove_package :: proc() {
	using failz


	catch(len(os.args) < 3, REMOVE_USAGE)
	pkg_name := os.args[2]
	info(
		fmt.tprintf(
			"%s `%s` from dependencies",
			ansi.colorize("Removing", {0, 210, 80}),
			pkg_name,
		),
	)

	catch(pkg_name == "help", REMOVE_USAGE)
	pwd := os.get_current_directory()

	libs_path := filepath.join({pwd, "libs"})
	if !os.exists(libs_path) {
		info(
			fmt.tprintf(
				"%s dependencies library",
				ansi.colorize("Missing", {0, 210, 80}),
				pkg_name,
			),
		)
		return
	}

	local_pkg_path := filepath.join({libs_path, pkg_name})
	if !os.exists(local_pkg_path) {
		return
	}

	catch(remove_dir(local_pkg_path))
}
