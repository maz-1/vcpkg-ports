vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO maz-1/libcitygml
    REF d0b5fda4a292018ad6c2e492e6ac385fc6795322 # 2.4.1
    SHA512 c6958a2d0cdc8dab7fa735f6661b361dda539a6ee103b18b998fdd53347fb39f27d803b765f07d8a4929119616b563ef4e34b4dd5226a8df537be71a8860c4aa
    HEAD_REF master
    PATCHES
        0001_fix_tools.patch
        0002_fix_pkgconfig.patch
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        osg         LIBCITYGML_OSGPLUGIN
        gdal        LIBCITYGML_USE_GDAL
        tools       LIBCITYGML_TESTS
)

if ("osg" IN_LIST FEATURES)
    SET(VCPKG_POLICY_DLLS_WITHOUT_EXPORTS enabled)
endif()

if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    list(APPEND ADDITIONAL_OPTIONS
        -DLIBCITYGML_DYNAMIC=ON
    )
else()
    list(APPEND ADDITIONAL_OPTIONS
        -DLIBCITYGML_DYNAMIC=OFF
    )
endif()

if (VCPKG_TARGET_IS_UWP OR VCPKG_TARGET_IS_WINDOWS)
    if(VCPKG_CRT_LINKAGE STREQUAL "static")
        list(APPEND ADDITIONAL_OPTIONS
            -DLIBCITYGML_STATIC_CRT=ON
        )
    else()
        list(APPEND ADDITIONAL_OPTIONS
            -DLIBCITYGML_STATIC_CRT=OFF
        )
    endif()
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        ${FEATURE_OPTIONS}
        ${ADDITIONAL_OPTIONS}
)

vcpkg_install_cmake()
#vcpkg_fixup_pkgconfig()
vcpkg_copy_pdbs()

if(EXISTS ${CURRENT_PACKAGES_DIR}/cmake)
    vcpkg_fixup_cmake_targets(CONFIG_PATH cmake TARGET_PATH share/citygml)
else()
    vcpkg_fixup_cmake_targets(CONFIG_PATH lib/cmake/citygml TARGET_PATH share/citygml)
endif()

if ("tools" IN_LIST FEATURES)
    vcpkg_copy_tools(
        TOOL_NAMES citygmltest
        AUTO_CLEAN
    )
    if ("osg" IN_LIST FEATURES)
        vcpkg_copy_tools(
            TOOL_NAMES citygmlOsgViewer
            AUTO_CLEAN
        )
    endif()
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/lib/pkgconfig")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)

