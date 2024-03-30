package octo

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:time"
import "libs:ansi"
import "libs:cmd"
import "libs:failz"

build_package :: proc() {
	using failz

	timer: time.Stopwatch
	time.stopwatch_start(&timer)
	pwd := os.get_current_directory()
	pkg := get_config()

	info(
		fmt.tprintf(
			"%s %s [%s] (%s)",
			ansi.colorize("Compiling", {0, 210, 80}),
			pkg.name,
			pkg.version,
			pwd,
		),
	)

	has_dependencies := os.exists(filepath.join({pwd, "libs"}))
	collections := has_dependencies ? "-collection:libs=libs" : ""

	is_release := len(os.args) > 2 && os.args[2] == "--release"
	bin_path: string
	if is_release {
		bin_path = get_bin_path(pwd, "release")
		catch(
			!cmd.launch(
				 {
					"odin",
					"build",
					"src",
					collections,
					fmt.tprintf("-out:%s", bin_path),
					"-o:speed",
				},
			),
			"Failed to build binary release target",
		)
	} else {
		bin_path = get_bin_path(pwd)
		catch(
			!cmd.launch(
				 {
					"odin",
					"build",
					"src",
					collections,
					"-use-separate-modules",
					fmt.tprintf("-out:%s", bin_path),
					"-debug",
				},
			),
			"Failed to build binary debug target",
		)
	}

	time.stopwatch_stop(&timer)
	duration := time.stopwatch_duration(timer)
	duration_secs := time.duration_milliseconds(duration) / 1_000

	info(
		fmt.tprintf(
			"%s %s [%s] target(s) in %.2fs",
			ansi.colorize("Finished", {0, 210, 80}),
			is_release ? "release" : "dev",
			is_release ? "optimized" : "unoptimized + debuginfo",
			duration_secs,
		),
	)
}
