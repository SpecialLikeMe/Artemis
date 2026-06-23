# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file LICENSE.rst or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION ${CMAKE_VERSION}) # this file comes with cmake

# If CMAKE_DISABLE_SOURCE_CHANGES is set to true and the source directory is an
# existing directory in our source tree, calling file(MAKE_DIRECTORY) on it
# would cause a fatal error, even though it would be a no-op.
if(NOT EXISTS "C:/Users/devon/Artemis")
  file(MAKE_DIRECTORY "C:/Users/devon/Artemis")
endif()
file(MAKE_DIRECTORY
  "C:/Users/devon/Artemis/build/cross/macos"
  "C:/Users/devon/Artemis/build/artemis-macos-prefix"
  "C:/Users/devon/Artemis/build/artemis-macos-prefix/tmp"
  "C:/Users/devon/Artemis/build/artemis-macos-prefix/src/artemis-macos-stamp"
  "C:/Users/devon/Artemis/build/artemis-macos-prefix/src"
  "C:/Users/devon/Artemis/build/artemis-macos-prefix/src/artemis-macos-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "C:/Users/devon/Artemis/build/artemis-macos-prefix/src/artemis-macos-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "C:/Users/devon/Artemis/build/artemis-macos-prefix/src/artemis-macos-stamp${cfgdir}") # cfgdir has leading slash
endif()
