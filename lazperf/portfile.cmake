set(VERSION 3.0.0)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO hobuinc/laz-perf
    REF 3.0.0
    SHA512 57fcbf661c306b01f86254c4471de68f7359d050cc562ff549ab3560f54f9a4455624740335009d2dfd6d9b3298c4742198106886ba1b0c97d4dfdeddeb180c0
    HEAD_REF master
    PATCHES 
        "0001_cmake_path.patch"
)

vcpkg_cmake_configure(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
)
vcpkg_cmake_install()
#vcpkg_cmake_config_fixup()
vcpkg_copy_pdbs()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)

file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)