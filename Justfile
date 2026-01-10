# Test runner recipes

# Run all tests
test: test-unit test-integration

# Run unit tests
test-unit:
    nvim --headless --noplugin -u tests/minimal_init.lua \
        -c "PlenaryBustedDirectory tests/unit/ { minimal_init = 'tests/minimal_init.lua' }"

# Run integration tests
test-integration:
    nvim --headless --noplugin -u tests/minimal_init.lua \
        -c "PlenaryBustedDirectory tests/integration/ { minimal_init = 'tests/minimal_init.lua' }"

# Run a specific test file
test-file FILE:
    nvim --headless --noplugin -u tests/minimal_init.lua \
        -c "PlenaryBustedFile {{ FILE }}"

# Format code with stylua
format:
    stylua .

# Check code formatting with stylua
lint:
    stylua --check .

# Fix code formatting with stylua
lint-fix:
    stylua .
