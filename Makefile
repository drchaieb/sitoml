# SITO Makefile

.PHONY: all setup build test doc run clean deploy-ui

# Default target: build everything and generate docs
all: build deploy-ui doc test

# Environment setup (Local Opam Switch)
setup:
	opam switch create . 5.4.0 --no-install -y
	opam install . --deps-only --with-test -y
	opam install odoc -y

# Build core library, server, and web frontend
build:
	opam exec -- dune build

# Deploy compiled JS to the web folder for static serving
deploy-ui: build
	cp _build/default/web/main.bc.js web/

# Run all tests (Symbolic, Server, Verification)
test:
	opam exec -- dune runtest

# Generate high-quality HTML documentation from source code (odoc)
# Output will be in _build/default/_doc/_html
doc:
	opam exec -- dune build @doc

# Run the unified server (API + UI)
run: deploy-ui
	opam exec -- dune exec bin/server.exe

# Clean build artifacts
clean:
	dune clean
	rm -f web/main.bc.js
