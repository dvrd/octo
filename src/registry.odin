package octo

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "libs:failz"

Registry :: struct {
	packages: map[string]string,
	amount:   int,
}

read_registry :: proc() -> (reg: ^Registry) {
	using failz

	home, found := os.lookup_env("HOME")
	catch(!found, "HOME env variable not set")

	reg = new(Registry)
	registry_path := filepath.join({home, REGISTRY_DIR, "registry.json"})
	data, ok := os.read_entire_file(registry_path)
	catch(!ok, fmt.tprint("Failed to read registry.json:", os.get_last_error_string()))

	json.unmarshal(data, reg)

	return
}
