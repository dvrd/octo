package octo

import "core:fmt"
import "core:os"
import "libs:ansi"
import "libs:cmd"
import "libs:failz"

run_package :: proc() {
	using failz

	pwd := os.get_current_directory()
	pkg := read_pkg()
	bail(pkg == nil, "No package config found (%s)", pwd)

	extra_args_idx: Maybe(int)
	for arg, idx in os.args {
		if arg == "--" {
			extra_args_idx = idx
			break
		}
	}

	octo_args := os.args
	cmd_args := []string{}
	if extra_args_idx != nil {
		octo_args = os.args[:extra_args_idx.?]
		cmd_args = os.args[extra_args_idx.? + 1:]
	}

	build_name := len(octo_args) > 2 ? octo_args[2] : "debug"
	found := build_name in pkg.builds
	bail(!found, "No executable configuration found for '%s'", build_name)

	bin_path := get_bin_path(pwd, build_name)
	build_package()

	info("%s `%s`", ansi.colorize("Running", {0, 210, 80}), build_name)
	catch(cmd.exec(bin_path, cmd_args), "Failed to run the package")
}
