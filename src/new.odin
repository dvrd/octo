package octo

import "core:fmt"
import "core:os"
import "libs:ansi"
import "libs:failz"

new_package :: proc() {
	using failz

	bail(len(os.args) < 3, NEW_USAGE)
	proj_name := os.args[2]
	bail(proj_name == "help", NEW_USAGE)

	proj_path := make_project_dir(proj_name)
	err := os.set_current_directory(proj_path)
	catch(Errno(err))

	make_ols_file(proj_path)
	make_octo_file(proj_path, proj_name)
	make_main_file(make_src_dir(proj_path), proj_name)
	init_git()

	info("%s binary (application) `%s` package", ansi.colorize("Created", {0, 210, 80}), proj_name)
}
