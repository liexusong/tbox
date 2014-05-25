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
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        strcmp.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#ifdef TB_CONFIG_ASSEMBLER_GAS
#   define TB_LIBC_STRING_OPT_STRCMP
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#ifdef TB_CONFIG_ASSEMBLER_GAS
static tb_long_t tb_strcmp_impl(tb_char_t const* s1, tb_char_t const* s2)
{
    tb_assert_and_check_return_val(s1 && s2, 0);
    if (s1 == s2) return 0;

    __tb_register__ tb_long_t r = 0;
    __tb_asm__ __tb_volatile__
    (
        "1:\n"
        "ldrb   r2, [%1], #1\n"
        "ldrb   r3, [%2], #1\n"
        "cmp    r2, #1\n"
        "cmpcs  r2, r3\n"       // r2 == r3? if r2 >= 1
        "beq    1b\n"
        "sub    %0, r2, r3"     // r = r2 - r3 if r2 != r3

        : "=r"(r)
        : "r"(s1), "r"(s2)
        : "memory"
    );

    return r;
}
#endif
