vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO jklimke/libcitygml
    REF 081993794cdd3264af396a79358100302fef5a83 # 2.4.0
    SHA512 5daf66d418726a31df3f62330515590e7ebc3d6d833742b1f806ae8e52f6ade04ce6f4c2425356a03b748deec319a8b44340afbb7f6d788507bd91504ef277ac
    HEAD_REF master
    PATCHES
        0001_fix_vs2019.patch
)

#LIBCITYGML_OSG_PLUGIN_INSTALL_DIR
vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        -DLIBCITYGML_OSGPLUGIN=ON
        -DLIBCITYGML_USE_GDAL=ON
)

file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/debug/share/libcitygml)

vcpkg_install_cmake()
vcpkg_fixup_cmake_targets()
vcpkg_copy_pdbs()

file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
#file(INSTALL ${SOURCE_PATH}/src/refimpl/E57RefImplConfig.cmake DESTINATION ${CURRENT_PACKAGES_DIR}/share/e57refimpl/)

file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/tools)
file(RENAME ${CURRENT_PACKAGES_DIR}/lib ${CURRENT_PACKAGES_DIR}/tools/osg)
file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/lib)
file(RENAME ${CURRENT_PACKAGES_DIR}/tools/osg/pkgconfig ${CURRENT_PACKAGES_DIR}/lib/pkgconfig)
file(RENAME ${CURRENT_PACKAGES_DIR}/tools/osg/citygml.lib ${CURRENT_PACKAGES_DIR}/lib/citygml.lib)
file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/tools/libcitygml)
file(RENAME ${CURRENT_PACKAGES_DIR}/bin/citygmlOsgViewer.exe ${CURRENT_PACKAGES_DIR}/tools/libcitygml/citygmlOsgViewer.exe)
file(RENAME ${CURRENT_PACKAGES_DIR}/bin/citygmltest.exe ${CURRENT_PACKAGES_DIR}/tools/libcitygml/citygmltest.exe)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/debug/tools)
file(RENAME ${CURRENT_PACKAGES_DIR}/debug/lib ${CURRENT_PACKAGES_DIR}/debug/tools/osg)
file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/debug/lib)
file(RENAME ${CURRENT_PACKAGES_DIR}/debug/tools/osg/pkgconfig ${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig)
file(RENAME ${CURRENT_PACKAGES_DIR}/debug/tools/osg/citygmld.lib ${CURRENT_PACKAGES_DIR}/debug/lib/citygmld.lib)
file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/debug/tools/libcitygml)
file(RENAME ${CURRENT_PACKAGES_DIR}/debug/bin/citygmlOsgViewer.exe ${CURRENT_PACKAGES_DIR}/debug/tools/libcitygml/citygmlOsgViewer.exe)
file(RENAME ${CURRENT_PACKAGES_DIR}/debug/bin/citygmltest.exe ${CURRENT_PACKAGES_DIR}/debug/tools/libcitygml/citygmltest.exe)
