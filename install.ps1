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
        $Prefix = "C:\Program Files\Artemis"
    } else {
        $Prefix = Join-Path $env:LOCALAPPDATA "Artemis"
    }
}
$BinDir = Join-Path $Prefix "bin"

# ------------------------------------------------------------------ uninstall
if ($Uninstall) {
    Write-Info "Uninstalling Artemis from $BinDir"
    $names = @("artemis.exe", "atc.exe", "atc.cmd", "atx.exe", "atx.cmd")
    foreach ($name in $names) {
        $p = Join-Path $BinDir $name
        if (Test-Path $p) {
            Remove-Item $p -Force
            Write-OK "Removed $p"
        }
    }
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -and $userPath.Contains($BinDir)) {
        $parts   = $userPath -split ";"
        $newPath = ($parts | Where-Object { $_ -ne $BinDir }) -join ";"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-OK "Removed $BinDir from user PATH"
    }
    Write-OK "Uninstall complete."
    exit 0
}

# ------------------------------------------------------------------ find binary
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Find-Binary {
    $c = Join-Path $ScriptDir "artemis.exe"
    if (Test-Path $c) { return $c }
    $subdirs = @("build", "build\Release", "build\Debug")
    foreach ($d in $subdirs) {
        $c = Join-Path $ScriptDir "$d\artemis.exe"
        if (Test-Path $c) { return $c }
    }
    $c = Join-Path $ScriptDir "build\cross\windows\artemis.exe"
    if (Test-Path $c) { return $c }
    return $null
}

$Binary = Find-Binary

# ------------------------------------------------------------------ build if needed
if (-not $Binary) {
    Write-Warn "Pre-built artemis.exe not found -- attempting to build from source."

    $cmakeCmd = Get-Command cmake -ErrorAction SilentlyContinue
    if (-not $cmakeCmd) {
        Write-Fail "cmake not found. Install cmake 3.20+ from https://cmake.org/download/"
    }

    # Locate LLVM cmake dir via llvm-config.
    $LlvmDir  = $null
    $llvmCmds = @("llvm-config", "llvm-config-18", "llvm-config-17")
    foreach ($cmd in $llvmCmds) {
        $found = Get-Command $cmd -ErrorAction SilentlyContinue
        if ($found) {
            try {
                $out = & $cmd --cmakedir 2>$null
                if ($out) { $LlvmDir = $out.Trim(); break }
            } catch { }
        }
    }

    if (-not $LlvmDir) {
        $wellKnown = @(
            "C:\msys64\mingw64\lib\cmake\llvm",
            "C:\Program Files\LLVM\lib\cmake\llvm",
            "C:\LLVM\lib\cmake\llvm"
        )
        foreach ($p in $wellKnown) {
            if (Test-Path $p) { $LlvmDir = $p; break }
        }
    }

    if (-not $LlvmDir) {
        Write-Fail "LLVM not found. Install LLVM 17+ and add llvm-config to PATH. See: https://github.com/llvm/llvm-project/releases"
    }

    $BuildDir    = Join-Path $ScriptDir "_install_build"
    $configArgs  = @("-S", $ScriptDir, "-B", $BuildDir,
                     "-DCMAKE_BUILD_TYPE=Release",
                     "-DLLVM_DIR=$LlvmDir",
                     "-DCMAKE_INSTALL_PREFIX=$Prefix")
    $buildArgs   = @("--build", $BuildDir, "--target", "artemis", "--parallel")

    Write-Info "Configuring build..."
    & cmake @configArgs | Out-Null

    Write-Info "Building (this may take a minute)..."
    & cmake @buildArgs | Out-Null

    $Binary = Join-Path $BuildDir "artemis.exe"
    if (-not (Test-Path $Binary)) {
        Write-Fail "Build failed -- artemis.exe not produced."
    }
}

Write-OK "Using binary: $Binary"

# ------------------------------------------------------------------ install dir
if (-not (Test-Path $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}

# Elevation check for system install.
if ($System) {
    $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
    $isAdmin   = $principal.IsInRole($adminRole)
    if (-not $isAdmin) {
        Write-Warn "System install requires Administrator. Re-launching elevated..."
        $scriptPath = $MyInvocation.MyCommand.Path
        $relaunchArgs = "-ExecutionPolicy Bypass -File `"$scriptPath`" -System"
        if ($Prefix -ne "C:\Program Files\Artemis") {
            $relaunchArgs += " -Prefix `"$Prefix`""
        }
        Start-Process powershell -ArgumentList $relaunchArgs -Verb RunAs
        exit 0
    }
}

# ------------------------------------------------------------------ copy files
Write-Info "Installing to $BinDir"
Copy-Item $Binary (Join-Path $BinDir "artemis.exe") -Force
Write-OK "Installed artemis.exe"

# Create atc.cmd and atx.cmd wrappers.
$wrapperContent = "@echo off" + [char]13 + [char]10 + "artemis %*" + [char]13 + [char]10
$aliases = @("atc", "atx")
foreach ($alias in $aliases) {
    $wrapper = Join-Path $BinDir "$alias.cmd"
    [System.IO.File]::WriteAllText($wrapper, $wrapperContent, [System.Text.Encoding]::ASCII)
    Write-OK "Created $alias.cmd"
}

# ------------------------------------------------------------------ PATH
$scope       = if ($System) { "Machine" } else { "User" }
$currentPath = [Environment]::GetEnvironmentVariable("Path", $scope)
if (-not $currentPath) { $currentPath = "" }

if (-not $currentPath.Contains($BinDir)) {
    Write-Info "Adding $BinDir to $scope PATH..."
    $newPath = $BinDir + ";" + $currentPath.TrimEnd(";")
    [Environment]::SetEnvironmentVariable("Path", $newPath, $scope)
    Write-OK "Added $BinDir to $scope PATH"
    Write-Warn "Restart your terminal for PATH changes to take effect."
} else {
    Write-OK "$BinDir is already on PATH"
}

# ------------------------------------------------------------------ verify
$env:Path = $BinDir + ";" + $env:Path
try {
    $ver = & "$BinDir\artemis.exe" --version 2>&1 | Select-Object -First 1
    Write-OK "$ver is ready."
} catch {
    Write-Info "Installation complete. Welcome to Artemis."
}
