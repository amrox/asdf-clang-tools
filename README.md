<div align="center">

# asdf-clang-tools [![Build](https://github.com/amrox/asdf-clang-tools/actions/workflows/build.yml/badge.svg)](https://github.com/amrox/asdf-clang-tools/actions/workflows/build.yml) [![Lint](https://github.com/amrox/asdf-clang-tools/actions/workflows/lint.yml/badge.svg)](https://github.com/amrox/asdf-clang-tools/actions/workflows/lint.yml)


[clang-tools](https://github.com/muttleyxd/clang-tools-static-binaries) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Overview

This is an asdf plugin for installing several clang tools:

- clang-format
- clang-query
- clang-tidy

This plugin uses the pre-compiled binaries from the very handy [muttleyxd/clang-tools-static-binaries](https://github.com/muttleyxd/clang-tools-static-binaries) repo.

## Caveats

- Again, the source for these binaries is currently [muttleyxd/clang-tools-static-binaries](https://github.com/muttleyxd/clang-tools-static-binaries). Please make sure you trust that repository.
- Only Intel (`x86_64`/`amd64`) binaries are currently provided.
  - These binaries do work on macOS with Apple Silicon, but they will run under Rosetta.
- Signed binaries are not provided for macOS. This plugin will offer to de-quarantine the binaries for you, but please make sure you understand the consequences.

# Dependencies

- `curl`, `jq`
- `sha512sum` (optional, but recommended)

# Install

This plugin supports multiple tools (similar to [asdf-hashicorp](https://github.com/asdf-community/asdf-hashicorp) and [asdf-pyapp](https://github.com/amrox/asdf-pyapp).

| Tool         | Command to add Plugin                                                        |
| ------------ | ---------------------------------------------------------------------------- |
| clang-format | `asdf plugin add clang-format https://github.com/amrox/asdf-clang-tools.git` |
| clang-query  | `asdf plugin add clang-query https://github.com/amrox/asdf-clang-tools.git`  |
| clang-tidy   | `asdf plugin add clang-tidy https://github.com/amrox/asdf-clang-tools.git`   |


Example:

```shell
asdf plugin add clang-format https://github.com/amrox/asdf-clang-tools.git
```

clang-format:

```shell
# Show all installable versions
asdf list-all clang-format

# Install specific version
asdf install clang-format latest

# Set a version globally (on your ~/.tool-versions file)
asdf global clang-format latest

# Now clang-tools commands are available
clang-format
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# Configuration

## Environment Variables

- `ASDF_CLANG_TOOLS_MACOS_DEQUARANTINE`: set to "1" to automatically de-quarantine binaries. Otherwise, it will interactively ask to do so.
- `ASDF_CLANG_TOOLS_LINUX_IGNORE_ARCH`: set to "1" to install the `amd64` binary regardless of the host architecture. The [clang-tools](https://github.com/muttleyxd/clang-tools-static-binaries) project does not currently provide `arm64`/`aarch64` Linux binaries. This assumes that you have set up [QEMU User Emulation](https://wiki.debian.org/QemuUserEmulation) (or similar) to run foreign binaries under emulation.

# Acknowledgements

Thank you to the authors and contributors to [muttleyxd/clang-tools-static-binaries](https://github.com/muttleyxd/clang-tools-static-binaries).

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/amrox/asdf-clang-tools/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [Andy Mroczkowski](https://github.com/amrox/)
