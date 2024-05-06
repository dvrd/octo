package octo

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "libs:ansi"
import "libs:cmd"
import "libs:failz"

update_package :: proc() {
	using failz

	usage(len(os.args) < 3, UPDATE_USAGE)

	home, found := os.lookup_env("HOME")
	catch(!found, "HOME env variable not set")

	pkg: Package
	pkg.name = os.args[2]
	registry_pkg_path := filepath.join({home, REGISTRY_DIR, pkg.name})
	bail(!os.exists(registry_pkg_path), "Package `%s` does not exist", pkg.name)

	pwd := os.get_current_directory()
	os.set_current_directory(registry_pkg_path)
	catch(!cmd.launch({"git", "pull", "-r"}), "Failed to update package")

	os.set_current_directory(pwd)

	libs_path := filepath.join({pwd, "libs"})
	if !os.is_dir(libs_path) do catch(Errno(os.make_directory(libs_path)))
	if strings.contains(pkg.name, ".ol") do pkg.name = strings.trim_right(pkg.name, ".ol")
	local_pkg_path := filepath.join({libs_path, pkg.name})
	pkg_src_path := filepath.join({registry_pkg_path, "src"})
	update_dependencies(&pkg, pkg_src_path, local_pkg_path)
}

update_dependencies :: proc(pkg: ^Package, pkg_src_path, local_pkg_path: string) {
	using failz

	info("%s `%s` package to dependencies", ansi.colorize("Adding", {0, 210, 80}), pkg.name)
	debug("Copying from %s to %s", pkg_src_path, local_pkg_path)
	_, err := copy_dir(
		from = pkg_src_path,
		to = local_pkg_path,
		allowed_filetypes = {"odin", "a", "lib", "o", "dll", "dynlib"},
	)
	catch(err)
}
