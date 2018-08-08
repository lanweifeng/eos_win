/* ===-- modti3.c - Implement __modti3 -------------------------------------===
 *
 *                     The LLVM Compiler Infrastructure
 *
 * This file is dual licensed under the MIT and the University of Illinois Open
 * Source Licenses. See LICENSE.TXT for details.
 *
 * ===----------------------------------------------------------------------===
 *
 * This file implements __modti3 for the compiler_rt library.
 *
 * ===----------------------------------------------------------------------===
 */

#include "int_t.h"

/*Returns: a % b */

ti_int __modti3(ti_int a, ti_int b)
{
    const int bits_in_tword_m1 = (int)(sizeof(ti_int) * CHAR_BIT) - 1;
    ti_int s = b >> bits_in_tword_m1;  /* s = b < 0 ? -1 : 0 */
    b = (b ^ s) - s;                   /* negate if s == -1 */
    s = a >> bits_in_tword_m1;         /* s = a < 0 ? -1 : 0 */
    a = (a ^ s) - s;                   /* negate if s == -1 */
    tu_int r;
    __udivmodti4(a, b, &r);
    return ((ti_int)r ^ s) - s;                /* negate if s == -1 */
}
