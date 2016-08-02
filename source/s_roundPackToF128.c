
/*============================================================================

This C source file is part of the SoftFloat IEEE Floating-Point Arithmetic
Package, Release 3a, by John R. Hauser.

Copyright 2011, 2012, 2013, 2014, 2015 The Regents of the University of
California.  All rights reserved.

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
 1) Saved rounded result with unbounded unbiased exponent to enable
    return of a scaled rounded result, required by many instructions.
 2) Added rounding mode softfloat_rounding_odd, which corresponds to
    IBM Round For Shorter precision (RFS).  (not coded yet)
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
#include "softfloat.h"

float128_t
 softfloat_roundPackToF128(
     bool sign,
     int_fast32_t exp,
     uint_fast64_t sig64,
     uint_fast64_t sig0,
     uint_fast64_t sigExtra
 )
{
    uint_fast8_t roundingMode;
    bool roundNearEven, doIncrement, isTiny;
    struct uint128_extra sig128Extra;
    uint_fast64_t uiZ64, uiZ0;
    struct uint128 sig128;
    union ui128_f128 uZ;

#ifdef IBM_IEEE
    struct uint128 savesig;                 /* Savearea for rounded pre-underflow significand   */
#endif /* IBM_IEEE */

    roundingMode = softfloat_roundingMode;
    roundNearEven = (roundingMode == softfloat_round_near_even);
    doIncrement = (UINT64_C( 0x8000000000000000 ) <= sigExtra);
    if ( ! roundNearEven && (roundingMode != softfloat_round_near_maxMag) ) {
        doIncrement =
            (roundingMode
                 == (sign ? softfloat_round_min : softfloat_round_max))
                && sigExtra;
    }

#ifdef IBM_IEEE
    if (doIncrement) {
        sig128 = softfloat_add128(sig64, sig0, 0, 1);
        savesig.v64 = sig128.v64;
        savesig.v0  =
            sig128.v0
            & ~(uint64_t)
            (!(sigExtra & UINT64_C(0x7FFFFFFFFFFFFFFF))
                & roundNearEven);
    }
    else {
        savesig.v64 = sig64;
        savesig.v0 = sig0;
    }
    /* secret sauce below for round to odd                                                          */
    /* if pre-rounding result is exact, no rounding                                                 */
    /* rounding increment for round to odd is always zero, so alternatives are truncation to odd    */
    /* or increment to next odd.  Or'ing in a one-in the low-order bit achieves this                */
    savesig.v0 |= (uint_fast64_t)(sigExtra && (roundingMode == softfloat_round_odd));   /* ensure odd valued result if round to odd   */

    savesig = softfloat_shortShiftLeft128(savesig.v64, savesig.v0, 15);
    softfloat_rawExp   = exp - 16383;
    softfloat_rawSig64 = savesig.v64;
    softfloat_rawSig0  = savesig.v0;
    softfloat_rawSign  = sign;
#endif  /*   IBM_IEEE   */

    if ( 0x7FFD <= (uint32_t) exp ) {               /* if not overflow          */
        if ( exp < 0 ) {                            /* if underflow             */
            isTiny =                                /* isTiny always true in IBM_IEEE (tininesss before rounding)   */
                   (softfloat_detectTininess
                        == softfloat_tininess_beforeRounding)
                || (exp < -1)
                || ! doIncrement
                || softfloat_lt128(
                       sig64,
                       sig0,
                       UINT64_C( 0x0001FFFFFFFFFFFF ),
                       UINT64_C( 0xFFFFFFFFFFFFFFFF )
                   );
            sig128Extra =                           /* denormalize input value to enable zero exponent              */
                softfloat_shiftRightJam128Extra( sig64, sig0, sigExtra, -exp );
            sig64 = sig128Extra.v.v64;
            sig0  = sig128Extra.v.v0;
            sigExtra = sig128Extra.extra;
            exp = 0;
            if ( isTiny && sigExtra ) {             /* if one-bits shifted out, it's underflow                      */
                softfloat_raiseFlags( softfloat_flag_underflow );
            }
            doIncrement = (UINT64_C( 0x8000000000000000 ) <= sigExtra);     /* recalculate rounding increment       */
            if (
                   ! roundNearEven
                && (roundingMode != softfloat_round_near_maxMag)
            ) {
                doIncrement =
                    (roundingMode
                         == (sign ? softfloat_round_min : softfloat_round_max))
                        && sigExtra;
            }
        } else if (                         /* test for overflow or overflow after rounding                         */
               (0x7FFD < exp)               /* test for extant overflow                                             */
            || ((exp == 0x7FFD)             /* test for maxmag sig and max exp and increment needed, = overflow     */
                    && softfloat_eq128( 
                           sig64,
                           sig0,
                           UINT64_C( 0x0001FFFFFFFFFFFF ),
                           UINT64_C( 0xFFFFFFFFFFFFFFFF )
                       )
                    && doIncrement)
        ) {
            softfloat_raiseFlags(
                softfloat_flag_overflow | softfloat_flag_inexact );
            if (
                   roundNearEven
                || (roundingMode == softfloat_round_near_maxMag)
                || (roundingMode
                        == (sign ? softfloat_round_min : softfloat_round_max))
            ) {
                uiZ64 = packToF128UI64( sign, 0x7FFF, 0 );      /* set up to return infinity of correct sign        */
                uiZ0  = 0;
            } else {
                uiZ64 =
                    packToF128UI64(
                        sign, 0x7FFE, UINT64_C( 0x0000FFFFFFFFFFFF ) );
                uiZ0 = UINT64_C( 0xFFFFFFFFFFFFFFFF );
            }
            goto uiZ;
        }
    }
    if ( sigExtra ) softfloat_exceptionFlags |= softfloat_flag_inexact;

#ifdef IBM_IEEE
    if ( doIncrement && isTiny ) {
        sig128 = softfloat_add128( sig64, sig0, 0, 1 );
        sig64 = sig128.v64;
        sig0 =
            sig128.v0
                & ~(uint64_t)
                       (! (sigExtra & UINT64_C( 0x7FFFFFFFFFFFFFFF ))
                            & roundNearEven);
        /* secret sauce below for round to odd                                                          */
        /* if pre-rounding result is exact, no rounding                                                 */
        /* rounding increment for round to odd is always zero, so alternatives are truncation to odd    */
        /* or increment to next odd.  Or'ing in a one-in the low-order bit achieves this                */
        sig0 |= (uint_fast64_t)(sigExtra && (roundingMode == softfloat_round_odd));   /* ensure odd valued result if round to odd   */
    } else {
        if ( ! (sig64 | sig0) ) exp = 0;
        sig64 = savesig.v64;
        sig0 = savesig.v0;
    }

#else   /* not defined IBM_IEEE  */
    if (doIncrement) {
        sig128 = softfloat_add128(sig64, sig0, 0, 1);
        sig64 = sig128.v64;
        sig0 =
            sig128.v0
            & ~(uint64_t)
            (!(sigExtra & UINT64_C(0x7FFFFFFFFFFFFFFF))
                & roundNearEven);
    }
    else {
        if (!(sig64 | sig0)) exp = 0;
    }
#endif  /* IBM_IEEE  */

    uiZ64 = packToF128UI64(sign, exp, sig64);
    uiZ0 = sig0;

 uiZ:
    uZ.ui.v64 = uiZ64;
    uZ.ui.v0  = uiZ0;
    return uZ.f;

}

