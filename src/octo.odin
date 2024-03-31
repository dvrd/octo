package octo

import "core:fmt"
import "core:os"
import "libs:failz"

octo :: proc() {
	using failz

	usage(len(os.args) < 2, USAGE)

	command := os.args[1]
	switch command {
	case "new":
		new_package()
	case "init":
		init_package()
	case "run", "r":
		run_package()
	case "build":
		build_package()
	case "release":
		os.args = {"", "", "--release"}
		build_package()
	case "install", "i":
		install_package()
	case "add":
		add_package()
	case "remove", "rm":
		remove_package()
	case "search":
		search_package()
	case "list", "ls":
		list_registry()
	case:
		fmt.println(USAGE)
	}
}
