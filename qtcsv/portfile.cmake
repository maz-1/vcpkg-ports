include(vcpkg_common_functions)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/qtcsv-1.5)
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO iamantony/qtcsv
    REF v1.5
    SHA512 c8fac9b4fbcfa30fbae844fb4afd39d7672fbdb567f0db3982a4e4d673271c202645e0cffa9126dd50cbdf3ed9b65512cb3400fbc12e5ea839fb66e5f3e6b5bb
    HEAD_REF master
)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        #-DBOOST_UUID_FORCE_AUTO_LINK=ON
        #-DXERCES_ROOT=${CURRENT_INSTALLED_DIR}
)


vcpkg_install_cmake()
vcpkg_fixup_cmake_targets()
vcpkg_copy_pdbs()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

configure_file(${SOURCE_PATH}/LICENSE ${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright COPYONLY)

## Extra steps
# Duplicate this line in qtcsvConfig.cmake: get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)