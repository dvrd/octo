package octo

import "core:encoding/json"
import "core:fmt"
import "core:strings"
import "core:os"
import "core:path/filepath"
import "libs:failz"

Package :: struct {
	name:         string,
	url:          string,
	readme:       string,
	description:  string,
	version:      string,
	license:      string,
	root:         string,
	keywords:     [dynamic]string,
	dependencies: map[string]string,
}

get_config :: proc() -> ^Package {
	using failz

	pkg := new(Package)
	config_file, success := os.read_entire_file(OCTO_CONFIG_FILE)
	catch(!success, "Failed to read config file")

	err := json.unmarshal(config_file, pkg)
	catch(err != nil, "Failed to unmarshal config file")

	return pkg
}

update_config :: proc(pkg: ^Package) {
	using failz

	debug("Updating config\n%#v", pkg^)

	opts: json.Marshal_Options
	opts.pretty = true
	opts.use_spaces = true
	data, err := json.marshal(pkg^, opts)
	catch(err != nil, "Failed to parse package struct")

	os.write_entire_file(OCTO_CONFIG_FILE, data)
}

read_config :: proc(pkg: ^Package, pkg_path: string) {
	using failz

	config_path := filepath.join({pkg_path, OCTO_CONFIG_FILE})
	if !os.exists(config_path) {
		debug("Missing `octo` config in package")
		debug("Trying `opm` config")
		config_path = filepath.join({pkg_path, OPM_CONFIG_FILE})
	}
	if !os.exists(config_path) {
		debug("Missing `opm` config file in package")
		debug("Creating configuration for new package")
		make_octo_file(config_path, config_path)
	}

	config_raw_data, success := os.read_entire_file(config_path)
	catch(!success, "Could not read pkg config")

	catch(json.unmarshal(config_raw_data, pkg))
}

contains_dependency :: proc(pkg: ^Package, target: string) -> bool {
	_, found := find_dependency(pkg, target)
	return found
}

find_dependency :: proc(pkg: ^Package, target: string) -> (string, bool) {
	using failz

	for dep_name, dep_version in pkg.dependencies {
		server, owner, name, success := parse_dependency(pkg.url)
		catch(!success, "Corrupt package uri")
		if dep_name == target {
			return dep_version, true
		}
	}
	return "", false
}

get_pkg_info_from_args :: proc(server, owner, name: ^string) -> (pkg_info: []string) {
	pkg_info = strings.split(os.args[2], "/")

	switch len(pkg_info) {
	case 1:
		name^ = pkg_info[0]
	case 2:
		owner^ = pkg_info[0]
		name^ = pkg_info[1]
	case 3:
		server^ = pkg_info[0]
		owner^ = pkg_info[1]
		name^ = pkg_info[2]
	}

	return
}
