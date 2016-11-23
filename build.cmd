@if defined TRACEON (@echo on) else (@echo off)

  REM  If this batch file works, then it was written by Fish.
  REM  If it doesn't then I don't know who the heck wrote it.

  setlocal
  pushd .

  set "_versnum=2.0"
  set "_versdate=November, 2016"

  goto :init

::-----------------------------------------------------------------------------
::                              BUILD.CMD
::-----------------------------------------------------------------------------
:help

  echo.
  echo     NAME
  echo.
  echo         %nx0%   --   Builds and installs a Hercules external package
  echo.
  echo     SYNOPSIS
  echo.
  echo         %nx0%   [ { -d   ^| --pkgdir    }  [ pkgdir  ]                 ]
  echo                     [ { -n   ^| --pkgname   }  [ pkgname ]                 ]
  echo                     [ { -a   ^| --arch      }  [ 64       ^| 32    ^| BOTH ] ]
  echo                     [ { -c   ^| --config    }  [ Release  ^| Debug ^| BOTH ] ]
  echo                     [ { -all ^| --all       }                              ]
  echo                     [ { -r   ^| --rebuild   }                              ]
  echo                     [ { -i   ^| --install   }  [ instdir  ]                ]
  echo                     [ { -u   ^| --uninstall }  [ uinstdir ]                ]
  echo                     [ { -f   ^| --force     }
  echo.
  echo     ARGUMENTS
  echo.
  echo         pkgdir     The package directory where the CMakeLists.txt
  echo                    file exists.  This is usually the name of the
  echo                    package's primary source directory ^(i.e. its
  echo                    repository directory^).  The default when not
  echo                    specified is the same one as where %nx0%
  echo                    is running from.
  echo.
  echo         pkgname    The single word alphanumeric package name.  The
  echo                    default if not specified is derived from the last
  echo                    directory component of pkgdir.  The value "." may
  echo                    be specified to derive from the last component of
  echo                    the current directory instead.
  echo.
  echo         arch       The build architecture. Use '32' to build an x86
  echo                    32-bit version of the package. Use '64' to build
  echo                    an x64 64-bit version of the package. Use 'BOTH'
  echo                    to build both architectures.  The default is 64.
  echo.
  echo         config     The build configuration. Specify 'Debug' to build
  echo                    an unoptimized debug version of the product.  Use
  echo                    Release to build an optimized version ^(which also
  echo                    has debugging symbols).  The default is Release.
  echo.
  echo         install    Install the package into the specified directory.
  echo                    If not specified the package will not be installed.
  echo.
  echo         instdir    The package installation directory.  If specified
  echo                    the given directory MUST exist.  If not specified
  echo                    the directory specified in a previous run is used
  echo                    if such is possible.  Otherwise the package CMake
  echo                    default installation directory is used instead.
  echo.
  echo         uninstall  Uninstall the package from the specified directory.
  echo.
  echo         uinstdir   The directory where the package was installed.  If
  echo                    specified without the force option, the value MUST
  echo                    match the install directory used in a previous run.
  echo                    If not specified, then the install directory from
  echo                    the previous run is retrieved from the CMake cache
  echo                    and used instead.  If the directory isn't found in
  echo                    CMake's cache the package default install directory
  echo                    is used instead.  The directory MUST exist.
  echo.
  echo     OPTIONS
  echo.
  echo         all        Shorthand for "--arch BOTH --config BOTH".
  echo.
  echo         rebuild    Forces a complete CMake reconfigure and rebuild.
  echo.
  echo         force      Overrides CMake's cached install directory used in
  echo                    a previous run and forces the uninstall to use the
  echo                    specified directory instead.  It effectively forces
  echo                    a complete CMake reconfigure just like the rebuild
  echo                    option does but is used exclusively for uninstalls.
  echo.
  echo     NOTES
  echo.
  echo         %nx0% first creates a build directory in the current directory,
  echo         switches to the build directory, runs vstools.cmd ^(to initialize
  echo         the proper build environment^) followed by the cmake command ^(to
  echo         create the makefile^) and then finally runs nmake and nmake install
  echo         commands to actually build and install the package for the specified
  echo         architecture and configuration combination.  The name of the binary
  echo         build directory is derived from the package's name and the specified
  echo         architetcure/configuration combination.  The vstools.cmd batch file
  echo         is presumed to exist in the same directory as %nx0%.
  echo.
  echo     EXIT STATUS
  echo.
  echo         0      All requested actions successfully completed.
  echo         n      One or more actions failed w/error^(s^) where 'n' is the
  echo                highest return code detected.
  echo.
  echo     AUTHOR
  echo.
  echo         "Fish"  ^(David B. Trout^)
  echo.
  echo     VERSION
  echo.
  echo         %_versnum%     ^(%_versdate%^)

  call :setrc1
  %exit%

::-----------------------------------------------------------------------------
::                               INIT
::-----------------------------------------------------------------------------
:init

  @REM Define some constants...

  set "TRACE=if defined DEBUG echo"
  set "return=goto :EOF"
  set "break=goto :break"
  set "skip=goto :skip"
  set "exit=goto :exit"
  set "help=goto :help"

  set "numbers=0123456789"
  set "letters=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

  set /a "rc=0"
  set /a "maxrc=0"

  set "n0=%~n0"               && @REM (our name only)
  set "nx0=%~nx0"             && @REM (our name and extension)
  set "dp0=%~dp0"             && @REM (our own drive and path only)
  set "dp0=%dp0:~0,-1%"       && @REM (remove trailing backslash)
  set "nx0_cmdline=%0 %*"     && @REM (save original cmdline used)

  @REM Define external tools

  set "cmake=cmake.exe"
  set "vstools=%dp0%\vstools.cmd"

  @REM  Options as listed in help...

  set "pkgdir="
  set "pkgname="
  set "install="
  set "instdir="
  set "uninstall="
  set "uinstdir="
  set "arch="
  set "config="
  set "rebuild="
  set "force="
  set "bldall="

  @REM  Default values...

  set "def_pkgdir=%dp0%"
  set "def_arch=64"
  set "def_config=Release"

  goto :parse_args

::-----------------------------------------------------------------------------
::                             load_tools
::-----------------------------------------------------------------------------
:load_tools

  call :fullpath "%cmake%"
  if not defined # (
    call :errmsg %cmake% not found.
    set "cmake="
  )

  call :fullpath "%vstools%"  vstools
  if not defined # (
    call :errmsg %vstools% not found.
    set "vstools="
  )

  %return%

::-----------------------------------------------------------------------------
::                             fullpath
::-----------------------------------------------------------------------------
:fullpath

  set "@=%path%"
  set "path=.;%path%"
  set "#=%~$PATH:1"
  set "path=%@%"
  if defined # (
    if not "%~2" == "" (
      set "%~2=%#%"
    )
  )
  %return%

::-----------------------------------------------------------------------------
::                              isfile
::-----------------------------------------------------------------------------
:isfile

  if not exist "%~1" (
    set "isfile="
    %return%
  )
  set "isfile=%~a1"
  if defined isfile (
    if /i "%isfile:~0,1%" == "d" set "isfile="
  )
  %return%

::-----------------------------------------------------------------------------
::                              isdir
::-----------------------------------------------------------------------------
:isdir

  if not exist "%~1" (
    set "isdir="
    %return%
  )
  set "isdir=%~a1"
  if defined isdir (
    if /i not "%isdir:~0,1%" == "d" set "isdir="
  )
  %return%

::-----------------------------------------------------------------------------
::                              tempfn
::-----------------------------------------------------------------------------
:tempfn

  setlocal
  set "var_name=%~1"
  set "file_ext=%~2"
  set "%var_name%="
  set "@="
  for /f "delims=/ tokens=1-3" %%a in ("%date:~4%") do (
    for /f "delims=:. tokens=1-4" %%d in ("%time: =0%") do (
      set "@=TMP%%c%%a%%b%%d%%e%%f%%g%random%%file_ext%"
    )
  )
  endlocal && set "%var_name%=%@%"
  %return%

::-----------------------------------------------------------------------------
::                              dirname
::-----------------------------------------------------------------------------
:dirname

  set "dirname=%~nx1"    && @REM (get just the final directory name component)
  %return%

::-----------------------------------------------------------------------------
::                            normalize_dir
::-----------------------------------------------------------------------------
:normalize_dir

  if "%~2" == "" %return%

  setlocal

  set "var_name=%~1"
  set "var_value=%~2"

  ::  Normalize path separator
  ::  Remove trailing separator

  set "norm_val=%var_value:/=\%"

  if "%norm_val:~-1%" == "\" (
    set "norm_val=%norm_val:~0,-1%"
  )

  endlocal && set "%var_name%=%norm_val%"

  %return%

::-----------------------------------------------------------------------------
::                            is_valid_dir
::-----------------------------------------------------------------------------
:is_valid_dir

  @REM  Return value 'is_valid_dir' defined if valid, otherwise undefined.

  @REM  Passed variable will ALWAYS be updated (normalized) REGARDLESS of
  @REM  whether it is determined to be valid or not.

  @REM  Use quiet option to preserve rc/maxrc value if only interested in
  @REM  the 'is_valid_dir' return value.  Otherwise an error message will
  @REM  be issued and 'rc' & 'maxrc' will be updated if directory invalid.

  setlocal

  set "is_valid_dir=1"

  set "var_name=%~1"
  set "var_value=%~2"
  set "quiet=%~3"

  call :normalize_dir  norm_val  "%var_value%"

  call :fullpath "%norm_val%"

  if not defined # (
    set "is_valid_dir="
    if not defined quiet (
      call :errmsg %var_name% "%var_value%" not found.
    )
    goto :is_valid_dir_ret
  )

  set "norm_val=%#%"

  call :isdir "%norm_val%"

  if not defined isdir (
    set "is_valid_dir="
    if not defined quiet (
      call :errmsg %var_name% "%var_value%" is not a directory.
    )
  )

:is_valid_dir_ret

  if defined quiet (
    endlocal && set "is_valid_dir=%is_valid_dir%" && set "%var_name%=%norm_val%"
  ) else (
    endlocal && set "is_valid_dir=%is_valid_dir%" && set "%var_name%=%norm_val%" && set "rc=%rc%" && set "maxrc=%maxrc%"
  )

  %return%

::-----------------------------------------------------------------------------
::                             isalphanum
::-----------------------------------------------------------------------------
:isalphanum

  set "@=%~1"

  set "isalphanum="

  if not "%@%" == "" (
    for /f "delims=%numbers%%letters%" %%i in ("%@%/") do (
      if "%%i" == "/" set "isalphanum=1"
    )
  )

  :: (ensure first char is letter not number)

  set "@=%@:~0,1%"

  if defined isalphanum (
    for /f "delims=%letters%" %%i in ("%@%/") do (
      if not "%%i" == "/" set "isalphanum="
    )
  )

  %return%

::-----------------------------------------------------------------------------
::                           get_cache_value
::-----------------------------------------------------------------------------
:get_cache_value

  setlocal

  set "_cachefile=%~1"
  set "_varname=%~2"
  set "cache_value="           && @REM (the value we will be returning_

  if not exist "%_cachefile%" (
    goto :get_cache_value_ret
  )

  for /f "tokens=*" %%a in (%_cachefile%) do (
    call :cache_stmt "%%a"
    if defined cache_value (
      goto :get_cache_value_ret
    )
  )

:get_cache_value_ret

  endlocal && set "cache_value=%cache_value%"
  %return%

:cache_stmt

  set "stmt=%~1"

  for /f "tokens=1-2* delims=:=" %%a in ("%stmt%") do (
    if /i "%%a" == "%_varname%" (
      set "cache_value=%%c"
      %return%
    )
  )

  %return%

::-----------------------------------------------------------------------------
::                   ( parse_options_loop helper )
::-----------------------------------------------------------------------------
:isopt

  @REM  Examines first character of passed value to determine
  @REM  whether it's the next option or not. If it starts with
  @REM  a '/' or '-' then it's the next option. Else it's not.

  set           "isopt=%~1"
  if not defined isopt     %return%
  if "%isopt:~0,1%" == "/" %return%
  if "%isopt:~0,1%" == "-" %return%
  set "isopt="
  %return%

::-----------------------------------------------------------------------------
::                   ( parse_options_loop helper )
::-----------------------------------------------------------------------------
:parseopt

  @REM  This function expects the next two command line arguments
  @REM  %1 and %2 to be passed to it.  %1 is expected to be a true
  @REM  option (its first character should start with a / or -).
  @REM
  @REM  Both arguments are then examined and the results are placed into
  @REM  the following variables:
  @REM
  @REM    opt:        The current option as-is (e.g. "-d")
  @REM
  @REM    optname:    Just the characters following the '-' (e.g. "d")
  @REM
  @REM    optval:     The next token following the option (i.e. %2),
  @REM                but only if it's not an option itself (not isopt).
  @REM                Otherwise optval is set to empty/undefined since
  @REM                it is not actually an option value but is instead
  @REM                the next option.

  set "opt=%~1"
  set "optname=%opt:~1%"
  set "optval=%~2"
  setlocal
  call :isopt "%optval%"
  endlocal && set "#=%isopt%"
  if defined # set "optval="
  %return%

::-----------------------------------------------------------------------------
::                             parse_args
::-----------------------------------------------------------------------------
:parse_args

  set /a "rc=0"

  if /i "%~1" == "?"       %help%
  if /i "%~1" == "/?"      %help%
  if /i "%~1" == "-?"      %help%
  if /i "%~1" == "-h"      %help%
  if /i "%~1" == "--help"  %help%

  call :load_tools
  if %rc% NEQ 0 %exit%

:parse_options_loop

  if "%~1" == "" goto :options_loop_end

  @REM  Parse next option...

  set "cmdline_arg=%~1"

  call :isopt    "%~1"
  call :parseopt "%~1" "%~2"
  shift /1

  if not defined isopt (

    @REM  Must be a positional option.
    @REM  Set optname identical to opt
    @REM  and empty meaningless optval.

    set "optname=%opt%"
    set "optval="
    goto :parse_positional_arg
  )

  if /i "%optname%" == "?"   goto :parse_help_opt
  if /i "%optname%" == "h"   goto :parse_help_opt
  if /i "%optname%" == "d"   goto :parse_pkgdir_opt
  if /i "%optname%" == "n"   goto :parse_pkgname_opt
  if /i "%optname%" == "i"   goto :parse_install_opt
  if /i "%optname%" == "u"   goto :parse_uninstall_opt
  if /i "%optname%" == "a"   goto :parse_arch_opt
  if /i "%optname%" == "c"   goto :parse_config_opt
  if /i "%optname%" == "r"   goto :parse_rebuild_opt
  if /i "%optname%" == "f"   goto :parse_force_opt
  if /i "%optname%" == "all" goto :parse_all_opt

  @REM  Determine if "--xxxx" long option

  call :isopt "%optname%"
  if not defined isopt goto :parse_unknown_opt

  @REM  Long "--xxxxx" option parsing...
  @REM  We use %~1 here (instead of %~2)
  @REM  since shift /1 was already done.

  call :parseopt "%optname%" "%~1"

  if /i "%optname%" == "help"      goto :parse_help_opt
  if /i "%optname%" == "pkgdir"    goto :parse_pkgdir_opt
  if /i "%optname%" == "pkgname"   goto :parse_pkgname_opt
  if /i "%optname%" == "install"   goto :parse_install_opt
  if /i "%optname%" == "uninstall" goto :parse_uninstall_opt
  if /i "%optname%" == "arch"      goto :parse_arch_opt
  if /i "%optname%" == "config"    goto :parse_config_opt
  if /i "%optname%" == "rebuild"   goto :parse_rebuild_opt
  if /i "%optname%" == "force"     goto :parse_force_opt
  if /i "%optname%" == "all"       goto :parse_all_opt
  if /i "%optname%" == "version"   goto :parse_version_opt

  goto :parse_unknown_opt

  @REM ------------------------------------
  @REM  Options that require an argument
  @REM ------------------------------------

:parse_pkgdir_opt

  if not defined optval goto :parse_missing_optarg
  set "pkgdir=%optval%"
  shift /1
  goto :parse_options_loop

:parse_pkgname_opt

  if not defined optval goto :parse_missing_optarg
  set "pkgname=%optval%"
  shift /1
  goto :parse_options_loop

:parse_arch_opt

  if not defined optval goto :parse_missing_optarg
  set "arch=%optval%"
  shift /1
  goto :parse_options_loop

:parse_config_opt

  if not defined optval goto :parse_missing_optarg
  set "config=%optval%"
  shift /1
  goto :parse_options_loop

  @REM ------------------------------------
  @REM  Options whose argument is optional
  @REM ------------------------------------

:parse_install_opt

  set "install=1"

  if not defined optval goto :parse_options_loop
  set "instdir=%optval%"
  shift /1
  goto :parse_options_loop

:parse_uninstall_opt

  set "uninstall=1"

  if not defined optval goto :parse_options_loop
  set "uinstdir=%optval%"
  shift /1
  goto :parse_options_loop

  @REM ------------------------------------
  @REM  Options that are just switches
  @REM ------------------------------------

:parse_help_opt

  %help%
  goto :parse_options_loop

:parse_rebuild_opt

  set "rebuild=1"
  goto :parse_options_loop

:parse_force_opt

  set "force=1"
  goto :parse_options_loop

:parse_all_opt

  set "bldall=1"
  goto :parse_options_loop

:parse_version_opt

  echo %nx0% version %_versnum% ^(%_versdate%^) 1>&2
  call :setrc1
  goto :parse_options_loop

  @REM ------------------------------------
  @REM      Positional arguments
  @REM ------------------------------------

:parse_positional_arg

  ::  We do not have any positional arguments

  goto :parse_unknown_arg

  @REM ------------------------------------
  @REM  Error routines
  @REM ------------------------------------

:parse_unknown_arg

  call :errmsg Unrecognized/extraneous argument '%cmdline_arg%'.
  goto :parse_options_loop

:parse_unknown_opt

  call :errmsg Unknown/unsupported option '%cmdline_arg%'.
  goto :parse_options_loop

:parse_missing_optarg

  call :errmsg Option '%cmdline_arg%' is missing its required argument.
  goto :parse_options_loop

:options_loop_end

  %TRACE% Debug: values after parsing:
  %TRACE%.
  %TRACE% pkgdir    = "%pkgdir%"
  %TRACE% pkgname   = "%pkgname%"
  %TRACE% install   = "%install%"
  %TRACE% instdir   = "%instdir%"
  %TRACE% uninstall = "%uninstall%"
  %TRACE% uinstdir  = "%uinstdir%"
  %TRACE% arch      = "%arch%"
  %TRACE% config    = "%config%"
  %TRACE% rebuild   = "%rebuild%"
  %TRACE% force     = "%force%"
  %TRACE% bldall    = "%bldall%"
  %TRACE%.

  if %rc% NEQ 0 %exit%
  goto :validate_args

::-----------------------------------------------------------------------------
::                            validate_args
::-----------------------------------------------------------------------------
:validate_args

  if not defined pkgdir (
    set "pkgdir=%def_pkgdir%"
  )

  call :is_valid_dir  pkgdir  "%pkgdir%"

  if %rc% NEQ 0 (
    @REM error message already issued
    goto :validate_pkgname
  )

  pushd "%pkgdir%"
  call :fullpath "CMakeLists.txt"
  popd

  if not defined # (
    call :errmsg File "CMakeLists.txt" not found in pkgdir.
    goto :validate_pkgname
  )

  goto :validate_pkgname

::-----------------------------------------------------------------------------
:validate_pkgname

  if "%pkgname%" == "." (
    goto :validate_dot_pkgname
  )

  if defined pkgname (
    goto :validate_specified_pkgname
  )

  ::  Derive pkgname from pkgdir value

  call :dirname "%pkgdir%"
  set "pkgname=%dirname%"
  goto :validate_derived_pkgname

:validate_dot_pkgname

  ::  Derive pkgname from current directory name

  call :dirname "%cd%"
  set "pkgname=%dirname%"
  goto :validate_derived_pkgname

:validate_derived_pkgname

  set "_pkgname=%pkgname%"
  set "pkgname="

  ::  The following loop constructs a pkgname value
  ::  by skipping all non-alphanumeric characters
  ::  and ensuring the first character is a letter.

:validate_derived_pkgname_loop

  if not defined _pkgname (
    @REM We're done. Go validate our results.
    goto :validate_specified_pkgname
  )

  :: Grab the next character from _pgkname...

  set "@=%_pkgname:~0,1%"
  set "_pkgname=%_pkgname:~1%"
  
  for /f "delims=%numbers%%letters%" %%i in ("%@%/") do (
    if "%%i" == "/" call :validate_derived_pkgname_append_sub
    goto :validate_derived_pkgname_loop
  )

:validate_derived_pkgname_append_sub
  set "pkgname=%pkgname%%@%"
  %return%

:validate_specified_pkgname

  call :isalphanum "%pkgname%"
  if not defined isalphanum (
    call :errmsg Invalid pkgname "%pkgname%".
    goto :validate_instdir
  )

  goto :validate_instdir

::-----------------------------------------------------------------------------
:validate_instdir

  if defined instdir (
    call :is_valid_dir  instdir  "%instdir%"
  )

  goto :validate_uinstdir

::-----------------------------------------------------------------------------
:validate_uinstdir

  if defined uinstdir (
    call :is_valid_dir  uinstdir  "%uinstdir%"
  )

  goto :validate_build

::-----------------------------------------------------------------------------
:validate_build

  ::  Ignore specified arch and config values if bldall was specified

  if defined bldall (
    if defined arch (
      if /i not "%arch%" == "BOTH" (
        echo WARNING: arch ignored due to 'all' option. 1>&2
      )
      set "arch="
    )
    if defined config (
      if /i not "%config%" == "BOTH" (
        echo WARNING: config ignored due to 'all' option. 1>&2
      )
      set "config="
    )
  ) else (
    if not defined arch   set "arch=%def_arch%"
    if not defined config set "config=%def_config%"
  )

  ::  Validate arch and config if not bldall

  if not defined bldall (
    if /i not "%arch%" == "32" (
      if /i not "%arch%" == "64" (
        if /i not "%arch%" == "BOTH" (
          call :errmsg Invalid arch "%arch%"
        )
      )
    )
    if /i not "%config%" == "Debug" (
      if /i not "%config%" == "Release" (
        if /i not "%config%" == "BOTH" (
          call :errmsg Invalid config "%config%"
        )
      )
    )
  )

  ::  Both 'arch' and 'config' == "BOTH" implies 'bldall'

  if /i "%arch%" == "BOTH" (
    if /i "%config%" == "BOTH" (
      set "arch="
      set "config="
      set "bldall=1"
    )
  )

  goto :validate_arg_sanity

::-----------------------------------------------------------------------------
:validate_arg_sanity

  ::  Check for conflicting options, etc...

  if defined uninstall (
    if defined install (
      call :errmsg Cannot specify both install and uninstall.
      call :errmsg Choose one or the other but not both.
    )
  )

  if defined install (
    if defined force (
      call :errmsg Option --force is only for uninstalls.
      call :errmsg For installs specify --rebuild instead.
    )
  )

  if defined uninstall (
    if defined rebuild (
      call :errmsg Option --rebuild is only for installs.
      call :errmsg For uninstalls specify --force instead.
    )
  )

  goto :validate_args_done

::-----------------------------------------------------------------------------
:validate_args_done

  %TRACE% Debug: values after validation:
  %TRACE%.
  %TRACE% pkgdir    = "%pkgdir%"
  %TRACE% pkgname   = "%pkgname%"
  %TRACE% install   = "%install%"
  %TRACE% instdir   = "%instdir%"
  %TRACE% uninstall = "%uninstall%"
  %TRACE% uinstdir  = "%uinstdir%"
  %TRACE% arch      = "%arch%"
  %TRACE% config    = "%config%"
  %TRACE% rebuild   = "%rebuild%"
  %TRACE% force     = "%force%"
  %TRACE% bldall    = "%bldall%"
  %TRACE%.

  if %rc% NEQ 0 %exit%
  goto :BEGIN

::-----------------------------------------------------------------------------
::                          get_prev_instdir
::-----------------------------------------------------------------------------
:get_prev_instdir

  set "prev_instdir="

  if not exist "%cachefile%" %return%

  call :get_cache_value "%cachefile%" "CMAKE_INSTALL_PREFIX"

  if defined cache_value (
    call :normalize_dir  prev_instdir  "%cache_value%"
  )

  %return%

::-----------------------------------------------------------------------------
::                         is_configure_needed
::-----------------------------------------------------------------------------
:is_configure_needed

  set "configure_needed="

  @REM  Initialization...

  set "blddir=%pkgname%%arch%.%config%"
  set "cachefile=%blddir%\CMakeCache.txt"
  call :get_prev_instdir

  @REM  configure is needed ONLY if:
  @REM
  @REM    *  rebuild specified, OR
  @REM    *  blddir does NOT exist yet, OR
  @REM    *  blddir does NOT contain makefile, OR
  @REM    *  uninstall --force specified

  if defined rebuild (
    goto :configure_is_needed
  )

  call :isdir "%blddir%"

  if not defined isdir (
    goto :configure_is_needed
  )

  call :isfile "%blddir%\Makefile"

  if not defined isfile (
    goto :configure_is_needed
  )

  if defined uninstall (
    if defined force (
      goto :configure_is_needed
    )
  )

  %return%

:configure_is_needed

  set "configure_needed=1"

  if     exist "%blddir%" rmdir /s /q "%blddir%"
  if not exist "%blddir%" mkdir       "%blddir%"

  %return%

::-----------------------------------------------------------------------------
::                            is_make_needed
::-----------------------------------------------------------------------------
:is_make_needed

  set "make_needed=1"       && @REM safest default is to always do a make

  @REM  a make is NOT needed ONLY if:
  @REM
  @REM    *  configure is not needed, AND
  @REM    *  uninstalling, AND
  @REM    *  blddir DOES contain "install_manifest.txt"
  @REM
  @REM  Otherwise a make IS needed.

  if not defined configure_needed (
    if defined uninstall (
      call :isfile "%blddir%\install_manifest.txt"
      if defined isfile (
        set "make_needed="  && @REM make NOT needed since we're uninstalling
      )
    )
  )

  %return%

::-----------------------------------------------------------------------------
::                          is_install_needed
::-----------------------------------------------------------------------------
:is_install_needed

  set "install_needed="

  @REM  install is needed ONLY if:
  @REM
  @REM    *  install specified, OR
  @REM    *  uninstall specified, AND
  @REM    *  blddir does NOT contain "install_manifest.txt"

  if defined install (
    goto :install_is_needed
  )

  if not defined uninstall (
    :: Neither install nor uninstall was specified
    %return%
  )

  :: Uninstall was specified

  call :isfile "%blddir%\install_manifest.txt"

  if not defined isfile (
    goto :install_is_needed
  )

  :: Uninstalling and install manifest DOES exist.
  :: Skip the install step, and do ONLY uninstall.

  %return%

:install_is_needed

  set "install_needed=1"
  %return%

::-----------------------------------------------------------------------------
::                         is_uninstall_needed
::-----------------------------------------------------------------------------
:is_uninstall_needed

  set "uninstall_needed="

  @REM  uninstall is needed ONLY if:
  @REM
  @REM    *  uninstall specified

  if defined uninstall (
    set "uninstall_needed=1"
  )

  %return%

::-----------------------------------------------------------------------------
::                               BEGIN
::-----------------------------------------------------------------------------
:BEGIN

  if defined bldall (

    call :do_build "32" "Debug"
    call :do_build "32" "Release"
    call :do_build "64" "Debug"
    call :do_build "64" "Release"

  ) else (

    if /i "%arch%" == "BOTH" (

      call :do_build "32" "%config%"
      call :do_build "64" "%config%"

    ) else (

      if /i "%config%" == "BOTH" (

        call :do_build "%arch%" "Debug"
        call :do_build "%arch%" "Release"

      ) else (

        call :do_build "%arch%" "%config%"
      )
    )
  )

  %exit%

::-----------------------------------------------------------------------------
::                                do_build
::-----------------------------------------------------------------------------
:do_build

  setlocal

    ::  PROGRAMMING NOTE: Because we did a setlocal, we must remember
    ::  to never use %return% without first doing endlocal beforehand!

    set "arch=%~1"
    set "config=%~2"

    set "rc=0"                    &&  @REM  (always!)
    set "did_vstools="            &&  @REM  (to support skipping steps)

    ::  Determine which steps are needed for this arch/config combination...

    call :is_configure_needed     &&  @REM  (skip configure if possible)
    call :is_make_needed          &&  @REM  (skip make      if possible)
    call :is_install_needed       &&  @REM  (skip install   if possible)
    call :is_uninstall_needed     &&  @REM  (skip uninstall if possible)

    echo cmdline = %nx0_cmdline%
    echo.
    echo Build of %arch%-bit %config% version of %pkgname% begun on %date% at %time: =0%

    %TRACE%.
    %TRACE% Debug: values for this arch/config build:
    %TRACE%.
    %TRACE% prev_instdir     = "%prev_instdir%"
    %TRACE% configure_needed = "%configure_needed%"
    %TRACE% make_needed      = "%make_needed%"
    %TRACE% install_needed   = "%install_needed%"
    %TRACE% uninstall_needed = "%uninstall_needed%"
    %TRACE%.

    ::  If they didn't specify an install or uninstall directory,
    ::  use the same value as previously configured, if possible.
    ::
    ::  If there is no previously configured directory then leave
    ::  the specified value undefined so the configure step knows
    ::  to use the CMake default instead.

    if defined install (
      if not defined rebuild (
        if not defined instdir (
          if defined prev_instdir (
            set "instdir=%prev_instdir%"
          )
        )
      )
    )

    if defined uninstall (
      if not defined force (
        if not defined uinstdir (
          if defined prev_instdir (
            set "uinstdir=%prev_instdir%"
          )
        )
      )
    )

    if defined uninstall (
      set "instdir=%uinstdir%"
    )

    ::  Check to make sure their instdir value matches the previously
    ::  configured directory if such exists.  They cannot specify one
    ::  directory on one run and then a completely different directory
    ::  on a subsequent run.  For uninstalls the instdir value was set
    ::  to their specified uinstdir just above so the below checks for
    ::  both uninstalls and installs too.

    if not defined configure_needed (
      if defined instdir (
        if defined prev_instdir (
          if /i not "%instdir%" == "%prev_instdir%" (
            if defined install (
              goto :do_build_install_dir_error
            )
            if defined uninstall (
              goto :do_build_uninstall_dir_error
            )
          )
        )
      )
    )

    goto :do_build_build

:do_build_install_dir_error

    call :errmsg Specified instdir does not match previously configured value.
    call :errmsg Use --rebuild to reconfigure if you wish to use a new value.
    goto :do_build_ret

:do_build_uninstall_dir_error

    call :errmsg Specified uinstdir does not match previously used instdir.
    call :errmsg Use --force option to uninstall from the specified uinstdir.
    goto :do_build_ret

:do_build_build

    ::  Do the build...

    pushd "%blddir%"

      if %rc% EQU 0 call :do_configure
      if %rc% EQU 0 call :do_make
      if %rc% EQU 0 call :do_install
      if %rc% EQU 0 call :do_uninstall

    popd

    goto :do_build_ret

:do_build_ret

    ::  Display results

    if %rc% EQU 0 set "result=SUCCEEDED"
    if %rc% NEQ 0 set "result=FAILED"

    echo.
    echo Build %result% on %date% at %time: =0%
    echo.

  endlocal
  %return%

::-----------------------------------------------------------------------------
::                            do_configure
::-----------------------------------------------------------------------------
:do_configure

  if not defined configure_needed %return%

  echo.&& echo Configuring %pkgname%%arch%.%config% ...&& echo.

  if not defined did_vstools (
    call "%vstools%" "%arch%"
    set "did_vstools=1"
  )

  if defined instdir (
    set "install_prefix_opt=-D INSTALL_PREFIX="%instdir%""
  ) else (
    set "install_prefix_opt="
  )

  :: PROGRAMMING NOTE: CMake apparently uses the 'RC' environment variable
  :: to hold the path to Microsoft's Resource Compiler (rc.exe) and becomes
  :: very upset when it doesn't find it.  Thus we undefine our existing rc
  :: variable before invoking CMake.  We will set it to its proper "return
  :: code" value again immediately after CMake finishes doing its thing.

  set "rc="     &&    @REM (allows cmake to find rc.exe)

  cmake -G "NMake Makefiles"  %install_prefix_opt%  "%pkgdir%"

  set "rc=%errorlevel%"
  call :update_maxrc

  if %rc% NEQ 0 (
    call :errmsg CMake has failed! rc=%rc%
  )

  %return%

::-----------------------------------------------------------------------------
::                            do_make
::-----------------------------------------------------------------------------
:do_make

  if not defined make_needed %return%

  echo.&& echo Building %pkgname%%arch%.%config% ...&& echo.

  if not defined did_vstools (
    call "%vstools%" "%arch%"
    set "did_vstools=1"
  )

  nmake /nologo

  set "rc=%errorlevel%"
  call :update_maxrc

  if %rc% NEQ 0 (
    call :errmsg nmake has failed! rc=%rc%
  )

  %return%

::-----------------------------------------------------------------------------
::                            do_install
::-----------------------------------------------------------------------------
:do_install

  if not defined install_needed %return%

  echo.&& echo Installing %pkgname%%arch%.%config% ...&& echo.

  if not defined did_vstools (
    call "%vstools%" "%arch%"
    set "did_vstools=1"
  )

  nmake /nologo install

  set "rc=%errorlevel%"
  call :update_maxrc

  if %rc% NEQ 0 (
    call :errmsg nmake install has failed! rc=%rc%
  )

  %return%

::-----------------------------------------------------------------------------
::                            do_uninstall
::-----------------------------------------------------------------------------
:do_uninstall

  if not defined uninstall_needed %return%

  echo.&& echo UNinstalling %pkgname%%arch%.%config% ...&& echo.

  if not defined did_vstools (
    call "%vstools%" "%arch%"
    set "did_vstools=1"
  )

  nmake /nologo uninstall

  set "rc=%errorlevel%"
  call :update_maxrc

  if %rc% NEQ 0 (
    call :errmsg nmake uninstall has failed! rc=%rc%
  )

  %return%

::-----------------------------------------------------------------------------
::                              errmsg
::-----------------------------------------------------------------------------
:errmsg

  :: PROGRAMMING NOTE: the only reason for the below unusual error message
  :: format is so Visual Studio IDE detects it as a build error since just
  :: exiting with a non-zero return code doesn't do the trick. Visual Studio
  :: apparently examines the message-text looking for error/warning strings.

  echo.                               1>&2
  echo %~nx0^(1^) : error C9999 : %*  1>&2
  call :setrc1
  %return%

::-----------------------------------------------------------------------------
::                              setrc1
::-----------------------------------------------------------------------------
:setrc1

  set /a "rc=1"
  call :update_maxrc
  %return%

::-----------------------------------------------------------------------------
::                           update_maxrc
::-----------------------------------------------------------------------------
:update_maxrc

  @REM maxrc remains negative once it's negative.

  if %maxrc% GEQ 0 (
    if %rc% LSS 0 (
      set /a "maxrc=%rc%"
    ) else (
      if %rc% GTR 0 (
        if %rc% GTR %maxrc% (
          set /a "maxrc=%rc%"
        )
      )
    )
  )

  %return%

::-----------------------------------------------------------------------------
::                                EXIT
::-----------------------------------------------------------------------------
:exit

  popd
  endlocal && exit /b %maxrc%

::-----------------------------------------------------------------------------
