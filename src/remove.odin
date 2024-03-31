package octo

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "libs:ansi"
import "libs:failz"

remove_package :: proc() {
	using failz

	if len(os.args) < 3 do fmt.println(REMOVE_USAGE)
	dep_name := os.args[2]
	if dep_name == "help" do fmt.println(REMOVE_USAGE)

	info("%s `%s` from dependencies", ansi.colorize("Removing", {0, 210, 80}), dep_name)

	pwd := os.get_current_directory()

	libs_path := filepath.join({pwd, "libs"})
	if !os.exists(libs_path) {
		info("%s dependencies library", ansi.colorize("Missing", {0, 210, 80}), dep_name)
		return
	}

	local_pkg_path := filepath.join({libs_path, dep_name})
	if !os.exists(local_pkg_path) {
		return
	}

	catch(remove_dir(local_pkg_path))

	pkg_config := get_config()
	for pkg_uri, version in pkg_config.dependencies {
		server, owner, name, success := parse_dependency(pkg_uri)
		catch(!success, "Corrupt package uri")
		if name == dep_name {
			delete_key(&pkg_config.dependencies, pkg_uri)
			break
		}
	}
	update_config(pkg_config)
}
