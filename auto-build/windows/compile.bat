REM Execute this batch file in "x86 Native Tools Command Prompt for VS 2019" console
REM If you have a Professional or Community edition then update the path below C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise

echo off

set root=%cd%

rd /s /q ThirdParty
rd /s /q Libraries
mkdir ThirdParty
mkdir Libraries

cd ThirdParty

if not exist "Strawberry" (
    echo Downloading perl...
    curl -o strawberry.zip -LO https://strawberryperl.com/download/5.32.1.1/strawberry-perl-5.32.1.1-64bit-portable.zip
    unzip -q strawberry.zip -d Strawberry
    del strawberry.zip
) else (
    echo Using Strawberry...
)

if not exist "%cd%\Python27" (
    echo Downloading python...
    curl -o install.msi https://www.python.org/ftp/python/2.7.8/python-2.7.8.amd64.msi
    msiexec /i install.msi /quiet /qn /norestart TARGETDIR="%cd%\Python27"
    del install.msi
) else (
    echo Using "%cd%\Python27"...
)
if not exist "cmake" (
    echo Downloading cmake...
    curl -o cmake.zip -LO https://github.com/Kitware/CMake/releases/download/v3.19.4/cmake-3.19.4-win64-x64.zip
    unzip -q cmake.zip -d cmake
    del cmake.zip
) else (
    echo Using cmake...
)

if not exist "NASM" (
    echo Downloading nasm...
    curl -o nasm.zip https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/win64/nasm-2.15.05-win64.zip
    unzip -q nasm.zip -d NASM
    del nasm.zip
) else (
    echo Using NASM...
)

if not exist "yasm" (
    echo Downloading yasm...
    curl -o yasm.zip http://www.tortall.net/projects/yasm/releases/vsyasm-1.3.0-win64.zip
    unzip -q yasm.zip -d yasm
    del yasm.zip
) else (
    echo Using yasm...
)

if not exist "Ninja" (
    echo Downloading ninja...
    curl -o ninja.zip -LO https://github.com/ninja-build/ninja/releases/download/v1.10.2/ninja-win.zip
    unzip -q ninja.zip -d Ninja
    del ninja.zip
) else (
    echo Using Ninja...
)

if not exist "jom" (
    echo Downloading jom...
    curl -o jom.zip http://www.mirrorservice.org/sites/download.qt-project.org/official_releases/jom/jom_1_1_3.zip
    unzip -q jom.zip -d jom
    del jom.zip
) else (
    echo Using jom...
)

if not exist "patches" (
    echo Cloning patches...
    git clone https://github.com/desktop-app/patches.git
    cd patches
    git checkout 10aeaf6
    cd ..
    git clone https://chromium.googlesource.com/external/gyp
    cd gyp
    git checkout 9f2a7bb1
    git apply ../patches/gyp.diff
    cd ..
) else (
    echo Using patches...
)

cd ..

SET PATH=%cd%\ThirdParty\Strawberry\perl\bin;%cd%\ThirdParty\NASM\nasm-2.15.05;%cd%\ThirdParty\Python27;%cd%\ThirdParty\jom;%cd%\ThirdParty\cmake\cmake-3.19.4-win64-x64\bin;%cd%\ThirdParty\yasm;%cd%\ThirdParty\gyp;%cd%\ThirdParty\Ninja;%PATH%

echo %PATH%

cd Libraries
SET LibrariesPath=%cd%

SET GYP_MSVS_OVERRIDE_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise
SET GYP_MSVS_VERSION=2019

if not exist "openssl_1_1_1" (
    git clone https://github.com/openssl/openssl.git openssl_1_1_1
    cd openssl_1_1_1
    git checkout OpenSSL_1_1_1i

    perl Configure no-shared debug-VC-WIN32
    nmake
    mkdir out32.dbg
    move libcrypto.lib out32.dbg
    move libssl.lib out32.dbg
    move ossl_static.pdb out32.dbg\ossl_static
    nmake clean
    move out32.dbg\ossl_static out32.dbg\ossl_static.pdb

    perl Configure no-shared VC-WIN32
    nmake
    mkdir out32
    move libcrypto.lib out32
    move libssl.lib out32
    move ossl_static.pdb out32
    cd ..
) else (
    echo Using openssl_1_1_1...
)


if not exist "patches" (
    git clone https://github.com/desktop-app/patches.git
    cd patches
    git checkout 10aeaf6
    cd ..
) else (
    echo Using patches...
)


if not exist "range-v3" (
    git clone --branch 0.10.0 https://github.com/ericniebler/range-v3 range-v3
) else (
    echo Using range-v3...
)


if not exist "zlib" (
    git clone https://github.com/desktop-app/zlib.git
    cd zlib\contrib\vstudio\vc14
    msbuild zlibstat.vcxproj /property:Configuration=Debug /p:PlatformToolset=v142 /p:platform=x86 /p:WindowsTargetPlatformVersion=10.0.19041.0
    msbuild zlibstat.vcxproj /property:Configuration=ReleaseWithoutAsm /p:PlatformToolset=v142 /p:platform=x86 /p:WindowsTargetPlatformVersion=10.0.19041.0
    cd ..\..\..\..
) else (
    echo Using zlib...
)

if not exist "secp256k1" (
    git clone https://github.com/bitcoin-core/secp256k1.git
    cd secp256k1
    git checkout v0.3.2
    cmake -G "Visual Studio 16 2019" -A x64 -S . -B build -DSECP256K1_ENABLE_MODULE_RECOVERY=ON -DBUILD_SHARED_LIBS=OFF
    cmake --build build --config Debug
    cmake --build build --config Release
    cd ..
) else (
    echo Using secp256k1...
)


if not exist "lz4" (
    git clone https://github.com/lz4/lz4.git
    cd lz4
    git checkout v1.9.4
    cd build\VS2017\liblz4
    msbuild liblz4.vcxproj /p:Configuration=Release /p:platform=x64 -p:PlatformToolset=v142
    IF %errorlevel% NEQ 0 (
      echo Can't install lz4
      exit /b %errorlevel%
    )
    cd ..\..\..\..
) else (
    echo Using lz4...
)


if not exist "libsodium" (
    curl  -Lo libsodium-1.0.18-stable-msvc.zip https://download.libsodium.org/libsodium/releases/libsodium-1.0.18-stable-msvc.zip
    IF %errorlevel% NEQ 0 (
      echo Can't download libsodium
      exit /b %errorlevel%
    )
    unzip libsodium-1.0.18-stable-msvc.zip
) else (
    echo Using libsodium...
)

SET SODIUM_DIR=%LibrariesPath%\libsodium


if not exist "lzma" (
    git clone https://github.com/desktop-app/lzma.git
    cd lzma\C\Util\LzmaLib
    msbuild LzmaLib.sln /property:Configuration=Debug /p:PlatformToolset=v142 /p:platform=x86 /p:WindowsTargetPlatformVersion=10.0.19041.0
    msbuild LzmaLib.sln /property:Configuration=Release /p:PlatformToolset=v142 /p:platform=x86 /p:WindowsTargetPlatformVersion=10.0.19041.0
    cd ..\..\..\..
) else (
    echo Using lzma...
)

if not exist "breakpad" (
    git clone https://github.com/google/breakpad
    cd breakpad
    git checkout a1dbcdcb43
    git apply ../patches/breakpad.diff
    cd src
    git clone https://github.com/google/googletest testing
    cd client\windows
    call gyp --no-circular-check breakpad_client.gyp --format=ninja
    cd ..\..
    ninja -C out/Debug common crash_generation_client exception_handler
    ninja -C out/Release common crash_generation_client exception_handler
    cd tools\windows\dump_syms
    call gyp dump_syms.gyp
    msbuild dump_syms.vcxproj /property:Configuration=Debug /p:PlatformToolset=v142 /p:platform=x86 /p:WindowsTargetPlatformVersion=10.0.19041.0
    msbuild dump_syms.vcxproj /property:Configuration=Release /p:PlatformToolset=v142 /p:platform=x86 /p:WindowsTargetPlatformVersion=10.0.19041.0
    cd ..\..\..\..\..
) else (
    echo Using breakpad...
)

if not exist "qt_5_12_8" (
    git clone git://code.qt.io/qt/qt5.git qt_5_12_8
    cd qt_5_12_8
    perl init-repository --module-subset=qtbase,qtimageformats
    git checkout v5.12.8
    git submodule update --init qtbase
    git submodule update --init qtimageformats

    call configure -prefix "%LibrariesPath%\Qt-5.12.8" -debug-and-release -force-debug-info -opensource -confirm-license -static -static-runtime -I "%LibrariesPath%\openssl_1_1_1\include" -no-opengl -openssl-linked OPENSSL_LIBS_DEBUG="%LibrariesPath%\openssl_1_1_1\out32.dbg\libssl.lib %LibrariesPath%\openssl_1_1_1\out32.dbg\libcrypto.lib Ws2_32.lib Gdi32.lib Advapi32.lib Crypt32.lib User32.lib" OPENSSL_LIBS_RELEASE="%LibrariesPath%\openssl_1_1_1\out32\libssl.lib %LibrariesPath%\openssl_1_1_1\out32\libcrypto.lib Ws2_32.lib Gdi32.lib Advapi32.lib Crypt32.lib User32.lib" -mp -nomake examples -nomake tests -platform win32-msvc

    call jom -j4
    call jom -j4 install
    cd ..
) else (
    echo Using qt_5_12_8...
)

if not exist "ton" (
    git clone --recursive https://github.com/newton-blockchain/ton.git
    REM git clone --recursive https://github.com/ton-blockchain/ton.git
    cd ton
    git checkout wallets
    mkdir build-debug
    cd build-debug
    cmake -A Win32 -DTON_USE_ROCKSDB=OFF -DTON_USE_ABSEIL=OFF -DTON_ARCH= -DTON_ONLY_TONLIB=ON ^
    -DOPENSSL_FOUND=1 -DOPENSSL_INCLUDE_DIR=%LibrariesPath%\openssl_1_1_1\include ^
    -DOPENSSL_CRYPTO_LIBRARY=%LibrariesPath%\openssl_1_1_1\out32.dbg\libcrypto.lib ^
    -DSODIUM_USE_STATIC_LIBS=1 ^
    -DLZ4_FOUND=1 ^
    -DLZ4_INCLUDE_DIRS=%LibrariesPath%\lz4\lib ^
    -DLZ4_LIBRARIES=%LibrariesPath%\lz4\build\VS2017\liblz4\bin\x64_Debug\liblz4_static.lib ^
    -DSECP256K1_FOUND=1 ^
    -DSECP256K1_INCLUDE_DIR=%LibrariesPath%\secp256k1\include ^
    -DSECP256K1_LIBRARY=%LibrariesPath%\secp256k1\build\src\Debug\libsecp256k1.lib ^
    -DZLIB_FOUND=1 -DZLIB_INCLUDE_DIR=%LibrariesPath%\zlib ^
    -DZLIB_LIBRARY=%LibrariesPath%\zlib\contrib\vstudio\vc14\x86\ZlibStatDebug\zlibstat.lib ^
    -DCMAKE_CXX_FLAGS_DEBUG="/DZLIB_WINAPI /DNDEBUG /MTd /Zi /Od /Ob0" ^
    -DCMAKE_C_FLAGS_DEBUG="/DNDEBUG /MTd /Zi /Od /Ob0" ^
    -DCMAKE_EXE_LINKER_FLAGS="/SAFESEH:NO Ws2_32.lib Gdi32.lib Advapi32.lib Crypt32.lib User32.lib" ..

    cmake --build . --target tonlib --config Debug

    cd ..
    mkdir build
    cd build
    cmake -A Win32 -DTON_USE_ROCKSDB=OFF -DTON_USE_ABSEIL=OFF -DTON_ARCH= -DTON_ONLY_TONLIB=ON ^
    -DOPENSSL_FOUND=1 -DOPENSSL_INCLUDE_DIR=%LibrariesPath%\openssl_1_1_1\include ^
    -DOPENSSL_CRYPTO_LIBRARY=%LibrariesPath%\openssl_1_1_1\out32\libcrypto.lib ^
    -DSODIUM_USE_STATIC_LIBS=1 ^
    -DLZ4_FOUND=1 ^
    -DLZ4_INCLUDE_DIRS=%LibrariesPath%\lz4\lib ^
    -DLZ4_LIBRARIES=%LibrariesPath%\lz4\build\VS2017\liblz4\bin\x64_Release\liblz4_static.lib ^
    -DSECP256K1_FOUND=1 ^
    -DSECP256K1_INCLUDE_DIR=%LibrariesPath%\secp256k1\include ^
    -DSECP256K1_LIBRARY=%LibrariesPath%\secp256k1\build\src\Release\libsecp256k1.lib ^
    -DZLIB_FOUND=1 -DZLIB_INCLUDE_DIR=%LibrariesPath%\zlib ^
    -DZLIB_LIBRARY=%LibrariesPath%\zlib\contrib\vstudio\vc14\x86\ZlibStatReleaseWithoutAsm\zlibstat.lib ^
    -DCMAKE_CXX_FLAGS_RELEASE="/DZLIB_WINAPI /MT /Ob2" ^
    -DCMAKE_C_FLAGS_RELEASE="/MT /Ob2" ^
    -DCMAKE_EXE_LINKER_FLAGS="/SAFESEH:NO Ws2_32.lib Gdi32.lib Advapi32.lib Crypt32.lib User32.lib" ..

    cmake --build . --target tonlib --config Release
) else (
    echo Using ton...
)


cd %LibrariesPath%\..
git clone --recursive https://github.com/ton-blockchain/wallet-desktop.git

cd wallet-desktop\Wallet

call configure.bat -D DESKTOP_APP_USE_PACKAGED=OFF

cd lib_storage
copy %root%\lib_storage.patch .
git apply lib_storage.patch
cd ..

cd ThirdParty\variant
copy %root%\variant.patch .
git apply variant.patch

rem free up disc space, git actions windows server 2019 has 14GB limit
rm -rf %root%\ThirdParty\Strawberry
rm -rf %root%\Libraries\openssl_1_1_1\test

cd %root%\wallet-desktop\out

msbuild Wallet.sln /property:Configuration=Debug /p:platform=win32 /p:PlatformToolset=v142 /p:WindowsTargetPlatformVersion=10.0.19041.0 /p:Zc=preprocessor

dir Debug
