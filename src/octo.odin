package octo

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:time"
import "libs:ansi"
import "libs:cmd"
import "libs:failz"

main :: proc() {
	using failz

	catch(len(os.args) < 2, USAGE)
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
