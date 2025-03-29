# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
# Copyright 2024-2025 Arm Limited and/or its affiliates.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

# Enforce the package (aka folder) to be included in the target name.
macro(enforce_target_name_standard TARGET_NAME)
  # Get the relative path from PROJECT_SOURCE_DIR
  file(RELATIVE_PATH rel_path ${PROJECT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR})
  # Replace folders into namespaces
  string(REPLACE "/" "." expected_prefix "${rel_path}")
  string(REPLACE "\\" "." expected_prefix "${expected_prefix}")

  # Check if TARGET_NAME starts with expected_prefix
  if(NOT "${TARGET_NAME}" MATCHES "^${expected_prefix}\.")
    message(FATAL_ERROR "Target name '${TARGET_NAME}' must start with '${expected_prefix}.'. Suggested: ${expected_prefix}.${TARGET_NAME}")
  endif()
endmacro()

# Get the current source directory relative to the project root.
function(set_relative_current_source_dir OUTPUT_VAR)
  file(RELATIVE_PATH rel_path ${PROJECT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR})
  set(${OUTPUT_VAR} "executorch/${rel_path}" PARENT_SCOPE)
endfunction()

# A convinent way to announce the most important configurations.
function(announce_configured_options NAME)
  get_property(configs GLOBAL PROPERTY _announce_configured_options)
  if(NOT configs)
    set_property(GLOBAL PROPERTY _announce_configured_options)
    get_property(configs GLOBAL PROPERTY _announce_configured_options)
  endif()

  set(option_exists FALSE)
  foreach(config IN LISTS configs)
    if(config STREQUAL "${NAME}")
      set(option_exists TRUE)
      break()
    endif()
  endforeach()

  if(NOT option_exists)
    set(configs ${configs} "${NAME}")
    set_property(GLOBAL PROPERTY _announce_configured_options "${configs}")
  endif()
endfunction()

function(print_configured_options)
  get_property(configs GLOBAL PROPERTY _announce_configured_options)
  message(STATUS "--- ⚙️ Configurations ---\n")
  foreach(config IN LISTS configs)
    message(STATUS "${config}: ${${config}}")
  endforeach()
  message(STATUS "------------------------")
endfunction()
