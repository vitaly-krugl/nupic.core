:: Remove sh.exe from the paths (CMake doesn't like it)
set PATH=%PATH:C:\Program Files (x86)\Git\bin;=%
set PATH=%PATH:C:\Program Files\Git\usr\bin;=%
set PATH=%PATH:C:\Program Files\OpenSSH\bin;=%
set PATH=%PATH:C:\MinGW\msys\1.0\bin;=%

:: Make unix-compatible patch.exe available to the build by copying it from
:: Git\usr\bin (that we remove from PATH) to another directory and adding it to
:: PATH; the reason we copy it is that logic below removes
:: C:\Program Files\Git\usr\bin from Path to avoid build issue resulting from
:: sh.exe being on the path
mkdir "C:\Program Files\PatchFromGit"
copy "C:\Program Files\Git\usr\bin\patch.exe" "C:\Program Files\PatchFromGit"
copy "C:\Program Files\Git\usr\bin\msys*.dll" "C:\Program Files\PatchFromGit"
set PATH=C:\Program Files\PatchFromGit;%PATH%

pushd nupic.core

:: Setup MinGW GCC as a valid distutils compiler
copy external\windows64-gcc\bin\distutils.cfg %PYTHONHOME%\Lib\distutils.cfg

:: Build nupic.core
mkdir build\release
mkdir build\scripts
set NUPIC_DEPLOYMENT_BUILD=1

pushd build\scripts
cmake -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release  -DCMAKE_INSTALL_PREFIX=..\release -DPY_EXTENSIONS_DIR=..\..\bindings\py\nupic\bindings ..\..
cmake --build . --target install --config Release
popd

python setup.py sdist bdist bdist_wheel

:: Run tests

:: Note: this also installs nupic.bindigns, which is subsequently needed by
:: py_region_test.exe
python setup.py test

pushd build\release\bin
echo "ZZZ Running py_region_test.exe"
py_region_test.exe
echo "ZZZ Running connections_performance_test.exe"
connections_performance_test.exe
cpp_region_test.exe
helloregion.exe
hello_sp_tp.exe
prototest.exe
unit_tests.exe
popd

popd