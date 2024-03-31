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

	usage(len(os.args) < 3, ADD_USAGE)
	usage(os.args[2] == "help", ADD_USAGE)

	home, found := os.lookup_env("HOME")
	catch(!found, "HOME env variable not set")

	pwd := os.get_current_directory()

	new_pkg_server: string
	new_pkg_owner: string
	new_pkg_name: string
	new_pkg_info := get_pkg_info_from_args(&new_pkg_server, &new_pkg_owner, &new_pkg_name)

	libs_path := filepath.join({pwd, "libs"})
	if !os.is_dir(libs_path) do catch(Errno(os.make_directory(libs_path)))

	local_pkg_path := filepath.join({libs_path, new_pkg_name})
	bail(
		os.is_dir(local_pkg_path),
		"Found `%s` package already in libs folder",
		failz.purple(new_pkg_name),
	)

	pkg_config := get_config()
	bail(
		contains_dependency(pkg_config, new_pkg_name),
		"Found `%s` package already in dependencies",
		failz.purple(new_pkg_name),
	)

	registry_path := filepath.join({home, REGISTRY_DIR})
	if !os.is_dir(registry_path) do catch(Errno(os.make_directory(registry_path)))

	registry_pkg_path := filepath.join({registry_path, new_pkg_name})
	if !os.is_dir(registry_pkg_path) {
		catch(
			len(new_pkg_info) == 1,
			fmt.tprintf("Package `%s` not found in %s", new_pkg_name, purple("registry")),
		)

		if len(new_pkg_info) == 2 do new_pkg_server = get_git_server()

		repo_uri := fmt.tprintf("https://%s/%s/%s", new_pkg_server, new_pkg_owner, new_pkg_name)
		clone_cmd: []string = {"git", "clone", repo_uri, registry_pkg_path}
		ok := cmd.launch(clone_cmd)
		catch(!ok, "Could not clone package")
	}

	update_dependencies(new_pkg_name, registry_pkg_path, local_pkg_path)
}

get_git_server :: proc() -> string {
	env_server, found := os.lookup_env("OCTO_GIT_SERVER")
	if found do return env_server
	debug("No git server specified (OCTO_GIT_SERVER is unset), using default (github.com)")
	return "github.com"
}

update_dependencies :: proc(new_pkg_name, registry_pkg_path, local_pkg_path: string) {
	using failz

	registry_pkg_path := registry_pkg_path

	info("%s package configuration...", ansi.colorize("Reading", {0, 210, 80}))
	new_pkg_config: Package
	read_config(&new_pkg_config, registry_pkg_path)
	info("%s root folder for package...", ansi.colorize("Searching", {0, 210, 80}))
	if new_pkg_config.root != "" {
		registry_pkg_path = filepath.join({registry_pkg_path, new_pkg_config.root})
	} else {
		new_pkg_root: strings.Builder
		prompt(sb = &new_pkg_root, msg = "Enter the root folder of the package:", default = "src")
		registry_pkg_path = filepath.join({registry_pkg_path, strings.to_string(new_pkg_root)})
	}

	info("%s `%s` package to dependencies", ansi.colorize("Adding", {0, 210, 80}), new_pkg_name)
	_, err := copy_dir(
		from = registry_pkg_path,
		to = local_pkg_path,
		allowed_filetypes = {"odin", "a", "lib", "o", "dll", "dynlib"},
	)
	catch(err)

	server, owner, name, success_parse := parse_dependency(new_pkg_config.url)
	catch(!success_parse, "Corrupt package uri")

	new_pkg_config_uri := filepath.join({server, owner, name})

	pkg_config := get_config()
	pkg_config.dependencies[new_pkg_config_uri] = new_pkg_config.version
	update_config(pkg_config)
}
