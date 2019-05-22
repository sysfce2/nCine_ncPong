if(MSVC AND NOT DEFINED CMAKE_PREFIX_PATH AND NOT DEFINED nCine_DIR)
	get_filename_component(CMAKE_PREFIX_PATH "[HKEY_LOCAL_MACHINE\\SOFTWARE\\nCine]" ABSOLUTE)
endif()
find_package(nCine REQUIRED)

set(NCINE_CONFIGURATION "RELEASE" CACHE STRING "Preferred nCine configuration type when more than one has been exported")
get_target_property(NCINE_CONFIGURATIONS ncine::ncine IMPORTED_CONFIGURATIONS)
message(STATUS "nCine exported build configurations: ${NCINE_CONFIGURATIONS} (preferred: ${NCINE_CONFIGURATION})")

get_target_property(NCINE_LOCATION ncine::ncine IMPORTED_LOCATION_${NCINE_CONFIGURATION})
if(NOT EXISTS ${NCINE_LOCATION})
	unset(NCINE_CONFIGURATION CACHE)
	foreach(NCINE_CFG ${NCINE_CONFIGURATIONS})
		get_target_property(NCINE_LOCATION ncine::ncine IMPORTED_LOCATION_${NCINE_CFG})
		if(EXISTS ${NCINE_LOCATION})
			message(STATUS "Preferred configuration unavailable, changing to ${NCINE_CFG}")
			set(NCINE_CONFIGURATION ${NCINE_CFG})
			break()
		endif()
	endforeach()
endif()
if(NOT DEFINED NCINE_CONFIGURATION)
	message(FATAL_ERROR "No nCine build configuration found")
endif()

message(STATUS "nCine library: ${NCINE_LOCATION}")
if(WIN32 AND NCINE_DYNAMIC_LIBRARY)
	get_target_property(NCINE_IMPLIB ncine::ncine IMPORTED_IMPLIB_${NCINE_CONFIGURATION})
	message(STATUS "nCine import library: ${NCINE_IMPLIB}")
endif()
get_target_property(NCINE_INCLUDE_DIR ncine::ncine INTERFACE_INCLUDE_DIRECTORIES)
message(STATUS "nCine include directory: ${NCINE_INCLUDE_DIR}")
get_target_property(NCINE_MAIN_LOCATION ncine::ncine_main IMPORTED_LOCATION_${NCINE_CONFIGURATION})
message(STATUS "nCine main function library: ${NCINE_MAIN_LOCATION}")

if(NOT NCINE_EMBEDDED_SHADERS)
	if(IS_DIRECTORY ${NCINE_SHADERS_DIR})
		message(STATUS "nCine shaders directory: ${NCINE_SHADERS_DIR}")
	else()
		message(FATAL_ERROR "nCine shaders directory not found at: ${NCINE_SHADERS_DIR}")
	endif()
endif()

if(PACKAGE_BUILD_ANDROID)
	if(IS_DIRECTORY ${NCINE_ANDROID_DIR})
		message(STATUS "nCine Android directory: ${NCINE_ANDROID_DIR}")
	else()
		message(FATAL_ERROR "nCine Android directory not found at: ${NCINE_ANDROID_DIR}")
	endif()

	set(NCINE_EXTERNAL_ANDROID_DIR "" CACHE PATH "Path to the nCine external Android libraries directory")
	if(NOT IS_DIRECTORY ${NCINE_EXTERNAL_ANDROID_DIR})
		unset(NCINE_EXTERNAL_ANDROID_DIR CACHE)
		get_filename_component(PARENT_DIR ${CMAKE_SOURCE_DIR} DIRECTORY)
		find_path(NCINE_EXTERNAL_ANDROID_DIR
			NAMES libopenal.so
			PATHS ${PARENT_SOURCE_DIR}/nCine-android-external ${PARENT_BINARY_DIR}/nCine-android-external
			PATH_SUFFIXES openal/armeabi-v7a openal/arm64-v8a openal/x86_64
			DOC "Path to the nCine external Android libraries directory")

		if(IS_DIRECTORY ${NCINE_EXTERNAL_ANDROID_DIR})
			get_filename_component(NCINE_EXTERNAL_ANDROID_DIR ${NCINE_EXTERNAL_ANDROID_DIR} DIRECTORY)
			get_filename_component(NCINE_EXTERNAL_ANDROID_DIR ${NCINE_EXTERNAL_ANDROID_DIR} DIRECTORY)
		endif()
	endif()

	if(IS_DIRECTORY ${NCINE_EXTERNAL_ANDROID_DIR})
		message(STATUS "nCine external Android libraries directory: ${NCINE_EXTERNAL_ANDROID_DIR}")
	else()
		message(STATUS "nCine external Android libraries directory not found at: ${NCINE_EXTERNAL_ANDROID_DIR}")
	endif()
endif()

if(MSVC)
	set(ARCH_SUFFIX "x86")
	if(MSVC_C_ARCHITECTURE_ID MATCHES 64 OR MSVC_CXX_ARCHITECTURE_ID MATCHES 64)
		set(ARCH_SUFFIX "x64")
	endif()

	get_filename_component(NCINE_LOCATION_DIR ${NCINE_LOCATION} DIRECTORY)
	find_path(BINDIR
		NAMES glfw3.dll SDL2.dll
		PATHS ${NCINE_LOCATION_DIR} ${NCINE_EXTERNAL_DIR} ${PARENT_SOURCE_DIR}/nCine-external ${PARENT_BINARY_DIR}/nCine-external
		PATH_SUFFIXES bin/${ARCH_SUFFIX}
		DOC "Path to the nCine external libraries directory"
		NO_DEFAULT_PATH) # To avoid finding MSYS/MinGW libraries

	if(IS_DIRECTORY ${BINDIR})
		message(STATUS "nCine MSVC DLLs directory: ${BINDIR}")
	else()
		message(FATAL_ERROR "nCine MSVC DLLs directory not found at: ${BINDIR}")
	endif()
elseif(APPLE)
	get_filename_component(NCINE_LOCATION_DIR ${NCINE_LOCATION} DIRECTORY)
	find_path(FRAMEWORKS_DIR
		NAMES glfw.framework sdl2.framework
		PATHS ${NCINE_LOCATION_DIR}/../../Frameworks ${NCINE_EXTERNAL_DIR} ${PARENT_SOURCE_DIR}/nCine-external ${PARENT_BINARY_DIR}/nCine-external
		PATH_SUFFIXES bin/${ARCH_SUFFIX}
		DOC "Path to the nCine frameworks directory")

	if(IS_DIRECTORY ${FRAMEWORKS_DIR})
		message(STATUS "nCine frameworks directory: ${FRAMEWORKS_DIR}")
	else()
		message(FATAL_ERROR "nCine frameworks directory not found at: ${FRAMEWORKS_DIR}")
	endif()
endif()
