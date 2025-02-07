include(RunCMake)

if(RunCMake_GENERATOR STREQUAL Xcode)
  if(XCODE_VERSION VERSION_LESS 6.1)
    run_cmake(XcodeTooOld)
  elseif(CMake_TEST_Swift)
    run_cmake(CMP0157-NEW)
    run_cmake(CMP0157-OLD)
    run_cmake(CMP0157-WARN)
  endif()
elseif(RunCMake_GENERATOR STREQUAL Ninja)
  if(CMake_TEST_Swift)
    if (CMAKE_SYSTEM_NAME MATCHES "Windows")
      run_cmake_with_options(Win32ExecutableDisallowed)
    else()
      run_cmake_with_options(Win32ExecutableIgnored)
      set(RunCMake_TEST_OPTIONS -DCMAKE_SYSTEM_NAME=Darwin)
      run_cmake(SwiftMultiArch)
      unset(RunCMake_TEST_OPTIONS)
    endif()

    # Test that a second build with no changes does nothing.
    block()
      run_cmake(NoWorkToDo)
      set(RunCMake_TEST_NO_CLEAN 1)
      set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/NoWorkToDo-build)
      set(RunCMake_TEST_OUTPUT_MERGE 1)
      run_cmake_command(NoWorkToDo-build ${CMAKE_COMMAND} --build .)
      run_cmake_command(NoWorkToDo-nowork ${CMAKE_COMMAND} --build . -- -d explain)
      file(WRITE ${RunCMake_TEST_BINARY_DIR}/hello.swift "//No-op change\n")
      run_cmake_command(NoWorkToDo-norelink ${CMAKE_COMMAND} --build . -- -d explain)
      run_cmake_command(NoWorkToDo-nowork ${CMAKE_COMMAND} --build . -- -d explain)
    endblock()

    # Test that intermediate static libraries are rebuilt when the public
    # interface of their dependency changes
    block()
      set(IncrementalSwift_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/IncrementalSwift-build)
      set(IncrementalSwift_TEST_NO_CLEAN 1)
      set(IncrementalSwift_TEST_OUTPUT_MERGE 1)
      # Since files are modified during test, the files are created in the cmake
      # file into the build directory
      run_cmake(IncrementalSwift)
      run_cmake_command(IncrementalSwift-first ${CMAKE_COMMAND} --build ${IncrementalSwift_TEST_BINARY_DIR})

      # Modify public interface of libA requiring rebuild of libB
      file(WRITE ${IncrementalSwift_TEST_BINARY_DIR}/a.swift
        "public func callA() -> Float { return 32.0 }\n")

      # Note: We still expect this to fail, but instead of failure at link time,
      # it should fail while re-compiling libB because the function changed
      run_cmake_command(IncrementalSwift-second ${CMAKE_COMMAND} --build ${IncrementalSwift_TEST_BINARY_DIR} -- -d explain)
    endblock()

    block()
      set(CMP0157-OLD_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/CMP0157-OLD-build)
      set(CMP0157-OLD_TEST_NO_CLEAN 1)
      set(CMP0157-OLD_TEST_OUTPUT_MERGE 1)

      run_cmake(CMP0157-NEW)
      run_cmake(CMP0157-OLD)
      # -n: dry-run to avoid actually compiling, -v: verbose to capture executed command
      run_cmake_command(CMP0157-OLD-build ${CMAKE_COMMAND} --build ${CMP0157-OLD_TEST_BINARY_DIR} -- -n -v)
      run_cmake(CMP0157-WARN)
    endblock()

    block()
      set(CompileCommands_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/CompileCommands-build)
      run_cmake(CompileCommands)
      run_cmake_command(CompileCommands-check ${CMAKE_COMMAND} --build ${CompileCommands_TEST_BINARY_DIR})
    endblock()

    block()
      set(ForceResponseFile_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/ForceResponseFile-build)
      run_cmake(ForceResponseFile)
      # -v: verbose to capture executed commands -n: dry-run to avoid actually compiling
      run_cmake_command(ForceResponseFile-check ${CMAKE_COMMAND} --build ${ForceResponseFile_TEST_BINARY_DIR} -- -vn)
    endblock()

    block()
      if(CMAKE_SYSTEM_NAME MATCHES Windows)
        set(ImportLibraryFlags_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/SwiftLibraryModuleCommand-build)
        run_cmake(ImportLibraryFlags)
        run_cmake_command(ImportLibraryFlags-check ${CMAKE_COMMAND} --build ${SwiftLibraryModuleCommand_TEST_BINARY_DIR} -- -n -v)
      endif()
    endblock()

    block()
      set(SwiftLibraryModuleCommand_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/SwiftLibraryModuleCommand-build)
      run_cmake(SwiftLibraryModuleCommand)
      run_cmake_command(SwiftLibraryModuleCommand-check ${CMAKE_COMMAND} --build ${SwiftLibraryModuleCommand_TEST_BINARY_DIR} -- -n -v)
    endblock()
  endif()
elseif(RunCMake_GENERATOR STREQUAL "Ninja Multi-Config")
  if(CMake_TEST_Swift)
    set(RunCMake_TEST_OPTIONS "-DCMAKE_CONFIGURATION_TYPES=Debug\\;Release")
    run_cmake(SwiftSimple)

    run_cmake(CMP0157-NEW)
    run_cmake(CMP0157-OLD)
    run_cmake(CMP0157-WARN)
    unset(RunCMake_TEST_OPTIONS)
  endif()
else()
  run_cmake(NotSupported)
endif()
