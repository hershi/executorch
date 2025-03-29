# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

if(PLATFORM_TARGET_OS STREQUAL PLATFORM_OS_IOS)
  set(PLATFORM "OS64" CACHE STRING "iOS platform target")
  set(IOS ON)
elseif(PLATFORM_TARGET_OS STREQUAL PLATFORM_OS_IOS_SIMULATOR)
  # set(PLATFORM "SIMULATORARM64" CACHE STRING "iOS platform target")
  # set(IOS ON)
  # set(IOS_SIMULATOR ON)
  message(FATAL_ERROR "Simulator not supported yet")
else()
  return()
endif()

if(NOT PLATFORM_TARGET_ARCH STREQUAL ${PLATFORM_ARCH_ARM64})
  message(FATAL_ERROR "Unsupported architecture for iOS: ${PLATFORM_TARGET_ARCH}")
endif()

find_program(XCODEBUILD_EXECUTABLE xcodebuild)
if(NOT XCODEBUILD_EXECUTABLE)
  message(FATAL_ERROR "xcodebuild not found. Please install either the standalone commandline tools or Xcode.")
endif()

execute_process(
  COMMAND ${XCODEBUILD_EXECUTABLE} -version
  OUTPUT_VARIABLE XCODE_VERSION_INT
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
string(REGEX MATCH "Xcode [0-9\\.]+" XCODE_VERSION_INT "${XCODE_VERSION_INT}")
string(REGEX REPLACE "Xcode ([0-9\\.]+)" "\\1" XCODE_VERSION_INT "${XCODE_VERSION_INT}")
set(XCODE_VERSION_INT "${XCODE_VERSION_INT}" CACHE INTERNAL "")
announce_configured_options(XCODE_VERSION_INT)

set(IOS_SDK_NAME iphoneos)
announce_configured_options(IOS_SDK_NAME)

execute_process(
  COMMAND ${XCODEBUILD_EXECUTABLE} -version -sdk ${IOS_SDK_NAME} Path
  OUTPUT_VARIABLE IOS_SDK_SYSROOT
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
set(IOS_SDK_SYSROOT "${IOS_SDK_SYSROOT}" CACHE INTERNAL "")
announce_configured_options(IOS_SDK_SYSROOT)

execute_process(
  COMMAND ${XCODEBUILD_EXECUTABLE} -sdk ${IOS_SDK_SYSROOT} -version SDKVersion
  OUTPUT_VARIABLE IOS_SDK_VERSION
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
set(IOS_SDK_VERSION "${IOS_SDK_VERSION}" CACHE INTERNAL "")
announce_configured_options(IOS_SDK_VERSION)

set(IOS_DEPLOYMENT_TARGET "13.0" CACHE INTERNAL "")
announce_configured_options(IOS_DEPLOYMENT_TARGET)

set(IOS_TARGET_TRIPLE_INT "${PLATFORM_TARGET_ARCH}-apple-${PLATFORM_TARGET_OS}${IOS_DEPLOYMENT_TARGET}" CACHE INTERNAL "")
announce_configured_options(IOS_TARGET_TRIPLE_INT)

add_library(ios_toolchain INTERFACE)
target_link_libraries(ios_toolchain INTERFACE cxx_toolchain)

target_compile_options(ios_toolchain INTERFACE -isysroot ${IOS_SDK_SYSROOT})
