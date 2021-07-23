set (PACKAGE_VERSION 1.8.7)

if(VCPKG_TARGET_IS_WINDOWS)
    message(WARNING "libgcrypt on Windows uses a fork managed by the ShiftMediaProject: https://shiftmediaproject.github.io/")
    vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO ShiftMediaProject/libgcrypt
        REF libgcrypt-${PACKAGE_VERSION}
        SHA512 aef8d9c15f880e2510f0d7d39a689bbb35c923e3915621d75e0b926c00be176a0ad1d2d8d6ce02f1feec65780b87f35793b9f60697fdc2f44f54653764bd3238
        HEAD_REF master
        PATCHES
            outdir.patch
            runtime.patch
    )

    if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
        set(CONFIGURATION_RELEASE ReleaseDLL)
        set(CONFIGURATION_DEBUG DebugDLL)
    else()
        set(CONFIGURATION_RELEASE Release)
        set(CONFIGURATION_DEBUG Debug)
    endif()

    if(VCPKG_TARGET_IS_UWP)
        string(APPEND CONFIGURATION_RELEASE WinRT)
        string(APPEND CONFIGURATION_DEBUG WinRT)
    endif()

    if(VCPKG_TARGET_IS_UWP)
        set(_gcryptproject "${SOURCE_PATH}/SMP/libgcrypt_winrt.vcxproj")
    else()
        set(_gcryptproject "${SOURCE_PATH}/SMP/libgcrypt.vcxproj")
    endif()

    if(VCPKG_CRT_LINKAGE STREQUAL "static")
        set(RuntimeLibraryExt "")
    else()
        set(RuntimeLibraryExt "DLL")
    endif()

    vcpkg_install_msbuild(
        USE_VCPKG_INTEGRATION
        SOURCE_PATH ${SOURCE_PATH}
        PROJECT_SUBPATH SMP/libgcrypt.sln
        PLATFORM ${TRIPLET_SYSTEM_ARCH}
        LICENSE_SUBPATH COPYING.LIB
        RELEASE_CONFIGURATION ${CONFIGURATION_RELEASE}
        DEBUG_CONFIGURATION ${CONFIGURATION_DEBUG}
        SKIP_CLEAN
        OPTIONS_DEBUG "/p:RuntimeLibrary=MultiThreadedDebug${RuntimeLibraryExt}"
        OPTIONS_RELEASE "/p:RuntimeLibrary=MultiThreaded${RuntimeLibraryExt}"
    )

    get_filename_component(SOURCE_PATH_SUFFIX "${SOURCE_PATH}" NAME)
    file(RENAME "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/${SOURCE_PATH_SUFFIX}/msvc/include" "${CURRENT_PACKAGES_DIR}/include")
    
    set(exec_prefix "\${prefix}")
    set(libdir "\${prefix}/lib")
    set(includedir "\${prefix}/include")
    set(GCRYPT_CONFIG_LIBS "-L\${libdir} -lgcrypt")
    configure_file("${SOURCE_PATH}/src/libgcrypt.pc.in" "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/libgcrypt.pc" @ONLY)
    
    set(exec_prefix "\${prefix}")
    set(libdir "\${prefix}/lib")
    set(includedir "\${prefix}/../include")
    set(GCRYPT_CONFIG_LIBS "-L\${libdir} -lgcryptd")
    configure_file("${SOURCE_PATH}/src/libgcrypt.pc.in" "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/libgcrypt.pc" @ONLY)
    vcpkg_fixup_pkgconfig()
    vcpkg_copy_pdbs()

    # temp fix 
    file(REMOVE ${CURRENT_PACKAGES_DIR}/lib/COPYING.LIB)
    file(REMOVE ${CURRENT_PACKAGES_DIR}/debug/lib/COPYING.LIB)

else()
    vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO gpg/libgcrypt
        REF libgcrypt-${PACKAGE_VERSION}
        SHA512 43e50a1b8a3cdbf420171c785fe558f443b414b708defa585277ac5ea59f9d8ae7f4555ed291c16fa004e7d4dd93a5ab2011c3c591e784ce3c6662a3193fd3e1
        HEAD_REF master
        PATCHES
            fix-pkgconfig.patch
            fix-flags.patch
    )

    vcpkg_configure_make(
        AUTOCONFIG
        SOURCE_PATH ${SOURCE_PATH}
        OPTIONS
            --disable-doc
            --disable-silent-rules
            --with-libgpg-error-prefix=${CURRENT_INSTALLED_DIR}/tools/libgpg-error
    )

    vcpkg_install_make()
    vcpkg_fixup_pkgconfig() 
    vcpkg_copy_pdbs()

    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)
    file(INSTALL ${SOURCE_PATH}/COPYING.LIB DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
endif()