# Installing betl

There are two install paths. Pick by OS:

| If you're on...   | Use the...                                  |
| ----------------- | ------------------------------------------- |
| Linux, macOS      | Containerized `betl.native` (this repo)     |
| Windows           | Native `betl-dotnet` (no WSL, no container) |

The two engines are independent reference implementations of
[`SPEC_CORE.md`][spec-core] — any pipeline that uses only spec-floor
step types runs identically on either. See [Which engine?](#which-engine)
below for the differences that matter.

[spec-core]: https://github.com/jasonuithol/betl-native/blob/master/SPEC_CORE.md

---

## Linux / macOS — containerized `betl.native`

### Prerequisites

- `podman` or `docker`
- `git`

### Install

```sh
git clone https://github.com/jasonuithol/betl-tools
cd betl-tools
./betl-container/build.sh
```

That single command:

- pulls Debian bookworm + the .NET 8 SDK + apt deps
- clones `betl-native` (master HEAD by default; pin via
  `BETL_NATIVE_REF=<sha-or-tag>`)
- compiles the C engine
- bundles dtsx2yaml and yaml-ui into the image

First build takes 5–10 minutes; the resulting `betl:dev` image is
~700 MB.

### Run

```sh
./betl-container/betl ui                            # http://127.0.0.1:8765
./betl-container/betl validate path/to/pipeline.yml
./betl-container/betl run      path/to/pipeline.yml
./betl-container/betl convert  path/to/package.dtsx
```

The wrapper bind-mounts `$PWD` to `/workspace`, so paths are interpreted
relative to wherever you ran from. See
[`betl-container/README.md`](betl-container/README.md) for environment
overrides (`BETL_IMAGE`, `BETL_DEV`, etc.).

---

## Windows — native `betl-dotnet`

### Prerequisites

```powershell
winget install Microsoft.DotNet.SDK.9
winget install Python.Python.3.12     # only if you want the yaml-ui
```

### Install the runtime engine

Until the preview package is published to NuGet, install from source:

```powershell
git clone https://github.com/jasonuithol/betl-dotnet
cd betl-dotnet
dotnet pack -c Release src\Betl.Cli\Betl.Cli.csproj
dotnet tool install -g `
    --add-source src\Betl.Cli\bin\Release `
    Betl.Dotnet --version 0.10.0-preview1
```

Once 0.x is on NuGet the install will collapse to:

```powershell
dotnet tool install -g Betl.Dotnet
```

### Install the dtsx2yaml converter (optional)

```powershell
git clone https://github.com/jasonuithol/betl-tools
cd betl-tools
dotnet pack -c Release betl-dtsx2yaml\Betl.Dtsx2Yaml.csproj
dotnet tool install -g `
    --add-source betl-dtsx2yaml\bin\Release `
    Betl.Dtsx2Yaml --version 0.10.0-preview1
```

### Run the yaml-ui (optional)

```powershell
pwsh .\betl-yaml-ui\run.ps1
```

First run creates `betl-yaml-ui\.venv\`, installs FastAPI + uvicorn,
then serves the UI at `http://127.0.0.1:8765`. The UI auto-discovers
`betl-dotnet` and `betl-dtsx2yaml` on PATH.

### Run a pipeline

```powershell
betl-dotnet validate path\to\pipeline.betl.yml
betl-dotnet run      path\to\pipeline.betl.yml
```

---

## Which engine?

Both runtimes implement `SPEC_CORE.md`. Pipelines stay portable as long
as you use only spec-floor step types. The differences:

| Feature                           | `betl.native` (Linux/macOS) | `betl-dotnet` (Windows) |
| --------------------------------- | --------------------------- | ----------------------- |
| `ssisexpr` expressions            | ✓                           | ✓                       |
| `csv` / `json` / `xml` / `xlsx`   | ✓                           | ✓                       |
| Postgres + MSSQL providers        | ✓                           | ✓                       |
| `lua.map` / `lua.script` / etc.   | ✓                           | ✗ (use `dotnet.script`) |
| `dotnet.task` / `dotnet.script`   | via SDK shim                | native                  |
| Native plugin ABI (`.so`)         | ✓                           | n/a (uses ALC)          |

For SSIS migration specifically, both runtimes accept the same
`.betl.yml` produced by `dtsx2yaml`.

---

## Verify the install

The smallest hello-world pipeline:

```yaml
# hello.betl.yml
betl: 1
name: hello
parameters:
  out: { type: string, required: true }
pipeline:
  - id: flow
    type: dataflow
    steps:
      - id: gen
        type: betl.gen_strings
        n: 3
        prefix: hello-
      - id: write
        type: csv.write
        from: gen
        path: ${params.out}
```

Run:

```sh
# Linux/macOS:
./betl-container/betl run hello.betl.yml --param out=hello.csv

# Windows:
betl-dotnet run hello.betl.yml --param out=hello.csv
```

You should get a 4-line CSV (`s` header + `hello-0` through
`hello-2`).

---

## Uninstall

```sh
# Linux/macOS:
podman rmi betl:dev                       # or `docker rmi`
rm -rf betl-tools/

# Windows:
dotnet tool uninstall -g Betl.Dotnet
dotnet tool uninstall -g Betl.Dtsx2Yaml
Remove-Item -Recurse -Force betl-tools\betl-yaml-ui\.venv
```

---

## Troubleshooting

**`build.sh` says "no container runtime found".** Install podman
(`brew install podman` on macOS, `apt install podman` on Debian/Ubuntu)
or docker, then re-run.

**Container build doesn't pick up new betl-native commits.** Docker
caches the `git fetch` layer by the resolved SHA. `build.sh` defaults to
the current master HEAD, so the first re-run after an upstream push
naturally busts the cache. If for some reason it doesn't, pass
`--no-cache` or an explicit `BETL_NATIVE_REF=<sha>`.

**`dotnet tool install` says ".NET 8 runtime not installed".** Either
install the runtime (`winget install Microsoft.DotNet.Runtime.8`) or
let `Betl.Dtsx2Yaml`'s `<RollForward>LatestMajor</RollForward>` carry
it forward to whatever major you have (.NET 9 / 10).

**`run.ps1` fails with "Python 3.10+ not found".** Install Python via
`winget install Python.Python.3.12` (any 3.10–3.13 works), then re-run.

**`betl ui` opens but Convert DTSX button is dead.** The UI discovers
the converter via `BETL_DTSX2YAML`, PATH (`betl-dtsx2yaml`), then a
local publish dir. On Windows make sure
`dotnet tool install -g Betl.Dtsx2Yaml` succeeded; on Linux the
containerized path bakes it into the image, so you shouldn't see this
unless the container build itself failed.
