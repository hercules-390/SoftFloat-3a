#------------------------------------------------------------------------------
#                           GIT_Revision.cmake
#------------------------------------------------------------------------------

# Output values:  GIT_COMMIT_COUNT, GIT_HASH7 and GIT_MODIFIED

#-----------------
#  Commit count
#-----------------

execute_process( COMMAND ${GIT_EXECUTABLE} rev-list HEAD --count
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    RESULT_VARIABLE _r
    ERROR_VARIABLE  _e
    ERROR_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE _o
    OUTPUT_STRIP_TRAILING_WHITESPACE )

if( NOT ${_r} EQUAL 0 )
    message( FATAL_ERROR "Command \"${GIT_EXECUTABLE} rev-list HEAD --count\" failed with rc=${_r}: ${_e}" )
endif()

string( STRIP ${_o} GIT_COMMIT_COUNT )
trace( GIT_COMMIT_COUNT )

#-----------------
#     Hash
#-----------------

execute_process( COMMAND ${GIT_EXECUTABLE} log -1 --pretty=format:%H
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    RESULT_VARIABLE _r
    ERROR_VARIABLE  _e
    ERROR_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE _o
    OUTPUT_STRIP_TRAILING_WHITESPACE )

if( NOT ${_r} EQUAL 0 )
    message( FATAL_ERROR "Command \"${GIT_EXECUTABLE} log -1 --pretty=format:%H\" failed with rc=${_r}: ${_e}" )
endif()

string( SUBSTRING ${_o} 0 7 GIT_HASH7 )
trace( GIT_HASH7 )

#-----------------
# Pending changes
#-----------------

execute_process( COMMAND ${GIT_EXECUTABLE} diff-index --name-only HEAD --
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    RESULT_VARIABLE _r
    ERROR_VARIABLE  _e
    ERROR_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE _o
    OUTPUT_STRIP_TRAILING_WHITESPACE )

if( NOT ${_r} EQUAL 0 )
    message( FATAL_ERROR "Command \"${GIT_EXECUTABLE} diff-index --name-only HEAD --\" failed with rc=${_r}: ${_e}" )
endif()

if( "${_o}" STREQUAL "" )
    set( GIT_MODIFIED "" )
else()
    set( GIT_MODIFIED "-modified" )
endif()
trace( GIT_MODIFIED )

#------------------------------------------------------------------------------
