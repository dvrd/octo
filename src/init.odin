package octo

import "core:fmt"
import "core:os"
import "libs:ansi"
import "libs:failz"

init_package :: proc() {
	using failz

	pwd := os.get_current_directory()
	pwd_info, err := os.stat(pwd)
	catch(Errno(err))

	make_ols_file(pwd)
	make_octo_file(pwd, pwd_info.name)
	make_main_file(make_src_dir(pwd), pwd_info.name)
	init_git()

	info(fmt.tprintf("%s binary (application) package", ansi.colorize("Created", {0, 210, 80})))
}
