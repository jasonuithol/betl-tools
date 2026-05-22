# betl-tools

Cross-platform tools for the [betl][betl] ecosystem.

[betl]: https://github.com/jasonuithol/betl-native

## Contents

| Directory               | What                                                          |
| ----------------------- | ------------------------------------------------------------- |
| `betl-dtsx2yaml/`       | SSIS `.dtsx` → `.betl.yml` converter (.NET 8 console tool)    |
| `betl-yaml-ui/`         | Browser-based pipeline viewer/editor (Python + HTML)          |
| `betl-container/`       | Wrapper scripts for the Linux bundled image                   |
| `Containerfile`         | Multi-stage build for the Linux bundled image                 |

## Install

See [INSTALL.md](INSTALL.md) for both the Linux/macOS containerized
path and the native-Windows path.

## License

Apache-2.0, matching `betl-native` and `betl-dotnet`.
