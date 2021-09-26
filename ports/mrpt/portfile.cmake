
# git clone recursive, from scratch or cleaning if needed:
# -----------------------------------------------------------------------
if(VCPKG_USE_HEAD_VERSION)
    set(TARGET_GIT_SHA develop)
else()
    set(TARGET_GIT_SHA master)
endif()
set(TARGET_GIT_URL https://github.com/MRPT/mrpt.git)

set(PACKAGE_CHECKOUT_DIR "src")
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/${PACKAGE_CHECKOUT_DIR})

if (NOT EXISTS "${CURRENT_BUILDTREES_DIR}/${PACKAGE_CHECKOUT_DIR}")
  vcpkg_execute_required_process(
    COMMAND ${GIT} clone ${TARGET_GIT_URL} ${PACKAGE_CHECKOUT_DIR}
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}
    LOGNAME git-clone-${TARGET_TRIPLET}
  )
else()
  # Purge any local changes
  vcpkg_execute_required_process(
    COMMAND ${GIT} clean -xfd
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${PACKAGE_CHECKOUT_DIR}
    LOGNAME git-clean-1-${TARGET_TRIPLET}
  )

  # Also purge changes in submodules
  vcpkg_execute_required_process(
    COMMAND ${GIT} submodule foreach --recursive git clean -xfd
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${PACKAGE_CHECKOUT_DIR}
    LOGNAME git-clean-2-${TARGET_TRIPLET}
  )

  # And ensure that we are dealing with the right commit
  vcpkg_execute_required_process(
    COMMAND ${GIT} fetch origin ${TARGET_GIT_SHA}
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${PACKAGE_CHECKOUT_DIR}
    LOGNAME git-clean-3-${TARGET_TRIPLET}
  )
endif()

vcpkg_execute_required_process(
  COMMAND ${GIT} checkout ${TARGET_GIT_SHA}
  WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${PACKAGE_CHECKOUT_DIR}
  LOGNAME git-checkout-${TARGET_TRIPLET}
)

vcpkg_execute_required_process(
  COMMAND ${GIT} submodule update --init --recursive
  WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${PACKAGE_CHECKOUT_DIR}
  LOGNAME git-submodule-${TARGET_TRIPLET}
)

# CMake configure and build
# ---------------------------
vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    DISABLE_PARALLEL_CONFIGURE
    OPTIONS
        -DMRPT_BUILD_EXAMPLES:BOOL=OFF
    OPTIONS_DEBUG
        -DMRPT_BUILD_APPLICATIONS:BOOL=OFF
)
vcpkg_install_cmake(
    ADD_BIN_TO_PATH
)
file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/mrpt RENAME copyright)
vcpkg_copy_pdbs()
