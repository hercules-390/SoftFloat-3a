@echo off

:: This script is the one-stop shopping for MakeDirs, BuildMe, and InstallMe
:: in the utils subdirectory.

:: Your current working directory MUST be the one where this file resides

:: Save current directory and go to where the individual scripts are

:: Parameters passed on the command line are passed as parameters to the
:: BuildMe script.

setlocal

set "retcode="
pushd tools

:: We check for PLATFORM because Windows is not very clear about whether
:: we are building for amd64 or just running on amd64.  Visual Studio
:: 2015 and later (and maybe earlier too) set PLATFORM to the architecture
:: of the target.  Visual Studio 2008 does not set PLATFORM.

:: If PLATFORM is set, then we can use its value without worry.

:: if PLATFORM does not exist, then we must figure out the target
:: architecture from PROCESSOR_ARCHITECTURE and, if present, from
:: PROCESSOR_ARCHITEW6432.

:: If PROCESSOR_ARCHITEW6432 does not exist, then PROCESSOR_ARCHITECTURE
:: identifies the target architecture.  If PROCESSOR_ARCHITEW6432 does
:: exist, then the build is taking place in a 32-bit command prompt on
:: a 64-bit system, and PROCESSOR_ARCHITEW6432 describes the real
:: hardware.

:: Finally, if Visual Studio 2008 provides the compiler, we do not know
:: if it is Express Edition, which builds 32-bit apps only, or Standard
:: or better, which builds 32- or 64-bit apps.  Because 1Stop is the
:: "easy to use, builds a working Hercules," we shall assume a 32-bit
:: target, as that will work on a 64-bit system for many things one can
:: do with Hercules.

:: If a builder has Visual Studio 2008 Standard or better and needs a
:: 64-bit build, 1Stop is not a solution that will work for them.

if DEFINED PLATFORM (
    set "build_arch=%PLATFORM%"
) else (
    if DEFINED PROCESSOR_ARCHITEW6432 (
        set "build_arch=%PROCESSOR_ARCHITEW6432%"
    ) else (
        set "build_arch=%PROCESSOR_ARCHITECTURE%"
    )
)

:: PLATFORM is either x86 or x64, PROCESSORS_ARCHITECTURE is either
:: x86 or AMD64.  Conform x64 to AMD64

If /I "%build_arch%"=="x64" (
    set "build_arch=AMD64"
)


:: Set the CMake generator to the most modern version of Visual Studio
:: installed on this machine.  This script assumes that at least one
:: such is installed.  Lowest acceptable is VS2008; highest is VS2017.

:: Visual Studio 2012 and higher command prompts can be identified by
:: checking the environment variable VisualStudioVersion.  Older than
:: 2012, we can parse the PATH variable, but that will fail if the
:: builder installed Visual Studio in a non-default directory.  There
:: is no help for that beyond understanding the difficulty and
:: documenting it.

:: If Visual Studio 9.0 2008 is identified as the the newest version
:: installed, it is assumed to be the Express Edition.  VS2008EE is
:: limited to building 32-bit applications out of the box, and 1Stop
:: will therefore only build a 32-bit Hercules when VS2008EE is in use.
:: (Yes, there are VS2008EE hacks to enable 64-bit builds, and a builder
:: who uses those hacks will need to use the more flexible build tools
:: like makefile.bat.)

:: If there are multiple versions of Visual Studio installed, well,
:: 1Stop  will end badly if someone wishes to use an older VS version to
:: build.  In that case, we will expect the builder to use more flexible
:: build tools.

if "%VisualStudioVersion%" == "15.0" (
    set "cmake_generator=Visual Studio 15 2017"
) else if "%VisualStudioVersion%" == "14.0" (
    set "cmake_generator=Visual Studio 14 2015"
) else if "%VisualStudioVersion%" == "12.0" (
    set "cmake_generator=Visual Studio 12 2013"
) else if "%VisualStudioVersion%" == "11.0" (
    set "cmake_generator=Visual Studio 11 2012"
) else if "%VisualStudioVersion%" == "10.0" (
    set "cmake_generator=Visual Studio 10 2010"
) else if "%VisualStudioVersion%" == "9.0" (
    set "cmake_generator=Visual Studio 9 2008"
) else if NOT "%PATH:Visual Studio 10.0=%"=="%PATH%" (
    set "cmake_generator=Visual Studio 10 2010"
) else if NOT "%PATH:Visual Studio 9.0=%"=="%PATH%" (
    echo Visual Studio 9 ^(2008^) identified as build tool.  Assuming Express Edition.
    echo Building 32-bit library.
    set "build_arch=x86"
    set "cmake_generator=Visual Studio 9 2008"
) else (
    set "retcode=12"
    echo Unable to determine Visual Studio version.
    echo Unable to match VisualStudioVersion "%VisualStudioVersion%" to a valid version.
    echo Unable to to determine version from PATH environment variable.
    echo Terminating.
    exit /b 0
)

:: If building for 64-bit target, set the suffix for the CMake generator
if /I "%build_arch%" == "AMD64" (
    set "cmake_generator=%cmake_generator% Win64"
)

:: Unfortunately the PLATFORM variable will mess up --clean-first.  We
:: shall unset it for the duration of the script.  The cmake_generator
:: variable set above will determine whether a 32-bit or 64-bit library
:: is built.

set "PLATFORM="

call MakeDirs.cmd  && ( call BuildMe.cmd %* && call InstallMe.cmd )

set "retcode=%errorlevel%"

popd

if %retcode% GTR 0 (
  echo *** Unsuccessful completion!
)

exit /b %retcode%