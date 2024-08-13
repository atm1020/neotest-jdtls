SRC_DIR=lua
TESTS_DIR=tests
TEST_CONFIG=${TESTS_DIR}/minimal_init.lua

.PHONY: test lint format all

checks: format lint

test:
	nvim --headless -c "PlenaryBustedDirectory  {minimal_init = '${TEST_CONFIG}'}"
lint: 
	luacheck ${SRC_DIR} 

format:
	~/.cargo/bin//stylua ${SRC_DIR} --config-path=.stylua.toml

