package octo

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "libs:ansi"
import "libs:cmd"
import "libs:failz"

@(init)
add_package :: proc() {
	using failz

	catch(len(os.args) < 3, ADD_USAGE)
	pkg_name := os.args[2]
	catch(pkg_name == "help", ADD_USAGE)
	home := os.get_env("HOME")
	pwd := os.get_current_directory()

	libs_path := filepath.join({pwd, "libs"})
	if !os.is_dir(libs_path) {
		catch(Errno(os.make_directory(libs_path)))
	}

	local_pkg_path := filepath.join({libs_path, pkg_name})
	if os.is_dir(local_pkg_path) {
		fmt.println(
			fmt.tprintf(
				"%s `%s` package to dependencies",
				ansi.colorize("Adding", {0, 210, 80}),
				pkg_name,
			),
		)
		os.exit(0)
	}

	registry_path := filepath.join({home, REGISTRY_DIR})
	if !os.is_dir(registry_path) {
		catch(Errno(os.make_directory(registry_path)))
	}

	pkg_path := filepath.join({registry_path, pkg_name})
	if os.is_dir(pkg_path) {
		info(
			fmt.tprintf(
				"%s `%s` package to dependencies",
				ansi.colorize("Adding", {0, 210, 80}),
				pkg_name,
			),
		)
		copy_dir(pkg_path, local_pkg_path)
	} else {
		warn(msg = fmt.tprintf("Package `%s` not found in registry", pkg_name))

		odin_bin_path := cmd.find_program("odin")
		odin_dir_path := odin_bin_path[:len(odin_bin_path) - len("/odin")]
		shared_pkg_path := filepath.join({odin_dir_path, "shared", pkg_name})
		info(
			fmt.tprintf(
				"%s package in `%s`",
				ansi.colorize("Searching", {0, 210, 80}),
				shared_pkg_path,
			),
		)
		if os.is_dir(shared_pkg_path) {
			info(
				fmt.tprintf(
					"%s `%s` package to dependencies",
					ansi.colorize("Adding", {0, 210, 80}),
					pkg_name,
				),
			)
			copy_dir(shared_pkg_path, local_pkg_path)
		} else {
			warn(msg = fmt.tprintf("Package `%s` not found in shared", pkg_name))
		}
	}

}
