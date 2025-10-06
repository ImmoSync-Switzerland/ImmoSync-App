# Project-level configuration.
cmake_minimum_required(VERSION 3.14)
project(immolink LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "immolink")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# Define build configuration option.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()
# Define settings for the Profile build mode.
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

# Use Unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  # /FS allows multiple cl.exe processes to serialize access to the PDB, preventing C1041 errors.
  # Removed /WX (treat warnings as errors) because some third-party static libs (Firebase C++ SDK)
  # emit unavoidable linker warnings (e.g. LNK4099) about missing PDBs. Keeping /WX would break builds.
  target_compile_options(${TARGET} PRIVATE /W4 /wd"4100" /FS)
  # Suppress LNK4099 (missing PDB) noise from prebuilt Firebase/LevelDB/libcurl objects.
  if (MSVC)
    target_link_options(${TARGET} PRIVATE /IGNORE:4099)
  endif()
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)

# When INSTALL step is disabled (FLUTTER_ENABLE_INSTALL=OFF), replicate the minimal
# asset + plugin library copying so running the built exe (flutter run) succeeds.
if(NOT FLUTTER_ENABLE_INSTALL)
  add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "$<TARGET_FILE_DIR:${BINARY_NAME}>/data/flutter_assets"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${PROJECT_BUILD_DIR}flutter_assets" "$<TARGET_FILE_DIR:${BINARY_NAME}>/data/flutter_assets"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${FLUTTER_ICU_DATA_FILE}" "$<TARGET_FILE_DIR:${BINARY_NAME}>/data/icudtl.dat"
    # Copy plugin bundled libraries if they exist (ignore failures quietly)
    COMMAND ${CMAKE_COMMAND} -E echo "Copying plugin libraries (if any)"
    COMMAND ${CMAKE_COMMAND} -DPLUGIN_LIBS="$<JOIN:${PLUGIN_BUNDLED_LIBRARIES},;>" -DTARGET_DIR="$<TARGET_FILE_DIR:${BINARY_NAME}>" -P "${CMAKE_CURRENT_SOURCE_DIR}/flutter/copy_plugin_libs.cmake"
    VERBATIM
  )

  # Generate helper script to iterate plugin libs because generator expressions are
  # not expanded inside foreach at configure time for add_custom_command.
  file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/flutter/copy_plugin_libs.cmake" "\n"
    "if(\"${PLUGIN_LIBS}\" STREQUAL \"\")\n  message(STATUS \"No plugin libraries to copy.\")\n  return()\nendif()\n"
    "string(REPLACE \";\" \";\" PLUGIN_LIST \"${PLUGIN_LIBS}\")\n"
    "separate_arguments(PLUGIN_LIST)\n"
    "foreach(lib IN LISTS PLUGIN_LIST)\n"
    "  if(EXISTS \"${lib}\")\n"
    "    execute_process(COMMAND \"${CMAKE_COMMAND}\" -E copy_if_different \"${lib}\" \"${TARGET_DIR}\" )\n"
    "  endif()\n"
    "endforeach()\n"
  )
endif()


# === Installation (optional) ===
# Historically Flutter desktop templates trigger an INSTALL step automatically.
# This project has encountered intermittent MSB3073 failures during the INSTALL
# phase (invoking cmake_install.cmake) when some Debug-only artifacts are not
# yet present or locked. To improve iteration speed we disable the automatic
# inclusion of INSTALL in the default build unless explicitly re‑enabled.
option(FLUTTER_ENABLE_INSTALL "Include INSTALL target in default VS build" OFF)
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
if(FLUTTER_ENABLE_INSTALL)
  set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
else()
  set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 0)
endif()
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

if(FLUTTER_ENABLE_INSTALL)
  install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
    COMPONENT Runtime)

  install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
    COMPONENT Runtime OPTIONAL)

  install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime OPTIONAL)

  if(PLUGIN_BUNDLED_LIBRARIES)
    install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
      DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
      COMPONENT Runtime OPTIONAL)
  endif()

  # Copy the native assets provided by the build.dart from all packages.
  set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/windows/")
  install(DIRECTORY "${NATIVE_ASSETS_DIR}"
     DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
     COMPONENT Runtime)

  # Fully re-copy the assets directory on each build to avoid having stale files
  # from a previous install.
  set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
  install(CODE "
    file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
    " COMPONENT Runtime)
  install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
    DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

  # Install the AOT library on non-Debug builds only.
  install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
    CONFIGURATIONS Profile;Release
    COMPONENT Runtime OPTIONAL)
endif()
