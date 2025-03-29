


































# Find the Developer root for the specific iOS platform being compiled for
# from CMAKE_OSX_SYSROOT.  Should be ../../ from SDK specified in
# CMAKE_OSX_SYSROOT. There does not appear to be a direct way to obtain
# this information from xcrun or xcodebuild.
if (NOT DEFINED CMAKE_DEVELOPER_ROOT AND NOT CMAKE_GENERATOR MATCHES "Xcode")
  get_filename_component(PLATFORM_SDK_DIR ${CMAKE_OSX_SYSROOT_INT} PATH)
  get_filename_component(CMAKE_DEVELOPER_ROOT ${PLATFORM_SDK_DIR} PATH)
endif()

# Find the C & C++ compilers for the specified SDK.
if(DEFINED CMAKE_C_COMPILER)
  # Environment variables are always preserved.
  set(ENV{_CMAKE_C_COMPILER} "${CMAKE_C_COMPILER}")
elseif(DEFINED ENV{_CMAKE_C_COMPILER})
  set(CMAKE_C_COMPILER "$ENV{_CMAKE_C_COMPILER}")
  set(CMAKE_ASM_COMPILER ${CMAKE_C_COMPILER})
elseif(NOT DEFINED CMAKE_C_COMPILER)
  execute_process(COMMAND xcrun -sdk ${CMAKE_OSX_SYSROOT_INT} -find clang
          OUTPUT_VARIABLE CMAKE_C_COMPILER
          ERROR_QUIET
          OUTPUT_STRIP_TRAILING_WHITESPACE)
  set(CMAKE_ASM_COMPILER ${CMAKE_C_COMPILER})
endif()
if(DEFINED CMAKE_CXX_COMPILER)
  # Environment variables are always preserved.
  set(ENV{_CMAKE_CXX_COMPILER} "${CMAKE_CXX_COMPILER}")
elseif(DEFINED ENV{_CMAKE_CXX_COMPILER})
  set(CMAKE_CXX_COMPILER "$ENV{_CMAKE_CXX_COMPILER}")
elseif(NOT DEFINED CMAKE_CXX_COMPILER)
  execute_process(COMMAND xcrun -sdk ${CMAKE_OSX_SYSROOT_INT} -find clang++
          OUTPUT_VARIABLE CMAKE_CXX_COMPILER
          ERROR_QUIET
          OUTPUT_STRIP_TRAILING_WHITESPACE)
endif()
# Find (Apple's) libtool.
if(DEFINED BUILD_LIBTOOL)
  # Environment variables are always preserved.
  set(ENV{_BUILD_LIBTOOL} "${BUILD_LIBTOOL}")
elseif(DEFINED ENV{_BUILD_LIBTOOL})
  set(BUILD_LIBTOOL "$ENV{_BUILD_LIBTOOL}")
elseif(NOT DEFINED BUILD_LIBTOOL)
  execute_process(COMMAND xcrun -sdk ${CMAKE_OSX_SYSROOT_INT} -find libtool
          OUTPUT_VARIABLE BUILD_LIBTOOL
          ERROR_QUIET
          OUTPUT_STRIP_TRAILING_WHITESPACE)
endif()
# Find the toolchain's provided install_name_tool if none is found on the host
if(DEFINED CMAKE_INSTALL_NAME_TOOL)
  # Environment variables are always preserved.
  set(ENV{_CMAKE_INSTALL_NAME_TOOL} "${CMAKE_INSTALL_NAME_TOOL}")
elseif(DEFINED ENV{_CMAKE_INSTALL_NAME_TOOL})
  set(CMAKE_INSTALL_NAME_TOOL "$ENV{_CMAKE_INSTALL_NAME_TOOL}")
elseif(NOT DEFINED CMAKE_INSTALL_NAME_TOOL)
  execute_process(COMMAND xcrun -sdk ${CMAKE_OSX_SYSROOT_INT} -find install_name_tool
          OUTPUT_VARIABLE CMAKE_INSTALL_NAME_TOOL_INT
          ERROR_QUIET
          OUTPUT_STRIP_TRAILING_WHITESPACE)
  set(CMAKE_INSTALL_NAME_TOOL ${CMAKE_INSTALL_NAME_TOOL_INT} CACHE INTERNAL "")
endif()

# Configure libtool to be used instead of ar + ranlib to build static libraries.
# This is required on Xcode 7+, but should also work on previous versions of
# Xcode.
get_property(languages GLOBAL PROPERTY ENABLED_LANGUAGES)
foreach(lang ${languages})
  set(CMAKE_${lang}_CREATE_STATIC_LIBRARY "${BUILD_LIBTOOL} -static -o <TARGET> <LINK_FLAGS> <OBJECTS> " CACHE INTERNAL "")
endforeach()

# CMake 3.14+ support building for iOS, watchOS, and tvOS out of the box.
if(MODERN_CMAKE)
  if(SDK_NAME MATCHES "iphone")
    set(CMAKE_SYSTEM_NAME iOS)
  elseif(SDK_NAME MATCHES "xros")
      set(CMAKE_SYSTEM_NAME visionOS)
  elseif(SDK_NAME MATCHES "xrsimulator")
      set(CMAKE_SYSTEM_NAME visionOS)
  elseif(SDK_NAME MATCHES "macosx")
    set(CMAKE_SYSTEM_NAME Darwin)
  elseif(SDK_NAME MATCHES "appletv")
    set(CMAKE_SYSTEM_NAME tvOS)
  elseif(SDK_NAME MATCHES "watch")
    set(CMAKE_SYSTEM_NAME watchOS)
  endif()
  # Provide flags for a combined FAT library build on newer CMake versions
  if(PLATFORM_INT MATCHES ".*COMBINED")
    set(CMAKE_IOS_INSTALL_COMBINED YES)
    if(CMAKE_GENERATOR MATCHES "Xcode")
      # Set the SDKROOT Xcode properties to a Xcode-friendly value (the SDK_NAME, E.g, iphoneos)
      # This way, Xcode will automatically switch between the simulator and device SDK when building.
      set(CMAKE_XCODE_ATTRIBUTE_SDKROOT "${SDK_NAME}")
      # Force to not build just one ARCH, but all!
      set(CMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH "NO")
    endif()
  endif()
elseif(NOT DEFINED CMAKE_SYSTEM_NAME AND ${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.10")
  # Legacy code path prior to CMake 3.14 or fallback if no CMAKE_SYSTEM_NAME specified
  set(CMAKE_SYSTEM_NAME iOS)
elseif(NOT DEFINED CMAKE_SYSTEM_NAME)
  # Legacy code path before CMake 3.14 or fallback if no CMAKE_SYSTEM_NAME specified
  set(CMAKE_SYSTEM_NAME Darwin)
endif()
# Standard settings.
set(CMAKE_SYSTEM_VERSION ${SDK_VERSION} CACHE INTERNAL "")
set(UNIX ON CACHE BOOL "")
set(APPLE ON CACHE BOOL "")
if(PLATFORM STREQUAL "MAC" OR PLATFORM STREQUAL "MAC_ARM64" OR PLATFORM STREQUAL "MAC_UNIVERSAL")
  set(IOS OFF CACHE BOOL "")
  set(MACOS ON CACHE BOOL "")
elseif(PLATFORM STREQUAL "MAC_CATALYST" OR PLATFORM STREQUAL "MAC_CATALYST_ARM64")
  set(IOS ON CACHE BOOL "")
  set(MACOS ON CACHE BOOL "")
else()
  set(IOS ON CACHE BOOL "")
endif()
# Set the architectures for which to build.
set(CMAKE_OSX_ARCHITECTURES ${ARCHS} CACHE INTERNAL "")
# Change the type of target generated for try_compile() so it'll work when cross-compiling, weak compiler checks
if(NOT ENABLE_STRICT_TRY_COMPILE_INT)
  set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
endif()
# All iOS/Darwin specific settings - some may be redundant.
if (NOT DEFINED CMAKE_MACOSX_BUNDLE)
  set(CMAKE_MACOSX_BUNDLE YES)
endif()
set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "NO")
set(CMAKE_SHARED_LIBRARY_PREFIX "lib")
set(CMAKE_SHARED_LIBRARY_SUFFIX ".dylib")
set(CMAKE_EXTRA_SHARED_LIBRARY_SUFFIXES ".tbd" ".so")
set(CMAKE_SHARED_MODULE_PREFIX "lib")
set(CMAKE_SHARED_MODULE_SUFFIX ".so")
set(CMAKE_C_COMPILER_ABI ELF)
set(CMAKE_CXX_COMPILER_ABI ELF)
set(CMAKE_C_HAS_ISYSROOT 1)
set(CMAKE_CXX_HAS_ISYSROOT 1)
set(CMAKE_MODULE_EXISTS 1)
set(CMAKE_DL_LIBS "")
set(CMAKE_C_OSX_COMPATIBILITY_VERSION_FLAG "-compatibility_version ")
set(CMAKE_C_OSX_CURRENT_VERSION_FLAG "-current_version ")
set(CMAKE_CXX_OSX_COMPATIBILITY_VERSION_FLAG "${CMAKE_C_OSX_COMPATIBILITY_VERSION_FLAG}")
set(CMAKE_CXX_OSX_CURRENT_VERSION_FLAG "${CMAKE_C_OSX_CURRENT_VERSION_FLAG}")

if(ARCHS MATCHES "((^|;|, )(arm64|arm64e|x86_64))+")
  set(CMAKE_C_SIZEOF_DATA_PTR 8)
  set(CMAKE_CXX_SIZEOF_DATA_PTR 8)
  if(ARCHS MATCHES "((^|;|, )(arm64|arm64e))+")
    set(CMAKE_SYSTEM_PROCESSOR "aarch64")
  else()
    set(CMAKE_SYSTEM_PROCESSOR "x86_64")
  endif()
else()
  set(CMAKE_C_SIZEOF_DATA_PTR 4)
  set(CMAKE_CXX_SIZEOF_DATA_PTR 4)
  set(CMAKE_SYSTEM_PROCESSOR "arm")
endif()

# Note that only Xcode 7+ supports the newer more specific:
# -m${SDK_NAME}-version-min flags, older versions of Xcode use:
# -m(ios/ios-simulator)-version-min instead.
if(${CMAKE_VERSION} VERSION_LESS "3.11")
  if(PLATFORM_INT STREQUAL "OS" OR PLATFORM_INT STREQUAL "OS64")
    if(XCODE_VERSION_INT VERSION_LESS 7.0)
      set(SDK_NAME_VERSION_FLAGS
              "-mios-version-min=${DEPLOYMENT_TARGET}")
    else()
      # Xcode 7.0+ uses flags we can build directly from SDK_NAME.
      set(SDK_NAME_VERSION_FLAGS
              "-m${SDK_NAME}-version-min=${DEPLOYMENT_TARGET}")
    endif()
  elseif(PLATFORM_INT STREQUAL "TVOS")
    set(SDK_NAME_VERSION_FLAGS
            "-mtvos-version-min=${DEPLOYMENT_TARGET}")
  elseif(PLATFORM_INT STREQUAL "SIMULATOR_TVOS")
    set(SDK_NAME_VERSION_FLAGS
            "-mtvos-simulator-version-min=${DEPLOYMENT_TARGET}")
elseif(PLATFORM_INT STREQUAL "SIMULATORARM64_TVOS")
    set(SDK_NAME_VERSION_FLAGS
            "-mtvos-simulator-version-min=${DEPLOYMENT_TARGET}")
  elseif(PLATFORM_INT STREQUAL "WATCHOS")
    set(SDK_NAME_VERSION_FLAGS
            "-mwatchos-version-min=${DEPLOYMENT_TARGET}")
  elseif(PLATFORM_INT STREQUAL "SIMULATOR_WATCHOS")
    set(SDK_NAME_VERSION_FLAGS
            "-mwatchos-simulator-version-min=${DEPLOYMENT_TARGET}")
  elseif(PLATFORM_INT STREQUAL "SIMULATORARM64_WATCHOS")
    set(SDK_NAME_VERSION_FLAGS
            "-mwatchos-simulator-version-min=${DEPLOYMENT_TARGET}")
  elseif(PLATFORM_INT STREQUAL "MAC")
    set(SDK_NAME_VERSION_FLAGS
            "-mmacosx-version-min=${DEPLOYMENT_TARGET}")
  else()
    # SIMULATOR or SIMULATOR64 both use -mios-simulator-version-min.
    set(SDK_NAME_VERSION_FLAGS
            "-mios-simulator-version-min=${DEPLOYMENT_TARGET}")
  endif()
elseif(NOT PLATFORM_INT MATCHES "^MAC_CATALYST")
  # Newer versions of CMake sets the version min flags correctly, skip this for Mac Catalyst targets
  set(CMAKE_OSX_DEPLOYMENT_TARGET ${DEPLOYMENT_TARGET} CACHE INTERNAL "Minimum OS X deployment version")
endif()

if(DEFINED APPLE_TARGET_TRIPLE_INT)
  set(APPLE_TARGET_TRIPLE ${APPLE_TARGET_TRIPLE_INT} CACHE INTERNAL "")
  set(CMAKE_C_COMPILER_TARGET ${APPLE_TARGET_TRIPLE})
  set(CMAKE_CXX_COMPILER_TARGET ${APPLE_TARGET_TRIPLE})
  set(CMAKE_ASM_COMPILER_TARGET ${APPLE_TARGET_TRIPLE})
endif()

if(PLATFORM_INT MATCHES "^MAC_CATALYST")
  set(C_TARGET_FLAGS "-isystem ${CMAKE_OSX_SYSROOT_INT}/System/iOSSupport/usr/include -iframework ${CMAKE_OSX_SYSROOT_INT}/System/iOSSupport/System/Library/Frameworks")
endif()

if(ENABLE_BITCODE_INT)
  set(BITCODE "-fembed-bitcode")
  set(CMAKE_XCODE_ATTRIBUTE_BITCODE_GENERATION_MODE "bitcode")
  set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE "YES")
else()
  set(BITCODE "")
  set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE "NO")
endif()

if(ENABLE_ARC_INT)
  set(FOBJC_ARC "-fobjc-arc")
  set(CMAKE_XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "YES")
else()
  set(FOBJC_ARC "-fno-objc-arc")
  set(CMAKE_XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "NO")
endif()

if(NAMED_LANGUAGE_SUPPORT_INT)
  set(OBJC_VARS "-fobjc-abi-version=2 -DOBJC_OLD_DISPATCH_PROTOTYPES=0")
  set(OBJC_LEGACY_VARS "")
else()
  set(OBJC_VARS "")
  set(OBJC_LEGACY_VARS "-fobjc-abi-version=2 -DOBJC_OLD_DISPATCH_PROTOTYPES=0")
endif()

if(NOT ENABLE_VISIBILITY_INT)
  foreach(lang ${languages})
    set(CMAKE_${lang}_VISIBILITY_PRESET "hidden" CACHE INTERNAL "")
  endforeach()
  set(CMAKE_XCODE_ATTRIBUTE_GCC_SYMBOLS_PRIVATE_EXTERN "YES")
  set(VISIBILITY "-fvisibility=hidden -fvisibility-inlines-hidden")
else()
  foreach(lang ${languages})
    set(CMAKE_${lang}_VISIBILITY_PRESET "default" CACHE INTERNAL "")
  endforeach()
  set(CMAKE_XCODE_ATTRIBUTE_GCC_SYMBOLS_PRIVATE_EXTERN "NO")
  set(VISIBILITY "-fvisibility=default")
endif()

if(DEFINED APPLE_TARGET_TRIPLE)
  set(APPLE_TARGET_TRIPLE_FLAG "-target ${APPLE_TARGET_TRIPLE}")
endif()

#Check if Xcode generator is used since that will handle these flags automagically
if(CMAKE_GENERATOR MATCHES "Xcode")
  message(STATUS "Not setting any manual command-line buildflags, since Xcode is selected as the generator. Modifying the Xcode build-settings directly instead.")
else()
  set(CMAKE_C_FLAGS "${C_TARGET_FLAGS} ${APPLE_TARGET_TRIPLE_FLAG} ${SDK_NAME_VERSION_FLAGS} ${OBJC_LEGACY_VARS} ${BITCODE} ${VISIBILITY} ${CMAKE_C_FLAGS}" CACHE INTERNAL
     "Flags used by the compiler during all C build types.")
  set(CMAKE_C_FLAGS_DEBUG "-O0 -g ${CMAKE_C_FLAGS_DEBUG}")
  set(CMAKE_C_FLAGS_MINSIZEREL "-DNDEBUG -Os ${CMAKE_C_FLAGS_MINSIZEREL}")
  set(CMAKE_C_FLAGS_RELWITHDEBINFO "-DNDEBUG -O2 -g ${CMAKE_C_FLAGS_RELWITHDEBINFO}")
  set(CMAKE_C_FLAGS_RELEASE "-DNDEBUG -O3 ${CMAKE_C_FLAGS_RELEASE}")
  set(CMAKE_CXX_FLAGS "${C_TARGET_FLAGS} ${APPLE_TARGET_TRIPLE_FLAG} ${SDK_NAME_VERSION_FLAGS} ${OBJC_LEGACY_VARS} ${BITCODE} ${VISIBILITY} ${CMAKE_CXX_FLAGS}" CACHE INTERNAL
     "Flags used by the compiler during all CXX build types.")
  set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g ${CMAKE_CXX_FLAGS_DEBUG}")
  set(CMAKE_CXX_FLAGS_MINSIZEREL "-DNDEBUG -Os ${CMAKE_CXX_FLAGS_MINSIZEREL}")
  set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-DNDEBUG -O2 -g ${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
  set(CMAKE_CXX_FLAGS_RELEASE "-DNDEBUG -O3 ${CMAKE_CXX_FLAGS_RELEASE}")
  if(NAMED_LANGUAGE_SUPPORT_INT)
    set(CMAKE_OBJC_FLAGS "${C_TARGET_FLAGS} ${APPLE_TARGET_TRIPLE_FLAG} ${SDK_NAME_VERSION_FLAGS} ${BITCODE} ${VISIBILITY} ${FOBJC_ARC} ${OBJC_VARS} ${CMAKE_OBJC_FLAGS}" CACHE INTERNAL
     "Flags used by the compiler during all OBJC build types.")
    set(CMAKE_OBJC_FLAGS_DEBUG "-O0 -g ${CMAKE_OBJC_FLAGS_DEBUG}")
    set(CMAKE_OBJC_FLAGS_MINSIZEREL "-DNDEBUG -Os ${CMAKE_OBJC_FLAGS_MINSIZEREL}")
    set(CMAKE_OBJC_FLAGS_RELWITHDEBINFO "-DNDEBUG -O2 -g ${CMAKE_OBJC_FLAGS_RELWITHDEBINFO}")
    set(CMAKE_OBJC_FLAGS_RELEASE "-DNDEBUG -O3 ${CMAKE_OBJC_FLAGS_RELEASE}")
    set(CMAKE_OBJCXX_FLAGS "${C_TARGET_FLAGS} ${APPLE_TARGET_TRIPLE_FLAG} ${SDK_NAME_VERSION_FLAGS} ${BITCODE} ${VISIBILITY} ${FOBJC_ARC} ${OBJC_VARS} ${CMAKE_OBJCXX_FLAGS}" CACHE INTERNAL
     "Flags used by the compiler during all OBJCXX build types.")
    set(CMAKE_OBJCXX_FLAGS_DEBUG "-O0 -g ${CMAKE_OBJCXX_FLAGS_DEBUG}")
    set(CMAKE_OBJCXX_FLAGS_MINSIZEREL "-DNDEBUG -Os ${CMAKE_OBJCXX_FLAGS_MINSIZEREL}")
    set(CMAKE_OBJCXX_FLAGS_RELWITHDEBINFO "-DNDEBUG -O2 -g ${CMAKE_OBJCXX_FLAGS_RELWITHDEBINFO}")
    set(CMAKE_OBJCXX_FLAGS_RELEASE "-DNDEBUG -O3 ${CMAKE_OBJCXX_FLAGS_RELEASE}")
  endif()
  set(CMAKE_C_LINK_FLAGS "${C_TARGET_FLAGS} ${SDK_NAME_VERSION_FLAGS} -Wl,-search_paths_first ${CMAKE_C_LINK_FLAGS}" CACHE INTERNAL
     "Flags used by the compiler for all C link types.")
  set(CMAKE_CXX_LINK_FLAGS "${C_TARGET_FLAGS} ${SDK_NAME_VERSION_FLAGS}  -Wl,-search_paths_first ${CMAKE_CXX_LINK_FLAGS}" CACHE INTERNAL
     "Flags used by the compiler for all CXX link types.")
  if(NAMED_LANGUAGE_SUPPORT_INT)
    set(CMAKE_OBJC_LINK_FLAGS "${C_TARGET_FLAGS} ${SDK_NAME_VERSION_FLAGS} -Wl,-search_paths_first ${CMAKE_OBJC_LINK_FLAGS}" CACHE INTERNAL
     "Flags used by the compiler for all OBJC link types.")
    set(CMAKE_OBJCXX_LINK_FLAGS "${C_TARGET_FLAGS} ${SDK_NAME_VERSION_FLAGS} -Wl,-search_paths_first ${CMAKE_OBJCXX_LINK_FLAGS}" CACHE INTERNAL
     "Flags used by the compiler for all OBJCXX link types.")
  endif()
  set(CMAKE_ASM_FLAGS "${CMAKE_C_FLAGS} -x assembler-with-cpp -arch ${CMAKE_OSX_ARCHITECTURES} ${APPLE_TARGET_TRIPLE_FLAG}" CACHE INTERNAL
     "Flags used by the compiler for all ASM build types.")
endif()

## Print status messages to inform of the current state
message(STATUS "Configuring ${SDK_NAME} build for platform: ${PLATFORM_INT}, architecture(s): ${ARCHS}")
message(STATUS "Using SDK: ${CMAKE_OSX_SYSROOT_INT}")
message(STATUS "Using C compiler: ${CMAKE_C_COMPILER}")
message(STATUS "Using CXX compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "Using libtool: ${BUILD_LIBTOOL}")
message(STATUS "Using install name tool: ${CMAKE_INSTALL_NAME_TOOL}")
if(DEFINED APPLE_TARGET_TRIPLE)
  message(STATUS "Autoconf target triple: ${APPLE_TARGET_TRIPLE}")
endif()
message(STATUS "Using minimum deployment version: ${DEPLOYMENT_TARGET}"
        " (SDK version: ${SDK_VERSION})")
if(MODERN_CMAKE)
  message(STATUS "Merging integrated CMake 3.14+ iOS,tvOS,watchOS,macOS toolchain(s) with this toolchain!")
  if(PLATFORM_INT MATCHES ".*COMBINED")
    message(STATUS "Will combine built (static) artifacts into FAT lib...")
  endif()
endif()
if(CMAKE_GENERATOR MATCHES "Xcode")
  message(STATUS "Using Xcode version: ${XCODE_VERSION_INT}")
endif()
message(STATUS "CMake version: ${CMAKE_VERSION}")
if(DEFINED SDK_NAME_VERSION_FLAGS)
  message(STATUS "Using version flags: ${SDK_NAME_VERSION_FLAGS}")
endif()
message(STATUS "Using a data_ptr size of: ${CMAKE_CXX_SIZEOF_DATA_PTR}")
if(ENABLE_BITCODE_INT)
  message(STATUS "Bitcode: Enabled")
else()
  message(STATUS "Bitcode: Disabled")
endif()

if(ENABLE_ARC_INT)
  message(STATUS "ARC: Enabled")
else()
  message(STATUS "ARC: Disabled")
endif()

if(ENABLE_VISIBILITY_INT)
  message(STATUS "Hiding symbols: Disabled")
else()
  message(STATUS "Hiding symbols: Enabled")
endif()

# Set global properties
set_property(GLOBAL PROPERTY PLATFORM "${PLATFORM}")
set_property(GLOBAL PROPERTY APPLE_TARGET_TRIPLE "${APPLE_TARGET_TRIPLE_INT}")
set_property(GLOBAL PROPERTY SDK_VERSION "${SDK_VERSION}")
set_property(GLOBAL PROPERTY XCODE_VERSION "${XCODE_VERSION_INT}")
set_property(GLOBAL PROPERTY OSX_ARCHITECTURES "${CMAKE_OSX_ARCHITECTURES}")

# Export configurable variables for the try_compile() command.
set(CMAKE_TRY_COMPILE_PLATFORM_VARIABLES
        PLATFORM
        XCODE_VERSION_INT
        SDK_VERSION
        NAMED_LANGUAGE_SUPPORT
        DEPLOYMENT_TARGET
        CMAKE_DEVELOPER_ROOT
        CMAKE_OSX_SYSROOT_INT
        ENABLE_BITCODE
        ENABLE_ARC
        CMAKE_ASM_COMPILER
        CMAKE_C_COMPILER
        CMAKE_C_COMPILER_TARGET
        CMAKE_CXX_COMPILER
        CMAKE_CXX_COMPILER_TARGET
        BUILD_LIBTOOL
        CMAKE_INSTALL_NAME_TOOL
        CMAKE_C_FLAGS
        CMAKE_C_DEBUG
        CMAKE_C_MINSIZEREL
        CMAKE_C_RELWITHDEBINFO
        CMAKE_C_RELEASE
        CMAKE_CXX_FLAGS
        CMAKE_CXX_FLAGS_DEBUG
        CMAKE_CXX_FLAGS_MINSIZEREL
        CMAKE_CXX_FLAGS_RELWITHDEBINFO
        CMAKE_CXX_FLAGS_RELEASE
        CMAKE_C_LINK_FLAGS
        CMAKE_CXX_LINK_FLAGS
        CMAKE_ASM_FLAGS
)

if(NAMED_LANGUAGE_SUPPORT_INT)
  list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES
        CMAKE_OBJC_FLAGS
        CMAKE_OBJC_DEBUG
        CMAKE_OBJC_MINSIZEREL
        CMAKE_OBJC_RELWITHDEBINFO
        CMAKE_OBJC_RELEASE
        CMAKE_OBJCXX_FLAGS
        CMAKE_OBJCXX_DEBUG
        CMAKE_OBJCXX_MINSIZEREL
        CMAKE_OBJCXX_RELWITHDEBINFO
        CMAKE_OBJCXX_RELEASE
        CMAKE_OBJC_LINK_FLAGS
        CMAKE_OBJCXX_LINK_FLAGS
  )
endif()

set(CMAKE_PLATFORM_HAS_INSTALLNAME 1)
set(CMAKE_SHARED_LINKER_FLAGS "-rpath @executable_path/Frameworks -rpath @loader_path/Frameworks")
set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS "-dynamiclib -Wl,-headerpad_max_install_names")
set(CMAKE_SHARED_MODULE_CREATE_C_FLAGS "-bundle -Wl,-headerpad_max_install_names")
set(CMAKE_SHARED_MODULE_LOADER_C_FLAG "-Wl,-bundle_loader,")
set(CMAKE_SHARED_MODULE_LOADER_CXX_FLAG "-Wl,-bundle_loader,")
set(CMAKE_FIND_LIBRARY_SUFFIXES ".tbd" ".dylib" ".so" ".a")
set(CMAKE_SHARED_LIBRARY_SONAME_C_FLAG "-install_name")

# Set the find root to the SDK developer roots.
# Note: CMAKE_FIND_ROOT_PATH is only useful when cross-compiling. Thus, do not set on macOS builds.
if(NOT PLATFORM_INT MATCHES "^MAC.*$")
  list(APPEND CMAKE_FIND_ROOT_PATH "${CMAKE_OSX_SYSROOT_INT}" CACHE INTERNAL "")
  set(CMAKE_IGNORE_PATH "/System/Library/Frameworks;/usr/local/lib;/opt/homebrew" CACHE INTERNAL "")
endif()

# Default to searching for frameworks first.
IF(NOT DEFINED CMAKE_FIND_FRAMEWORK)
  set(CMAKE_FIND_FRAMEWORK FIRST)
ENDIF(NOT DEFINED CMAKE_FIND_FRAMEWORK)

# Set up the default search directories for frameworks.
if(PLATFORM_INT MATCHES "^MAC_CATALYST")
  set(CMAKE_FRAMEWORK_PATH
          ${CMAKE_DEVELOPER_ROOT}/Library/PrivateFrameworks
          ${CMAKE_OSX_SYSROOT_INT}/System/Library/Frameworks
          ${CMAKE_OSX_SYSROOT_INT}/System/iOSSupport/System/Library/Frameworks
          ${CMAKE_FRAMEWORK_PATH} CACHE INTERNAL "")
else()
  set(CMAKE_FRAMEWORK_PATH
          ${CMAKE_DEVELOPER_ROOT}/Library/PrivateFrameworks
          ${CMAKE_OSX_SYSROOT_INT}/System/Library/Frameworks
          ${CMAKE_FRAMEWORK_PATH} CACHE INTERNAL "")
endif()

# By default, search both the specified iOS SDK and the remainder of the host filesystem.
if(NOT CMAKE_FIND_ROOT_PATH_MODE_PROGRAM)
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM BOTH CACHE INTERNAL "")
endif()
if(NOT CMAKE_FIND_ROOT_PATH_MODE_LIBRARY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH CACHE INTERNAL "")
endif()
if(NOT CMAKE_FIND_ROOT_PATH_MODE_INCLUDE)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH CACHE INTERNAL "")
endif()
if(NOT CMAKE_FIND_ROOT_PATH_MODE_PACKAGE)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH CACHE INTERNAL "")
endif()

#
# Some helper-macros below to simplify and beautify the CMakeFile
#

# This little macro lets you set any Xcode specific property.
macro(set_xcode_property TARGET XCODE_PROPERTY XCODE_VALUE XCODE_RELVERSION)
  set(XCODE_RELVERSION_I "${XCODE_RELVERSION}")
  if(XCODE_RELVERSION_I STREQUAL "All")
    set_property(TARGET ${TARGET} PROPERTY XCODE_ATTRIBUTE_${XCODE_PROPERTY} "${XCODE_VALUE}")
  else()
    set_property(TARGET ${TARGET} PROPERTY XCODE_ATTRIBUTE_${XCODE_PROPERTY}[variant=${XCODE_RELVERSION_I}] "${XCODE_VALUE}")
  endif()
endmacro(set_xcode_property)

# This macro lets you find executable programs on the host system.
macro(find_host_package)
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE NEVER)
  set(_TOOLCHAIN_IOS ${IOS})
  set(IOS OFF)
  find_package(${ARGN})
  set(IOS ${_TOOLCHAIN_IOS})
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM BOTH)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)
endmacro(find_host_package)
