#-------------------------------------------------------------------------------
# Copyright (c) 2020-2023, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
#-------------------------------------------------------------------------------

cmake_policy(SET CMP0076 NEW)

#========================= Platform region defs ===============================#

target_include_directories(platform_region_defs
    INTERFACE
        ${CORSTONE310_COMMON_DIR}/partition
        ${CMAKE_CURRENT_SOURCE_DIR}
)

#========================= Platform common defs ===============================#

# Specify the location of platform specific build dependencies.
target_sources(tfm_s
    PRIVATE
    ${CORSTONE310_COMMON_DIR}/device/source/startup_corstone310.c
)
target_add_scatter_file(tfm_s
    $<$<C_COMPILER_ID:ARMClang>:${PLATFORM_DIR}/ext/common/armclang/tfm_common_s.sct>
    $<$<C_COMPILER_ID:GNU>:${PLATFORM_DIR}/ext/common/gcc/tfm_common_s.ld>
    $<$<C_COMPILER_ID:IAR>:${PLATFORM_DIR}/ext/common/iar/tfm_common_s.icf>
)

if(BL2)
    target_sources(bl2
        PRIVATE
            ${CORSTONE310_COMMON_DIR}/device/source/startup_corstone310.c
    )
    target_add_scatter_file(bl2
        $<$<C_COMPILER_ID:ARMClang>:${PLATFORM_DIR}/ext/common/armclang/tfm_common_bl2.sct>
        $<$<C_COMPILER_ID:GNU>:${PLATFORM_DIR}/ext/common/gcc/tfm_common_bl2.ld>
        $<$<C_COMPILER_ID:IAR>:${PLATFORM_DIR}/ext/common/iar/tfm_common_bl2.icf>
    )
endif()

#========================= Device definition lib ===============================#

add_library(device_definition INTERFACE)
target_include_directories(device_definition
    INTERFACE
        ${CORSTONE310_COMMON_DIR}/device/include
        ${CORSTONE310_COMMON_DIR}/native_drivers
        ${CORSTONE310_COMMON_DIR}/partition
        ${PLATFORM_DIR}/ext/target/arm/drivers/flash/common
        ${PLATFORM_DIR}/ext/target/arm/drivers/usart/cmsdk
        ${PLATFORM_DIR}/ext/target/arm/drivers/usart/common
        ${PLATFORM_DIR}/ext/target/arm/drivers/mpc_sie
        ${PLATFORM_DIR}/ext/target/arm/drivers/mpu/armv8m
        ${PLATFORM_DIR}/ext/target/arm/drivers/counter/armv8m
        ${PLATFORM_DIR}/ext/target/arm/drivers/timer/armv8m
        ${ETHOS_DRIVER_PATH}/src
        ${ETHOS_DRIVER_PATH}/include
        ${CMAKE_CURRENT_SOURCE_DIR}/device/config
        ${CMAKE_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/platform/include
)

add_library(device_definition_s STATIC)
target_sources(device_definition_s
    PUBLIC
        ${CORSTONE310_COMMON_DIR}/device/source/platform_s_device_definition.c
)

target_compile_options(device_definition_s
    PRIVATE
        ${COMPILER_CMSE_FLAG}
)

#========================= CMSIS lib ===============================#

add_library(cmsis_includes INTERFACE)
target_include_directories(cmsis_includes
    INTERFACE
        ${CORSTONE310_COMMON_DIR}/device/include
        ${CORSTONE310_COMMON_DIR}/cmsis_drivers
        ${PLATFORM_DIR}/ext/cmsis
        ${CORSTONE310_COMMON_DIR}/partition
)

add_library(cmsis_includes_s INTERFACE)
target_link_libraries(cmsis_includes_s INTERFACE cmsis_includes)
target_include_directories(cmsis_includes_s
    INTERFACE
        ${CORSTONE310_COMMON_DIR}/cmsis_drivers/config/secure
)

target_compile_options(cmsis_includes_s
    INTERFACE
        ${COMPILER_CMSE_FLAG}
)

target_compile_options(cmsis_includes_s
    INTERFACE
        ${COMPILER_CP_FLAG}
)

target_link_options(cmsis_includes_s
    INTERFACE
        ${LINKER_CP_OPTION}
)

#========================= Linking ===============================#

target_link_libraries(device_definition_s PUBLIC device_definition)
target_link_libraries(device_definition_s PRIVATE cmsis_includes_s)

target_link_libraries(platform_bl2
    PUBLIC
        cmsis_includes
    PRIVATE
        device_definition_s
        cmsis_includes_s
)

target_link_libraries(platform_s
    PUBLIC
        cmsis_includes_s
    INTERFACE
        device_definition
    PRIVATE
        device_definition_s

)

#========================= Platform Secure ====================================#

target_include_directories(platform_s
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CORSTONE310_COMMON_DIR}
    PRIVATE
        ${CORSTONE310_COMMON_DIR}
        ${CORSTONE310_COMMON_DIR}/device
        ${CORSTONE310_COMMON_DIR}/services/src
        ${PLATFORM_DIR}/ext/common
)

target_sources(platform_s
    PRIVATE
        ${CORSTONE310_COMMON_DIR}/cmsis_drivers/Driver_MPC.c
        ${CORSTONE310_COMMON_DIR}/cmsis_drivers/Driver_TGU.c
        ${CORSTONE310_COMMON_DIR}/cmsis_drivers/Driver_PPC.c
        ${CORSTONE310_COMMON_DIR}/cmsis_drivers/Driver_USART.c
        ${CORSTONE310_COMMON_DIR}/device/source/system_core_init.c
        ${CORSTONE310_COMMON_DIR}/native_drivers/ppc_corstone310_drv.c
        ${CORSTONE310_COMMON_DIR}/native_drivers/tgu_armv8_m_drv.c
        ${CORSTONE310_COMMON_DIR}/tfm_peripherals_def.c
        ${PLATFORM_DIR}/ext/target/arm/drivers/usart/cmsdk/uart_cmsdk_drv.c
        ${PLATFORM_DIR}/ext/target/arm/drivers/mpc_sie/mpc_sie_drv.c
        ${PLATFORM_DIR}/ext/target/arm/drivers/mpu/armv8m/mpu_armv8m_drv.c
        ${PLATFORM_DIR}/ext/target/arm/drivers/counter/armv8m/syscounter_armv8-m_cntrl_drv.c
        ${ETHOS_DRIVER_PATH}/src/ethosu_device_u55_u65.c
        $<$<OR:$<BOOL:${TFM_PARTITION_SLIH_TEST}>,$<BOOL:${TFM_PARTITION_FLIH_TEST}>>:${CORSTONE310_COMMON_DIR}/plat_test.c>
        $<$<BOOL:${TFM_PARTITION_PLATFORM}>:${CORSTONE310_COMMON_DIR}/services/src/tfm_platform_system.c>
)

target_sources(tfm_sprt
    PRIVATE
        # SLIH test Partition and FLIH test Partition access the timer as ARoT Partitions.
        # Put the driver to SPRT so that both SLIH and FLIH tests can access it.
        $<$<OR:$<BOOL:${TFM_PARTITION_SLIH_TEST}>,$<BOOL:${TFM_PARTITION_FLIH_TEST}>>:${PLATFORM_DIR}/ext/target/arm/drivers/timer/armv8m/systimer_armv8-m_drv.c>
)

target_compile_options(platform_s
    PUBLIC
        ${COMPILER_CMSE_FLAG}
)

target_compile_definitions(platform_s
    PUBLIC
        ETHOSU_ARCH=$<LOWER_CASE:${ETHOSU_ARCH}>
        ETHOS$<UPPER_CASE:${ETHOSU_ARCH}>
        ETHOSU_LOG_SEVERITY=${ETHOSU_LOG_SEVERITY}
)

#========================= Platform BL2 =======================================#

if(BL2)
    # boot_hal_bl2.c is compiled as part of 'bl2' target and not inside
    # 'platform_bl2' where it suppose to be. This is due to
    # platform_init/quit* apis symbol collision in bl1.
    target_sources(bl2
        PRIVATE
            ${CORSTONE310_COMMON_DIR}/bl2/boot_hal_bl2.c
    )

    target_sources(platform_bl2
        PRIVATE
            ${CORSTONE310_COMMON_DIR}/cmsis_drivers/Driver_USART.c
            ${CORSTONE310_COMMON_DIR}/device/source/system_core_init.c
            ${PLATFORM_DIR}/ext/target/arm/drivers/flash/emulated/emulated_flash_drv.c
            ${PLATFORM_DIR}/ext/target/arm/drivers/usart/cmsdk/uart_cmsdk_drv.c
    )

    target_include_directories(platform_bl2
        PRIVATE
            ${CORSTONE310_COMMON_DIR}/device
            ${CORSTONE310_COMMON_DIR}/services/src
            ${CMAKE_CURRENT_SOURCE_DIR}/device/config
            ${CORSTONE310_COMMON_DIR}
    )
endif()

#========================= tfm_spm ============================================#

target_sources(tfm_spm
    PRIVATE
        ${CORSTONE310_COMMON_DIR}/target_cfg.c
        ${CORSTONE310_COMMON_DIR}/tfm_hal_platform.c
        ${PLATFORM_DIR}/ext/common/mpc_ppc_faults.c
        ${PLATFORM_DIR}/ext/common/tfm_hal_platform_v8m.c
        ${PLATFORM_DIR}/ext/common/tfm_hal_isolation_v8m.c
        ${CMAKE_CURRENT_SOURCE_DIR}/dma_init.c
        $<$<OR:$<BOOL:${CONFIG_TFM_FLIH_API}>,$<BOOL:${CONFIG_TFM_SLIH_API}>>:${PLATFORM_DIR}/ext/common/tfm_interrupts.c>
)

add_library(tfm_platform_config INTERFACE)

#========================= platform_region_defs ===============================#
target_compile_definitions(platform_region_defs
    INTERFACE
        FLASH_S_PARTITION_SIZE=${FLASH_S_PARTITION_SIZE}
        FLASH_NS_PARTITION_SIZE=${FLASH_NS_PARTITION_SIZE}
        PROVISIONING_CODE_PADDED_SIZE=${PROVISIONING_CODE_PADDED_SIZE}
        PROVISIONING_VALUES_PADDED_SIZE=${PROVISIONING_VALUES_PADDED_SIZE}
        PROVISIONING_DATA_PADDED_SIZE=${PROVISIONING_DATA_PADDED_SIZE}
)

if(NOT PLATFORM_DEFAULT_PROVISIONING)
add_subdirectory(${PLATFORM_DIR}/ext/target/arm/mps3/common/provisioning provisioning)
endif()

#========================= Files for building NS side platform ================#
target_compile_definitions(tfm_config
    INTERFACE
        FLASH_S_PARTITION_SIZE=${FLASH_S_PARTITION_SIZE}
        FLASH_NS_PARTITION_SIZE=${FLASH_NS_PARTITION_SIZE}
        PROVISIONING_CODE_PADDED_SIZE=${PROVISIONING_CODE_PADDED_SIZE}
        PROVISIONING_VALUES_PADDED_SIZE=${PROVISIONING_VALUES_PADDED_SIZE}
        PROVISIONING_DATA_PADDED_SIZE=${PROVISIONING_DATA_PADDED_SIZE}
)

install(FILES       ${CORSTONE310_COMMON_DIR}/cmsis_drivers/Driver_USART.c
                    ${CORSTONE310_COMMON_DIR}/cmsis_drivers/config/non_secure/cmsis_driver_config.h
                    ${CORSTONE310_COMMON_DIR}/cmsis_drivers/config/non_secure/RTE_Device.h
        DESTINATION ${INSTALL_PLATFORM_NS_DIR}/common/cmsis_drivers)

install(DIRECTORY   ${CORSTONE310_COMMON_DIR}/device
                    ${CORSTONE310_COMMON_DIR}/native_drivers
                    ${CORSTONE310_COMMON_DIR}/cmsis_drivers
        DESTINATION ${INSTALL_PLATFORM_NS_DIR}/common)

install(DIRECTORY   ${PLATFORM_DIR}/ext/target/arm/drivers
        DESTINATION ${INSTALL_PLATFORM_NS_DIR}/ext/target/arm)

install(FILES       ${PLATFORM_DIR}/ext/driver/Driver_USART.h
                    ${PLATFORM_DIR}/ext/driver/Driver_Common.h
        DESTINATION ${INSTALL_PLATFORM_NS_DIR}/ext/driver)

install(FILES       ${CORSTONE310_COMMON_DIR}/target_cfg.h
                    ${CORSTONE310_COMMON_DIR}/tfm_peripherals_def.h
                    ${PLATFORM_DIR}/include/tfm_plat_defs.h
        DESTINATION ${INSTALL_PLATFORM_NS_DIR}/common/include)

install(DIRECTORY   ${CORSTONE310_COMMON_DIR}/partition
        DESTINATION ${INSTALL_PLATFORM_NS_DIR}/common)

install(FILES       ${CORSTONE310_COMMON_DIR}/cpuarch.cmake
                    ${CORSTONE310_COMMON_DIR}/config.cmake
                    ${CORSTONE310_COMMON_DIR}/target_cfg.h
                    ${CORSTONE310_COMMON_DIR}/check_config.cmake
                    ${CORSTONE310_COMMON_DIR}/ns/common.cmake
        DESTINATION ${INSTALL_PLATFORM_NS_DIR}/common)

install(DIRECTORY   ${CORSTONE310_COMMON_DIR}/tests
        DESTINATION ${INSTALL_PLATFORM_NS_DIR})

if(DEFAULT_NS_SCATTER)
    # Install linker scripts
    install(FILES       ${PLATFORM_DIR}/ext/common/armclang/tfm_common_ns.sct
                        ${PLATFORM_DIR}/ext/common/gcc/tfm_common_ns.ld
                        ${PLATFORM_DIR}/ext/common/iar/tfm_common_ns.icf
            DESTINATION ${INSTALL_PLATFORM_NS_DIR}/linker_scripts)
endif()
