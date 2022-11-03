set(VERSION 0.9.0)

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:maz-1/VerbCpp.git
    REF e759442812a8d2dfc470998951d694f350960723
    HEAD_REF master
)


if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    list(APPEND ADDITIONAL_OPTIONS
        -DVERB_DYNAMIC=ON
    )
else()
    list(APPEND ADDITIONAL_OPTIONS
        -DVERB_DYNAMIC=OFF
    )
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
        ${ADDITIONAL_OPTIONS}
)
vcpkg_cmake_install()
#vcpkg_cmake_config_fixup()
vcpkg_copy_pdbs()

if(EXISTS ${CURRENT_PACKAGES_DIR}/cmake)
    vcpkg_fixup_cmake_targets(CONFIG_PATH cmake TARGET_PATH share/verb)
else()
    vcpkg_fixup_cmake_targets(CONFIG_PATH lib/cmake/verb TARGET_PATH share/verb)
endif()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)

file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)