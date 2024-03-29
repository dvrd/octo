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
	target_path := "/usr/local/bin"

	if os.exists(filepath.join({target_path, pwd_info.name})) {
		warn(msg = "The package is already installed")
		return
	}

	info(
		fmt.tprintf(
			"%s `%s` release build [target = %s]",
			ansi.colorize("Installing", {0, 210, 80}),
			pwd_info.name,
			target_path,
		),
	)

	catch(
		cmd.launch({"sudo", "ln", "-s", bin_path, target_path}) != .Ok,
		"Failed to install binary to system",
	)
}
