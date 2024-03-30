package octo

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "libs:failz"

Package :: struct {
	name:         string,
	url:          string,
	readme:       string,
	description:  string,
	version:      string,
	license:      string,
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

	debug(fmt.tprintf("Updating config\n%#v", pkg^))

	opts: json.Marshal_Options
	opts.pretty = true
	opts.use_spaces = true
	data, err := json.marshal(pkg^, opts)
	catch(err != nil, "Failed to parse package struct")

	os.write_entire_file(OCTO_CONFIG_FILE, data)
}
octo :: proc() {
	using failz

	bail(len(os.args) < 2, USAGE)
	command := os.args[1]
	switch command {
	case "new":
		new_package()
	case "init":
		init_package()
	case "run":
		run_package()
	case "build":
		build_package()
	case "install":
		install_package()
	case "add":
		add_package()
	case "remove":
		remove_package()
	case:
		fmt.println(USAGE)
	}
}
