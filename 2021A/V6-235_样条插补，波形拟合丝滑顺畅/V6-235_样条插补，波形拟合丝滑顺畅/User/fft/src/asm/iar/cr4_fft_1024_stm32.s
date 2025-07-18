/******************** (C) COPYRIGHT 2009  STMicroelectronics ********************
* File Name          : cr4_fft_1024_stm32.s
* Author             : MCD Application Team
;* Version            : V2.0.0
;* Date               : 04/27/2009
* Description        : Optimized 1024-point radix-4 complex FFT for Cortex-M3
********************************************************************************
* THE PRESENT FIRMWARE WHICH IS FOR GUIDANCE ONLY AIMS AT PROVIDING CUSTOMERS
* WITH CODING INFORMATION REGARDING THEIR PRODUCTS IN ORDER FOR THEM TO SAVE TIME.
* AS A RESULT, STMICROEECTRONICS SHALL NOT BE HELD LIABLE FOR ANY DIRECT,
* INDIRECT OR CONSEQUENTIAL DAMAGES WITH RESPECT TO ANY CLAIMS ARISING FROM THE
* CONTENT OF SUCH SOFTWARE AND/OR THE USE MADE BY CUSTOMERS OF THE CODING
* INFORMATION CONTAINED HEREIN IN CONNECTION WITH THEIR PRODUCTS.
*******************************************************************************/

#define pssK      R0
#define pssOUT    R0
#define pssX      R1
#define pssIN     R1
#define butternbr R2
#define Nbin      R2
#define index     R3
#define Ar        R4
#define Ai        R5
#define Br        R6
#define Bi        R7
#define Cr        R8
#define Ci        R9
#define Dr        R10
#define Di        R11
#define cntrbitrev R12
#define tmp       R12
#define pssIN2    R14
#define tmp2      R14
#define NPT       1024

/*---------------------------- MACROS ----------------------------------------*/
DEC     MACRO reg
        SUB  reg,reg,#1
        ENDM

INC     MACRO reg
        ADD  reg,reg,#1
        ENDM
  
QUAD    MACRO reg
        MOV  reg,reg,LSL#2
        ENDM

/*sXi = *(PssX+1); sXr = *PssX; PssX += offset; PssX= R1*/
LDR2Q   MACRO sXr,sXi, PssX, offset
        LDRSH sXi, [PssX, #2]
        LDRSH sXr, [PssX]
        ADD PssX, PssX, offset
        ENDM

/*!! Same macro, to be used when passing negative offset value !!*/
LDR2Qm  MACRO sXr,sXi, PssX, offset
        LDRSH sXi, [PssX, #2]
        LDRSH sXr, [PssX]
        SUB PssX, PssX, offset
        ENDM

/*(PssX+1)= sXi;  *PssX=sXr; PssX += offset */
STR2Q   MACRO sXr,sXi,PssX, offset
        STRH  sXi, [PssX, #2]
        STRH  sXr, [PssX]
        ADD PssX, PssX, offset
        ENDM

/* YY = Cplx_conjugate_mul(Y,K)
   Y = YYr + i*YYi
   use the following trick
   K = (Kr-Ki) + i*Ki */
CXMUL_V7 MACRO YYr, YYi, Yr, Yi, Kr, Ki,tmp,tmp2
         SUB  tmp2, Yi, Yr         /* sYi-sYr */
         MUL  tmp, tmp2, Ki        /* (sYi-sYr)*sKi */
         ADD  tmp2, Kr, Ki, LSL#1  /* (sKr+sKi) */
         MLA  YYi, Yi, Kr, tmp     /* lYYi = sYi*sKr-sYr*sKi */
         MLA  YYr, Yr, tmp2, tmp   /* lYYr = sYr*sKr+sYi*sKi */
         ENDM

/* Four point complex Fast Fourier Transform */
CXADDA4  MACRO s
        /* (C,D) = (C+D, C-D) */
        ADD     Cr, Cr, Dr
        ADD     Ci, Ci, Di
        SUB     Dr, Cr, Dr, LSL#1
        SUB     Di, Ci, Di, LSL#1
        /* (A,B) = (A+(B>>s), A-(B>>s))/4 */
        MOV     Ar, Ar, ASR#2
        MOV     Ai, Ai, ASR#2
        ADD     Ar, Ar, Br, ASR#(2+s)
        ADD     Ai, Ai, Bi, ASR#(2+s)
        SUB     Br, Ar, Br, ASR#(1+s)
        SUB     Bi, Ai, Bi, ASR#(1+s)
        /* (A,C) = (A+(C>>s)/4, A-(C>>s)/4) */
        ADD     Ar, Ar, Cr, ASR#(2+s)
        ADD     Ai, Ai, Ci, ASR#(2+s)
        SUB     Cr, Ar, Cr, ASR#(1+s)
        SUB     Ci, Ai, Ci, ASR#(1+s)
        /* (B,D) = (B-i*(D>>s)/4, B+i*(D>>s)/4) */
        ADD     Br, Br, Di, ASR#(2+s)
        SUB     Bi, Bi, Dr, ASR#(2+s)
        SUB     Di, Br, Di, ASR#(1+s)
        ADD     Dr, Bi, Dr, ASR#(1+s)
        ENDM

BUTFLY4ZERO_OPT  MACRO pIN,offset, pOUT
        LDRSH Ai, [pIN, #2]
        LDRSH Ar, [pIN]
	ADD   pIN, pIN, #NPT
        LDRSH Ci, [pIN, #2]
        LDRSH Cr, [pIN]
        ADD   pIN, pIN, #NPT
        LDRSH Bi, [pIN, #2]
        LDRSH Br, [pIN]
        ADD   pIN, pIN, #NPT
        LDRSH Di, [pIN, #2]
        LDRSH Dr, [pIN]
        ADD   pIN, pIN, #NPT	

        /* (C,D) = (C+D, C-D) */
        ADD     Cr, Cr, Dr
        ADD     Ci, Ci, Di
        SUB     Dr, Cr, Dr, LSL#1  /* trick */
        SUB     Di, Ci, Di, LSL#1  /* trick */
        /* (A,B) = (A+B)/4, (A-B)/4 */
        MOV     Ar, Ar, ASR#2
        MOV     Ai, Ai, ASR#2
        ADD     Ar, Ar, Br, ASR#2
        ADD     Ai, Ai, Bi, ASR#2
        SUB     Br, Ar, Br, ASR#1
        SUB     Bi, Ai, Bi, ASR#1
        /* (A,C) = (A+C)/4, (A-C)/4 */
        ADD     Ar, Ar, Cr, ASR#2
        ADD     Ai, Ai, Ci, ASR#2
        SUB     Cr, Ar, Cr, ASR#1
        SUB     Ci, Ai, Ci, ASR#1
        /* (B,D) = (B-i*D)/4, (B+i*D)/4 */
        ADD     Br, Br, Di, ASR#2
        SUB     Bi, Bi, Dr, ASR#2
        SUB     Di, Br, Di, ASR#1
        ADD     Dr, Bi, Dr, ASR#1
        
        STRH    Ai, [pOUT, #2]
        STRH    Ar, [pOUT], #4
        STRH    Bi, [pOUT, #2]
        STRH    Br, [pOUT], #4
        STRH    Ci, [pOUT, #2]
        STRH    Cr, [pOUT], #4
        STRH    Dr, [pOUT, #2]  /* inversion here */
        STRH    Di, [pOUT], #4
        ENDM

BUTFLY4_V7  MACRO pssDin,offset,pssDout,qformat,pssK
        LDR2Qm   Ar,Ai,pssDin, -offset                     
        LDR2Q    Dr,Di,pssK, #4
        /* format CXMUL_V7 YYr, YYi, Yr, Yi, Kr, Ki,tmp,tmp2 */
        CXMUL_V7 Dr,Di,Ar,Ai,Dr,Di,tmp,tmp2
        LDR2Qm   Ar,Ai,pssDin,-offset
        LDR2Q    Cr,Ci,pssK,#4
        CXMUL_V7 Cr,Ci,Ar,Ai,Cr,Ci,tmp,tmp2
        LDR2Qm    Ar,Ai, pssDin, -offset
        LDR2Q    Br,Bi, pssK, #4
        CXMUL_V7  Br,Bi,Ar,Ai,Br,Bi,tmp,tmp2
        LDR2Q    Ar,Ai, pssDin, #0
        CXADDA4  qformat
        STRH    Ai, [pssDout, #2]
        STRH    Ar, [pssDout]
        ADD     pssDout, pssDout, offset
        STRH    Bi, [pssDout, #2]
        STRH    Br, [pssDout]
        ADD     pssDout, pssDout, offset
        STRH    Ci, [pssDout, #2]
        STRH    Cr, [pssDout]
        ADD     pssDout, pssDout, offset
        STRH    Dr, [pssDout, #2]  /* inversion here */
        STRH    Di, [pssDout], #4
        ENDM


/*---------------------------- CODE ------------------------------------------*/
/*============================================================================*/
        MODULE FFT_CORTEXM3
        PUBLIC cr4_fft_1024_stm32
        EXTERN TableFFT
        SECTION .text:CODE(2)

/*******************************************************************************
* Function Name  : cr4_fft_1024_stm32
* Description    : complex radix-4 1024 points FFT
* Input          : - R0 = pssOUT: Output array .
*                  - R1 = pssIN: Input array 
*                  - R2 = Nbin: =1024 number of points, this optimized FFT   
*                    function can only convert 1024-points.
* Output         : None 
* Return         : None
*******************************************************************************/
cr4_fft_1024_stm32

        STMFD   SP!, {R4-R11, LR}
        
        MOV cntrbitrev, #0
        MOV index,#0
        
preloop_v7
        ADD     pssIN2, pssIN, cntrbitrev, LSR#22 /*1024-pts*/
        BUTFLY4ZERO_OPT pssIN2,Nbin,pssOUT
        INC index
        RBIT cntrbitrev,index
        CMP index,#256  /* 1024-pts */
        BNE  preloop_v7


        SUB     pssX, pssOUT, Nbin, LSL#2
        MOV     index, #16
        MOVS    butternbr, Nbin, LSR#4   /*dual use of register */
        
/*------------------------------------------------------------------------------
   The FFT coefficients table can be stored into Flash or RAM. 
   The following two lines of code allow selecting the method for coefficients 
   storage. 
   In the case of choosing coefficients in RAM, you have to:
   1. Include the file table_fft.h, which is a part of the DSP library, 
      in your main file.
   2. Decomment the line LDR.W pssK, =TableFFT and comment the line 
      ADRL    pssK, TableFFT_V7
   3. Comment all the TableFFT_V7 data.
------------------------------------------------------------------------------*/         
        ADRL    pssK, TableFFT_V7   /* Coeff in Flash */
        //LDR.W pssK, =TableFFT      /* Coeff in RAM */

/*................................*/
passloop_v7
        STMFD   SP!, {pssX,butternbr}
        ADD     tmp, index, index, LSL#1
        ADD     pssX, pssX, tmp
        SUB     butternbr, butternbr, #1<<16
/*................*/
grouploop_v7
        ADD     butternbr,butternbr,index,LSL#(16-2)
/*.......*/
butterloop_v7
        BUTFLY4_V7  pssX,index,pssX,14,pssK
        SUBS        butternbr,butternbr, #1<<16
        BGE     butterloop_v7
/*.......*/
        ADD     tmp, index, index, LSL#1
        ADD     pssX, pssX, tmp
        DEC     butternbr
        MOVS    tmp2, butternbr, LSL#16
        IT      NE
        SUBNE   pssK, pssK, tmp
        BNE     grouploop_v7
/*................*/
        LDMFD   sp!, {pssX, butternbr}
        QUAD    index
        MOVS    butternbr, butternbr, LSR#2    /* loop nbr /= radix */
        BNE     passloop_v7
/*................................*/
       LDMFD   SP!, {R4-R11, PC}

/*============================================================================*/

        DATA

TableFFT_V7
        // N=16
        DC16 0x4000,0x0000, 0x4000,0x0000, 0x4000,0x0000
        DC16 0xdd5d,0x3b21, 0x22a3,0x187e, 0x0000,0x2d41
        DC16 0xa57e,0x2d41, 0x0000,0x2d41, 0xc000,0x4000
        DC16 0xdd5d,0xe782, 0xdd5d,0x3b21, 0xa57e,0x2d41
        // N=64
        DC16 0x4000,0x0000, 0x4000,0x0000, 0x4000,0x0000
        DC16 0x2aaa,0x1294, 0x396b,0x0646, 0x3249,0x0c7c
        DC16 0x11a8,0x238e, 0x3249,0x0c7c, 0x22a3,0x187e
        DC16 0xf721,0x3179, 0x2aaa,0x1294, 0x11a8,0x238e
        DC16 0xdd5d,0x3b21, 0x22a3,0x187e, 0x0000,0x2d41
        DC16 0xc695,0x3fb1, 0x1a46,0x1e2b, 0xee58,0x3537
        DC16 0xb4be,0x3ec5, 0x11a8,0x238e, 0xdd5d,0x3b21
        DC16 0xa963,0x3871, 0x08df,0x289a, 0xcdb7,0x3ec5
        DC16 0xa57e,0x2d41, 0x0000,0x2d41, 0xc000,0x4000
        DC16 0xa963,0x1e2b, 0xf721,0x3179, 0xb4be,0x3ec5
        DC16 0xb4be,0x0c7c, 0xee58,0x3537, 0xac61,0x3b21
        DC16 0xc695,0xf9ba, 0xe5ba,0x3871, 0xa73b,0x3537
        DC16 0xdd5d,0xe782, 0xdd5d,0x3b21, 0xa57e,0x2d41
        DC16 0xf721,0xd766, 0xd556,0x3d3f, 0xa73b,0x238e
        DC16 0x11a8,0xcac9, 0xcdb7,0x3ec5, 0xac61,0x187e
        DC16 0x2aaa,0xc2c1, 0xc695,0x3fb1, 0xb4be,0x0c7c
        // N=256
        DC16 0x4000,0x0000, 0x4000,0x0000, 0x4000,0x0000
        DC16 0x3b1e,0x04b5, 0x3e69,0x0192, 0x3cc8,0x0324
        DC16 0x35eb,0x0964, 0x3cc8,0x0324, 0x396b,0x0646
        DC16 0x306c,0x0e06, 0x3b1e,0x04b5, 0x35eb,0x0964
        DC16 0x2aaa,0x1294, 0x396b,0x0646, 0x3249,0x0c7c
        DC16 0x24ae,0x1709, 0x37af,0x07d6, 0x2e88,0x0f8d
        DC16 0x1e7e,0x1b5d, 0x35eb,0x0964, 0x2aaa,0x1294
        DC16 0x1824,0x1f8c, 0x341e,0x0af1, 0x26b3,0x1590
        DC16 0x11a8,0x238e, 0x3249,0x0c7c, 0x22a3,0x187e
        DC16 0x0b14,0x2760, 0x306c,0x0e06, 0x1e7e,0x1b5d
        DC16 0x0471,0x2afb, 0x2e88,0x0f8d, 0x1a46,0x1e2b
        DC16 0xfdc7,0x2e5a, 0x2c9d,0x1112, 0x15fe,0x20e7
        DC16 0xf721,0x3179, 0x2aaa,0x1294, 0x11a8,0x238e
        DC16 0xf087,0x3453, 0x28b2,0x1413, 0x0d48,0x2620
        DC16 0xea02,0x36e5, 0x26b3,0x1590, 0x08df,0x289a
        DC16 0xe39c,0x392b, 0x24ae,0x1709, 0x0471,0x2afb
        DC16 0xdd5d,0x3b21, 0x22a3,0x187e, 0x0000,0x2d41
        DC16 0xd74e,0x3cc5, 0x2093,0x19ef, 0xfb8f,0x2f6c
        DC16 0xd178,0x3e15, 0x1e7e,0x1b5d, 0xf721,0x3179
        DC16 0xcbe2,0x3f0f, 0x1c64,0x1cc6, 0xf2b8,0x3368
        DC16 0xc695,0x3fb1, 0x1a46,0x1e2b, 0xee58,0x3537
        DC16 0xc197,0x3ffb, 0x1824,0x1f8c, 0xea02,0x36e5
        DC16 0xbcf0,0x3fec, 0x15fe,0x20e7, 0xe5ba,0x3871
        DC16 0xb8a6,0x3f85, 0x13d5,0x223d, 0xe182,0x39db
        DC16 0xb4be,0x3ec5, 0x11a8,0x238e, 0xdd5d,0x3b21
        DC16 0xb140,0x3daf, 0x0f79,0x24da, 0xd94d,0x3c42
        DC16 0xae2e,0x3c42, 0x0d48,0x2620, 0xd556,0x3d3f
        DC16 0xab8e,0x3a82, 0x0b14,0x2760, 0xd178,0x3e15
        DC16 0xa963,0x3871, 0x08df,0x289a, 0xcdb7,0x3ec5
        DC16 0xa7b1,0x3612, 0x06a9,0x29ce, 0xca15,0x3f4f
        DC16 0xa678,0x3368, 0x0471,0x2afb, 0xc695,0x3fb1
        DC16 0xa5bc,0x3076, 0x0239,0x2c21, 0xc338,0x3fec
        DC16 0xa57e,0x2d41, 0x0000,0x2d41, 0xc000,0x4000
        DC16 0xa5bc,0x29ce, 0xfdc7,0x2e5a, 0xbcf0,0x3fec
        DC16 0xa678,0x2620, 0xfb8f,0x2f6c, 0xba09,0x3fb1
        DC16 0xa7b1,0x223d, 0xf957,0x3076, 0xb74d,0x3f4f
        DC16 0xa963,0x1e2b, 0xf721,0x3179, 0xb4be,0x3ec5
        DC16 0xab8e,0x19ef, 0xf4ec,0x3274, 0xb25e,0x3e15
        DC16 0xae2e,0x1590, 0xf2b8,0x3368, 0xb02d,0x3d3f
        DC16 0xb140,0x1112, 0xf087,0x3453, 0xae2e,0x3c42
        DC16 0xb4be,0x0c7c, 0xee58,0x3537, 0xac61,0x3b21
        DC16 0xb8a6,0x07d6, 0xec2b,0x3612, 0xaac8,0x39db
        DC16 0xbcf0,0x0324, 0xea02,0x36e5, 0xa963,0x3871
        DC16 0xc197,0xfe6e, 0xe7dc,0x37b0, 0xa834,0x36e5
        DC16 0xc695,0xf9ba, 0xe5ba,0x3871, 0xa73b,0x3537
        DC16 0xcbe2,0xf50f, 0xe39c,0x392b, 0xa678,0x3368
        DC16 0xd178,0xf073, 0xe182,0x39db, 0xa5ed,0x3179
        DC16 0xd74e,0xebed, 0xdf6d,0x3a82, 0xa599,0x2f6c
        DC16 0xdd5d,0xe782, 0xdd5d,0x3b21, 0xa57e,0x2d41
        DC16 0xe39c,0xe33a, 0xdb52,0x3bb6, 0xa599,0x2afb
        DC16 0xea02,0xdf19, 0xd94d,0x3c42, 0xa5ed,0x289a
        DC16 0xf087,0xdb26, 0xd74e,0x3cc5, 0xa678,0x2620
        DC16 0xf721,0xd766, 0xd556,0x3d3f, 0xa73b,0x238e
        DC16 0xfdc7,0xd3df, 0xd363,0x3daf, 0xa834,0x20e7
        DC16 0x0471,0xd094, 0xd178,0x3e15, 0xa963,0x1e2b
        DC16 0x0b14,0xcd8c, 0xcf94,0x3e72, 0xaac8,0x1b5d
        DC16 0x11a8,0xcac9, 0xcdb7,0x3ec5, 0xac61,0x187e
        DC16 0x1824,0xc850, 0xcbe2,0x3f0f, 0xae2e,0x1590
        DC16 0x1e7e,0xc625, 0xca15,0x3f4f, 0xb02d,0x1294
        DC16 0x24ae,0xc44a, 0xc851,0x3f85, 0xb25e,0x0f8d
        DC16 0x2aaa,0xc2c1, 0xc695,0x3fb1, 0xb4be,0x0c7c
        DC16 0x306c,0xc18e, 0xc4e2,0x3fd4, 0xb74d,0x0964
        DC16 0x35eb,0xc0b1, 0xc338,0x3fec, 0xba09,0x0646
        DC16 0x3b1e,0xc02c, 0xc197,0x3ffb, 0xbcf0,0x0324
        // N=1024
        DC16 0x4000,0x0000, 0x4000,0x0000, 0x4000,0x0000
        DC16 0x3ed0,0x012e, 0x3f9b,0x0065, 0x3f36,0x00c9
        DC16 0x3d9a,0x025b, 0x3f36,0x00c9, 0x3e69,0x0192
        DC16 0x3c5f,0x0388, 0x3ed0,0x012e, 0x3d9a,0x025b
        DC16 0x3b1e,0x04b5, 0x3e69,0x0192, 0x3cc8,0x0324
        DC16 0x39d9,0x05e2, 0x3e02,0x01f7, 0x3bf4,0x03ed
        DC16 0x388e,0x070e, 0x3d9a,0x025b, 0x3b1e,0x04b5
        DC16 0x373f,0x0839, 0x3d31,0x02c0, 0x3a46,0x057e
        DC16 0x35eb,0x0964, 0x3cc8,0x0324, 0x396b,0x0646
        DC16 0x3492,0x0a8e, 0x3c5f,0x0388, 0x388e,0x070e
        DC16 0x3334,0x0bb7, 0x3bf4,0x03ed, 0x37af,0x07d6
        DC16 0x31d2,0x0cdf, 0x3b8a,0x0451, 0x36ce,0x089d
        DC16 0x306c,0x0e06, 0x3b1e,0x04b5, 0x35eb,0x0964
        DC16 0x2f02,0x0f2b, 0x3ab2,0x051a, 0x3505,0x0a2b
        DC16 0x2d93,0x1050, 0x3a46,0x057e, 0x341e,0x0af1
        DC16 0x2c21,0x1173, 0x39d9,0x05e2, 0x3334,0x0bb7
        DC16 0x2aaa,0x1294, 0x396b,0x0646, 0x3249,0x0c7c
        DC16 0x2931,0x13b4, 0x38fd,0x06aa, 0x315b,0x0d41
        DC16 0x27b3,0x14d2, 0x388e,0x070e, 0x306c,0x0e06
        DC16 0x2632,0x15ee, 0x381f,0x0772, 0x2f7b,0x0eca
        DC16 0x24ae,0x1709, 0x37af,0x07d6, 0x2e88,0x0f8d
        DC16 0x2326,0x1821, 0x373f,0x0839, 0x2d93,0x1050
        DC16 0x219c,0x1937, 0x36ce,0x089d, 0x2c9d,0x1112
        DC16 0x200e,0x1a4b, 0x365d,0x0901, 0x2ba4,0x11d3
        DC16 0x1e7e,0x1b5d, 0x35eb,0x0964, 0x2aaa,0x1294
        DC16 0x1ceb,0x1c6c, 0x3578,0x09c7, 0x29af,0x1354
        DC16 0x1b56,0x1d79, 0x3505,0x0a2b, 0x28b2,0x1413
        DC16 0x19be,0x1e84, 0x3492,0x0a8e, 0x27b3,0x14d2
        DC16 0x1824,0x1f8c, 0x341e,0x0af1, 0x26b3,0x1590
        DC16 0x1688,0x2091, 0x33a9,0x0b54, 0x25b1,0x164c
        DC16 0x14ea,0x2193, 0x3334,0x0bb7, 0x24ae,0x1709
        DC16 0x134a,0x2292, 0x32bf,0x0c1a, 0x23a9,0x17c4
        DC16 0x11a8,0x238e, 0x3249,0x0c7c, 0x22a3,0x187e
        DC16 0x1005,0x2488, 0x31d2,0x0cdf, 0x219c,0x1937
        DC16 0x0e61,0x257e, 0x315b,0x0d41, 0x2093,0x19ef
        DC16 0x0cbb,0x2671, 0x30e4,0x0da4, 0x1f89,0x1aa7
        DC16 0x0b14,0x2760, 0x306c,0x0e06, 0x1e7e,0x1b5d
        DC16 0x096d,0x284c, 0x2ff4,0x0e68, 0x1d72,0x1c12
        DC16 0x07c4,0x2935, 0x2f7b,0x0eca, 0x1c64,0x1cc6
        DC16 0x061b,0x2a1a, 0x2f02,0x0f2b, 0x1b56,0x1d79
        DC16 0x0471,0x2afb, 0x2e88,0x0f8d, 0x1a46,0x1e2b
        DC16 0x02c7,0x2bd8, 0x2e0e,0x0fee, 0x1935,0x1edc
        DC16 0x011c,0x2cb2, 0x2d93,0x1050, 0x1824,0x1f8c
        DC16 0xff72,0x2d88, 0x2d18,0x10b1, 0x1711,0x203a
        DC16 0xfdc7,0x2e5a, 0x2c9d,0x1112, 0x15fe,0x20e7
        DC16 0xfc1d,0x2f28, 0x2c21,0x1173, 0x14ea,0x2193
        DC16 0xfa73,0x2ff2, 0x2ba4,0x11d3, 0x13d5,0x223d
        DC16 0xf8ca,0x30b8, 0x2b28,0x1234, 0x12bf,0x22e7
        DC16 0xf721,0x3179, 0x2aaa,0x1294, 0x11a8,0x238e
        DC16 0xf579,0x3236, 0x2a2d,0x12f4, 0x1091,0x2435
        DC16 0xf3d2,0x32ef, 0x29af,0x1354, 0x0f79,0x24da
        DC16 0xf22c,0x33a3, 0x2931,0x13b4, 0x0e61,0x257e
        DC16 0xf087,0x3453, 0x28b2,0x1413, 0x0d48,0x2620
        DC16 0xeee3,0x34ff, 0x2833,0x1473, 0x0c2e,0x26c1
        DC16 0xed41,0x35a5, 0x27b3,0x14d2, 0x0b14,0x2760
        DC16 0xeba1,0x3648, 0x2733,0x1531, 0x09fa,0x27fe
        DC16 0xea02,0x36e5, 0x26b3,0x1590, 0x08df,0x289a
        DC16 0xe865,0x377e, 0x2632,0x15ee, 0x07c4,0x2935
        DC16 0xe6cb,0x3812, 0x25b1,0x164c, 0x06a9,0x29ce
        DC16 0xe532,0x38a1, 0x252f,0x16ab, 0x058d,0x2a65
        DC16 0xe39c,0x392b, 0x24ae,0x1709, 0x0471,0x2afb
        DC16 0xe208,0x39b0, 0x242b,0x1766, 0x0355,0x2b8f
        DC16 0xe077,0x3a30, 0x23a9,0x17c4, 0x0239,0x2c21
        DC16 0xdee9,0x3aab, 0x2326,0x1821, 0x011c,0x2cb2
        DC16 0xdd5d,0x3b21, 0x22a3,0x187e, 0x0000,0x2d41
        DC16 0xdbd5,0x3b92, 0x221f,0x18db, 0xfee4,0x2dcf
        DC16 0xda4f,0x3bfd, 0x219c,0x1937, 0xfdc7,0x2e5a
        DC16 0xd8cd,0x3c64, 0x2117,0x1993, 0xfcab,0x2ee4
        DC16 0xd74e,0x3cc5, 0x2093,0x19ef, 0xfb8f,0x2f6c
        DC16 0xd5d3,0x3d21, 0x200e,0x1a4b, 0xfa73,0x2ff2
        DC16 0xd45c,0x3d78, 0x1f89,0x1aa7, 0xf957,0x3076
        DC16 0xd2e8,0x3dc9, 0x1f04,0x1b02, 0xf83c,0x30f9
        DC16 0xd178,0x3e15, 0x1e7e,0x1b5d, 0xf721,0x3179
        DC16 0xd00c,0x3e5c, 0x1df8,0x1bb8, 0xf606,0x31f8
        DC16 0xcea5,0x3e9d, 0x1d72,0x1c12, 0xf4ec,0x3274
        DC16 0xcd41,0x3ed8, 0x1ceb,0x1c6c, 0xf3d2,0x32ef
        DC16 0xcbe2,0x3f0f, 0x1c64,0x1cc6, 0xf2b8,0x3368
        DC16 0xca88,0x3f40, 0x1bdd,0x1d20, 0xf19f,0x33df
        DC16 0xc932,0x3f6b, 0x1b56,0x1d79, 0xf087,0x3453
        DC16 0xc7e1,0x3f91, 0x1ace,0x1dd3, 0xef6f,0x34c6
        DC16 0xc695,0x3fb1, 0x1a46,0x1e2b, 0xee58,0x3537
        DC16 0xc54e,0x3fcc, 0x19be,0x1e84, 0xed41,0x35a5
        DC16 0xc40c,0x3fe1, 0x1935,0x1edc, 0xec2b,0x3612
        DC16 0xc2cf,0x3ff1, 0x18ad,0x1f34, 0xeb16,0x367d
        DC16 0xc197,0x3ffb, 0x1824,0x1f8c, 0xea02,0x36e5
        DC16 0xc065,0x4000, 0x179b,0x1fe3, 0xe8ef,0x374b
        DC16 0xbf38,0x3fff, 0x1711,0x203a, 0xe7dc,0x37b0
        DC16 0xbe11,0x3ff8, 0x1688,0x2091, 0xe6cb,0x3812
        DC16 0xbcf0,0x3fec, 0x15fe,0x20e7, 0xe5ba,0x3871
        DC16 0xbbd4,0x3fdb, 0x1574,0x213d, 0xe4aa,0x38cf
        DC16 0xbabf,0x3fc4, 0x14ea,0x2193, 0xe39c,0x392b
        DC16 0xb9af,0x3fa7, 0x145f,0x21e8, 0xe28e,0x3984
        DC16 0xb8a6,0x3f85, 0x13d5,0x223d, 0xe182,0x39db
        DC16 0xb7a2,0x3f5d, 0x134a,0x2292, 0xe077,0x3a30
        DC16 0xb6a5,0x3f30, 0x12bf,0x22e7, 0xdf6d,0x3a82
        DC16 0xb5af,0x3efd, 0x1234,0x233b, 0xde64,0x3ad3
        DC16 0xb4be,0x3ec5, 0x11a8,0x238e, 0xdd5d,0x3b21
        DC16 0xb3d5,0x3e88, 0x111d,0x23e2, 0xdc57,0x3b6d
        DC16 0xb2f2,0x3e45, 0x1091,0x2435, 0xdb52,0x3bb6
        DC16 0xb215,0x3dfc, 0x1005,0x2488, 0xda4f,0x3bfd
        DC16 0xb140,0x3daf, 0x0f79,0x24da, 0xd94d,0x3c42
        DC16 0xb071,0x3d5b, 0x0eed,0x252c, 0xd84d,0x3c85
        DC16 0xafa9,0x3d03, 0x0e61,0x257e, 0xd74e,0x3cc5
        DC16 0xaee8,0x3ca5, 0x0dd4,0x25cf, 0xd651,0x3d03
        DC16 0xae2e,0x3c42, 0x0d48,0x2620, 0xd556,0x3d3f
        DC16 0xad7b,0x3bda, 0x0cbb,0x2671, 0xd45c,0x3d78
        DC16 0xacd0,0x3b6d, 0x0c2e,0x26c1, 0xd363,0x3daf
        DC16 0xac2b,0x3afa, 0x0ba1,0x2711, 0xd26d,0x3de3
        DC16 0xab8e,0x3a82, 0x0b14,0x2760, 0xd178,0x3e15
        DC16 0xaaf8,0x3a06, 0x0a87,0x27af, 0xd085,0x3e45
        DC16 0xaa6a,0x3984, 0x09fa,0x27fe, 0xcf94,0x3e72
        DC16 0xa9e3,0x38fd, 0x096d,0x284c, 0xcea5,0x3e9d
        DC16 0xa963,0x3871, 0x08df,0x289a, 0xcdb7,0x3ec5
        DC16 0xa8eb,0x37e1, 0x0852,0x28e7, 0xcccc,0x3eeb
        DC16 0xa87b,0x374b, 0x07c4,0x2935, 0xcbe2,0x3f0f
        DC16 0xa812,0x36b1, 0x0736,0x2981, 0xcafb,0x3f30
        DC16 0xa7b1,0x3612, 0x06a9,0x29ce, 0xca15,0x3f4f
        DC16 0xa757,0x356e, 0x061b,0x2a1a, 0xc932,0x3f6b
        DC16 0xa705,0x34c6, 0x058d,0x2a65, 0xc851,0x3f85
        DC16 0xa6bb,0x3419, 0x04ff,0x2ab0, 0xc772,0x3f9c
        DC16 0xa678,0x3368, 0x0471,0x2afb, 0xc695,0x3fb1
        DC16 0xa63e,0x32b2, 0x03e3,0x2b45, 0xc5ba,0x3fc4
        DC16 0xa60b,0x31f8, 0x0355,0x2b8f, 0xc4e2,0x3fd4
        DC16 0xa5e0,0x3139, 0x02c7,0x2bd8, 0xc40c,0x3fe1
        DC16 0xa5bc,0x3076, 0x0239,0x2c21, 0xc338,0x3fec
        DC16 0xa5a1,0x2faf, 0x01aa,0x2c6a, 0xc266,0x3ff5
        DC16 0xa58d,0x2ee4, 0x011c,0x2cb2, 0xc197,0x3ffb
        DC16 0xa581,0x2e15, 0x008e,0x2cfa, 0xc0ca,0x3fff
        DC16 0xa57e,0x2d41, 0x0000,0x2d41, 0xc000,0x4000
        DC16 0xa581,0x2c6a, 0xff72,0x2d88, 0xbf38,0x3fff
        DC16 0xa58d,0x2b8f, 0xfee4,0x2dcf, 0xbe73,0x3ffb
        DC16 0xa5a1,0x2ab0, 0xfe56,0x2e15, 0xbdb0,0x3ff5
        DC16 0xa5bc,0x29ce, 0xfdc7,0x2e5a, 0xbcf0,0x3fec
        DC16 0xa5e0,0x28e7, 0xfd39,0x2e9f, 0xbc32,0x3fe1
        DC16 0xa60b,0x27fe, 0xfcab,0x2ee4, 0xbb77,0x3fd4
        DC16 0xa63e,0x2711, 0xfc1d,0x2f28, 0xbabf,0x3fc4
        DC16 0xa678,0x2620, 0xfb8f,0x2f6c, 0xba09,0x3fb1
        DC16 0xa6bb,0x252c, 0xfb01,0x2faf, 0xb956,0x3f9c
        DC16 0xa705,0x2435, 0xfa73,0x2ff2, 0xb8a6,0x3f85
        DC16 0xa757,0x233b, 0xf9e5,0x3034, 0xb7f8,0x3f6b
        DC16 0xa7b1,0x223d, 0xf957,0x3076, 0xb74d,0x3f4f
        DC16 0xa812,0x213d, 0xf8ca,0x30b8, 0xb6a5,0x3f30
        DC16 0xa87b,0x203a, 0xf83c,0x30f9, 0xb600,0x3f0f
        DC16 0xa8eb,0x1f34, 0xf7ae,0x3139, 0xb55e,0x3eeb
        DC16 0xa963,0x1e2b, 0xf721,0x3179, 0xb4be,0x3ec5
        DC16 0xa9e3,0x1d20, 0xf693,0x31b9, 0xb422,0x3e9d
        DC16 0xaa6a,0x1c12, 0xf606,0x31f8, 0xb388,0x3e72
        DC16 0xaaf8,0x1b02, 0xf579,0x3236, 0xb2f2,0x3e45
        DC16 0xab8e,0x19ef, 0xf4ec,0x3274, 0xb25e,0x3e15
        DC16 0xac2b,0x18db, 0xf45f,0x32b2, 0xb1cd,0x3de3
        DC16 0xacd0,0x17c4, 0xf3d2,0x32ef, 0xb140,0x3daf
        DC16 0xad7b,0x16ab, 0xf345,0x332c, 0xb0b5,0x3d78
        DC16 0xae2e,0x1590, 0xf2b8,0x3368, 0xb02d,0x3d3f
        DC16 0xaee8,0x1473, 0xf22c,0x33a3, 0xafa9,0x3d03
        DC16 0xafa9,0x1354, 0xf19f,0x33df, 0xaf28,0x3cc5
        DC16 0xb071,0x1234, 0xf113,0x3419, 0xaea9,0x3c85
        DC16 0xb140,0x1112, 0xf087,0x3453, 0xae2e,0x3c42
        DC16 0xb215,0x0fee, 0xeffb,0x348d, 0xadb6,0x3bfd
        DC16 0xb2f2,0x0eca, 0xef6f,0x34c6, 0xad41,0x3bb6
        DC16 0xb3d5,0x0da4, 0xeee3,0x34ff, 0xacd0,0x3b6d
        DC16 0xb4be,0x0c7c, 0xee58,0x3537, 0xac61,0x3b21
        DC16 0xb5af,0x0b54, 0xedcc,0x356e, 0xabf6,0x3ad3
        DC16 0xb6a5,0x0a2b, 0xed41,0x35a5, 0xab8e,0x3a82
        DC16 0xb7a2,0x0901, 0xecb6,0x35dc, 0xab29,0x3a30
        DC16 0xb8a6,0x07d6, 0xec2b,0x3612, 0xaac8,0x39db
        DC16 0xb9af,0x06aa, 0xeba1,0x3648, 0xaa6a,0x3984
        DC16 0xbabf,0x057e, 0xeb16,0x367d, 0xaa0f,0x392b
        DC16 0xbbd4,0x0451, 0xea8c,0x36b1, 0xa9b7,0x38cf
        DC16 0xbcf0,0x0324, 0xea02,0x36e5, 0xa963,0x3871
        DC16 0xbe11,0x01f7, 0xe978,0x3718, 0xa912,0x3812
        DC16 0xbf38,0x00c9, 0xe8ef,0x374b, 0xa8c5,0x37b0
        DC16 0xc065,0xff9b, 0xe865,0x377e, 0xa87b,0x374b
        DC16 0xc197,0xfe6e, 0xe7dc,0x37b0, 0xa834,0x36e5
        DC16 0xc2cf,0xfd40, 0xe753,0x37e1, 0xa7f1,0x367d
        DC16 0xc40c,0xfc13, 0xe6cb,0x3812, 0xa7b1,0x3612
        DC16 0xc54e,0xfae6, 0xe642,0x3842, 0xa774,0x35a5
        DC16 0xc695,0xf9ba, 0xe5ba,0x3871, 0xa73b,0x3537
        DC16 0xc7e1,0xf88e, 0xe532,0x38a1, 0xa705,0x34c6
        DC16 0xc932,0xf763, 0xe4aa,0x38cf, 0xa6d3,0x3453
        DC16 0xca88,0xf639, 0xe423,0x38fd, 0xa6a4,0x33df
        DC16 0xcbe2,0xf50f, 0xe39c,0x392b, 0xa678,0x3368
        DC16 0xcd41,0xf3e6, 0xe315,0x3958, 0xa650,0x32ef
        DC16 0xcea5,0xf2bf, 0xe28e,0x3984, 0xa62c,0x3274
        DC16 0xd00c,0xf198, 0xe208,0x39b0, 0xa60b,0x31f8
        DC16 0xd178,0xf073, 0xe182,0x39db, 0xa5ed,0x3179
        DC16 0xd2e8,0xef4f, 0xe0fc,0x3a06, 0xa5d3,0x30f9
        DC16 0xd45c,0xee2d, 0xe077,0x3a30, 0xa5bc,0x3076
        DC16 0xd5d3,0xed0c, 0xdff2,0x3a59, 0xa5a9,0x2ff2
        DC16 0xd74e,0xebed, 0xdf6d,0x3a82, 0xa599,0x2f6c
        DC16 0xd8cd,0xeacf, 0xdee9,0x3aab, 0xa58d,0x2ee4
        DC16 0xda4f,0xe9b4, 0xde64,0x3ad3, 0xa585,0x2e5a
        DC16 0xdbd5,0xe89a, 0xdde1,0x3afa, 0xa57f,0x2dcf
        DC16 0xdd5d,0xe782, 0xdd5d,0x3b21, 0xa57e,0x2d41
        DC16 0xdee9,0xe66d, 0xdcda,0x3b47, 0xa57f,0x2cb2
        DC16 0xe077,0xe559, 0xdc57,0x3b6d, 0xa585,0x2c21
        DC16 0xe208,0xe448, 0xdbd5,0x3b92, 0xa58d,0x2b8f
        DC16 0xe39c,0xe33a, 0xdb52,0x3bb6, 0xa599,0x2afb
        DC16 0xe532,0xe22d, 0xdad1,0x3bda, 0xa5a9,0x2a65
        DC16 0xe6cb,0xe124, 0xda4f,0x3bfd, 0xa5bc,0x29ce
        DC16 0xe865,0xe01d, 0xd9ce,0x3c20, 0xa5d3,0x2935
        DC16 0xea02,0xdf19, 0xd94d,0x3c42, 0xa5ed,0x289a
        DC16 0xeba1,0xde18, 0xd8cd,0x3c64, 0xa60b,0x27fe
        DC16 0xed41,0xdd19, 0xd84d,0x3c85, 0xa62c,0x2760
        DC16 0xeee3,0xdc1e, 0xd7cd,0x3ca5, 0xa650,0x26c1
        DC16 0xf087,0xdb26, 0xd74e,0x3cc5, 0xa678,0x2620
        DC16 0xf22c,0xda31, 0xd6cf,0x3ce4, 0xa6a4,0x257e
        DC16 0xf3d2,0xd93f, 0xd651,0x3d03, 0xa6d3,0x24da
        DC16 0xf579,0xd851, 0xd5d3,0x3d21, 0xa705,0x2435
        DC16 0xf721,0xd766, 0xd556,0x3d3f, 0xa73b,0x238e
        DC16 0xf8ca,0xd67f, 0xd4d8,0x3d5b, 0xa774,0x22e7
        DC16 0xfa73,0xd59b, 0xd45c,0x3d78, 0xa7b1,0x223d
        DC16 0xfc1d,0xd4bb, 0xd3df,0x3d93, 0xa7f1,0x2193
        DC16 0xfdc7,0xd3df, 0xd363,0x3daf, 0xa834,0x20e7
        DC16 0xff72,0xd306, 0xd2e8,0x3dc9, 0xa87b,0x203a
        DC16 0x011c,0xd231, 0xd26d,0x3de3, 0xa8c5,0x1f8c
        DC16 0x02c7,0xd161, 0xd1f2,0x3dfc, 0xa912,0x1edc
        DC16 0x0471,0xd094, 0xd178,0x3e15, 0xa963,0x1e2b
        DC16 0x061b,0xcfcc, 0xd0fe,0x3e2d, 0xa9b7,0x1d79
        DC16 0x07c4,0xcf07, 0xd085,0x3e45, 0xaa0f,0x1cc6
        DC16 0x096d,0xce47, 0xd00c,0x3e5c, 0xaa6a,0x1c12
        DC16 0x0b14,0xcd8c, 0xcf94,0x3e72, 0xaac8,0x1b5d
        DC16 0x0cbb,0xccd4, 0xcf1c,0x3e88, 0xab29,0x1aa7
        DC16 0x0e61,0xcc21, 0xcea5,0x3e9d, 0xab8e,0x19ef
        DC16 0x1005,0xcb73, 0xce2e,0x3eb1, 0xabf6,0x1937
        DC16 0x11a8,0xcac9, 0xcdb7,0x3ec5, 0xac61,0x187e
        DC16 0x134a,0xca24, 0xcd41,0x3ed8, 0xacd0,0x17c4
        DC16 0x14ea,0xc983, 0xcccc,0x3eeb, 0xad41,0x1709
        DC16 0x1688,0xc8e8, 0xcc57,0x3efd, 0xadb6,0x164c
        DC16 0x1824,0xc850, 0xcbe2,0x3f0f, 0xae2e,0x1590
        DC16 0x19be,0xc7be, 0xcb6e,0x3f20, 0xaea9,0x14d2
        DC16 0x1b56,0xc731, 0xcafb,0x3f30, 0xaf28,0x1413
        DC16 0x1ceb,0xc6a8, 0xca88,0x3f40, 0xafa9,0x1354
        DC16 0x1e7e,0xc625, 0xca15,0x3f4f, 0xb02d,0x1294
        DC16 0x200e,0xc5a7, 0xc9a3,0x3f5d, 0xb0b5,0x11d3
        DC16 0x219c,0xc52d, 0xc932,0x3f6b, 0xb140,0x1112
        DC16 0x2326,0xc4b9, 0xc8c1,0x3f78, 0xb1cd,0x1050
        DC16 0x24ae,0xc44a, 0xc851,0x3f85, 0xb25e,0x0f8d
        DC16 0x2632,0xc3e0, 0xc7e1,0x3f91, 0xb2f2,0x0eca
        DC16 0x27b3,0xc37b, 0xc772,0x3f9c, 0xb388,0x0e06
        DC16 0x2931,0xc31c, 0xc703,0x3fa7, 0xb422,0x0d41
        DC16 0x2aaa,0xc2c1, 0xc695,0x3fb1, 0xb4be,0x0c7c
        DC16 0x2c21,0xc26d, 0xc627,0x3fbb, 0xb55e,0x0bb7
        DC16 0x2d93,0xc21d, 0xc5ba,0x3fc4, 0xb600,0x0af1
        DC16 0x2f02,0xc1d3, 0xc54e,0x3fcc, 0xb6a5,0x0a2b
        DC16 0x306c,0xc18e, 0xc4e2,0x3fd4, 0xb74d,0x0964
        DC16 0x31d2,0xc14f, 0xc476,0x3fdb, 0xb7f8,0x089d
        DC16 0x3334,0xc115, 0xc40c,0x3fe1, 0xb8a6,0x07d6
        DC16 0x3492,0xc0e0, 0xc3a1,0x3fe7, 0xb956,0x070e
        DC16 0x35eb,0xc0b1, 0xc338,0x3fec, 0xba09,0x0646
        DC16 0x373f,0xc088, 0xc2cf,0x3ff1, 0xbabf,0x057e
        DC16 0x388e,0xc064, 0xc266,0x3ff5, 0xbb77,0x04b5
        DC16 0x39d9,0xc045, 0xc1fe,0x3ff8, 0xbc32,0x03ed
        DC16 0x3b1e,0xc02c, 0xc197,0x3ffb, 0xbcf0,0x0324
        DC16 0x3c5f,0xc019, 0xc130,0x3ffd, 0xbdb0,0x025b
        DC16 0x3d9a,0xc00b, 0xc0ca,0x3fff, 0xbe73,0x0192
        DC16 0x3ed0,0xc003, 0xc065,0x4000, 0xbf38,0x00c9
        
                
       END
/******************* (C) COPYRIGHT 2009  STMicroelectronics *****END OF FILE****/
