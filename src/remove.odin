package octo

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "libs:ansi"
import "libs:failz"

remove_package :: proc() {
	using failz

	bail(len(os.args) < 3, REMOVE_USAGE)
	pkg_config := get_config()
	dep_owner, dep_name := filepath.split(os.args[2])
	info(
		fmt.tprintf(
			"%s `%s` from dependencies",
			ansi.colorize("Removing", {0, 210, 80}),
			dep_name,
		),
	)

	bail(dep_name == "help", REMOVE_USAGE)
	pwd := os.get_current_directory()

	libs_path := filepath.join({pwd, "libs"})
	if !os.exists(libs_path) {
		info(
			fmt.tprintf(
				"%s dependencies library",
				ansi.colorize("Missing", {0, 210, 80}),
				dep_name,
			),
		)
		return
	}

	local_pkg_path := filepath.join({libs_path, dep_name})
	if !os.exists(local_pkg_path) {
		return
	}

	catch(remove_dir(local_pkg_path))

	for pkg_uri, version in pkg_config.dependencies {
		server, owner, name := parse_dependency(pkg_uri)
		if name == dep_name {
			delete_key(&pkg_config.dependencies, pkg_uri)
			break
		}
	}
	update_config(pkg_config)
}
