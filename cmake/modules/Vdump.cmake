#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
macro( vdump _list _from )

    set( _line "0000${_from}" ) 
       
    string( LENGTH "${_line}"  _size )    
    
    math( EXPR _indx "${_size} - 4" )    
    
    string(SUBSTRING ${_line} ${_indx} -1 _line )
         
    string( REGEX REPLACE "[^a-zA-Z0-9_]" "_" _file "vars_at_${_list}_${_line}")
	
	set( _file "${CMAKE_BINARY_DIR}/${_file}.txt" )
	
	file( REMOVE ${_file} )
	
	get_cmake_property( _vars VARIABLES )
	
    if( 1 )
	foreach( _iden IN LISTS _vars )

        string( LENGTH "${_iden}"  _size ) 
        if( _size LESS 4 )
            continue()
        endif()

        string( SUBSTRING "${_iden}" 0 1 _pref )
        string( TOLOWER "${_pref}" _pref )
        if( "${_pref}" STREQUAL "_" )
        	continue()
		endif()

        if( "${_iden}" STREQUAL "OUTPUT" )
        	continue()
		endif()


		if( "${_iden}" MATCHES "(_CONTENT)$" )
			continue()
		endif()

		file( APPEND 	${_file}
			            "++ ${_iden}='${${_iden}}'\n" )
			            
	endforeach()
    endif()

endmacro()
