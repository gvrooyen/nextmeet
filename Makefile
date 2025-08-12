# NextMeet Makefile

.PHONY: build test install uninstall clean doc help

# Default target
all: build

# Build the project
build:
	dune build

# Run tests
test:
	dune test

# Install the binary
install: build
	dune install

# Uninstall the binary
uninstall:
	dune uninstall

# Clean build artifacts
clean:
	dune clean

# Generate documentation (if using odoc)
doc:
	dune build @doc

# Run in debug mode
debug: build
	dune exec bin/debug.exe

# Run production version
run: build
	dune exec bin/main.exe

# Check dependencies
deps:
	@echo "Checking OCaml dependencies..."
	@opam list lwt cohttp-lwt-unix tls-lwt yojson ptime uri base64 str dune alcotest 2>/dev/null || echo "Some dependencies missing. Run: make install-deps"

# Install dependencies via opam
install-deps:
	opam install lwt cohttp-lwt-unix tls-lwt yojson ptime uri base64 str dune alcotest

# Development setup
setup: install-deps build test
	@echo "Development environment setup complete!"

# Package for distribution
package: clean build test
	@echo "Creating distribution package..."
	tar -czf nextmeet-$(shell date +%Y%m%d).tar.gz \
		--exclude='.git*' \
		--exclude='_build' \
		--exclude='*.tar.gz' \
		.

# Help
help:
	@echo "NextMeet Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  build        - Build the project"
	@echo "  test         - Run test suite"
	@echo "  install      - Install the binary"
	@echo "  uninstall    - Uninstall the binary"
	@echo "  clean        - Clean build artifacts"
	@echo "  debug        - Run debug version"
	@echo "  run          - Run production version"
	@echo "  deps         - Check dependencies"
	@echo "  install-deps - Install OCaml dependencies"
	@echo "  setup        - Full development setup"
	@echo "  package      - Create distribution package"
	@echo "  help         - Show this help"
