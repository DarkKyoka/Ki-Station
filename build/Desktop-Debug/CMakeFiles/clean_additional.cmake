# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "Debug")
  file(REMOVE_RECURSE
  "CMakeFiles/appKi_Station_autogen.dir/AutogenUsed.txt"
  "CMakeFiles/appKi_Station_autogen.dir/ParseCache.txt"
  "appKi_Station_autogen"
  )
endif()
