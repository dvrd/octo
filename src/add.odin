package octo

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "libs:ansi"
import "libs:cmd"
import "libs:failz"

add_package :: proc() {
	using failz

	usage(len(os.args) < 3, ADD_USAGE)
	usage(os.args[2] == "help", ADD_USAGE)

	home, found := os.lookup_env("HOME")
	catch(!found, "HOME env variable not set")

	pwd := os.get_current_directory()
	pkg := get_pkg_from_args(os.args[2])

	libs_path := filepath.join({pwd, "libs"})
	if !os.is_dir(libs_path) do catch(Errno(os.make_directory(libs_path)))

	local_pkg_path := filepath.join({libs_path, pkg.name})
	bail(
		os.is_dir(local_pkg_path),
		"Found `%s` package already in libs folder",
		failz.purple(pkg.name),
	)

	registry_path := filepath.join({home, REGISTRY_DIR})
	if !os.is_dir(registry_path) do catch(Errno(os.make_directory(registry_path)))

	registry_pkg_path := filepath.join({registry_path, pkg.name})
	if !os.is_dir(registry_pkg_path) {
		repo_uri := fmt.tprintf("https://%s/%s/%s", pkg.host, pkg.owner, pkg.name)
		catch(
			!cmd.launch({"git", "clone", repo_uri, registry_pkg_path}),
			"Could not clone package",
		)
	}

	update_dependencies(pkg, registry_pkg_path, local_pkg_path)
}
