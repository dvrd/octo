package octo

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:time"
import "libs:ansi"
import "libs:cmd"
import "libs:failz"

@(init)
build_package :: proc() {
	using failz

	timer: time.Stopwatch
	time.stopwatch_start(&timer)
	pwd := os.get_current_directory()
	pwd_info, err := os.stat(pwd)
	catch(Errno(err))

	info(
		fmt.tprintf(
			" %s %s [version] (%s)",
			ansi.colorize("Compiling", {0, 210, 80}),
			pwd_info.name,
			pwd_info.fullpath,
		),
	)

	has_dependencies := os.exists(filepath.join({pwd, "libs"}))
	collections := has_dependencies ? "-collection:libs=libs" : ""

	bin_path: string
	if len(os.args) > 2 && os.args[2] == "--release" {
		bin_path = get_bin_path(pwd, "release")
		cmd.launch(
			{"odin", "build", "src", collections, fmt.tprintf("-out:%s", bin_path), "-o:speed"},
		)
	} else {
		bin_path = get_bin_path(pwd)
		cmd.launch(
			{"odin", "build", "src", collections, fmt.tprintf("-out:%s", bin_path), "-debug"},
		)
	}

	time.stopwatch_stop(&timer)
	duration := time.stopwatch_duration(timer)
	duration_secs := time.duration_milliseconds(duration) / 1_000

	info(
		fmt.tprintf(
			"%s dev [unoptimized + debuginfo] target(s) in %.2fs",
			ansi.colorize("Finished", {0, 210, 80}),
			duration_secs,
		),
	)
}
