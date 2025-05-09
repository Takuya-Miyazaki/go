// Copyright 2013 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build !math_big_pure_go && (ppc64 || ppc64le)

#include "textflag.h"

// This file provides fast assembly versions for the elementary
// arithmetic operations on vectors implemented in arith.go.

// func addVV(z, y, y []Word) (c Word)
// z[i] = x[i] + y[i] for all i, carrying
TEXT ·addVV(SB), NOSPLIT, $0
	MOVD  z_len+8(FP), R7   // R7 = z_len
	MOVD  x+24(FP), R8      // R8 = x[]
	MOVD  y+48(FP), R9      // R9 = y[]
	MOVD  z+0(FP), R10      // R10 = z[]

	// If z_len = 0, we are done
	CMP   R7, $0
	MOVD  R0, R4
	BEQ   done

	// Process the first iteration out of the loop so we can
	// use MOVDU and avoid 3 index registers updates.
	MOVD  0(R8), R11      // R11 = x[i]
	MOVD  0(R9), R12      // R12 = y[i]
	ADD   $-1, R7         // R7 = z_len - 1
	ADDC  R12, R11, R15   // R15 = x[i] + y[i], set CA
	CMP   R7, $0
	MOVD  R15, 0(R10)     // z[i]
	BEQ   final          // If z_len was 1, we are done

	SRD   $2, R7, R5      // R5 = z_len/4
	CMP   R5, $0
	MOVD  R5, CTR         // Set up loop counter
	BEQ   tail            // If R5 = 0, we can't use the loop

	// Process 4 elements per iteration. Unrolling this loop
	// means a performance trade-off: we will lose performance
	// for small values of z_len (0.90x in the worst case), but
	// gain significant performance as z_len increases (up to
	// 1.45x).

	PCALIGN $16
loop:
	MOVD  8(R8), R11      // R11 = x[i]
	MOVD  16(R8), R12     // R12 = x[i+1]
	MOVD  24(R8), R14     // R14 = x[i+2]
	MOVDU 32(R8), R15     // R15 = x[i+3]
	MOVD  8(R9), R16      // R16 = y[i]
	MOVD  16(R9), R17     // R17 = y[i+1]
	MOVD  24(R9), R18     // R18 = y[i+2]
	MOVDU 32(R9), R19     // R19 = y[i+3]
	ADDE  R11, R16, R20   // R20 = x[i] + y[i] + CA
	ADDE  R12, R17, R21   // R21 = x[i+1] + y[i+1] + CA
	ADDE  R14, R18, R22   // R22 = x[i+2] + y[i+2] + CA
	ADDE  R15, R19, R23   // R23 = x[i+3] + y[i+3] + CA
	MOVD  R20, 8(R10)     // z[i]
	MOVD  R21, 16(R10)    // z[i+1]
	MOVD  R22, 24(R10)    // z[i+2]
	MOVDU R23, 32(R10)    // z[i+3]
	ADD   $-4, R7         // R7 = z_len - 4
	BDNZ  loop

	// We may have more elements to read
	CMP   R7, $0
	BEQ   final

	// Process the remaining elements, one at a time
tail:
	MOVDU 8(R8), R11      // R11 = x[i]
	MOVDU 8(R9), R16      // R16 = y[i]
	ADD   $-1, R7         // R7 = z_len - 1
	ADDE  R11, R16, R20   // R20 = x[i] + y[i] + CA
	CMP   R7, $0
	MOVDU R20, 8(R10)     // z[i]
	BEQ   final           // If R7 = 0, we are done

	MOVDU 8(R8), R11
	MOVDU 8(R9), R16
	ADD   $-1, R7
	ADDE  R11, R16, R20
	CMP   R7, $0
	MOVDU R20, 8(R10)
	BEQ   final

	MOVD  8(R8), R11
	MOVD  8(R9), R16
	ADDE  R11, R16, R20
	MOVD  R20, 8(R10)

final:
	ADDZE R4              // Capture CA

done:
	MOVD  R4, c+72(FP)
	RET

// func subVV(z, x, y []Word) (c Word)
// z[i] = x[i] - y[i] for all i, carrying
TEXT ·subVV(SB), NOSPLIT, $0
	MOVD  z_len+8(FP), R7 // R7 = z_len
	MOVD  x+24(FP), R8    // R8 = x[]
	MOVD  y+48(FP), R9    // R9 = y[]
	MOVD  z+0(FP), R10    // R10 = z[]

	// If z_len = 0, we are done
	CMP   R7, $0
	MOVD  R0, R4
	BEQ   done

	// Process the first iteration out of the loop so we can
	// use MOVDU and avoid 3 index registers updates.
	MOVD  0(R8), R11      // R11 = x[i]
	MOVD  0(R9), R12      // R12 = y[i]
	ADD   $-1, R7         // R7 = z_len - 1
	SUBC  R12, R11, R15   // R15 = x[i] - y[i], set CA
	CMP   R7, $0
	MOVD  R15, 0(R10)     // z[i]
	BEQ   final           // If z_len was 1, we are done

	SRD   $2, R7, R5      // R5 = z_len/4
	CMP   R5, $0
	MOVD  R5, CTR         // Set up loop counter
	BEQ   tail            // If R5 = 0, we can't use the loop

	// Process 4 elements per iteration. Unrolling this loop
	// means a performance trade-off: we will lose performance
	// for small values of z_len (0.92x in the worst case), but
	// gain significant performance as z_len increases (up to
	// 1.45x).

	PCALIGN $16
loop:
	MOVD  8(R8), R11      // R11 = x[i]
	MOVD  16(R8), R12     // R12 = x[i+1]
	MOVD  24(R8), R14     // R14 = x[i+2]
	MOVDU 32(R8), R15     // R15 = x[i+3]
	MOVD  8(R9), R16      // R16 = y[i]
	MOVD  16(R9), R17     // R17 = y[i+1]
	MOVD  24(R9), R18     // R18 = y[i+2]
	MOVDU 32(R9), R19     // R19 = y[i+3]
	SUBE  R16, R11, R20   // R20 = x[i] - y[i] + CA
	SUBE  R17, R12, R21   // R21 = x[i+1] - y[i+1] + CA
	SUBE  R18, R14, R22   // R22 = x[i+2] - y[i+2] + CA
	SUBE  R19, R15, R23   // R23 = x[i+3] - y[i+3] + CA
	MOVD  R20, 8(R10)     // z[i]
	MOVD  R21, 16(R10)    // z[i+1]
	MOVD  R22, 24(R10)    // z[i+2]
	MOVDU R23, 32(R10)    // z[i+3]
	ADD   $-4, R7         // R7 = z_len - 4
	BDNZ  loop

	// We may have more elements to read
	CMP   R7, $0
	BEQ   final

	// Process the remaining elements, one at a time
tail:
	MOVDU 8(R8), R11      // R11 = x[i]
	MOVDU 8(R9), R16      // R16 = y[i]
	ADD   $-1, R7         // R7 = z_len - 1
	SUBE  R16, R11, R20   // R20 = x[i] - y[i] + CA
	CMP   R7, $0
	MOVDU R20, 8(R10)     // z[i]
	BEQ   final           // If R7 = 0, we are done

	MOVDU 8(R8), R11
	MOVDU 8(R9), R16
	ADD   $-1, R7
	SUBE  R16, R11, R20
	CMP   R7, $0
	MOVDU R20, 8(R10)
	BEQ   final

	MOVD  8(R8), R11
	MOVD  8(R9), R16
	SUBE  R16, R11, R20
	MOVD  R20, 8(R10)

final:
	ADDZE R4
	XOR   $1, R4

done:
	MOVD  R4, c+72(FP)
	RET

// func addVW(z, x []Word, y Word) (c Word)
TEXT ·addVW(SB), NOSPLIT, $0
	MOVD z+0(FP), R10	// R10 = z[]
	MOVD x+24(FP), R8	// R8 = x[]
	MOVD y+48(FP), R4	// R4 = y = c
	MOVD z_len+8(FP), R11	// R11 = z_len

	CMP   R11, $0		// If z_len is zero, return
	BEQ   done

	// We will process the first iteration out of the loop so we capture
	// the value of c. In the subsequent iterations, we will rely on the
	// value of CA set here.
	MOVD  0(R8), R20	// R20 = x[i]
	ADD   $-1, R11		// R11 = z_len - 1
	ADDC  R20, R4, R6	// R6 = x[i] + c
	CMP   R11, $0		// If z_len was 1, we are done
	MOVD  R6, 0(R10)	// z[i]
	BEQ   final

	// We will read 4 elements per iteration
	SRDCC $2, R11, R9	// R9 = z_len/4
	DCBT  (R8)
	MOVD  R9, CTR		// Set up the loop counter
	BEQ   tail		// If R9 = 0, we can't use the loop
	PCALIGN $16

loop:
	MOVD  8(R8), R20	// R20 = x[i]
	MOVD  16(R8), R21	// R21 = x[i+1]
	MOVD  24(R8), R22	// R22 = x[i+2]
	MOVDU 32(R8), R23	// R23 = x[i+3]
	ADDZE R20, R24		// R24 = x[i] + CA
	ADDZE R21, R25		// R25 = x[i+1] + CA
	ADDZE R22, R26		// R26 = x[i+2] + CA
	ADDZE R23, R27		// R27 = x[i+3] + CA
	MOVD  R24, 8(R10)	// z[i]
	MOVD  R25, 16(R10)	// z[i+1]
	MOVD  R26, 24(R10)	// z[i+2]
	MOVDU R27, 32(R10)	// z[i+3]
	ADD   $-4, R11		// R11 = z_len - 4
	BDNZ  loop

	// We may have some elements to read
	CMP R11, $0
	BEQ final

tail:
	MOVDU 8(R8), R20
	ADDZE R20, R24
	ADD $-1, R11
	MOVDU R24, 8(R10)
	CMP R11, $0
	BEQ final

	MOVDU 8(R8), R20
	ADDZE R20, R24
	ADD $-1, R11
	MOVDU R24, 8(R10)
	CMP R11, $0
	BEQ final

	MOVD 8(R8), R20
	ADDZE R20, R24
	MOVD R24, 8(R10)

final:
	ADDZE R0, R4		// c = CA
done:
	MOVD  R4, c+56(FP)
	RET

// func subVW(z, x []Word, y Word) (c Word)
TEXT ·subVW(SB), NOSPLIT, $0
	MOVD  z+0(FP), R10	// R10 = z[]
	MOVD  x+24(FP), R8	// R8 = x[]
	MOVD  y+48(FP), R4	// R4 = y = c
	MOVD  z_len+8(FP), R11	// R11 = z_len

	CMP   R11, $0		// If z_len is zero, return
	BEQ   done

	// We will process the first iteration out of the loop so we capture
	// the value of c. In the subsequent iterations, we will rely on the
	// value of CA set here.
	MOVD  0(R8), R20	// R20 = x[i]
	ADD   $-1, R11		// R11 = z_len - 1
	SUBC  R4, R20, R6	// R6 = x[i] - c
	CMP   R11, $0		// If z_len was 1, we are done
	MOVD  R6, 0(R10)	// z[i]
	BEQ   final

	// We will read 4 elements per iteration
	SRDCC $2, R11, R9	// R9 = z_len/4
	DCBT  (R8)
	MOVD  R9, CTR		// Set up the loop counter
	BEQ   tail		// If R9 = 0, we can't use the loop

	// The loop here is almost the same as the one used in s390x, but
	// we don't need to capture CA every iteration because we've already
	// done that above.

	PCALIGN $16
loop:
	MOVD  8(R8), R20
	MOVD  16(R8), R21
	MOVD  24(R8), R22
	MOVDU 32(R8), R23
	SUBE  R0, R20
	SUBE  R0, R21
	SUBE  R0, R22
	SUBE  R0, R23
	MOVD  R20, 8(R10)
	MOVD  R21, 16(R10)
	MOVD  R22, 24(R10)
	MOVDU R23, 32(R10)
	ADD   $-4, R11
	BDNZ  loop

	// We may have some elements to read
	CMP   R11, $0
	BEQ   final

tail:
	MOVDU 8(R8), R20
	SUBE  R0, R20
	ADD   $-1, R11
	MOVDU R20, 8(R10)
	CMP   R11, $0
	BEQ   final

	MOVDU 8(R8), R20
	SUBE  R0, R20
	ADD   $-1, R11
	MOVDU R20, 8(R10)
	CMP   R11, $0
	BEQ   final

	MOVD  8(R8), R20
	SUBE  R0, R20
	MOVD  R20, 8(R10)

final:
	// Capture CA
	SUBE  R4, R4
	NEG   R4, R4

done:
	MOVD  R4, c+56(FP)
	RET

//func lshVU(z, x []Word, s uint) (c Word)
TEXT ·lshVU(SB), NOSPLIT, $0
	MOVD    z+0(FP), R3
	MOVD    x+24(FP), R6
	MOVD    s+48(FP), R9
	MOVD    z_len+8(FP), R4
	MOVD    x_len+32(FP), R7
	CMP     R4, $0          // len(z)==0 return
	BEQ     done

	ADD     $-1, R4, R5     // len(z)-1
	SUBC    R9, $64, R4     // ŝ=_W-s, we skip & by _W-1 as the caller ensures s < _W(64)
	SLD     $3, R5, R7
	ADD     R6, R7, R15     // save starting address &x[len(z)-1]
	ADD     R3, R7, R16     // save starting address &z[len(z)-1]
	MOVD    (R6)(R7), R14
	SRD     R4, R14, R7     // compute x[len(z)-1]>>ŝ into R7
	CMP     R5, $0          // iterate from i=len(z)-1 to 0
	BEQ     loopexit        // Already at end?
	MOVD	0(R15),R10	// x[i]
	PCALIGN $16
shloop:
	SLD     R9, R10, R10    // x[i]<<s
	MOVDU   -8(R15), R14
	SRD     R4, R14, R11    // x[i-1]>>ŝ
	OR      R11, R10, R10
	MOVD    R10, 0(R16)     // z[i-1]=x[i]<<s | x[i-1]>>ŝ
	MOVD	R14, R10	// reuse x[i-1] for next iteration
	ADD     $-8, R16        // i--
	CMP     R15, R6         // &x[i-1]>&x[0]?
	BGT     shloop
loopexit:
	MOVD    0(R6), R4
	SLD     R9, R4, R4
	MOVD    R4, 0(R3)       // z[0]=x[0]<<s
	MOVD    R7, c+56(FP)    // store pre-computed x[len(z)-1]>>ŝ into c
	RET
done:
	MOVD    R0, c+56(FP)    // c=0
	RET

//func rshVU(z, x []Word, s uint) (c Word)
TEXT ·rshVU(SB), NOSPLIT, $0
	MOVD    z+0(FP), R3
	MOVD    x+24(FP), R6
	MOVD    s+48(FP), R9
	MOVD    z_len+8(FP), R4
	MOVD    x_len+32(FP), R7

	CMP     R4, $0          // len(z)==0 return
	BEQ     done
	SUBC    R9, $64, R5     // ŝ=_W-s, we skip & by _W-1 as the caller ensures s < _W(64)

	MOVD    0(R6), R7
	SLD     R5, R7, R7      // compute x[0]<<ŝ
	MOVD    $1, R8          // iterate from i=1 to i<len(z)
	CMP     R8, R4
	BGE     loopexit        // Already at end?

	// vectorize if len(z) is >=3, else jump to scalar loop
	CMP     R4, $3
	BLT     scalar
	MTVSRD  R9, VS38        // s
	VSPLTB  $7, V6, V4
	MTVSRD  R5, VS39        // ŝ
	VSPLTB  $7, V7, V2
	ADD     $-2, R4, R16
	PCALIGN $16
loopback:
	ADD     $-1, R8, R10
	SLD     $3, R10
	LXVD2X  (R6)(R10), VS32 // load x[i-1], x[i]
	SLD     $3, R8, R12
	LXVD2X  (R6)(R12), VS33 // load x[i], x[i+1]

	VSRD    V0, V4, V3      // x[i-1]>>s, x[i]>>s
	VSLD    V1, V2, V5      // x[i]<<ŝ, x[i+1]<<ŝ
	VOR     V3, V5, V5      // Or(|) the two registers together
	STXVD2X VS37, (R3)(R10) // store into z[i-1] and z[i]
	ADD     $2, R8          // Done processing 2 entries, i and i+1
	CMP     R8, R16         // Are there at least a couple of more entries left?
	BLE     loopback
	CMP     R8, R4          // Are we at the last element?
	BEQ     loopexit
scalar:
	ADD     $-1, R8, R10
	SLD     $3, R10
	MOVD    (R6)(R10),R11
	SRD     R9, R11, R11    // x[len(z)-2] >> s
	SLD     $3, R8, R12
	MOVD    (R6)(R12), R12
	SLD     R5, R12, R12    // x[len(z)-1]<<ŝ
	OR      R12, R11, R11   // x[len(z)-2]>>s | x[len(z)-1]<<ŝ
	MOVD    R11, (R3)(R10)  // z[len(z)-2]=x[len(z)-2]>>s | x[len(z)-1]<<ŝ
loopexit:
	ADD     $-1, R4
	SLD     $3, R4
	MOVD    (R6)(R4), R5
	SRD     R9, R5, R5      // x[len(z)-1]>>s
	MOVD    R5, (R3)(R4)    // z[len(z)-1]=x[len(z)-1]>>s
	MOVD    R7, c+56(FP)    // store pre-computed x[0]<<ŝ into c
	RET
done:
	MOVD    R0, c+56(FP)
	RET

// func mulAddVWW(z, x []Word, m, a Word) (c Word)
TEXT ·mulAddVWW(SB), NOSPLIT, $0
	MOVD    z+0(FP), R10      // R10 = z[]
	MOVD    x+24(FP), R8      // R8 = x[]
	MOVD    m+48(FP), R9      // R9 = m
	MOVD    a+56(FP), R4      // R4 = a = c
	MOVD    z_len+8(FP), R11  // R11 = z_len

	CMP     R11, $0
	BEQ     done

	MOVD    0(R8), R20
	ADD     $-1, R11
	MULLD   R9, R20, R6       // R6 = z0 = Low-order(x[i]*y)
	MULHDU  R9, R20, R7       // R7 = z1 = High-order(x[i]*y)
	ADDC    R4, R6            // R6 = z0 + r
	ADDZE   R7, R4            // R4 = z1 + CA
	CMP     R11, $0
	MOVD    R6, 0(R10)        // z[i]
	BEQ     done

	// We will read 4 elements per iteration
	SRDCC   $2, R11, R14      // R14 = z_len/4
	DCBT    (R8)
	MOVD    R14, CTR          // Set up the loop counter
	BEQ     tail              // If R9 = 0, we can't use the loop
	PCALIGN $16

loop:
	MOVD    8(R8), R20        // R20 = x[i]
	MOVD    16(R8), R21       // R21 = x[i+1]
	MOVD    24(R8), R22       // R22 = x[i+2]
	MOVDU   32(R8), R23       // R23 = x[i+3]
	MULLD   R9, R20, R24      // R24 = z0[i]
	MULHDU  R9, R20, R20      // R20 = z1[i]
	ADDC    R4, R24           // R24 = z0[i] + c
	MULLD   R9, R21, R25
	MULHDU  R9, R21, R21
	ADDE    R20, R25
	MULLD   R9, R22, R26
	MULHDU  R9, R22, R22
	MULLD   R9, R23, R27
	MULHDU  R9, R23, R23
	ADDE    R21, R26
	MOVD    R24, 8(R10)       // z[i]
	MOVD    R25, 16(R10)      // z[i+1]
	ADDE    R22, R27
	ADDZE   R23,R4		  // update carry
	MOVD    R26, 24(R10)      // z[i+2]
	MOVDU   R27, 32(R10)      // z[i+3]
	ADD     $-4, R11          // R11 = z_len - 4
	BDNZ    loop

	// We may have some elements to read
	CMP   R11, $0
	BEQ   done

	// Process the remaining elements, one at a time
tail:
	MOVDU   8(R8), R20        // R20 = x[i]
	MULLD   R9, R20, R24      // R24 = z0[i]
	MULHDU  R9, R20, R25      // R25 = z1[i]
	ADD     $-1, R11          // R11 = z_len - 1
	ADDC    R4, R24
	ADDZE   R25, R4
	MOVDU   R24, 8(R10)       // z[i]
	CMP     R11, $0
	BEQ     done              // If R11 = 0, we are done

	MOVDU   8(R8), R20
	MULLD   R9, R20, R24
	MULHDU  R9, R20, R25
	ADD     $-1, R11
	ADDC    R4, R24
	ADDZE   R25, R4
	MOVDU   R24, 8(R10)
	CMP     R11, $0
	BEQ     done

	MOVD    8(R8), R20
	MULLD   R9, R20, R24
	MULHDU  R9, R20, R25
	ADD     $-1, R11
	ADDC    R4, R24
	ADDZE   R25,R4
	MOVD    R24, 8(R10)

done:
	MOVD    R4, c+64(FP)
	RET

// func addMulVVWW(z, x, y []Word, m, a Word) (c Word)
TEXT ·addMulVVWW(SB), NOSPLIT, $0
	MOVD	z+0(FP), R22	// R22 = z[]
	MOVD	x+24(FP), R3	// R3 = x[]
	MOVD	y+48(FP), R4	// R4 = y[]
	MOVD	m+72(FP), R5	// R5 = m
	MOVD	z_len+8(FP), R6	// R6 = z_len

	CMP	R6, $4
	MOVD	a+80(FP), R9		// R9 = c = a
	BLT	tail
	SRD	$2, R6, R7
	MOVD	R7, CTR		// Initialize loop counter
	PCALIGN	$16

loop:
	MOVD	0(R4), R14	// y[i]
	MOVD	8(R4), R16	// y[i+1]
	MOVD	16(R4), R18	// y[i+2]
	MOVD	24(R4), R20	// y[i+3]
	MOVD	0(R3), R15	// x[i]
	MOVD	8(R3), R17	// x[i+1]
	MOVD	16(R3), R19	// x[i+2]
	MOVD	24(R3), R21	// x[i+3]
	MULLD	R5, R14, R10	// low y[i]*m
	MULHDU	R5, R14, R11	// high y[i]*m
	ADDC	R15, R10
	ADDZE	R11
	ADDC	R9, R10
	ADDZE	R11, R9
	MULLD	R5, R16, R14	// low y[i+1]*m
	MULHDU	R5, R16, R15	// high y[i+1]*m
	ADDC	R17, R14
	ADDZE	R15
	ADDC	R9, R14
	ADDZE	R15, R9
	MULLD	R5, R18, R16    // low y[i+2]*m
	MULHDU	R5, R18, R17    // high y[i+2]*m
	ADDC	R19, R16
	ADDZE	R17
	ADDC	R9, R16
	ADDZE	R17, R9
	MULLD	R5, R20, R18    // low y[i+3]*m
	MULHDU	R5, R20, R19    // high y[i+3]*m
	ADDC	R21, R18
	ADDZE	R19
	ADDC	R9, R18
	ADDZE	R19, R9
	MOVD	R10, 0(R22)	// z[i]
	MOVD	R14, 8(R22)	// z[i+1]
	MOVD	R16, 16(R22)	// z[i+2]
	MOVD	R18, 24(R22)	// z[i+3]
	ADD	$32, R3
	ADD	$32, R4
	ADD	$32, R22
	BDNZ	loop

	ANDCC	$3, R6
tail:
	CMP	R6, $0
	BEQ	done
	MOVD	R6, CTR
	PCALIGN $16
tailloop:
	MOVD	0(R4), R14
	MOVD	0(R3), R15
	MULLD	R5, R14, R10
	MULHDU	R5, R14, R11
	ADDC	R15, R10
	ADDZE	R11
	ADDC	R9, R10
	ADDZE	R11, R9
	MOVD	R10, 0(R22)
	ADD	$8, R3
	ADD	$8, R4
	ADD	$8, R22
	BDNZ	tailloop

done:
	MOVD	R9, c+88(FP)
	RET

