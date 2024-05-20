package octo

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "libs:failz"

Timings_Config :: struct {
	kind:   enum {
		Basic,
		Advanced,
	},
	export: enum {
		JSON,
		CSV,
	},
	file:   Maybe(string),
}

Optimizations :: enum {
	none,
	minimal,
	size,
	speed,
	aggressive,
}

Build_Mode :: enum {
	EXE, // Builds as an executable.
	DLL, // Builds as a dynamically linked library.
	OBJ, // Builds as an object file.
	ASM, // Builds as an assembly file.
	LLVM, // Builds as an LLVM IR file.
}

Vet :: enum {
	Unused,
	Unused_Variables,
	Unused_Imports,
	Shadowing,
	Using_Stmt,
	Using_Param,
	Style,
	Semicolon,
}

Microarch :: enum {
	Sandybridge,
	Native,
}

Reloc_Mode :: enum {
	Default,
	Static,
	PIC,
	Dynamic_No_PIC,
}

Sanitize :: enum {
	Address,
	Memory,
	Thread,
}

Build_Config :: struct {
	src:                  string,
	collections:          map[string]string,
	optim:                Optimizations,
	debug:                bool,
	timings:              Timings_Config,
	system_calls:         bool,
	threads:              int,
	keep_temp_files:      bool,
	definitions:          map[string]string,
	mode:                 Build_Mode,
	target:               string,
	sanitize:             bit_set[Sanitize],
	assert:               bool,
	no_bounds_check:      bool,
	no_type_assert:       bool,
	no_crt:               bool,
	no_thread_local:      bool,
	lld:                  bool,
	separate_modules:     bool,
	no_threaded_checker:  bool,
	vet:                  bit_set[Vet],
	ignore_unknown_attrs: bool,
	no_entry_point:       bool,
	minimum_os:           string,
	linker_flags:         string,
	assembler_flags:      string,
	microarch:            Microarch,
	reloc_mode:           Reloc_Mode,
	disable_red_zone:     bool,
	dynamic_map_calls:    bool,
	disallow_do:          bool,
	default_to_nil_alloc: bool,
	strict_style:         bool,
	ignore_warnings:      bool,
	warnings_as_errors:   bool,
	terse_errors:         bool,
	json_errors:          bool,
}

Package :: struct {
	host:    string `json:host`,
	owner:   string `json:owner`,
	name:    string `json:name`,
	version: string `json:version`,
	builds:  map[string]Build_Config,
}

read_pkg :: proc() -> (pkg: ^Package) {
	using failz

	pkg = new(Package)

	pwd := os.get_current_directory()
	octo_pkg_path := filepath.join({pwd, OCTO_PKG_FILE})
	data, ok := os.read_entire_file(octo_pkg_path)
	bail(!ok, "Failed to read package file: %s", octo_pkg_path)

	err := json.unmarshal(data, pkg)
	catch(Error(err))

	if exist := "debug" in pkg.builds; !exist {
		collections := map[string]string{}
		src := "."
		if os.exists("libs") do collections["libs"] = "libs"
		if os.exists("src") do src = "src"
		pkg.builds["debug"] = Build_Config {
			src              = src,
			debug            = true,
			collections      = collections,
			separate_modules = true,
		}
	}

	return
}

get_pkg_from_args :: proc(target_pkg: string) -> (pkg: ^Package) {
	if target_pkg == "" do return nil

	pkg_name := filepath.base(target_pkg)
	registry := read_registry()
	pkg = new(Package)

	if uri, ok := registry.packages[pkg_name]; ok {
		pkg_info := strings.split(registry.packages[pkg_name], "/")
		pkg.host = pkg_info[0]
		pkg.owner = pkg_info[1]
		pkg.name = pkg_info[2]
		return
	}

	pkg_info := strings.split(target_pkg, "/")
	n_parts := len(pkg_info)

	if n_parts > 3 || n_parts == 0 do return nil

	if n_parts == 3 {
		pkg.host = pkg_info[0]
		pkg.owner = pkg_info[1]
		pkg.name = pkg_info[2]
		return
	}

	pkg.host = os.lookup_env("OCTO_GIT_HOST") or_else "github.com"
	if n_parts == 2 {
		pkg.owner = pkg_info[0]
		pkg.name = pkg_info[1]
		return
	}

	user, found := os.lookup_env("OCTO_GIT_USER")
	if !found do return nil
	pkg.owner = user
	pkg.name = pkg_info[0]

	return
}
