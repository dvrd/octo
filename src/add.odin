package octo

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "libs:ansi"
import "libs:cmd"
import "libs:failz"

add_package :: proc() {
	using failz

	bail(len(os.args) < 3, ADD_USAGE)
	bail(os.args[2] == "help", ADD_USAGE)

	home, found := os.lookup_env("HOME")
	catch(!found, "HOME env variable not set")

	pwd := os.get_current_directory()
	pkg_config := get_config()

	new_pkg_server: string
	new_pkg_owner: string
	new_pkg_name: string

	new_pkg_info := strings.split(os.args[2], "/")

	if len(new_pkg_info) == 1 {
		new_pkg_name = new_pkg_info[0]
	} else if len(new_pkg_info) == 2 {
		new_pkg_owner = new_pkg_info[0]
		new_pkg_name = new_pkg_info[1]
	} else if len(new_pkg_info) == 3 {
		new_pkg_server = new_pkg_info[0]
		new_pkg_owner = new_pkg_info[1]
		new_pkg_name = new_pkg_info[2]
	}

	libs_path := filepath.join({pwd, "libs"})
	if !os.is_dir(libs_path) do catch(Errno(os.make_directory(libs_path)))

	local_pkg_path := filepath.join({libs_path, new_pkg_name})
	if os.is_dir(local_pkg_path) {
		info(
			"%s `%s` package already in libs folder",
			ansi.colorize("Found", {0, 210, 80}),
			new_pkg_name,
		)
		return
	}

	bail(
		contains_dependency(pkg_config, new_pkg_name),
		"%s `%s` package already in dependencies",
		ansi.colorize("Found", {0, 210, 80}),
		new_pkg_name,
	)

	registry_path := filepath.join({home, REGISTRY_DIR})
	if !os.is_dir(registry_path) do catch(Errno(os.make_directory(registry_path)))

	registry_pkg_path := filepath.join({registry_path, new_pkg_name})
	if os.is_dir(registry_pkg_path) {
		info(
			"%s `%s` package to dependencies",
			ansi.colorize("Adding", {0, 210, 80}),
			new_pkg_name,
		)
	} else {
		catch(
			len(new_pkg_info) == 1,
			fmt.tprintf("Package `%s` not found in %s", new_pkg_name, purple("registry")),
		)

		if len(new_pkg_info) == 2 do new_pkg_server = get_git_server()

		ok := cmd.launch(
			strings.split(
				fmt.tprintf(
					"git clone https://%s/%s/%s %s",
					new_pkg_server,
					new_pkg_owner,
					new_pkg_name,
					registry_pkg_path,
				),
				" ",
			),
		)
		catch(!ok, "Could not clone package")
	}

	update_dependencies(registry_pkg_path, local_pkg_path)
}

get_git_server :: proc() -> string {
	env_server, found := os.lookup_env("OCTO_GIT_SERVER")
	if found do return env_server
	debug("No git server specified (OCTO_GIT_SERVER is unset), using default (github.com)")
	return "github.com"
}

update_dependencies :: proc(registry_pkg_path, local_pkg_path: string) {
	_, err := copy_dir(
		registry_pkg_path,
		local_pkg_path,
		{"odin", "a", "lib", "o", "dll", "dynlib"},
	)
	catch(err)

	new_pkg_config: Package
	read_config(&new_pkg_config, registry_pkg_path)

	server, owner, name, success_parse := parse_dependency(new_pkg_config.url)
	catch(!success_parse, "Corrupt package uri")

	new_pkg_config_uri := filepath.join({server, owner, name})
	info("new dependency uri: %s", new_pkg_config_uri)
	pkg_config.dependencies[new_pkg_config_uri] = new_pkg_config.version
	info("Updating config file...")
	update_config(pkg_config)
}
