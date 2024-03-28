package octo

import "core:fmt"
import "core:os"
import "libs:failz"

init_package :: proc() {
	using failz

	pwd := os.get_current_directory()
	pwd_info, err := os.stat(pwd)
	catch(Errno(err))

	ols_path := make_ols_file(pwd)
	src_path := make_src_dir(pwd)
	main_path := make_main_file(src_path, pwd_info.name)
	init_git()

	info(fmt.tprintf("Created binary (application) package"))
}
