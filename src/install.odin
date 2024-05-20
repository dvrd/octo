package octo


import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "libs:ansi"
import "libs:cmd"
import "libs:failz"

install_package :: proc() {
	using failz

	pwd := os.get_current_directory()
	pkg := read_pkg()
	bail(pkg == nil, "No package config found (%s)", pwd)

	build_name := len(os.args) > 2 ? os.args[2] : "debug"
	bin_path := get_bin_path(pwd, build_name)
	if !os.exists(bin_path) do build_package(is_install = true)
	catch(!os.exists(bin_path), "Failed to build package")

	home_path := os.get_env("HOME")
	octo_registry_path := filepath.join({home_path, REGISTRY_DIR})
	if !os.is_dir(octo_registry_path) do catch(Errno(os.make_directory(octo_registry_path)))

	octo_bin_path := filepath.join({octo_registry_path, "bin"})
	if !os.is_dir(octo_bin_path) do catch(Errno(os.make_directory(octo_bin_path)))

	if len(os.args) == 3 do pkg.name = os.args[2]
	octo_bin_pkg_path := filepath.join({octo_bin_path, pkg.name})
	bail(os.is_dir(octo_bin_pkg_path), "Package %s is a directory", octo_bin_pkg_path)
	bail(os.exists(octo_bin_pkg_path), "Package %s is already installed", octo_bin_pkg_path)

	info(
		"%s `%s` release build [%s = %s]",
		ansi.colorize("Installing", {0, 210, 80}),
		pkg.name,
		ansi.colorize("target", {200, 150, 255}),
		octo_bin_path,
	)

	catch(!link(bin_path, octo_bin_pkg_path), "Failed to install binary to system")

	info("%s installation", ansi.colorize("Successful", {0, 210, 80}))
}
