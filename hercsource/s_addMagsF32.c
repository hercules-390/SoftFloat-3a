
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

/*============================================================================
Modifications to comply with IBM IEEE Binary Floating Point, as defined
in the z/Architecture Principles of Operation, SA22-7832-10, by
Stephen R. Orso.  Said modifications identified by compilation conditioned
on preprocessor variable IBM_IEEE.
All such modifications placed in the public domain by Stephen R. Orso.
Modifications:
1) Changed processing such that softfloat_flag_tiny is raised when input
   exponents are both zero and the result significand is not zero.  This
   can occur when adding a tiny to zero or another tiny.
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

#if  1  /* includes define for IBM_IEEE  */
#include "softfloat.h"
#endif /* IBM_IEEE */

#include "specialize.h"

float32_t softfloat_addMagsF32( uint_fast32_t uiA, uint_fast32_t uiB )
{
    int_fast16_t expA;
    uint_fast32_t sigA;
    int_fast16_t expB;
    uint_fast32_t sigB;
    int_fast16_t expDiff;
    uint_fast32_t uiZ;
    bool signZ;
    int_fast16_t expZ;
    uint_fast32_t sigZ;
    union ui32_f32 uZ;

    /*------------------------------------------------------------------------
      Extract float_32 into components: exponents and significands (fractions)

      Used when adding 32-bit floating-point values of like signs or 
      subtracting 32-bit values of differing signs.  

      Basic Algorithm:
      1.  Check for any operand being a non-finite (NaN, infinity).  These
          result in the return of a NaN or infinity; no calculation is needed.
          (This test is performed in multiple places to enable fast-path code
          for matching exponents.)
      2.  If the input values exponents are different, increment the smaller
          exponent and shift its significand right until the exponents match.
          Use s_shiftRightJam32 for the shift to ensure bits shifed out of 
          guard digit positions are or'd into a right-most sticky bit to 
          prevent false zeros.  
      3.  If the exponents are the same, add the significands and, if needed,
          normalize the result.  For other than subnormals, use s_roundPackToF32
          for rounding and normalization.  

      Key to understanding what happens in this routine is that for normal
      numbers, the MSB of the signficand is always a 1 (that's the definition
      of normalized), and because it's always 1, it is not represented in the
      float_32 format.  When adding normals, the MSB or the result of adding
      two MSBs must be represented in the result.  So when you see a single
      bit such as 0x01000000 being included in an addition of signficands,
      that's the MSB or the result of adding two implicit MSBs.
    *------------------------------------------------------------------------*/
    expA = expF32UI( uiA );
    sigA = fracF32UI( uiA );
    expB = expF32UI( uiB );
    sigB = fracF32UI( uiB );
    /*------------------------------------------------------------------------
      If exponents are the same, then could be too non-finites (NaN/infinity)
      or simply two values with same exponent.
    *------------------------------------------------------------------------*/
    expDiff = expA - expB;
    if ( ! expDiff ) {
        /*--------------------------------------------------------------------
          Exponents match.  There are three possibilities for the operand pair:
          1.  If exponent is a zero, then both are tiny and the result will
              not overflow 23 bits; rounding will not be needed.
          2.  Both are non-finite (NaN, infinity).  NaNs have a non-zero
              significand which must be propagated.  If both are infinity,
              then infinity is the result.
          3.  Both are finites with the same exponent.  These may be added
              without shifting the signficand to make the exponents equal.
              Overflow out of 23 bits into 24 bits is possible, but no 
              rounding is needed, and the high-order bit (bit 9) can be 
              dealt with very elegantly by treating it as the low-order
              bit of the exponent.  
        *--------------------------------------------------------------------*/
        if ( ! expA ) { /* Both tiny; add significands and we're done        */
            uiZ = uiA + sigB;   /* signs same, result sign from sigB         */
#if defined( IBM_IEEE )
                        /* If exp zero and sig non-zero, then still tiny.    */
                        /* ...IFF addition overflowed into exponent, which   */
                        /* ...is OK, then no longer a tiny.                  */
            if ( !(uiZ & 0x7F800000) && ( uiZ & 0x007FFFFF ) )
                        /* Is result still a tiny?                           */
            {           /* ..yes, save value for scaled result, set flags    */
                softfloat_exceptionFlags |= softfloat_flag_tiny;
                        /* Indicate subnormal result                         */
                softfloat_raw.Incre = false;    /* Not incremented           */
                softfloat_raw.Inexact = false;  /* Not inexact               */
                softfloat_raw.Tiny = true;      /* Is tiny (subnormal)       */
                softfloat_raw.Sign = signF32UI( uiA ); /* Save result sign   */
                softfloat_raw.Exp = -126;       /* Indicate subnormal exp    */
                        /* 32 + 7; save significand for scaling              */
                softfloat_raw.Sig64 = ((uint_fast64_t) uiZ) << 39;
                softfloat_raw.Sig0 = 0;         /* Zero bits 64-128          */
            }
#endif
            goto uiZ;
        }
        if ( expA == 0xFF ) {   /* Both are non-finite.  Check for NaN      */
            if ( sigA | sigB ) goto propagateNaN;  /* at least one NaN      */
            uiZ = uiA;          /* Both are infinity.  That is the result   */
            goto uiZ;           /* No rounding/exception checking needed    */
        }
                                /* Both are finite, add significands        */
        signZ = signF32UI( uiA );   /* Sign of result                       */
        expZ = expA;            /* Exponent of result                       */
                                /* Add significands. 0x01000000 is the sum  */
                                /* of the two implicit MSBs.                */
        sigZ = 0x01000000 + sigA + sigB;
                                /* If signifcand sum is odd, then we lose   */
                                /* a bit on conversion to float_32 format.  */
        if ( ! (sigZ & 1) && (expZ < 0xFE) ) {   /* low bit is 0, no loss   */
            uiZ = packToF32UI( signZ, expZ, sigZ>>1 );
            goto uiZ;
        }
                                /* align significand to meet expectations   */
        sigZ <<= 6;             /* of softfloat_roundPackToF32              */
    } else {
        /*--------------------------------------------------------------------
          Exponents do not match.  Shift the input with the smaller exponent
          to the right and increment the exponent so that exponents match.
          Also, move both significands to the left 6 bits to create guard
          digits and a sticky bit on the right.  And if either operand is
          a non-finite (infinity or NaN), deal with it.
        *--------------------------------------------------------------------*/
        signZ = signF32UI( uiA );   /* Signs must be the same when calling   */
        sigA <<= 6;
        sigB <<= 6;
        if ( expDiff < 0 ) {            /* B's exponent is bigger            */
            if ( expB == 0xFF ) {       /* Is B non-finite?                  */
                                /* ..yes, it is either NaN or infinity       */
                if ( sigB ) goto propagateNaN;      /* ..nz sig, B is a NaN  */
                                /* ..not a NaN, return infinity              */
                uiZ = packToF32UI( signZ, 0xFF, 0 );
                goto uiZ;
            }
            expZ = expB;        /* result gets B's exponent.  Add implicit   */
                                /* MSB for smaller op if smaller was normal  */
                                /* ...could have been an "or" "|"            */
            sigA += expA ? 0x20000000 : sigA;
                                /* Shift A right to align with B; cram bits  */
                                /* ...one-bits lost into sticky position     */
                                /* ...(significand, guard bits, sticky bit)  */
            sigA = softfloat_shiftRightJam32( sigA, -expDiff );
        } else {                        /* A's exponent is bigger            */
            if ( expA == 0xFF ) {       /* Is A non-finite?                  */
                                /* ..yes, it is either NaN or infinity       */
                if ( sigA ) goto propagateNaN;      /* ..nz sig, A is a NaN  */
                uiZ = uiA;      /* ..not a NaN, return infinity              */
                goto uiZ;
            }
            expZ = expA;        /* result gets A's exponent.  Add implicit   */
                                /* MSB for smaller op if smaller was normal  */
                                /* ...could have been an "or" "|"            */
            sigB += expB ? 0x20000000 : sigB;
                                /* Shift B right to align with B; cram any   */
                                /* ...one-bits lost into sticky position     */
                                /* ...(significand, guard bits, sticky bit)  */
            sigB = softfloat_shiftRightJam32( sigB, expDiff );
        }
                                /* Add operands and MSB for larger operand   */
        sigZ = 0x20000000 + sigA + sigB;

                                /* if not an explicit MSB 1-bit in bit 1 of  */
                                /* one but not both operands, then one was   */
                                /* tiny.  Normalize so roundPackToF32 can    */
                                /* handle it correctly                       */
        if ( sigZ < 0x40000000 ) {
            --expZ;             /* decrement exponent and make the matching  */
            sigZ <<= 1;         /* ...one-bit left shift.                    */
        }
    }
    return softfloat_roundPackToF32( signZ, expZ, sigZ );
    /*------------------------------------------------------------------------
      End of normal processing; result returned to caller.  Following code
      used for NaN propagation and (uiZ:) completion of NaN, Infinity, or
      two tiny (subnormal) operands.
    *------------------------------------------------------------------------*/
 propagateNaN:
    uiZ = softfloat_propagateNaNF32UI( uiA, uiB );
 uiZ:
    uZ.ui = uiZ;
    return uZ.f;

}

