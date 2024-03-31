package octo

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "libs:cmd"
import "libs:failz"

update_package :: proc() {
	using failz

	usage(len(os.args) < 3, UPDATE_USAGE)

	home, found := os.lookup_env("HOME")
	catch(!found, "HOME env variable not set")

	pkg_name := os.args[2]
	registry_pkg_path := filepath.join({home, REGISTRY_DIR, pkg_name})
	bail(!os.exists(registry_pkg_path), "Package `%s` does not exist", pkg_name)

	os.set_current_directory(registry_pkg_path)
	catch(!cmd.launch({"git", "pull", "-r"}), "Failed to update package")
}
