cmake_minimum_required(VERSION 2.8)
project(secp256k1)
include_directories("include")

if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
	set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /MD")
	set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /MDd")
ENDIF()
   
file(GLOB_RECURSE SOURCE_FILES
	"secp256k1.c"
)
   
# add_definitions(-DUSE_SCALAR_4X64)
add_definitions(-DUSE_SCALAR_8X32)
   
add_definitions(-DUSE_SCALAR_INV_BUILTIN)
# add_definitions(-DUSE_SCALAR_INV_NUM)
   
add_definitions(-DUSE_FIELD_INV_BUILTIN)
# add_definitions(-DUSE_FIELD_INV_NUM)
   
add_definitions(-DUSE_FIELD_10X26)
# add_definitions(-DUSE_FIELD_5X52)
   
add_definitions(-DUSE_NUM_GMP)
   
add_library(secp256k1 STATIC ${SOURCE_FILES})
install(TARGETS secp256k1 DESTINATION lib)
install(FILES "include/secp256k1.h" DESTINATION include)