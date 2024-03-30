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
	pwd_info, err := os.stat(pwd)
	catch(Errno(err))

	bin_path := get_bin_path(pwd, "release")
	if !os.exists(bin_path) {
		build_package()
	}

	home_path := os.get_env("HOME")
	octo_registry_path := filepath.join({home_path, REGISTRY_DIR})
	if !os.is_dir(octo_registry_path) {
		catch(Errno(os.make_directory(octo_registry_path)))
	}

	octo_bin_path := filepath.join({octo_registry_path, "bin"})
	if !os.is_dir(octo_bin_path) {
		catch(Errno(os.make_directory(octo_bin_path)))
	}

	if os.exists(filepath.join({octo_bin_path, pwd_info.name})) {
		warn(msg = "The package is already installed")
		return
	}

	info(
		fmt.tprintf(
			"%s `%s` release build [target = %s]",
			ansi.colorize("Installing", {0, 210, 80}),
			pwd_info.name,
			octo_bin_path,
		),
	)

	catch(!cmd.launch({"ln", "-s", bin_path, octo_bin_path}), "Failed to install binary to system")

	info(
		fmt.tprintf(
			"%s installation",
			ansi.colorize("Successful", {0, 210, 80}),
			pwd_info.name,
			octo_bin_path,
		),
	)
}
