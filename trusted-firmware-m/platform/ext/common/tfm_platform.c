/*
 * Copyright (c) 2019-2020, Arm Limited. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 */

#include "target_cfg.h"
#include "tfm_spm_hal.h"
#include "uart_stdout.h"
#include "tfm_hal_platform.h"

__WEAK enum tfm_hal_status_t tfm_hal_platform_init(void)
{
    __enable_irq();

    /* Only if UART1 is used by TF-M do we initialize it. */
    #ifdef CONFIG_SECURE_UART1
    stdio_init();
    #endif

    return TFM_HAL_SUCCESS;
}

__WEAK void tfm_hal_system_reset(void)
{
    NVIC_SystemReset();
}
