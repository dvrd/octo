package octo

import "core:encoding/json"
import "core:os"
import "libs:failz"

Registry :: struct {
	packages: map[string]string,
	amount:   int,
}

read_registry :: proc() -> (reg: ^Registry) {
	using failz

	reg = new(Registry)
	data, ok := os.read_entire_file("registry.json")
	catch(!ok, "Failed to read registry.json")

	json.unmarshal(data, reg)

	return
}
