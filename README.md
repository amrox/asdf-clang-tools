<div align="center">

# asdf-clang-tools [![Build](https://github.com/amrox/asdf-clang-tools/actions/workflows/build.yml/badge.svg)](https://github.com/amrox/asdf-clang-tools/actions/workflows/build.yml) [![Lint](https://github.com/amrox/asdf-clang-tools/actions/workflows/lint.yml/badge.svg)](https://github.com/amrox/asdf-clang-tools/actions/workflows/lint.yml)


[clang-tools](https://github.com/amrox/clang-tools) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Why?](#why)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

- `bash`, `curl`, `tar`: generic POSIX utilities.
- `SOME_ENV_VAR`: set this environment variable in your shell config to load the correct version of tool x.

# Install

Plugin:

```shell
asdf plugin add clang-tools
# or
asdf plugin add clang-tools https://github.com/amrox/asdf-clang-tools.git
```

clang-tools:

```shell
# Show all installable versions
asdf list-all clang-tools

# Install specific version
asdf install clang-tools latest

# Set a version globally (on your ~/.tool-versions file)
asdf global clang-tools latest

# Now clang-tools commands are available
clang-format
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/amrox/asdf-clang-tools/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [Andy Mroczkowski](https://github.com/amrox/)
