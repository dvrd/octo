package octo

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "libs:ansi"
import "libs:cmd"
import "libs:failz"

add_package :: proc() {
	using failz

	catch(len(os.args) < 3, ADD_USAGE)
	catch(strings.count(os.args[2], "/") == 1, ADD_USAGE)
	dep_owner, new_dep_name := filepath.split(os.args[2])
	catch(new_dep_name == "help", ADD_USAGE)
	home := os.get_env("HOME")
	pwd := os.get_current_directory()
	pkg_config := get_config()

	libs_path := filepath.join({pwd, "libs"})
	if !os.is_dir(libs_path) {
		catch(Errno(os.make_directory(libs_path)))
	}

	local_pkg_path := filepath.join({libs_path, new_dep_name})
	if os.is_dir(local_pkg_path) {
		info(
			fmt.tprintf(
				"%s `%s` package already in dependencies",
				ansi.colorize("Found", {0, 210, 80}),
				new_dep_name,
			),
		)
		return
	}

	for pkg_uri, version in pkg_config.dependencies {
		server, owner, name := parse_dependency(pkg_uri)
		if name == new_dep_name {
			info(
				fmt.tprintf(
					"%s `%s` package already in dependencies",
					ansi.colorize("Found", {0, 210, 80}),
					new_dep_name,
				),
			)
			return
		}
	}

	registry_path := filepath.join({home, REGISTRY_DIR})
	if !os.is_dir(registry_path) {
		catch(Errno(os.make_directory(registry_path)))
	}

	registry_pkg_path := filepath.join({registry_path, new_dep_name})
	if os.is_dir(registry_pkg_path) {
		info(
			fmt.tprintf(
				"%s `%s` package to dependencies",
				ansi.colorize("Adding", {0, 210, 80}),
				new_dep_name,
			),
		)
		copy_dir(registry_pkg_path, local_pkg_path)

		pkg_config.dependencies[filepath.join({"github.com", dep_owner, new_dep_name})] = "0.1.0"
		update_config(pkg_config)
	} else {
		warn(msg = fmt.tprintf("Package `%s` not found in %s", new_dep_name, purple("registry")))

		odin_bin_path := cmd.find_program("odin")
		odin_dir_path := odin_bin_path[:len(odin_bin_path) - len("/odin")]
		shared_pkg_path := filepath.join({odin_dir_path, "shared", new_dep_name})
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
					new_dep_name,
				),
			)
			catch(copy_dir(shared_pkg_path, registry_pkg_path))
			catch(copy_dir(shared_pkg_path, local_pkg_path))

			pkg_config.dependencies[filepath.join({"github.com", dep_owner, new_dep_name})] =
			"0.1.0"
			update_config(pkg_config)
		} else {
			warn(msg = fmt.tprintf("Package `%s` not found in %s", new_dep_name, purple("shared")))
		}
	}
}
