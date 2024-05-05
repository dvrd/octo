package octo

import "core:fmt"
import "core:os"
import "libs:ansi"
import "libs:failz"

new_package :: proc() {
	using failz

	if len(os.args) < 3 do fmt.println(NEW_USAGE)
	proj_name := os.args[2]

	if proj_name == "help" do fmt.println(NEW_USAGE)

	proj_path := make_project_dir(proj_name)
	err := os.set_current_directory(proj_path)
	catch(Errno(err))

	make_ols_file(proj_path)
	make_main_file(make_src_dir(proj_path), proj_name)
	init_git()

	info("%s binary (application) `%s` package", ansi.colorize("Created", {0, 210, 80}), proj_name)
}
