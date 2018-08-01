cmake_minimum_required(VERSION 2.8)
project(gettext C)

include_directories(".")

set(HEADER_FILES "config.h" "libgnuintl.h")

if("${CMAKE_C_COMPILER_ID}" STREQUAL "MSVC")
	set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /MT")
	set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} /MTd")
ENDIF()

add_definitions(-DIN_LIBINTL -DENABLE_RELOCATABLE=1 -DIN_LIBRARY -DHAVE_CONFIG_H -D_CRT_SECURE_NO_WARNINGS)

file(GLOB_RECURSE SOURCE_FILES	
	"gettext-runtime/intl/bindtextdom.c"
    "gettext-runtime/intl/dcgettext.c"
    "gettext-runtime/intl/dcigettext.c"
    "gettext-runtime/intl/dcngettext.c"
    "gettext-runtime/intl/dgettext.c"
    "gettext-runtime/intl/dngettext.c"
    "gettext-runtime/intl/explodename.c"
    "gettext-runtime/intl/finddomain.c"
    "gettext-runtime/intl/gettext.c"
    "gettext-runtime/intl/hash-string.c"
    "gettext-runtime/intl/intl-compat.c"
    "gettext-runtime/intl/l10nflist.c"
    "gettext-runtime/intl/langprefs.c"
    "gettext-runtime/intl/loadmsgcat.c"
    "gettext-runtime/intl/localcharset.c"
    "gettext-runtime/intl/localealias.c"
    "gettext-runtime/intl/localename.c"
    "gettext-runtime/intl/lock.c"
    "gettext-runtime/intl/log.c"
    "gettext-runtime/intl/ngettext.c"
    "gettext-runtime/intl/osdep.c"
    "gettext-runtime/intl/plural-exp.c"
    "gettext-runtime/intl/plural.c"
    "gettext-runtime/intl/printf.c"
    "gettext-runtime/intl/relocatable.c"
    "gettext-runtime/intl/setlocale.c"
    "gettext-runtime/intl/textdomain.c"
    "gettext-runtime/intl/version.c"
    "gettext-runtime/intl/xsize.c"
)

add_library(libintl STATIC ${SOURCE_FILES} ${HEADER_FILES})
install(TARGETS libintl DESTINATION lib)
install(FILES "libgnuintl.h" DESTINATION include RENAME "libintl.h")