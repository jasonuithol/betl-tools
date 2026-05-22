# betl-yaml-ui/run.ps1 — launch the pipeline YAML viewer/editor on Windows.
#
# Usage:
#   .\run.ps1 [server.py args...]
#
# First invocation creates .venv\ next to this script and installs
# fastapi + uvicorn. Subsequent runs reuse it. Pass any extra args
# through to server.py (e.g. --root C:\some\dir --port 9000).
#
# Sibling of run.sh; the two are kept in sync. Linux/macOS users run
# run.sh, Windows users run this file.

$ErrorActionPreference = 'Stop'

$here   = $PSScriptRoot
$venv   = Join-Path $here '.venv'
$python = Join-Path $venv 'Scripts\python.exe'

if (-not (Test-Path $python)) {
    Write-Host "[run] creating venv at $venv"
    $sysPython = Get-Command python -ErrorAction SilentlyContinue
    if (-not $sysPython) {
        $sysPython = Get-Command py -ErrorAction SilentlyContinue
        if (-not $sysPython) {
            Write-Error "Python 3.10+ not found. Install via 'winget install Python.Python.3.12'."
            exit 1
        }
    }
    & $sysPython.Source -m venv $venv
    # Invoke pip via `python -m pip` rather than pip.exe so that the
    # self-upgrade step doesn't trip the Windows file-lock issue (pip.exe
    # can't rewrite itself while it's running).
    & $python -m pip install --quiet --upgrade pip
    & $python -m pip install --quiet fastapi uvicorn
}

& $python (Join-Path $here 'server.py') @args
