#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   Global settings
#
cmake_minimum_required( VERSION 3.2 )

cmake_policy(SET CMP0048 NEW)
set( HERCMODS "../hercsource/" )

set(CMAKE_DEBUG_TARGET_PROPERTIES
  INCLUDE_DIRECTORIES
  COMPILE_DEFINITIONS
  POSITION_INDEPENDENT_CODE
  CONTAINER_SIZE_REQUIRED
  LIB_VERSION
) 

#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   the directory with the CMAKE user modules
if( EXISTS "${CMAKE_SOURCE_DIR}/cmake/modules" )
    set( CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/modules" )
    include( Vdump )
    include( Trace )
else()
	message( FATAL_ERROR "
Cmake modules directory not found '${CMAKE_SOURCE_DIR}/cmake/modules'
" )
endif()

set( TRAVIS $ENV{TRAVIS} )
if( TRAVIS )
    message( "@@ Remote build ( Travis ) " )
else()
    message( "@@ Local  build" )

#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   check for an in-source build
#   and make sure the user doesn't play dirty with symlinks
#
#   You will still have to manually clean up a few files
#   if You accidentally try an in-source build:
#   file 'CMakeCache.txt' and directory 'CMakeFiles'
#
set( CMAKE_DISABLE_IN_SOURCE_BUILD ON )
set( CMAKE_DISABLE_SOURCE_CHANGES  ON )

get_filename_component( SOURCE_DIR "${CMAKE_SOURCE_DIR}" REALPATH)
get_filename_component( BINARY_DIR "${CMAKE_BINARY_DIR}" REALPATH)

if( "${SOURCE_DIR}" STREQUAL "${BINARY_DIR}" )
    message( FATAL_ERROR "
 in-source builds are not allowed;
 remove file 'CMakeCache.txt' and directory 'CMakeFiles'
" )
endif( )

#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#  	install prefix, and build type
#

#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if( NOT DEFINED INSTALL_PREFIX )
    get_filename_component( BINARY_HLQ ${CMAKE_BINARY_DIR} DIRECTORY )
    get_filename_component( BINARY_DIR ${CMAKE_BINARY_DIR} NAME )
	string( REGEX MATCH "([^\\.]*)" INSTALL_PREFIX ${BINARY_DIR} )
	if(	BINARY_DIR STREQUAL INSTALL_PREFIX )
		message( FATAL_ERROR "
Unable to determine INSTALL_PREFIX from  ${CMAKE_BINARY_DIR}
" )
	endif()
	set( INSTALL_PREFIX  "${BINARY_HLQ}/${INSTALL_PREFIX}")
endif()
set( CMAKE_INSTALL_PREFIX  "${INSTALL_PREFIX}" CACHE PATH "" FORCE )

#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if( NOT DEFINED BUILD_TYPE )
    get_filename_component( BINARY_HLQ ${CMAKE_BINARY_DIR} DIRECTORY )
    get_filename_component( BINARY_DIR ${CMAKE_BINARY_DIR} NAME )
	string( REGEX MATCH "([^.]*\$)" BUILD_TYPE ${BINARY_DIR} )
	if(	BINARY_DIR STREQUAL BUILD_TYPE )
		message( FATAL_ERROR "
Unable to determine CMAKE_BUILD_TYPE from  ${CMAKE_BINARY_DIR}
" )
	endif()
endif()

include( CapitalizeWord )
Capitalize_Word( ${BUILD_TYPE} BUILD_TYPE )
if( NOT BUILD_TYPE MATCHES "Release" AND
    NOT BUILD_TYPE MATCHES "Debug" )
	message( FATAL_ERROR "
Invalid Release/Debug BUILD_TYPE ${BUILD_TYPE}
" )
endif()
set( CMAKE_BUILD_TYPE  "${BUILD_TYPE}" CACHE PATH "" FORCE )

message( ${INSTALL_PREFIX} "  **  " ${BUILD_TYPE} )

endif( TRAVIS )

set( SHARED_LIBRARY )

#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   define the project
#
project( SoftFloat VERSION 3.1.0 )

#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#  	revision information
#
find_package( Git )
if( GIT_FOUND AND EXISTS ${CMAKE_SOURCE_DIR}/.git )

	include( GIT_Revision )
	message( "@@ Building ${PROJECT_NAME} revision ${GIT_WC_REVISION}" )
endif()

#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#  	headers
#
include( CheckIncludeFile )
include( CheckHeader )
check_header( stdbool.h )
check_header( stdint.h )

#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#  	CFLAGS
#
if( WIN32 )

else()
    set( CMAKE_C_FLAGS_DEBUG    "-g -g3 -ggdb3"
        CACHE STRING "" FORCE )
    set( CMAKE_C_FLAGS_RELEASE  "-g -O2"
        CACHE STRING "" FORCE )

endif()

#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#  	CDEFS
#
if( WIN32 )
    set( CDEFS_DEBUG            "/D HAVE_PLATFORM_H /D _DEBUG" )
    set( CDEFS_RELEASE          "/D HAVE_PLATFORM_H /D _NDEBUG" )

else()
    set( CDEFS_DEBUG            "-D HAVE_PLATFORM_H -D DEBUG" )
    set( CDEFS_RELEASE          "-D HAVE_PLATFORM_H -D NDEBUG" )

endif()

set( CMAKE_C_FLAGS_DEBUG    "${CMAKE_C_FLAGS_DEBUG}   ${CDEFS_DEBUG}" )
set( CMAKE_C_FLAGS_RELEASE  "${CMAKE_C_FLAGS_RELEASE} ${CDEFS_RELEASE}" )

# 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   generate platform.h
#
if( EXISTS ${CMAKE_SOURCE_DIR}/platform.h.in.${CMAKE_SYSTEM_NAME} )
	configure_file( ${CMAKE_SOURCE_DIR}/platform.h.in.${CMAKE_SYSTEM_NAME}
    	            ${CMAKE_BINARY_DIR}/platform.h )
elseif( EXISTS ${CMAKE_SOURCE_DIR}/platform.h.in )
	configure_file( ${CMAKE_SOURCE_DIR}/platform.h.in
    	            ${CMAKE_BINARY_DIR}/platform.h )
else()
	message( FATAL_ERROR "** Unable to find platform.h.in" )
endif()

# 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   generate stdbool.h
#
if( NOT HAVE_STDBOOL_H )
    if( EXISTS ${CMAKE_SOURCE_DIR}/stdbool.h.in )
	    configure_file( ${CMAKE_SOURCE_DIR}/stdbool.h.in
    	                ${CMAKE_BINARY_DIR}/stdbool.h )
    else()

    endif()
endif()

# 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   generate stdint.h
#
if( NOT HAVE_STDINT_H )
    if( EXISTS ${CMAKE_SOURCE_DIR}/stdint.h.in )
	    configure_file( ${CMAKE_SOURCE_DIR}/stdint.h.in
    	                ${CMAKE_BINARY_DIR}/stdint.h )
    else()

    endif()
endif()

# 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   SoftFloat.pc
#
if(     EXISTS ${CMAKE_SOURCE_DIR}/${PROJECT_NAME}.pc.in )
	configure_file( ${CMAKE_SOURCE_DIR}/${PROJECT_NAME}.pc.in
    	            ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.pc @ONLY )
    install(    FILES ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.pc
                DESTINATION lib/pkgconfig )
else()
        message( "@@ will not install '${PROJECT_NAME}.pc' " )
endif()

# 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   include directories
#
include_directories(    BEFORE
                    ${CMAKE_BINARY_DIR}
                    ${CMAKE_SOURCE_DIR}/source/8086-SSE
                    ${CMAKE_SOURCE_DIR}/source/include
                    )

# 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   SoftFloat Public Headers

set(    _l
        softfloat_types.h
        softfloat.h    
    )
list( SORT _l )
set( public_headers "" )
foreach( _s IN LISTS _l )
    list(   APPEND
            public_headers
            source/include/${_s} )
endforeach()

message( ${public_headers} )


# 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   the sources
#
# 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   SoftFloat Primitives
set(    _l
        s_add128.c
        s_add256M.c
        s_approxRecip32_1.c
        s_approxRecipSqrt32_1.c
        s_countLeadingZeros32.c
        s_countLeadingZeros64.c
        s_countLeadingZeros8.c
        s_eq128.c
        s_le128.c
        s_lt128.c
        s_mul128By32.c
        s_mul128To256M.c
        s_mul64ByShifted32To128.c
        s_mul64To128.c
        s_shiftRightJam128.c
        s_shiftRightJam128Extra.c
        s_shiftRightJam256M.c
        s_shiftRightJam32.c
        s_shiftRightJam64.c
        s_shiftRightJam64Extra.c
        s_shortShiftLeft128.c
        s_shortShiftRight128.c
        s_shortShiftRightJam128.c
        s_shortShiftRightJam128Extra.c
        s_shortShiftRightJam64.c
        s_shortShiftRightJam64Extra.c
        s_sub128.c
        s_sub256M.c
    )
list( SORT _l )
set(    SoftFloat_PRIMITIVES "" )
foreach( _s IN LISTS _l )
    list(   APPEND
            SoftFloat_PRIMITIVES
            source/${_s} )
endforeach()

# 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   SoftFloat Specialised
set(    _l
 #[[    extF80M_isSignalingNaN.c   extF80 and "M" variants not required  ]]
 #[[    f128M_isSignalingNaN.c                                           ]]
 #[[    s_commonNaNToExtF80UI.c                                          ]]
        s_commonNaNToF128UI.c
        s_commonNaNToF32UI.c
        s_commonNaNToF64UI.c
 #[[    s_extF80UIToCommonNaN.c                                          ]]
        s_f128UIToCommonNaN.c
        s_f32UIToCommonNaN.c
        s_f64UIToCommonNaN.c
 #[[    s_propagateNaNExtF80UI.c                                         ]]
        ../${HERCMODS}s_propagateNaNF128UI.c
        ../${HERCMODS}s_propagateNaNF32UI.c
        ../${HERCMODS}s_propagateNaNF64UI.c
 #[[    softfloat_raiseFlags.c    Function call replaced by macro        ]]
    )
list( SORT _l )
set(    SoftFloat_SPECIALISED "" )
foreach( _s IN LISTS _l )
    list(   APPEND
            SoftFloat_SPECIALISED
            source/8086-SSE/${_s} )
endforeach()

# 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   SoftFloat Others
set(    _l
  #[[   extF80_add.c    ********************** extF80/extMF80 is not used by Hercules
        extF80_div.c
        extF80_eq_signaling.c
        extF80_eq.c
        extF80_isSignalingNaN.c
        extF80_le_quiet.c
        extF80_le.c
        extF80_lt_quiet.c
        extF80_lt.c
        extF80_mul.c
        extF80_rem.c
        extF80_roundToInt.c
        extF80_sqrt.c
        extF80_sub.c
        extF80_to_f128.c
        extF80_to_f32.c
        extF80_to_f64.c
        extF80_to_i32_r_minMag.c
        extF80_to_i32.c
        extF80_to_i64_r_minMag.c
        extF80_to_i64.c
        extF80_to_ui32_r_minMag.c
        extF80_to_ui32.c
        extF80_to_ui64_r_minMag.c
        extF80_to_ui64.c
        extF80M_add.c
        extF80M_div.c
        extF80M_eq_signaling.c
        extF80M_eq.c
        extF80M_le_quiet.c
        extF80M_le.c
        extF80M_lt_quiet.c
        extF80M_lt.c
        extF80M_mul.c
        extF80M_rem.c
        extF80M_roundToInt.c
        extF80M_sqrt.c
        extF80M_sub.c
        extF80M_to_f128M.c
        extF80M_to_f32.c
        extF80M_to_f64.c
        extF80M_to_i32_r_minMag.c
        extF80M_to_i32.c
        extF80M_to_i64_r_minMag.c
        extF80M_to_i64.c
        extF80M_to_ui32_r_minMag.c
        extF80M_to_ui32.c
        extF80M_to_ui64_r_minMag.c
        extF80M_to_ui64.c         ******************************************* ]]
        f128_add.c
        f128_div.c
        f128_eq_signaling.c
        f128_eq.c
        f128_isSignalingNaN.c
        f128_le_quiet.c
        f128_le.c
        f128_lt_quiet.c
        f128_lt.c
        f128_mul.c
        f128_mulAdd.c
        f128_rem.c
        ${HERCMODS}f128_roundToInt.c
        f128_sqrt.c
        f128_sub.c
 #[[    f128_to_extF80.c                                    ]]
        f128_to_f32.c
        f128_to_f64.c
        f128_to_i32_r_minMag.c
        f128_to_i32.c
        f128_to_i64_r_minMag.c
        f128_to_i64.c
        f128_to_ui32_r_minMag.c
        f128_to_ui32.c
        f128_to_ui64_r_minMag.c
        ${HERCMODS}f128_to_ui64.c
  #[[   f128M_add.c                    Pointer versions of functions are not used by Hercules
        f128M_div.c
        f128M_eq_signaling.c
        f128M_eq.c
        f128M_le_quiet.c
        f128M_le.c
        f128M_lt_quiet.c
        f128M_lt.c
        f128M_mul.c
        f128M_mulAdd.c
        f128M_rem.c
        f128M_roundToInt.c
        f128M_sqrt.c
        f128M_sub.c
        f128M_to_extF80M.c
        f128M_to_f32.c
        f128M_to_f64.c
        f128M_to_i32_r_minMag.c
        f128M_to_i32.c
        f128M_to_i64_r_minMag.c
        f128M_to_i64.c
        f128M_to_ui32_r_minMag.c
        f128M_to_ui32.c
        f128M_to_ui64_r_minMag.c
        f128M_to_ui64.c                 ******************* ]]
        f32_add.c
        f32_div.c
        f32_eq_signaling.c
        f32_eq.c
        f32_isSignalingNaN.c
        f32_le_quiet.c
        f32_le.c
        f32_lt_quiet.c
        f32_lt.c
        f32_mul.c
        f32_mulAdd.c
        f32_rem.c
        ${HERCMODS}f32_roundToInt.c
        f32_sqrt.c
        f32_sub.c
 #[[    f32_to_extF80.c    ]]
 #[[    f32_to_extF80M.c   ]]
        f32_to_f128.c
 #[[    f32_to_f128M.c     ]]
        f32_to_f64.c
        f32_to_i32_r_minMag.c
        f32_to_i32.c
        f32_to_i64_r_minMag.c
        f32_to_i64.c
        f32_to_ui32_r_minMag.c
        f32_to_ui32.c
        f32_to_ui64_r_minMag.c
        ${HERCMODS}f32_to_ui64.c
        f64_add.c
        f64_div.c
        f64_eq_signaling.c
        f64_eq.c
        f64_isSignalingNaN.c
        f64_le_quiet.c
        f64_le.c
        f64_lt_quiet.c
        f64_lt.c
        f64_mul.c
        f64_mulAdd.c
        f64_rem.c
        ${HERCMODS}f64_roundToInt.c
        f64_sqrt.c
        f64_sub.c
 #[[    f64_to_extF80.c             ]]
 #[[    f64_to_extF80M.c            ]]
        f64_to_f128.c
 #[[    f64_to_f128M.c              ]]
        f64_to_f32.c
        f64_to_i32_r_minMag.c
        f64_to_i32.c
        f64_to_i64_r_minMag.c
        f64_to_i64.c
        f64_to_ui32_r_minMag.c
        f64_to_ui32.c
        f64_to_ui64_r_minMag.c
        ${HERCMODS}f64_to_ui64.c
 #[[    i32_to_extF80.c             ]]
 #[[    i32_to_extF80M.c            ]]
        i32_to_f128.c
 #[[    i32_to_f128M.c              ]]
        i32_to_f32.c
        i32_to_f64.c
 #[[    i64_to_extF80.c             ]]
 #[[    i64_to_extF80M.c            ]]
        i64_to_f128.c
 #[[    i64_to_f128M.c              ]]
        i64_to_f32.c
        i64_to_f64.c
 #[[    s_addMagsExtF80.c           ]]
        ${HERCMODS}s_addMagsF128.c
        ${HERCMODS}s_addMagsF32.c
        ${HERCMODS}s_addMagsF64.c
        s_mulAddF128.c
        ${HERCMODS}s_mulAddF32.c
        ${HERCMODS}s_mulAddF64.c
 #[[    s_normRoundPackToExtF80.c   ]]
        s_normRoundPackToF128.c
        s_normRoundPackToF32.c
        s_normRoundPackToF64.c
 #[[    s_normSubnormalExtF80Sig.c  ]]
        s_normSubnormalF128Sig.c
        s_normSubnormalF32Sig.c
        s_normSubnormalF64Sig.c
#[[     s_roundPackToExtF80.c       ]]        
        ${HERCMODS}s_roundPackToF128.c
        ${HERCMODS}s_roundPackToF32.c
        ${HERCMODS}s_roundPackToF64.c
        ${HERCMODS}s_roundPackToI32.c
        ${HERCMODS}s_roundPackToI64.c
        ${HERCMODS}s_roundPackToUI32.c
        ${HERCMODS}s_roundPackToUI64.c
 #[[    s_subMagsExtF80.c           ]]
        s_subMagsF128.c
        s_subMagsF32.c
        s_subMagsF64.c
        ${HERCMODS}softfloat_state.c
 #[[    ui32_to_extF80.c            ]]
 #[[    ui32_to_extF80M.c           ]]
        ui32_to_f128.c
 #[[    ui32_to_f128M.c             ]]
        ui32_to_f32.c
        ui32_to_f64.c
 #[[    ui64_to_extF80.c            ]]
 #[[    ui64_to_extF80M.c           ]]
        ui64_to_f128.c
 #[[    ui64_to_f128M.c             ]]
        ui64_to_f32.c
        ui64_to_f64.c
    )
list( SORT _l )
set(    SoftFloat_OTHERS "" )
foreach( _s IN LISTS _l )
    list(   APPEND
            SoftFloat_OTHERS
            source/${_s} )
endforeach()

# 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   Hercules-required additions to SoftFloat
set(    _l
        f32_scaledResult.c
        f64_scaledResult.c
        f128_scaledResult.c
    )
list( SORT _l )
set(    SoftFloat_HERCMODS "" )
foreach( _s IN LISTS _l )
    list(   APPEND
            SoftFloat_HERCMODS
            hercsource/${_s} )
endforeach()


set(    SoftFloat_SRCS
        ${SoftFloat_PRIMITIVES}
        ${SoftFloat_SPECIALISED}
        ${SoftFloat_OTHERS}
        ${SoftFloat_HERCMODS} )

# 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   the static library
add_library( SoftFloat STATIC ${SoftFloat_SRCS} )
set_target_properties(  SoftFloat PROPERTIES
						OUTPUT_NAME SoftFloat
						PUBLIC_HEADER "${public_headers}" )

# Because the static library will be included in a shared library,
# Position-independent code is required for non-Windows builds.  
if ( WIN32 )
else ( )
    set_target_properties( SoftFloat PROPERTIES POSITION_INDEPENDENT_CODE ON )
endif ( )

install( TARGETS SoftFloat
        ARCHIVE DESTINATION lib
        PUBLIC_HEADER DESTINATION include)

# 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   the shared library
if( SHARED_LIBRARY )
add_library( SoftFloat_shared SHARED ${SoftFloat_SRCS} )
set_target_properties(  SoftFloat_shared PROPERTIES
						OUTPUT_NAME SoftFloat
                        PUBLIC_HEADER "${public_headers}" )

install( TARGETS SoftFloat_shared
        LIBRARY DESTINATION lib
        PUBLIC_HEADER DESTINATION include)
endif()

install(FILES "COPYING.txt" DESTINATION "." )
install(FILES "README.txt"  DESTINATION "." )
install(FILES "README.html" DESTINATION "." )

# 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   the cpack installers definitions
#
if( WIN32 )
    set( CPACK_GENERATOR "ZIP" )
else()
    set( CPACK_GENERATOR "TGZ" )
endif()

set( CPACK_PACKAGE_NAME         "${PROJECT_NAME}" )
#set( CPACK_PACKAGE_VERSION      "${${PROJECT_NAME}_VERSION}" )
set( CPACK_PACKAGE_FILE_NAME    "${CPACK_PACKAGE_NAME}" )

# 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   the cpack installers
#
include(CPack)

get_filename_component( CURRENT_LIST_FILE "${CMAKE_CURRENT_LIST_FILE}" NAME)
Vdump( "${CURRENT_LIST_FILE}" "at_exit" )