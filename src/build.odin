package octo

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:time"
import "libs:ansi"
import "libs:cmd"
import "libs:failz"

build_package :: proc(is_install := false) {
	using failz


	timer: time.Stopwatch
	time.stopwatch_start(&timer)
	pwd := os.get_current_directory()
	pkg := read_pkg()
	bail(pkg == nil, "No package config found (%s)", pwd)

	info("%s %s [%s] (%s)", ansi.colorize("Compiling", {0, 210, 80}), pkg.name, "0.1.0", pwd)

	build_path := len(os.args) > 2 ? os.args[2] : "debug"
	build_config, found := pkg.builds[build_path]
	bail(!found, "No build configuration found for '%s'", build_path)

	arguments := make([dynamic]string)
	append(&arguments, "odin")
	append(&arguments, "build")

	bail(build_config.src == "", "No source file specified for build")
	append(&arguments, build_config.src)

	for dep in build_config.collections {
		dep_path := build_config.collections[dep]
		bail(!os.exists(dep_path), "Collection '%s' not found in codebase", dep)
		append(&arguments, fmt.tprintf("-collection:%s=%s", dep, dep_path))
	}

	if len(build_config.linker_flags) != 0 {
		sb := strings.builder_make()
		for &flag in build_config.linker_flags {
			if strings.contains(flag, "[") && strings.contains(flag, "]") {
				start_idx := strings.index(flag, "[")
				end_idx := strings.index(flag, "]")
				vendor_library := flag[start_idx:end_idx]
				flag = fmt.tprint(
					"%s%s/vendor/%s%s",
					flag[:start_idx],
					ODIN_ROOT,
					vendor_library,
					flag[end_idx + 1:],
				)
			}
			strings.write_string(&sb, flag)
		}
		append(&arguments, fmt.tprintf("-extra-linker-flags:%s", strings.to_string(sb)))
	}

	switch build_config.mode {
	case .EXE:
		append(&arguments, "-build-mode:exe")
	case .DLL:
		append(&arguments, "-build-mode:dll")
	case .OBJ:
		append(&arguments, "-build-mode:obj")
	case .ASM:
		append(&arguments, "-build-mode:asm")
	case .LLVM:
		append(&arguments, "-build-mode:llvm")
	}

	if build_config.separate_modules {
		append(&arguments, "-use-separate-modules")
	}

	if build_config.debug {
		append(&arguments, "-debug")
	} else {
		switch build_config.optim {
		case .none:
			append(&arguments, "-o:none")
		case .minimal:
			append(&arguments, "-o:minimal")
		case .size:
			append(&arguments, "-o:size")
		case .speed:
			append(&arguments, "-o:speed")
		case .aggressive:
			append(&arguments, "-o:aggressive")
		}
	}

	bin_path := get_bin_path(pwd, build_path)
	append(&arguments, fmt.tprintf("-out:%s", bin_path))

	catch(!cmd.launch(arguments[:]), "Failed to build debug target binary")

	time.stopwatch_stop(&timer)
	duration := time.stopwatch_duration(timer)
	duration_secs := time.duration_milliseconds(duration) / 1_000

	info(
		"%s %s [%s] target(s) in %.2fs",
		ansi.colorize("Finished", {0, 210, 80}),
		build_path,
		build_config.optim != .none \
		? "optimized" \
		: build_config.debug ? "unoptimized + debuginfo" : "unoptimized",
		duration_secs,
	)
}
