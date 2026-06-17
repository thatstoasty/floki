# Development Guidelines

This file provides guidelines for AI coding assistants such as Claude Code when
working with code in this repository.

## Repository Overview

Floki is a lightweight HTTP client library written in Mojo, designed for
high-performance applications. It provides a `requests` like interface for making HTTP
requests, handling responses, and managing cookies. The library uses `libcurl` under the hood for efficient network communication.

## Essential Build Commands

### Pixi Environment Management

Many directories include `pixi.toml` files for environment management. Use Pixi
when present:

```bash
# Install Pixi environment (run once per directory)
pixi install

# Run Mojo files through Pixi
pixi run mojo [file.mojo]

# Format Mojo code
pixi run mojo format ./

# Use predefined tasks from pixi.toml
pixi run main              # Run main example
pixi run test              # Run tests
pixi run hello             # Run hello.mojo

# Common Pixi tasks available in different directories:
# - /mojo/: build, tests, examples, benchmarks
# - /max/: llama3, mistral, generate, serve
# - /examples/*/: main, test, hello, dev-server, format

# List available tasks
pixi task list
```

## High-Level Architecture

### Repository Structure

```text
floki/
├── examples/       # Floki package examples
├── floki/          # Floki HTTP client library (Mojo)
│   └── cookie/     # HTTP cookie handling
├── test/           # Tests for floki.
└── utils/          # Testing utilities
```

### Key Architectural Patterns

1. **Memory Management**:
   - Careful lifetime management in Mojo code

2. **Testing Philosophy**:
   - Tests mirror source structure
   - Migrating to `testing` module assertions

## Development Workflow

### Branch Strategy

- Work from `main` branch
- Create feature branches for significant changes

### Code Style

- Use `pixi run format` for Mojo code
- Follow existing patterns in the codebase
- Add docstrings to public APIs
- Sign commits with `git commit -s`

## Critical Development Notes

### Mojo Development

- Follow value semantics and ownership conventions
- Use `Reference` types with explicit lifetimes in APIs

### MAX Kernel Development

- Fine-grained control over memory layout and parallelism
- Hardware-specific optimizations (tensor cores, SIMD)
- Vendor library integration when beneficial
- Performance improvements must include benchmarks

## LLM-friendly Documentation

- Docs index: <https://docs.modular.com/llms.txt>
- Mojo API docs: <https://docs.modular.com/llms-mojo.txt>
- Comprehensive docs: <https://docs.modular.com/llms-full.txt>

## Git commit style

- **Atomic Commits:** Keep commits small and focused. Each commit should
address a single, logical change. This makes it easier to understand the
history and revert changes if needed.
- **Descriptive Commit Messages:** Write clear, concise, and informative commit
messages. Explain the *why* behind the change, not just *what* was changed. Use
a consistent format (e.g., imperative mood: "Fix bug", "Add feature").
- **Commit titles:** git commit titles should have the `[Stdlib]` or `[Kernel]`
depending on whether the kernel is modified and if they are modifying GPU
functions then they should use `[GPU]` tag as well.
- The commit messages should be surrounded by BEGIN_PUBLIC and END_PUBLIC
- Here is an example template a git commit

```git
[Kernels] Some new feature

BEGIN_PUBLIC
[Kernels] Some new feature

This add a new feature for [xyz] to enable [abc]
END_PUBLIC
```
