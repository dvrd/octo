package octo

import "core:fmt"
import "core:os"
import "libs:failz"

new_package :: proc() {
	using failz

	catch(len(os.args) < 3, NEW_USAGE)
	proj_name := os.args[2]
	catch(proj_name == "help", NEW_USAGE)

	proj_path := make_project_dir(proj_name)
	err := os.set_current_directory(proj_path)
	catch(Errno(err))

	ols_path := make_ols_file(proj_path)
	src_path := make_src_dir(proj_path)
	main_path := make_main_file(src_path, proj_name)
	init_git()

	info(fmt.tprintf("Created binary (application) `%s` package", proj_name))
}
