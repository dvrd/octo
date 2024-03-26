PROJ=octo
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

build: $(RELEASE_OUT_DIR)
	@echo "BUILD_INFO: building release version..."
	@odin build $(SRC_DIR) -out:$(RELEASE_OUT_DIR)/$(PROJ) -o:speed $(COLLECTIONS)

$(RELEASE_OUT_DIR):
	@mkdir -p $(RELEASE_OUT_DIR)
