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
	if !os.is_dir(libs_path) {
		catch(Errno(os.make_directory(libs_path)))
	}

	local_pkg_path := filepath.join({libs_path, new_pkg_name})
	if os.is_dir(local_pkg_path) {
		info(
			fmt.tprintf(
				"%s `%s` package already in libs folder",
				ansi.colorize("Found", {0, 210, 80}),
				new_pkg_name,
			),
		)
		return
	}

	for pkg_uri, version in pkg_config.dependencies {
		server, owner, name, success := parse_dependency(pkg_uri)
		catch(!success, "Corrupt package uri")
		if name == new_pkg_name {
			info(
				fmt.tprintf(
					"%s `%s` package already in dependencies",
					ansi.colorize("Found", {0, 210, 80}),
					new_pkg_name,
				),
			)
			return
		}
	}

	registry_path := filepath.join({home, REGISTRY_DIR})
	if !os.is_dir(registry_path) {
		catch(Errno(os.make_directory(registry_path)))
	}

	registry_pkg_path := filepath.join({registry_path, new_pkg_name})
	if os.is_dir(registry_pkg_path) {
		info(
			fmt.tprintf(
				"%s `%s` package to dependencies",
				ansi.colorize("Adding", {0, 210, 80}),
				new_pkg_name,
			),
		)

		_, err := copy_dir(
			registry_pkg_path,
			local_pkg_path,
			{"odin", "a", "lib", "o", "dll", "dynlib"},
		)
		catch(err)

		registry_pkg_config_path := filepath.join({registry_pkg_path, OCTO_CONFIG_FILE})
		if !os.exists(registry_pkg_config_path) {
			registry_pkg_config_path = filepath.join({registry_pkg_path, OPM_CONFIG_FILE})
		}
		if !os.exists(registry_pkg_config_path) {
			debug("Missing config file in new package")
			debug("Creating configuration for new package")
			make_octo_file(registry_pkg_path, new_pkg_name)
		}

		new_pkg_config_raw_data, success_read_file := os.read_entire_file(registry_pkg_config_path)
		catch(!success_read_file, "Could not open pkg registry config")

		new_pkg_config: Package
		catch(json.unmarshal(new_pkg_config_raw_data, &new_pkg_config))

		server, owner, name, success_parse := parse_dependency(new_pkg_config.url)
		catch(!success_parse, "Corrupt package uri")

		new_pkg_config_uri := filepath.join({server, owner, name})
		info(fmt.tprint("new dependency uri:", new_pkg_config_uri))
		pkg_config.dependencies[new_pkg_config_uri] = new_pkg_config.version
		info("Updating config file...")
		update_config(pkg_config)
	} else {
		catch(
			len(new_pkg_info) == 1,
			fmt.tprintf("Package `%s` not found in %s", new_pkg_name, purple("registry")),
		)

		if len(new_pkg_info) == 2 {
			env_server, found := os.lookup_env("OCTO_GIT_SERVER")
			if found {
				new_pkg_server = env_server
			} else {
				debug(
					"No git server specified (OCTO_GIT_SERVER is unset), using default (github.com)",
				)
				new_pkg_server = "github.com"
			}
		}

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
		_, err := copy_dir(
			registry_pkg_path,
			local_pkg_path,
			{"odin", "a", "lib", "o", "dll", "dynlib"},
		)
		catch(err)

		registry_pkg_config_path := filepath.join({registry_pkg_path, OCTO_CONFIG_FILE})
		if !os.exists(registry_pkg_config_path) {
			registry_pkg_config_path = filepath.join({registry_pkg_path, OPM_CONFIG_FILE})
		}
		if !os.exists(registry_pkg_config_path) {
			debug("Missing config file in new package")
			debug("Creating configuration for new package")
			make_placeholder_octo_file(
				registry_pkg_path,
				new_pkg_server,
				new_pkg_owner,
				new_pkg_name,
			)
		}

		new_pkg_config_raw_data, success := os.read_entire_file(registry_pkg_config_path)
		catch(!success, "Could not open pkg registry config")
		new_pkg_config: Package
		catch(json.unmarshal(new_pkg_config_raw_data, &new_pkg_config))

		new_pkg_config_uri := filepath.join({new_pkg_server, new_pkg_owner, new_pkg_name})
		pkg_config.dependencies[new_pkg_config_uri] = new_pkg_config.version
		update_config(pkg_config)
	}
}
