vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO PointCloudLibrary/pcl
    REF e8ed4be802f7d0b1acff2f8b01d7c5f381190e05 # pcl-1.12.1
    SHA512 6d6f54bd589d4c0e49de1a99da4ebe955336b2fb9176c0c8d311d710c9695ab7f036c6e72fc15ed4efec1b5c32ef2f5b2ae59d00e94e4fcf78821645cf0fc721
    HEAD_REF master
    PATCHES
        add-gcc-version-check.patch
        fix-check-sse.patch
        fix-find-qhull.patch
        fix-numeric-literals-flag.patch
        pcl_config.patch
        pcl_utils.patch
        remove-broken-targets.patch
        fix-cmake_find_library_suffixes.patch
        install-examples.patch
        no-absolute.patch
        fix_cuda_openmp.patch
        fix_msvc2022_bug.patch
)

file(REMOVE "${SOURCE_PATH}/cmake/Modules/FindQhull.cmake"
            "${SOURCE_PATH}/cmake/Modules/Findlibusb.cmake"
)
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" PCL_SHARED_LIBS)

if ("cuda" IN_LIST FEATURES AND VCPKG_TARGET_ARCHITECTURE STREQUAL x86)
    message(FATAL_ERROR "Feature cuda only supports 64-bit compilation.")
endif()

if ("tools" IN_LIST FEATURES AND VCPKG_LIBRARY_LINKAGE STREQUAL static)
    message(FATAL_ERROR "Feature tools only supports dynamic build")
endif()

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        openni2         WITH_OPENNI2
        qt              WITH_QT
        pcap            WITH_PCAP
        cuda            WITH_CUDA
        cuda            BUILD_CUDA
        cuda            BUILD_GPU
        tools           BUILD_tools
        opengl          WITH_OPENGL
        libusb          WITH_LIBUSB
        visualization   WITH_VTK
        visualization   BUILD_visualization
        examples        BUILD_examples
        apps            BUILD_apps
        # These 2 apps need openni1
        #apps            BUILD_apps_in_hand_scanner
        #apps            BUILD_apps_3d_rec_framework
        simulation      BUILD_simulation
)

if(VCPKG_TARGET_IS_WINDOWS)
    set(VCPKG_CXX_FLAGS_RELEASE "/bigobj")
    set(VCPKG_CXX_FLAGS_DEBUG "/bigobj")
    set(VCPKG_C_FLAGS_RELEASE "/bigobj")
    set(VCPKG_C_FLAGS_DEBUG "/bigobj")
endif()

if("cuda" IN_LIST FEATURES)
  #list(APPEND ADDITIONAL_OPTIONS "-DCUDA_ARCH_BIN=5.0 5.2 6.0 6.1 7.0 7.5")
    list(APPEND ADDITIONAL_OPTIONS
        -DBUILD_gpu_kinfu=OFF
        -DBUILD_gpu_kinfu_large_scale=OFF
        -DBUILD_gpu_kinfu_large_scale_tools=OFF
        -DBUILD_gpu_kinfu_tools=OFF
    )
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        # BUILD
        -DBUILD_surface_on_nurbs=ON
        # PCL
        -DPCL_BUILD_WITH_BOOST_DYNAMIC_LINKING_WIN32=${PCL_SHARED_LIBS}
        -DPCL_BUILD_WITH_FLANN_DYNAMIC_LINKING_WIN32=${PCL_SHARED_LIBS}
        -DPCL_BUILD_WITH_QHULL_DYNAMIC_LINKING_WIN32=${PCL_SHARED_LIBS}
        -DPCL_SHARED_LIBS=${PCL_SHARED_LIBS}
        # WITH
        -DWITH_PNG=ON
        -DWITH_QHULL=ON
        -DWITH_OPENNI=OFF
        -DWITH_ENSENSO=OFF
        -DWITH_DAVIDSDK=OFF
        -DWITH_DSSDK=OFF
        -DWITH_RSSDK=OFF
        -DWITH_RSSDK2=OFF
        -DWITH_OPENMP=OFF
        # FEATURES
        ${FEATURE_OPTIONS}
        ${ADDITIONAL_OPTIONS}
    MAYBE_UNUSED_VARIABLES
        PCL_BUILD_WITH_FLANN_DYNAMIC_LINKING_WIN32
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup()
vcpkg_copy_pdbs()

if (WITH_OPENNI2)
    if (NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
        file(GLOB PCL_PKGCONFIG_DBGS "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/*.pc")
        foreach (PCL_PKGCONFIG IN LISTS PCL_PKGCONFIG_DBGS)
            file(READ "${PCL_PKGCONFIG}" PCL_PC_DBG)
            if (PCL_PC_DBG MATCHES "libopenni2")
                string(REPLACE "libopenni2" "" PCL_PC_DBG "${PCL_PC_DBG}")
                string(REPLACE "Libs: " "Libs: -lKinect10 -lOpenNI2 " PCL_PC_DBG "${PCL_PC_DBG}")
                file(WRITE "${PCL_PKGCONFIG}" "${PCL_PC_DBG}")
            endif()
        endforeach()
    endif()
    if (NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
        file(GLOB PCL_PKGCONFIG_RELS "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/*.pc")
        foreach (PCL_PKGCONFIG IN LISTS PCL_PKGCONFIG_RELS)
            file(READ "${PCL_PKGCONFIG}" PCL_PC_REL)
            if (PCL_PC_REL MATCHES "libopenni2")
                string(REPLACE "libopenni2" "" PCL_PC_REL "${PCL_PC_REL}")
                string(REPLACE "Libs: " "Libs: -lKinect10 -lOpenNI2 " PCL_PC_REL "${PCL_PC_REL}")
                file(WRITE "${PCL_PKGCONFIG}" "${PCL_PC_REL}")
            endif()
        endforeach()
    endif()
endif()
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

if(BUILD_tools OR BUILD_apps OR BUILD_examples)
    file(GLOB EXEFILES_RELEASE "${CURRENT_PACKAGES_DIR}/bin/*${VCPKG_TARGET_EXECUTABLE_SUFFIX}")
    file(GLOB EXEFILES_DEBUG "${CURRENT_PACKAGES_DIR}/debug/bin/*${VCPKG_TARGET_EXECUTABLE_SUFFIX}")
    file(COPY ${EXEFILES_RELEASE} DESTINATION "${CURRENT_PACKAGES_DIR}/tools/pcl")
    file(REMOVE ${EXEFILES_RELEASE} ${EXEFILES_DEBUG})
    vcpkg_copy_tool_dependencies("${CURRENT_PACKAGES_DIR}/tools/pcl")
endif()

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(INSTALL "${SOURCE_PATH}/LICENSE.txt" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
