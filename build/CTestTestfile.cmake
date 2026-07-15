# CMake generated Testfile for 
# Source directory: C:/Users/devon/Artemis
# Build directory: C:/Users/devon/Artemis/build
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
if(CTEST_CONFIGURATION_TYPE MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
  add_test([=[unit_and_integration]=] "C:/Users/devon/Artemis/build/Debug/artemis_tests.exe")
  set_tests_properties([=[unit_and_integration]=] PROPERTIES  ENVIRONMENT "ARTEMIS_BIN=C:/Users/devon/Artemis/build/artemis.exe" WORKING_DIRECTORY "C:/Users/devon/Artemis/build" _BACKTRACE_TRIPLES "C:/Users/devon/Artemis/CMakeLists.txt;169;add_test;C:/Users/devon/Artemis/CMakeLists.txt;0;")
elseif(CTEST_CONFIGURATION_TYPE MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
  add_test([=[unit_and_integration]=] "C:/Users/devon/Artemis/build/Release/artemis_tests.exe")
  set_tests_properties([=[unit_and_integration]=] PROPERTIES  ENVIRONMENT "ARTEMIS_BIN=C:/Users/devon/Artemis/build/artemis.exe" WORKING_DIRECTORY "C:/Users/devon/Artemis/build" _BACKTRACE_TRIPLES "C:/Users/devon/Artemis/CMakeLists.txt;169;add_test;C:/Users/devon/Artemis/CMakeLists.txt;0;")
elseif(CTEST_CONFIGURATION_TYPE MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
  add_test([=[unit_and_integration]=] "C:/Users/devon/Artemis/build/MinSizeRel/artemis_tests.exe")
  set_tests_properties([=[unit_and_integration]=] PROPERTIES  ENVIRONMENT "ARTEMIS_BIN=C:/Users/devon/Artemis/build/artemis.exe" WORKING_DIRECTORY "C:/Users/devon/Artemis/build" _BACKTRACE_TRIPLES "C:/Users/devon/Artemis/CMakeLists.txt;169;add_test;C:/Users/devon/Artemis/CMakeLists.txt;0;")
elseif(CTEST_CONFIGURATION_TYPE MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
  add_test([=[unit_and_integration]=] "C:/Users/devon/Artemis/build/RelWithDebInfo/artemis_tests.exe")
  set_tests_properties([=[unit_and_integration]=] PROPERTIES  ENVIRONMENT "ARTEMIS_BIN=C:/Users/devon/Artemis/build/artemis.exe" WORKING_DIRECTORY "C:/Users/devon/Artemis/build" _BACKTRACE_TRIPLES "C:/Users/devon/Artemis/CMakeLists.txt;169;add_test;C:/Users/devon/Artemis/CMakeLists.txt;0;")
else()
  add_test([=[unit_and_integration]=] NOT_AVAILABLE)
endif()
