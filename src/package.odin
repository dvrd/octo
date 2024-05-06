package octo

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "libs:failz"

Package :: struct {
	host:  string,
	owner: string,
	name:  string,
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
