# Artemis installer -- Windows (PowerShell 5.1+)
# Usage:
#   .\install.ps1                    Install to %LOCALAPPDATA%\Artemis (no admin)
#   .\install.ps1 -Prefix C:\Tools   Install to C:\Tools\bin
#   .\install.ps1 -System            Install to "C:\Program Files\Artemis" (requires admin)
#   .\install.ps1 -Uninstall         Remove a previously installed Artemis

param(
    [string] $Prefix    = "",
    [switch] $System,
    [switch] $Uninstall
)

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------------ helpers
function Write-Info { param($msg) Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-OK   { param($msg) Write-Host "v  $msg"  -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "!  $msg"  -ForegroundColor Yellow }
function Write-Fail { param($msg) Write-Host "x  $msg"  -ForegroundColor Red; exit 1 }

# ------------------------------------------------------------------ prefix
if ($Prefix -eq "") {
    if ($System) {
        $Prefix = Join-Path $env:ProgramFiles "Artemis"
    } else {
        $Prefix = Join-Path $env:LOCALAPPDATA "Artemis"
    }
}
# Normalise: resolve any trailing slashes / mixed separators.
$Prefix = [System.IO.Path]::GetFullPath($Prefix)
$BinDir = Join-Path $Prefix "bin"

# ------------------------------------------------------------------ uninstall
if ($Uninstall) {
    Write-Info "Uninstalling Artemis from $BinDir"
    $names = @("artemis.exe", "aciso.exe",
               "atc.cmd", "atx.cmd", "arc.cmd", "aciso.cmd",
               "atc.exe", "atx.exe")   # legacy .exe stubs (safety net)
    foreach ($name in $names) {
        $p = Join-Path $BinDir $name
        if (Test-Path -LiteralPath $p) {
            Remove-Item -LiteralPath $p -Force
            Write-OK "Removed $p"
        }
    }

    # Remove BinDir from user (or machine) PATH.
    $scope       = if ($System) { "Machine" } else { "User" }
    $currentPath = [Environment]::GetEnvironmentVariable("Path", $scope)
    if ($currentPath -and $currentPath.Split(";") -contains $BinDir) {
        $newPath = ($currentPath.Split(";") | Where-Object { $_ -ne $BinDir }) -join ";"
        [Environment]::SetEnvironmentVariable("Path", $newPath, $scope)
        Write-OK "Removed $BinDir from $scope PATH"
    }

    # Remove ARTEMIS_HOME.
    $scope2 = if ($System) { "Machine" } else { "User" }
    if ([Environment]::GetEnvironmentVariable("ARTEMIS_HOME", $scope2) -ne $null) {
        [Environment]::SetEnvironmentVariable("ARTEMIS_HOME", $null, $scope2)
        Write-OK "Removed ARTEMIS_HOME from $scope2 environment"
    }

    Write-OK "Uninstall complete."
    exit 0
}

# ------------------------------------------------------------------ find binaries
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Find-Tool {
    param([string]$Name)
    $exe = "$Name.exe"
    $candidates = @(
        (Join-Path $ScriptDir $exe),
        (Join-Path $ScriptDir "build\$exe"),
        (Join-Path $ScriptDir "build\Release\$exe"),
        (Join-Path $ScriptDir "build\Debug\$exe"),
        (Join-Path $ScriptDir "build\cross\windows\$exe")
    )
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { return $c }
    }
    return $null
}

$ArtemisBin = Find-Tool "artemis"
$AcisoBin   = Find-Tool "aciso"

# ------------------------------------------------------------------ build if needed
if (-not $ArtemisBin -or -not $AcisoBin) {
    Write-Warn "One or more pre-built binaries not found -- building from source."

    if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
        Write-Fail "cmake not found. Install cmake 3.20+ from https://cmake.org/download/"
    }

    # Locate LLVM cmake dir.
    $LlvmDir = $null
    foreach ($cmd in @("llvm-config", "llvm-config-18", "llvm-config-17")) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) {
            try {
                $out = & $cmd --cmakedir 2>$null
                if ($out) { $LlvmDir = $out.Trim(); break }
            } catch {}
        }
    }
    if (-not $LlvmDir) {
        foreach ($p in @(
                "C:\msys64\mingw64\lib\cmake\llvm",
                "C:\Program Files\LLVM\lib\cmake\llvm",
                "C:\LLVM\lib\cmake\llvm")) {
            if (Test-Path $p) { $LlvmDir = $p; break }
        }
    }
    if (-not $LlvmDir) {
        Write-Fail "LLVM not found. Install LLVM 17+ and add llvm-config to PATH."
    }

    $BuildDir = Join-Path $ScriptDir "_install_build"

    Write-Info "Configuring build..."
    & cmake -S "$ScriptDir" -B "$BuildDir" `
            -DCMAKE_BUILD_TYPE=Release `
            "-DLLVM_DIR=$LlvmDir" `
            "-DCMAKE_INSTALL_PREFIX=$Prefix" | Out-Null

    Write-Info "Building (this may take a minute)..."
    & cmake --build "$BuildDir" `
            --target artemis --target aciso `
            --parallel | Out-Null

    $ArtemisBin = Join-Path $BuildDir "artemis.exe"
    $AcisoBin   = Join-Path $BuildDir "aciso.exe"

    if (-not (Test-Path -LiteralPath $ArtemisBin)) {
        Write-Fail "Build failed -- artemis.exe not produced."
    }
    if (-not (Test-Path -LiteralPath $AcisoBin)) {
        Write-Fail "Build failed -- aciso.exe not produced."
    }
}

Write-OK "Using artemis: $ArtemisBin"
Write-OK "Using aciso:   $AcisoBin"

# ------------------------------------------------------------------ elevation check
if ($System) {
    $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    $isAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Warn "System install requires Administrator. Re-launching elevated..."
        $scriptPath   = $MyInvocation.MyCommand.Path
        $relaunchArgs = "-ExecutionPolicy Bypass -File `"$scriptPath`" -System"
        if ($Prefix -ne (Join-Path $env:ProgramFiles "Artemis")) {
            $relaunchArgs += " -Prefix `"$Prefix`""
        }
        Start-Process powershell -ArgumentList $relaunchArgs -Verb RunAs
        exit 0
    }
}

# ------------------------------------------------------------------ install dir
if (-not (Test-Path -LiteralPath $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}

# ------------------------------------------------------------------ copy binaries
Write-Info "Installing to $BinDir"

Copy-Item -LiteralPath "$ArtemisBin" -Destination (Join-Path $BinDir "artemis.exe") -Force
Write-OK "Installed artemis.exe"

Copy-Item -LiteralPath "$AcisoBin" -Destination (Join-Path $BinDir "aciso.exe") -Force
Write-OK "Installed aciso.exe"

# ------------------------------------------------------------------ CMD wrappers
# Write wrappers with CRLF line endings and ASCII encoding so they work in
# every CMD/terminal variant, including those with narrow code pages.
# Quoting the binary name handles install paths that contain spaces.
$crlf = [char]13 + [char]10

$wrappers = @{
    "atc.cmd"   = "@echo off$crlf`"artemis`" %*$crlf"
    "atx.cmd"   = "@echo off$crlf`"artemis`" %*$crlf"
    "arc.cmd"   = "@echo off$crlf`"artemis`" %*$crlf"
    "aciso.cmd" = "@echo off$crlf`"aciso`" %*$crlf"
}

foreach ($entry in $wrappers.GetEnumerator()) {
    $dest = Join-Path $BinDir $entry.Key
    [System.IO.File]::WriteAllText($dest, $entry.Value, [System.Text.Encoding]::ASCII)
    Write-OK "Created $($entry.Key)"
}

# ------------------------------------------------------------------ ARTEMIS_HOME
# aciso uses ARTEMIS_HOME to find the artemis compiler when PATH lookup fails.
# We point it at $Prefix so aciso resolves $Prefix\bin\artemis.exe.
$scope = if ($System) { "Machine" } else { "User" }
[Environment]::SetEnvironmentVariable("ARTEMIS_HOME", $Prefix, $scope)
Write-OK "Set ARTEMIS_HOME=$Prefix ($scope)"

# ------------------------------------------------------------------ PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", $scope)
if (-not $currentPath) { $currentPath = "" }

# Split on ';', filter empties, check membership, rebuild — avoids accidental
# double-semicolons that can confuse some tools on long PATH values.
$pathParts = $currentPath.Split(";") | Where-Object { $_ -ne "" }
if ($pathParts -notcontains $BinDir) {
    Write-Info "Adding $BinDir to $scope PATH..."
    $newPath = ($BinDir + ";" + ($pathParts -join ";")).TrimEnd(";")
    [Environment]::SetEnvironmentVariable("Path", $newPath, $scope)
    Write-OK "Added $BinDir to $scope PATH"
    Write-Warn "Restart your terminal for PATH and ARTEMIS_HOME changes to take effect."
} else {
    Write-OK "$BinDir is already on PATH"
}

# ------------------------------------------------------------------ verify
$env:Path         = $BinDir + ";" + $env:Path
$env:ARTEMIS_HOME = $Prefix

try {
    $ver = & (Join-Path $BinDir "artemis.exe") --version 2>&1 | Select-Object -First 1
    Write-OK "$ver is ready."
} catch {
    Write-Info "artemis installed. Open a new terminal to use it."
}

if (Test-Path -LiteralPath (Join-Path $BinDir "aciso.exe")) {
    Write-OK "aciso is ready."
} else {
    Write-Warn "aciso.exe was not found after install — check build output."
}

Write-OK "Artemis toolchain installation complete."
