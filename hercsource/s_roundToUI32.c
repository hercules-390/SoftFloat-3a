
/*============================================================================

This C source file is part of the SoftFloat IEEE Floating-Point Arithmetic
Package, Release 3e, by John R. Hauser.

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 The Regents of the
University of California.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice,
    this list of conditions, and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions, and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

 3. Neither the name of the University nor the names of its contributors may
    be used to endorse or promote products derived from this software without
    specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS "AS IS", AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, ARE
DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=============================================================================*/

/*============================================================================
Modifications to comply with IBM IEEE Binary Floating Point, as defined
in the z/Architecture Principles of Operation, SA22-7832-10, by
Stephen R. Orso.  Said modifications identified by compilation conditioned
on preprocessor variable IBM_IEEE.
All such modifications placed in the public domain by Stephen R. Orso
Modifications:
 1) Changed value returned on negative non-zero input from max uint-32 to
    zero, per SA22-7832-10 Figure 19-19 on page 19-26.
 2) Added rounding mode softfloat_rounding_stickybit, which corresponds to
    IBM Round For Shorter precision (RFS).
 3) Added reporting of softfloat_flag_incremented when the significand was
    increased in magnitude by rounding.

=============================================================================*/


#ifdef HAVE_PLATFORM_H
#include "platform.h"
#endif
#if !defined(false)
#include <stdbool.h>
#endif
#if !defined(int32_t)
#include <stdint.h>             /* C99 standard integers */
#endif
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

uint_fast32_t
 softfloat_roundToUI32(
     bool sign, uint_fast64_t sig, uint_fast8_t roundingMode, bool exact )
{
    uint_fast16_t roundIncrement, roundBits;
    uint_fast32_t z;

#if defined( IBM_IEEE )
    uint_fast64_t savesig = sig >> 12; /* Save original significand for incremented test */
#endif /* IBM_IEEE  */

    /*------------------------------------------------------------------------
    *------------------------------------------------------------------------*/
    roundIncrement = 0x800;
    if (
        (roundingMode != softfloat_round_near_maxMag)
            && (roundingMode != softfloat_round_near_even)
    ) {
        roundIncrement = 0;
        if ( sign ) {
            if ( !sig ) return 0;
            if ( roundingMode == softfloat_round_min ) goto invalid;
#ifdef SOFTFLOAT_ROUND_ODD
            if ( roundingMode == softfloat_round_odd ) goto invalid;
#endif
        } else {
            if ( roundingMode == softfloat_round_max ) roundIncrement = 0xFFF;
        }
    }
    roundBits = sig & 0xFFF;
    sig += roundIncrement;
    if ( sig & UINT64_C( 0xFFFFF00000000000 ) ) goto invalid;
    z = sig>>12;
#if defined( IBM_IEEE )
    /* Sticky bit rounding: if pre-rounding result is exact, no rounding.  Leave result unchanged. */
    /* If the result is inexact (roundBits non-zero), the low-order bit of the result must be odd. */
    /* Or'ing in a one-in the low-order bit achieves this.  If it was not already a 1, it will be. */
    z |= (uint_fast32_t)(roundBits && (roundingMode == softfloat_round_stickybit));  /* ensure odd valued result if round to odd */
#endif  /* IBM_IEEE  */

    if (
        (roundBits == 0x800) && (roundingMode == softfloat_round_near_even)
    ) {
        z &= ~(uint_fast32_t) 1;
    }

#if defined( IBM_IEEE )
    softfloat_exceptionFlags |= (savesig < z) ? softfloat_flag_incremented : 0; /* indicate if significand was incremented */
#endif /*  IBM_IEEE */

    if ( sign && z ) goto invalid;
    if ( roundBits ) {
#ifdef SOFTFLOAT_ROUND_ODD
        if ( roundingMode == softfloat_round_odd ) z |= 1;
#endif
        if ( exact ) softfloat_exceptionFlags |= softfloat_flag_inexact;
    }
    return z;
    /*------------------------------------------------------------------------
    *------------------------------------------------------------------------*/
 invalid:
    softfloat_raiseFlags( softfloat_flag_invalid );
#if defined( IBM_IEEE )
    if (sign)
        return 0x00000000;
#endif   /* IBM_IEEE   */
    return sign ? ui32_fromNegOverflow : ui32_fromPosOverflow;

}

