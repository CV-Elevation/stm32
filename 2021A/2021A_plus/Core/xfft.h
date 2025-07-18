#ifndef	_xFFT_H
#define _xFFT_H

#include "main.h"
#include "math.h"

typedef struct
{
	float real;
	float imag;
} Complex;

void FFT_Init(void);

unsigned char FFT(Complex *x,int m);

extern	float Fs;
extern 	float f[5];
extern	float temp;
extern	float U[5];
extern	float	THD;

void FFT_DIS(void);

#endif
