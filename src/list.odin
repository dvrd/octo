package octo

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "libs:ansi"
import "libs:failz"

list_registry :: proc() {
	using failz

	home, found := os.lookup_env("HOME")
	catch(!found, "HOME env variable is not set")

	registry_path := filepath.join({home, REGISTRY_DIR})
	packages, err := read_dir(registry_path)
	catch(err, fmt.tprintf("Could not read directory (%s)", registry_path))

	info("Currently installed packages:")

	for pkg in packages {
		if pkg.name != "bin" {
			fmt.printfln("  %s %s", ansi.colorize("  ", {0, 210, 210}), pkg.name)
		}
	}
}
