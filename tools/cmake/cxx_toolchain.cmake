# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
# Copyright 2024-2025 Arm Limited and/or its affiliates.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

add_library(cxx_toolchain INTERFACE)
target_compile_options(cxx_toolchain
  INTERFACE
    -Wall
    -Wpedantic
    -Wextra
    -Werror
)
target_compile_features(cxx_toolchain INTERFACE cxx_std_17)
target_include_directories(cxx_toolchain INTERFACE ${PROJECT_SOURCE_DIR})
