
/*============================================================================

This C source file is part of the SoftFloat IEEE Floating-Point Arithmetic
Package, Release 3a, by John R. Hauser.

Copyright 2011, 2012, 2013, 2014 The Regents of the University of California.
All Rights Reserved.

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
 1) Added fields to the global state to store a rounded result with unbounded 
    unbiased exponent to enable return of a scaled rounded result. 
=============================================================================*/

#ifdef HAVE_PLATFORM_H 
#include "platform.h" 
#endif
#if !defined(int32_t) 
#include <stdint.h>             /* C99 standard integers */ 
#endif
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

#ifdef IBM_IEEE
/*----------------------------------------------------------------------------
| Rounded result with unbounded exponent, used for returning scaled results
|
| Raw unbiased exponent and raw rounded significand, used for return
| of scaled results following a trappable overflow or underflow.  Because
| trappability is dependent on the caller's state, not Softfloat's, these
| values are generated for every rounding.
|
| The routines fxxx_returnScaledResult() uses these values.
*----------------------------------------------------------------------------*/

uint_fast64_t softfloat_rawSig64;       /* Rounded significand bits 0-63                        */
uint_fast64_t softfloat_rawSig0;        /* Rounded significand bits 64-128                      */
int_fast16_t  softfloat_rawExp;         /* signed unbiased exponent                             */
bool          softfloat_rawSign;        /* sign of result                                       */

#endif /* IBM_IEEE  */

uint_fast8_t softfloat_roundingMode = softfloat_round_near_even;
uint_fast8_t softfloat_detectTininess = init_detectTininess;
uint_fast8_t softfloat_exceptionFlags = 0;

uint_fast8_t extF80_roundingPrecision = 80;

