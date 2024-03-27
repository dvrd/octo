package octo

import "core:c"
import "core:fmt"
import "core:io"
import "core:mem"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:time"
import "libs:ansi"
import cmd "libs:command"
import "libs:failz"

when ODIN_OS == .Darwin {
	@(require)
	foreign import libs "system:System.framework"
}

foreign libs {
	@(link_name = "_NSGetExecutablePath")
	get_executable_path :: proc(buf: [^]c.char, bufsize: ^c.uint32_t) -> c.int ---
}

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
		pwd := os.get_current_directory()
		pwd_info, err := os.stat(pwd)
		catch(Errno(err))
		has_dependencies := os.exists(filepath.join({pwd, "/libs"}))
		collections := has_dependencies ? "-collection:libs=libs" : ""
		bin_path := get_bin_path(pwd)
		timer: time.Stopwatch
		time.stopwatch_start(&timer)
		info(
			fmt.tprintf(
				" %s %s [version] (%s)",
				ansi.colorize("Compiling", {0, 255, 0}),
				pwd_info.name,
				pwd_info.fullpath,
			),
		)
		cmd.launch(
			{"odin", "build", "src", collections, fmt.tprintf("-out:%s", bin_path), "-debug"},
		)
		time.stopwatch_stop(&timer)
		duration := time.stopwatch_duration(timer)
		duration_secs := time.duration_milliseconds(duration) / 1_000
		info(
			fmt.tprintf(
				"%s dev [unoptimized + debuginfo] target(s) in %.2fs",
				ansi.colorize("Finished", {0, 255, 0}),
				duration_secs,
			),
		)
		info(fmt.tprintf("%s `%s`", ansi.colorize("Running", {0, 255, 0}), bin_path))
		cmd.launch({bin_path})
	case "build":
		timer: time.Stopwatch
		time.stopwatch_start(&timer)
		pwd := os.get_current_directory()
		pwd_info, err := os.stat(pwd)
		catch(Errno(err))
		info(
			fmt.tprintf(
				" %s %s [version] (%s)",
				ansi.colorize("Compiling", {0, 255, 0}),
				pwd_info.name,
				pwd_info.fullpath,
			),
		)
		has_dependencies := os.exists(filepath.join({pwd, "/libs"}))
		collections := has_dependencies ? "-collection:libs=libs" : ""
		bin_path := get_bin_path(pwd)
		cmd.launch(
			{"odin", "build", "src", collections, fmt.tprintf("-out:%s", bin_path), "-debug"},
		)
		time.stopwatch_stop(&timer)
		duration := time.stopwatch_duration(timer)
		duration_secs := time.duration_milliseconds(duration) / 1_000
		info(
			fmt.tprintf(
				"%s dev [unoptimized + debuginfo] target(s) in %.2fs",
				ansi.colorize("Finished", {0, 255, 0}),
				duration_secs,
			),
		)
	case "release":
		timer: time.Stopwatch
		time.stopwatch_start(&timer)
		pwd := os.get_current_directory()
		pwd_info, err := os.stat(pwd)
		catch(Errno(err))
		info(
			fmt.tprintf(
				" %s %s [version] (%s)",
				ansi.colorize("Compiling", {0, 255, 0}),
				pwd_info.name,
				pwd_info.fullpath,
			),
		)
		has_dependencies := os.exists(filepath.join({pwd, "/libs"}))
		collections := has_dependencies ? "-collection:libs=libs" : ""
		bin_path := get_bin_path(pwd, "/release")
		out_bin := fmt.tprintf("-out:%s", bin_path)
		cmd.launch({"odin", "build", "src", collections, out_bin, "-o:speed"})
		time.stopwatch_stop(&timer)
		duration := time.stopwatch_duration(timer)
		duration_secs := time.duration_milliseconds(duration) / 1_000
		info(
			fmt.tprintf(
				"%s release [optimized] target(s) in %.2fs",
				ansi.colorize("Finished", {0, 255, 0}),
				duration_secs,
			),
		)
	case "install":
		pwd := os.get_current_directory()
		pwd_info, err := os.stat(pwd)
		catch(Errno(err))
		bin_path := get_bin_path(pwd, "/release")
		target_path := "/usr/local/bin"
		info(
			fmt.tprintf(
				"%s `%s` release target to `%s`",
				ansi.colorize("Installing", {0, 255, 0}),
				pwd_info.name,
				target_path,
			),
		)
		cmd.launch({"sudo", "ln", "-s", bin_path, target_path})
	case "add":
		catch(len(os.args) < 3, ADD_USAGE)
		pkg_name := os.args[2]
		catch(pkg_name == "help", ADD_USAGE)
		home := os.get_env("HOME")
		pwd := os.get_current_directory()

		libs_path := filepath.join({pwd, "/libs"})
		if !os.is_dir(libs_path) {
			catch(Errno(os.make_directory(libs_path)))
		}

		local_pkg_path := filepath.join({libs_path, "/", pkg_name})
		if os.is_dir(local_pkg_path) {
			fmt.println(
				fmt.tprintf(
					"%s `%s` package to dependencies",
					ansi.colorize("Adding", {0, 255, 0}),
					pkg_name,
				),
			)
			os.exit(0)
		}

		registry_path := filepath.join({home, REGISTRY_DIR})
		if !os.is_dir(registry_path) {
			catch(Errno(os.make_directory(registry_path)))
		}

		pkg_path := filepath.join({registry_path, pkg_name})
		if os.is_dir(pkg_path) {
			info(
				fmt.tprintf(
					"%s `%s` package to dependencies",
					ansi.colorize("Adding", {0, 255, 0}),
					pkg_name,
				),
			)
			copy_dir(pkg_path, local_pkg_path)
		} else {
			warn(msg = fmt.tprintf("Package `%s` not found in registry", pkg_name))

			odin_bin_path := cmd.find_program("odin")
			path_split := strings.split(odin_bin_path, "/")
			odin_path := strings.join(path_split[:len(path_split) - 1], "/")

			odin_dir_path := strings.split(odin_bin_path, "/")
			info(
				fmt.tprintf(
					"%s package in `%s`",
					ansi.colorize("Searching", {0, 210, 80}),
					odin_path,
				),
			)
		}
	case:
		fmt.println(USAGE)
		os.exit(1)
	}
}
