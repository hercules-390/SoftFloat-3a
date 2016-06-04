#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   Global settings
#
cmake_minimum_required( VERSION 3.4 )

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
#   the directory with the CMAKE user modules
#
if( EXISTS "${CMAKE_SOURCE_DIR}/cmake/modules" )
    set( CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/modules" )
    include( Vdump )
    include( Trace )
else()
	message( FATAL_ERROR "
Cmake modules directory not found '${CMAKE_SOURCE_DIR}/cmake/modules'
" )
endif()

#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#  	install prefix, and build type
#
get_filename_component( BINARY_HLQ ${CMAKE_BINARY_DIR} DIRECTORY )
get_filename_component( BINARY_DIR ${CMAKE_BINARY_DIR} NAME )

#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if( NOT DEFINED INSTALL_PREFIX )
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
	message( "@@ Building SoftFloat revision ${GIT_WC_REVISION}" )
else()
    set(REVISION_STRING "Final" )
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
    set( CDEFS_DEBUG            "/D HAVE_PLATFORM_H /D DEBUG" )
    set( CDEFS_RELEASE          "/D HAVE_PLATFORM_H /D NDEBUG" )

else()
    set( CDEFS_DEBUG            "-D HAVE_PLATFORM_H -D DEBUG" )
    set( CDEFS_RELEASE          "-D HAVE_PLATFORM_H -D NDEBUG" )

endif()

set( CMAKE_C_FLAGS_DEBUG    "${CMAKE_C_FLAGS_DEBUG}   ${CDEFS_DEBUG}" )
set( CMAKE_C_FLAGS_RELEASE  "${CMAKE_C_FLAGS_RELEASE} ${CDEFS_RELEASE}" )


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
#   SoftFloat.pc
#
if(     EXISTS ${CMAKE_SOURCE_DIR}/SoftFloat.pc.in )
	configure_file( ${CMAKE_SOURCE_DIR}/SoftFloat.pc.in
    	            ${CMAKE_BINARY_DIR}/SoftFloat.pc @ONLY )
    install(    FILES ${CMAKE_BINARY_DIR}/SoftFloat.pc
                DESTINATION lib/pkgconfig )
else()
        message( "@@ will not install 'SoftFloat.pc' " )
endif()

# 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   include directories
#
include_directories(    BEFORE
                    ${CMAKE_BINARY_DIR}
                    ${CMAKE_SOURCE_DIR}/include
                    )
include_directories(    BEFORE
                    ${CMAKE_BINARY_DIR}
                    ${CMAKE_SOURCE_DIR}
                    ${CMAKE_SOURCE_DIR}/source/8086-SSE
                    ${CMAKE_SOURCE_DIR}/source/include
                    )

# 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   the public headers
file( GLOB public_headers
        RELATIVE "${CMAKE_SOURCE_DIR}" "source/include/*.h" )
list( SORT public_headers )

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
        extF80M_isSignalingNaN.c
        f128M_isSignalingNaN.c
        s_commonNaNToExtF80UI.c
        s_commonNaNToF128UI.c
        s_commonNaNToF32UI.c
        s_commonNaNToF64UI.c
        s_extF80UIToCommonNaN.c
        s_f128UIToCommonNaN.c
        s_f32UIToCommonNaN.c
        s_f64UIToCommonNaN.c
        s_propagateNaNExtF80UI.c
        s_propagateNaNF128UI.c
        s_propagateNaNF32UI.c
        s_propagateNaNF64UI.c
        softfloat_raiseFlags.c
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
        extF80_add.c
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
        extF80M_to_ui64.c
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
        f128_roundToInt.c
        f128_sqrt.c
        f128_sub.c
        f128_to_extF80.c
        f128_to_f32.c
        f128_to_f64.c
        f128_to_i32_r_minMag.c
        f128_to_i32.c
        f128_to_i64_r_minMag.c
        f128_to_i64.c
        f128_to_ui32_r_minMag.c
        f128_to_ui32.c
        f128_to_ui64_r_minMag.c
        f128_to_ui64.c
        f128M_add.c
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
        f128M_to_ui64.c
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
        f32_roundToInt.c
        f32_sqrt.c
        f32_sub.c
        f32_to_extF80.c
        f32_to_extF80M.c
        f32_to_f128.c
        f32_to_f128M.c
        f32_to_f64.c
        f32_to_i32_r_minMag.c
        f32_to_i32.c
        f32_to_i64_r_minMag.c
        f32_to_i64.c
        f32_to_ui32_r_minMag.c
        f32_to_ui32.c
        f32_to_ui64_r_minMag.c
        f32_to_ui64.c
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
        f64_roundToInt.c
        f64_sqrt.c
        f64_sub.c
        f64_to_extF80.c
        f64_to_extF80M.c
        f64_to_f128.c
        f64_to_f128M.c
        f64_to_f32.c
        f64_to_i32_r_minMag.c
        f64_to_i32.c
        f64_to_i64_r_minMag.c
        f64_to_i64.c
        f64_to_ui32_r_minMag.c
        f64_to_ui32.c
        f64_to_ui64_r_minMag.c
        f64_to_ui64.c
        i32_to_extF80.c
        i32_to_extF80M.c
        i32_to_f128.c
        i32_to_f128M.c
        i32_to_f32.c
        i32_to_f64.c
        i64_to_extF80.c
        i64_to_extF80M.c
        i64_to_f128.c
        i64_to_f128M.c
        i64_to_f32.c
        i64_to_f64.c
        s_addMagsExtF80.c
        s_addMagsF128.c
        s_addMagsF32.c
        s_addMagsF64.c
        s_mulAddF128.c
        s_mulAddF32.c
        s_mulAddF64.c
        s_normRoundPackToExtF80.c
        s_normRoundPackToF128.c
        s_normRoundPackToF32.c
        s_normRoundPackToF64.c
        s_normSubnormalExtF80Sig.c
        s_normSubnormalF128Sig.c
        s_normSubnormalF32Sig.c
        s_normSubnormalF64Sig.c
        s_roundPackToExtF80.c
        s_roundPackToF128.c
        s_roundPackToF32.c
        s_roundPackToF64.c
        s_roundPackToI32.c
        s_roundPackToI64.c
        s_roundPackToUI32.c
        s_roundPackToUI64.c
        s_subMagsExtF80.c
        s_subMagsF128.c
        s_subMagsF32.c
        s_subMagsF64.c
        softfloat_state.c
        ui32_to_extF80.c
        ui32_to_extF80M.c
        ui32_to_f128.c
        ui32_to_f128M.c
        ui32_to_f32.c
        ui32_to_f64.c
        ui64_to_extF80.c
        ui64_to_extF80M.c
        ui64_to_f128.c
        ui64_to_f128M.c
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

set(    SoftFloat_SRCS
        ${SoftFloat_PRIMITIVES}
        ${SoftFloat_SPECIALISED}
        ${SoftFloat_OTHERS} )

# 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   the static library
add_library( SoftFloat STATIC ${SoftFloat_SRCS} )
set_target_properties(  SoftFloat PROPERTIES
						OUTPUT_NAME SoftFloat
						PUBLIC_HEADER "${public_headers}" )
install( TARGETS SoftFloat
        ARCHIVE DESTINATION lib
        LIBRARY DESTINATION lib
        PUBLIC_HEADER DESTINATION include)

# 	- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   the shared library
if( SHARED_LIBRARY )
add_library( SoftFloat_shared SHARED ${SoftFloat_SRCS} )
set_target_properties(  SoftFloat_shared PROPERTIES
						OUTPUT_NAME SoftFloat
                        PUBLIC_HEADER "${public_headers}" )
install( TARGETS SoftFloat_shared
        ARCHIVE DESTINATION lib
        LIBRARY DESTINATION lib
        PUBLIC_HEADER DESTINATION include)
endif()

get_filename_component( CURRENT_LIST_FILE "${CMAKE_CURRENT_LIST_FILE}" NAME)
Vdump( "${CURRENT_LIST_FILE}" "${CMAKE_CURRENT_LIST_LINE}" )
