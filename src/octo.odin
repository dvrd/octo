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

	switch command := os.args[1]; command {
	case "new":
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
	case "init":
		pwd := os.get_current_directory()
		pwd_info, err := os.stat(pwd)
		catch(Errno(err))

		ols_path := make_ols_file(pwd)
		src_path := make_src_dir(pwd)
		main_path := make_main_file(src_path, pwd_info.name)
		init_git()

		info(fmt.tprintf("Created binary (application) package"))
	case "run":
		run_package()
	case "build":
		build_package()
	case "install":
		install_package()
	case "add":
		add_package()
	case:
		fmt.println(USAGE)
		os.exit(1)
	}
}
