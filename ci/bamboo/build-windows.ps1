# ----------------------------------------------------------------------
# Numenta Platform for Intelligent Computing (NuPIC)
# Copyright (C) 2016, Numenta, Inc.  Unless you have purchased from
# Numenta, Inc. a separate commercial license for this software code, the
# following terms and conditions apply:
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero Public License version 3 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Affero Public License for more details.
#
# You should have received a copy of the GNU Affero Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# http://numenta.org/licenses/
# ----------------------------------------------------------------------

# Builds and tests the nupic.bindings python extension using Release build
# type.
#
# ASUMPTIONS:
#          1. Building via Numenta Vagrant Task using Vagrant image
#             bamboo-vagrant-windows-1.x.x.
#
#          2. nupic.core root is the current directory on entry.
#
#          3. Expects a pristine nupic.core source tree without any remnant
#             build artifacts from prior build attempts. Otherwise, the
#             behavior is undefined.
#
# NOTES: Based on examples in comments of
#        https://github.com/NumentaCorp/infrastructure/pull/376
#
# OUTPUTS:
#   nupic.bindings wheel: On success, the resulting wheel will be located in
#                         the subdirectory nupic_bindings_wheelhouse of the
#                         source tree's root directory.
#
#   Test results: nupic.bindings test results will be located in the
#                 subdirectory test_results of the source tree's root directory
#                 with the the following content:
#
#                 junit-test-results.xml
#                 htmlcov/

$ErrorActionPreference = "Stop"

$NupicCoreRootDir = $(get-location).Path

# Use this function to wrap external commands for powershell error-checking.
#
# This is necessary so that `$ErrorActionPreference = "Stop"` will have the
# desired effect.
#
# Returns True if command's $LastExitCode was 0, False otherwise
#
# Usage: WrapCmd { cmd arg1 arg2 ... }
#
function WrapCmd
{
  [CmdletBinding()]

  param (
    [Parameter(Position=0, Mandatory=1)]
    [scriptblock]$Command,
    [Parameter(Position=1, Mandatory=0)]
    [string]$ErrorMessage = "ERROR: Command failed.`n$Command"
  )
  & $Command
  if ($LastExitCode -eq 0) {
    return $true
  }
  else {
    #throw "WrapCmd: $ErrorMessage"
    Write-Error "WrapCmd: $ErrorMessage"
    return $false
  }
}

# Remove sh.exe from the paths (CMake doesn't like it)
Write-Host "ZZZ PATH=" $env:PATH
Write-Host "ZZZ Looking for sh BEFORE cleaning PATH"

# Validate expectation that sh.exe is in PATH prior to its removal
WrapCmd { where.exe sh }

$env:PATH = $env:PATH.Replace('C:\Program Files (x86)\Git\bin','')
$env:PATH = $env:PATH.Replace('C:\Program Files\Git\usr\bin','')
$env:PATH = $env:PATH.Replace('C:\Program Files\OpenSSH\bin','')
$env:PATH = $env:PATH.Replace('C:\MinGW\msys\1.0\bin','')

Write-Host "Checking to make sure that sh command was removed from PATH"
&where.exe sh
if ($LastExitCode -eq 0) {
  throw "Failed to remove sh.exe from PATH."
}

Write-Host "ZZZ DONE Looking for sh AFTER cleaning PATH"


# Make unix-compatible patch.exe available to the build by copying it from
# Git\usr\bin (that we remove from PATH) to another directory and adding it to
# PATH; the reason we copy it is that logic below removes
# C:\Program Files\Git\usr\bin from Path to avoid build issue resulting from
# sh.exe being on the path

Write-Host "Checking that patch command was not present already."
&where.exe patch
if ($LastExitCode -eq 0) {
    throw "patch command was already available."
}

mkdir "C:\Program Files\PatchFromGit"
copy "C:\Program Files\Git\usr\bin\patch.exe" "C:\Program Files\PatchFromGit"
copy "C:\Program Files\Git\usr\bin\msys*.dll" "C:\Program Files\PatchFromGit"
$env:PATH = 'C:\Program Files\PatchFromGit;' + $env:PATH
WrapCmd { where.exe patch }


# Verify that gcc and g++ are available and log their location and version
Write-Host "Checking tools."
WrapCmd { where.exe gcc }
WrapCmd { gcc --version }
WrapCmd { where.exe g++ }
WrapCmd { g++ --version }

WrapCmd { where.exe python }
WrapCmd { python --version }

Write-Host "PYTHONHOME=$env:PYTHONHOME"
Write-Host "PYTHONPATH=$env:PYTHONPATH"

WrapCmd { where.exe pip }
WrapCmd { pip --version }

WrapCmd { where.exe wheel }
WrapCmd { wheel version }

WrapCmd { python -c "import numpy; print 'numpy version:', numpy.__version__, numpy" }
WrapCmd { python -c "import numpy.core.multiarray; print numpy.core.multiarray" }

WrapCmd { pip list }

# Dump env vars
Get-ChildItem Env:


# Setup MinGW GCC as a valid distutils compiler
copy ".\external\windows64-gcc\bin\distutils.cfg" "$env:PYTHONHOME\Lib\distutils.cfg"

# Build nupic.core
mkdir .\build\release
mkdir .\build\scripts
$env:NUPIC_DEPLOYMENT_BUILD = 1

pushd .\build\scripts

# ZZZ remove diagnostics
dir ..\..
dir ..\..\external
dir ..\..\src
# ZZZ end diagnostics


# Configure for non-debug build
$env:CC = "gcc"
$env:CXX = "g++"

Write-Host "Configuring build of nupic.bindings via cmake."
WrapCmd {
  cmake `
    -G "MinGW Makefiles"  `
    -DCMAKE_BUILD_TYPE="Release" `
    -DCMAKE_INSTALL_PREFIX:PATH="..\release" `
    -DNUPIC_BUILD_PYEXT_MODULES="ON" `
    -DPY_EXTENSIONS_DIR:PATH="..\..\bindings\py\nupic\bindings" `
    "..\.."
}

# Make nupic.core from non-debug configuration
Write-Host "Building nupic.bindings."
WrapCmd { cmake --build . --target install --config Release }

popd


# Create a python wheel in the destination wheelhouse
Write-Host "Building nupic.bindings python wheel."
WrapCmd {
  python setup.py bdist_wheel `
    --dist-dir "$($NupicCoreRootDir)\nupic_bindings_wheelhouse"
}


#
# Run tests
#

# Install nupic.bindings before running c++ tests; py_region_test depends on it
Write-Host "Installing from built nupic.bindings wheel."

WrapCmd { pip --version }
WrapCmd { wheel version }
dir
dir -Filter *.whl -Recurse | Select Fullname
dir ".\nupic_bindings_wheelhouse"

WrapCmd { python -c "import numpy; print 'numpy version:', numpy.__version__, numpy" }
WrapCmd { python -c "import numpy.core.multiarray; print numpy.core.multiarray" }

# Get path of nupic.bindings wheel
$NupicBindingsWheel = `
  (Get-ChildItem .\nupic_bindings_wheelhouse\nupic.bindings-*.whl)[0].FullName

# Install nupic.bindings
WrapCmd { pip install $NupicBindingsWheel }

WrapCmd { python -c "import numpy; print 'numpy version:', numpy.__version__, numpy" }
WrapCmd { python -c "import numpy.core.multiarray; print numpy.core.multiarray" }


# Run python nupic.bindings tests

# So that py.test will deposit its artifacts in test_results
mkdir .\test_results
pushd .\test_results

Write-Host "Running nupic.bindings python tests."

WrapCmd { python ..\setup.py test }

popd


# Run C++ nupic.core tests
pushd .\build\release\bin
Write-Host "Running nupic.core C++ tests."

Write-Host "ZZZ Running import_numpy_test.exe..."
WrapCmd { .\import_numpy_test.exe }
Write-Host "ZZZ Completed import_numpy_test.exe"

WrapCmd { .\py_region_test.exe }
WrapCmd { .\connections_performance_test.exe }
WrapCmd { .\cpp_region_test.exe }
WrapCmd { .\helloregion.exe }
WrapCmd { .\hello_sp_tp.exe }
WrapCmd { .\prototest.exe }
WrapCmd { .\unit_tests.exe }
popd
