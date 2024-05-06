PROJ=octo
REGISTRY_DIR=$(HOME)/.octo/bin
SRC_DIR=src
DEBUG_OUT_DIR=target/debug
RELEASE_OUT_DIR=target/release
COLLECTIONS=-collection:libs=libs

IGNORE_ERRORS=2> /dev/null || true

run: build
	@echo "BUILD_INFO: running $(PROJ)..."
	@$(RELEASE_OUT_DIR)/$(PROJ) $(CMD) $(ARG)

clear:
	@echo "BUILD_INFO: removing all binaries..."
	@rm -rf target $(IGNORE_ERRORS)

install: build $(REGISTRY_DIR)
	@echo "BUILD_INFO: installing $(PROJ)..."
	@ln -s $(PWD)/$(RELEASE_OUT_DIR)/$(PROJ) $(REGISTRY_DIR) $(IGNORE_ERRORS)

build: $(RELEASE_OUT_DIR)
	@echo "BUILD_INFO: building release version..."
	@odin build $(SRC_DIR) -out:$(RELEASE_OUT_DIR)/$(PROJ) -o:speed $(COLLECTIONS)

debug: $(DEBUG_OUT_DIR)
	@echo "BUILD_INFO: building debug version..."
	@odin build $(SRC_DIR) -out:$(DEBUG_OUT_DIR)/$(PROJ) -debug $(COLLECTIONS)

$(REGISTRY_DIR):
	@mkdir -p $(REGISTRY_DIR)
	@cp registry.json $(REGISTRY_DIR)/registry.json

$(RELEASE_OUT_DIR):
	@mkdir -p $(RELEASE_OUT_DIR)

$(DEBUG_OUT_DIR):
	@mkdir -p $(DEBUG_OUT_DIR)
