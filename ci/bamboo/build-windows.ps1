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


# Remove sh.exe from the paths (CMake doesn't like it)
Write-Host "ZZZ PATH=" $env:PATH
Write-Host "ZZZ Looking for sh BEFORE cleaning PATH"
where.exe sh

Write-Host "ZZZ  cleaning PATH"
$env:PATH = $env:PATH.Replace('C:\Program Files (x86)\Git\bin','')
$env:PATH = $env:PATH.Replace('C:\Program Files\Git\usr\bin','')
$env:PATH = $env:PATH.Replace('C:\Program Files\OpenSSH\bin','')
$env:PATH = $env:PATH.Replace('C:\MinGW\msys\1.0\bin','')

Write-Host "ZZZ Looking for sh AFTER cleaning PATH"
where.exe sh
Write-Host "ZZZ DONE Looking for sh AFTER cleaning PATH"


# Make unix-compatible patch.exe available to the build by copying it from
# Git\usr\bin (that we remove from PATH) to another directory and adding it to
# PATH; the reason we copy it is that logic below removes
# C:\Program Files\Git\usr\bin from Path to avoid build issue resulting from
# sh.exe being on the path
mkdir "C:\Program Files\PatchFromGit"
copy "C:\Program Files\Git\usr\bin\patch.exe" "C:\Program Files\PatchFromGit"
copy "C:\Program Files\Git\usr\bin\msys*.dll" "C:\Program Files\PatchFromGit"
$env:PATH = 'C:\Program Files\PatchFromGit;' + $env:PATH

# Setup MinGW GCC as a valid distutils compiler
copy ".\external\windows64-gcc\bin\distutils.cfg" "$env:PYTHONHOME\Lib\distutils.cfg"

# Build nupic.core
mkdir .\build\release
mkdir .\build\scripts
set NUPIC_DEPLOYMENT_BUILD=1

pushd .\build\scripts

# ZZZ remove diagnostics
dir ..\..
dir ..\..\external
dir ..\..\src
# ZZZ end diagnostics

# Configure for non-debug build
cmake `
  -G "MinGW Makefiles"  `
  -DCMAKE_BUILD_TYPE=Release `
  -DCMAKE_INSTALL_PREFIX=..\release `
  -DPY_EXTENSIONS_DIR=..\..\bindings\py\nupic\bindings `
  ..\..

# Make nupic.core from non-debug configuration
cmake --build . --target install --config Release
popd

# Create a python wheel in the destination wheelhouse
python setup.py bdist_wheel --dist-dir .\nupic_bindings_wheelhouse

#
# Run tests
#

# Install nupic.bindings before running c++ tests; py_region_test depends on it
pip install --ignore-installed .\nupic_bindings_wheelhouse\nupic.bindings-*.whl

pushd build\release\bin
connections_performance_test.exe
cpp_region_test.exe
helloregion.exe
hello_sp_tp.exe
prototest.exe
py_region_test.exe
unit_tests.exe
popd

# So that py.test will deposit its artifacts in test_results
mkdir .\test_results
pushd .\test_results

python ..\setup.py test

popd
