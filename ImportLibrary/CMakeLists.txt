cmake_minimum_required(VERSION 3.20)
project(libFAUSTWithLLVMDownloader)

set(FAUST_VERSION "2.79.3")

set(FAUST_LIBRARY_NAME "Faust-${FAUST_VERSION}")
set(FAUST_BASE_URL "https://github.com/grame-cncm/faust/releases/download/${FAUST_VERSION}")
set(DMG_ARM64 "${FAUST_LIBRARY_NAME}-arm64.dmg")
set(DMG_X64 "${FAUST_LIBRARY_NAME}-x64.dmg")

set(DOWNLOAD_DIR "${CMAKE_SOURCE_DIR}/Downloads")
set(FAUST_ROOT "${CMAKE_SOURCE_DIR}/${FAUST_LIBRARY_NAME}")
file(MAKE_DIRECTORY "${DOWNLOAD_DIR}")

# Helper macro to download and mount DMG
function(download_and_extract_dmg dmg_url dmg_name arch_suffix)
    set(mount_point "${CMAKE_BINARY_DIR}/mnt-${arch_suffix}")

    set(DMG_MOUNT_DIR "/Volumes/${FAUST_LIBRARY_NAME}")         # -${arch_suffix}")

    set(local_dmg "${DOWNLOAD_DIR}/${dmg_name}")
    
    if(NOT EXISTS "${local_dmg}")
        message(STATUS "Downloading ${dmg_name}...")
        file(DOWNLOAD
            "${dmg_url}"
            "${local_dmg}"
            SHOW_PROGRESS
            STATUS dl_statushd
            LOG log
        )
    endif()

    file(MAKE_DIRECTORY "${mount_point}")

    execute_process(
        COMMAND hdiutil attach "${local_dmg}" -mountpoint "${mount_point}" -nobrowse 
        RESULT_VARIABLE MOUNT_RESULT
    )
    if(NOT MOUNT_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to mount ${dmg_name}")
    endif()

    file(COPY
        "${mount_point}/${FAUST_LIBRARY_NAME}/include"
        DESTINATION "${FAUST_ROOT}"
    )

    file(MAKE_DIRECTORY "${FAUST_ROOT}/lib")
    file(COPY
        "${mount_point}/${FAUST_LIBRARY_NAME}/lib/libfaustwithllvm.a"
        DESTINATION "${FAUST_ROOT}/lib"
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE
    )
    file(RENAME
        "${FAUST_ROOT}/lib/libfaustwithllvm.a"
        "${FAUST_ROOT}/lib/libfaustwithllvm-${arch_suffix}.a"
    )

    execute_process(COMMAND hdiutil detach "${mount_point}" -force)
    file(REMOVE_RECURSE "${mount_point}")
endfunction()

download_and_extract_dmg("${FAUST_BASE_URL}/${DMG_ARM64}" "${DMG_ARM64}" "arm64")
download_and_extract_dmg("${FAUST_BASE_URL}/${DMG_X64}" "${DMG_X64}" "x64")

# Lipo the two arch libraries into one
set(LIPO_OUTPUT "${FAUST_ROOT}/lib/libfaustwithllvm.a")
execute_process(
    COMMAND lipo -create
        "${FAUST_ROOT}/lib/libfaustwithllvm-arm64.a"
        "${FAUST_ROOT}/lib/libfaustwithllvm-x64.a"
        -output "${LIPO_OUTPUT}"
    RESULT_VARIABLE lipo_result
)
if(NOT lipo_result EQUAL 0)
    message(FATAL_ERROR "Failed to create universal binary with lipo.")
endif()

# Create CMake target
file(GLOB_RECURSE FAUST_HEADERS "${FAUST_ROOT}/include/*.h")
add_library(faust STATIC IMPORTED GLOBAL)
set_target_properties(faust PROPERTIES
    IMPORTED_LOCATION "${LIPO_OUTPUT}"
    INTERFACE_INCLUDE_DIRECTORIES "${FAUST_ROOT}/include"
)

# Optional: If you want to use this in another project
# add_library(faust_full STATIC ${FAUST_HEADERS})
# target_include_directories(faust_full PUBLIC "${FAUST_ROOT}/include")
# target_link_libraries(faust_full PRIVATE faust)