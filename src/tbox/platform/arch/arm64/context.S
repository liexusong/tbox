/*!The Treasure Box Library
 * 
 * TBox is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * TBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with TBox; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2017, ruki All rights reserved.
 *
 * @author      ruki
 * @file        context.S
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* make context (refer to boost.context)
 *
 *
 *             --------------------------------------------------------------------------------------
 * stackdata: |                                                       |         context             ||
 *             --------------------------------------------------------------------------------------
 *                                                                                              (16-align)
 *
 *             ---------------------------------------------------------------------
 * context:   |   x19   |   x20   |   x21   |   x22   |   x23   |   x24   |   x25   |
 *             ---------------------------------------------------------------------
 *            0         8         16        24        32        40        48                     
 *                           
 *                                                                         
 *                                                     __end     func      
 *             ---------------------------------------------------------------------
 *            |   x26   |   x27   |   x28   |   fp    |   lr    |   pc    | padding |
 *             ---------------------------------------------------------------------
 *            56        64        72        80        88        96        |                 
 *                                                                        |                  
 *                                                                    16-align
 *
 *
 * @param stackdata     the stack data (x0)
 * @param stacksize     the stack size (x1)
 * @param func          the entry function (x2)
 *
 * @return              the context pointer (x0)
 */
function tb_context_make, export=1

    // save the stack top to x0
    add x0, x0, x1

    // 16-align of the stack top address 
    and x0, x0, ~0xf

    /* reserve space for context-data on context-stack
     *
     * 112 = align16(13 * 8)
     */
    sub x0, x0, #112

    // context.pc = func
    str x2, [x0, #96]

    // get the address of label __end
#ifdef TB_CONFIG_OS_IOS
    /* numeric offset since llvm still does not support labels in adr
     *
     * 0x0c = 3 instructions * size (4) before label '__end'
     *
     * new version llvm have already fix this issues.
     */
    adr x1, 0x0c
#else
    adr x1, __end
#endif

    // context.lr = the address of label __end
    str x1, [x0, #88]

    // return pointer to context-data (x0)
#ifdef TB_CONFIG_OS_IOS
    ret lr
#else
    ret x30
#endif

__end:

    // exit(0)
    mov x0, #0
#ifdef TB_ARCH_ELF
    bl _exit
#else
    bl __exit
#endif

endfunc

/* jump context (refer to boost.context)
 *
 * @param context       the to-context (x0)
 * @param priv          the passed user private data (x1)
 *
 * @return              the from-context (context: x0, priv: x1)
 */
function tb_context_jump, export=1

    /* prepare stack space first
     *
     * 0x70 = align16(13 * 8)
     */
    sub sp, sp, #0x70

    // save x19 - x30
    stp x19, x20, [sp, #0x00]
    stp x21, x22, [sp, #0x10]
    stp x23, x24, [sp, #0x20]
    stp x25, x26, [sp, #0x30]
    stp x27, x28, [sp, #0x40]
#ifdef TB_CONFIG_OS_IOS
    stp fp,  lr,  [sp, #0x50]
#else
    stp x29, x30, [sp, #0x50]
#endif

    // save lr as pc
#ifdef TB_CONFIG_OS_IOS
    str lr, [sp, #0x60]
#else
    str x30, [sp, #0x60]
#endif

    // save the old context(sp) to x4
    mov x4, sp

    // switch to the new context(sp) and stack
    mov sp, x0

    // restore x19 - x30
    ldp x19, x20, [sp, #0x00]
    ldp x21, x22, [sp, #0x10]
    ldp x23, x24, [sp, #0x20]
    ldp x25, x26, [sp, #0x30]
    ldp x27, x28, [sp, #0x40]
#ifdef TB_CONFIG_OS_IOS
    ldp fp,  lr,  [sp, #0x50]
#else
    ldp x29, x30, [sp, #0x50]
#endif

    /* pass old-context(context: x0, priv: x1) arguments to the context function
     *
     * and return from-context: retval(context: x0, priv: x1) from jump 
     */
    mov x0, x4

    // load pc
    ldr x4, [sp, #0x60]

    // restore stack space
    add sp, sp, #0x70

    // jump to the return or entry address(pc)
    ret x4

endfunc

