SRC_DIR=lua
TESTS_DIR=./tests
PREPARE_CONFIG=${TESTS_DIR}/prepare-config.lua
TEST_CONFIG=${TESTS_DIR}/minimal_init.lua

.PHONY: test lint format

checks: format lint test

lint: 
	luacheck ${SRC_DIR}  ${TESTS_DIR} --config .luacheckrc

format:
	~/.cargo/bin/stylua ${SRC_DIR}  ${TESTS_DIR} --config-path=.stylua.toml

test:
	@nvim --headless --noplugin -u ${TEST_CONFIG} -c "PlenaryBustedDirectory ${TESTS_DIR} {minimal_init = '${TEST_CONFIG}'}"
