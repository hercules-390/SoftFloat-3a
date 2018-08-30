
/*============================================================================

This C source file is part of the SoftFloat IEEE Floating-Point Arithmetic
Package, Release 3e, by John R. Hauser.

Copyright 2011, 2012, 2013, 2014, 2015, 2016 The Regents of the University of
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

float32_t softfloat_subMagsF32( uint_fast32_t uiA, uint_fast32_t uiB )
{
    int_fast16_t expA;
    uint_fast32_t sigA;
    int_fast16_t expB;
    uint_fast32_t sigB;
    int_fast16_t expDiff;
    uint_fast32_t uiZ;
    int_fast32_t sigDiff;
    bool signZ;
    int_fast8_t shiftDist;
    int_fast16_t expZ;
    uint_fast32_t sigX, sigY;
    union ui32_f32 uZ;

    /*------------------------------------------------------------------------
    *------------------------------------------------------------------------*/
    expA = expF32UI( uiA );
    sigA = fracF32UI( uiA );
    expB = expF32UI( uiB );
    sigB = fracF32UI( uiB );
    /*------------------------------------------------------------------------
    *------------------------------------------------------------------------*/
    expDiff = expA - expB;
    if ( ! expDiff ) {
        /*--------------------------------------------------------------------
            Exponents are the same, significand alignment not needed.  Check
            for each of the following:
            1. Non-finite inputs: NaN, infinity.
            2. Exact Zero Difference.  See SA22-7832-11 figure 19-8 on p. 19-8
            3. Non-zero difference.  
        *--------------------------------------------------------------------*/
        if ( expA == 0xFF ) {       /* inputs non-finite.               */
            if ( sigA | sigB ) goto propagateNaN;
            softfloat_raiseFlags( softfloat_flag_invalid );
            uiZ = defaultNaNF32UI;  /* Infinity - Infinity is not zero  */
            goto uiZ;
        }
        sigDiff = sigA - sigB;
        if ( ! sigDiff ) {          /* input values equal, return -0    */
            uiZ =                   /* ...if round to min, else +0.     */
                packToF32UI(        /* ...See SA22-7832-11 p. 19-8,     */
                                    /* ..."exact zero difference"       */
                    (softfloat_roundingMode == softfloat_round_min), 0, 0 );
            goto uiZ;
        }
        if ( expA ) --expA;     /* account for subtraction of implicit MSB  */
        signZ = signF32UI( uiA );   /* Sign of A is result sign         */
        if ( sigDiff < 0 ) {        /* if difference is neagative,      */
            signZ = ! signZ;        /* ...reverse sign and              */
            sigDiff = -sigDiff;     /* ...negate significand            */
        }
        shiftDist = softfloat_countLeadingZeros32( sigDiff ) - 8;
        expZ = expA - shiftDist;
        if ( expZ < 0 ) {
            shiftDist = expA;
            expZ = 0;
        }
#if defined( IBM_IEEE )
        /* If exp zero and sig non-zero, then still tiny.  If addition  */
        /* ...overflowed into exponent, which is OK, then no longer a   */
        /* ...tiny.                                                     */
                /* Is result still a tiny?                              */
        if ( !(expZ) && sigDiff )
        {       /* ..yes, save value for scaled result, set flags,      */
                /* ...indicate subnormal result                         */
            softfloat_exceptionFlags |= softfloat_flag_tiny;
            softfloat_raw.Incre = false;    /* Not incremented          */
            softfloat_raw.Inexact = false;  /* Not inexact              */
            softfloat_raw.Tiny = true;      /* Is tiny (subnormal)      */
            softfloat_raw.Sign = signZ;     /* Save result sign         */
            softfloat_raw.Exp = -126;       /* Indicate subnormal in exp */
                /* 32 + 7; save significand for scaling                 */
            softfloat_raw.Sig64 = ((uint_fast64_t) (sigDiff << shiftDist)) << 39;
            softfloat_raw.Sig0 = 0;         /* Zero bits 64-128         */
        }
#endif
        uiZ = packToF32UI( signZ, expZ, sigDiff<<shiftDist );
        goto uiZ;
    } else {
        /*--------------------------------------------------------------------
        *--------------------------------------------------------------------*/
        signZ = signF32UI( uiA );
        sigA <<= 7;
        sigB <<= 7;
        if ( expDiff < 0 ) {
            /*----------------------------------------------------------------
            *----------------------------------------------------------------*/
            signZ = ! signZ;
            if ( expB == 0xFF ) {
                if ( sigB ) goto propagateNaN;
                uiZ = packToF32UI( signZ, 0xFF, 0 );
                goto uiZ;
            }
            expZ = expB - 1;
            sigX = sigB | 0x40000000;
            sigY = sigA + (expA ? 0x40000000 : sigA);
            expDiff = -expDiff;
        } else {
            /*----------------------------------------------------------------
            *----------------------------------------------------------------*/
            if ( expA == 0xFF ) {
                if ( sigA ) goto propagateNaN;
                uiZ = uiA;
                goto uiZ;
            }
            expZ = expA - 1;
            sigX = sigA | 0x40000000;
            sigY = sigB + (expB ? 0x40000000 : sigB);
        }
        return
            softfloat_normRoundPackToF32(
                signZ, expZ, sigX - softfloat_shiftRightJam32( sigY, expDiff )
            );
    }
    /*------------------------------------------------------------------------
    *------------------------------------------------------------------------*/
 propagateNaN:
    uiZ = softfloat_propagateNaNF32UI( uiA, uiB );
 uiZ:
    uZ.ui = uiZ;
    return uZ.f;

}

