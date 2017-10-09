/*
 Copyright 2017 Lime Microsystems Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
#include <stdio.h>
#include <stdlib.h>
#include <complex>
#include <complex.h> // float _Complex
#include <math.h> // floor, pow

#include "WCDMAlib.hpp"
#include "FFTlib.hpp"

// essentially Walsh function generator to ensure orthogonality of code domain signals
void hadamard( signed char ** hadamardMat, unsigned char k )
{
	hadamardMat[0][0]=1; // seed
	for( unsigned char ck=0; ck<k; ck++ )
	{
		for( unsigned char cj=0; cj<(1<<ck); cj++ )
			for( unsigned char ci=0; ci<(1<<ck); ci++ )
			{
				hadamardMat[cj+(1<<ck)][ci]=hadamardMat[cj][ci];
				hadamardMat[cj][ci+(1<<ck)]=hadamardMat[cj][ci];
				hadamardMat[cj+(1<<ck)][ci+(1<<ck)]=-hadamardMat[cj][ci];
			}
	}
}

void spread( float _Complex *signal, float _Complex *data, signed char *code, short sprdFac, float gain )
{ // add spread signal to the cumulative signal to minimise storage
//	printf("spread gain=%f sprdFac=%i\n",gain,sprdFac);
	short dataLen=PTS/sprdFac;
	for( short cj=0; cj<dataLen; cj++ )
		for( short ci=0; ci<sprdFac; ci++ )
			signal[cj*sprdFac+ci]+=gain*data[cj]*code[ci];
}

void despread( float _Complex *data, float _Complex *signal, signed char *code, short sprdFac )
{
	short dataLen=PTS/sprdFac;
	for( short cj=0; cj<dataLen; cj++ )
	{
		data[cj]=0.0;
		for( short ci=0; ci<sprdFac; ci++ )
		{
			data[cj]+=signal[cj*sprdFac+ci]*code[ci];
		}
		data[cj]/=sprdFac;
	}
}

unsigned short ovsfCode( unsigned short code, unsigned char bits )
{ // reverse bits of code for ovsf index
	unsigned short index=0;
	for( unsigned char ci=0; ci<bits; ci++ )
		if( (code&(1<<ci))>0 )
			index+=(1<<((bits-1)-ci));
	return(index);
}

void ovsfScan( float *res, float _Complex *signal, signed char ** hadamardMat, short sprdFac, unsigned char bits )
{
	short dataLen=PTS/sprdFac;
	float _Complex *data=(float _Complex*)malloc(sizeof(float _Complex)*dataLen);
	for( unsigned short ci=0; ci<sprdFac; ci++ )
	{
		despread(data,signal,hadamardMat[ovsfCode(ci,bits)],sprdFac);
		res[ci]=20.0*log10(rms(data,dataLen)+1e-4);
	}
	free(data);
}

float gaindb( float leveldB )
{
	return(pow(10.0,leveldB/20));
}

float dB( float _Complex level )
{
	return( 20.0*log10(cabsf(level)) );
}

float rms( float _Complex *data, short dataLen )
{
	float res=0;
	for( short ci=0; ci<dataLen; ci++ )
		res+=crealf(data[ci]*conjf(data[ci]));
	res=sqrt(res/dataLen);
	return(res);
}

// create a unique random sequence for each channel
// assume memory already allocated
void makeRandIQ( float _Complex *vec, short len, short len2, short seed )
{
	unsigned char	statex[25];
	unsigned int	acc=1;
	unsigned int	seed2=9677210+seed; // seed based on randomised number
	for( short i=0; i<25; i++ )
	{
		statex[i]=(seed2&acc)/acc;
		acc*=2;  // 2^i  pow( double, double ), and unsigned int << unsigned int
	}
	for(long int i=0; i<(3+5*seed); i++ ) // fast forward sequence to reduce correlation with start point
		SRXLongUL( statex );
	for(long int i=0; i<len; i++ )
	{
		SRXLongUL( statex ); // use different tap patterns to randomise I and Q relative to one another
		vec[i]=1-2*(statex[0]^statex[3]^statex[7])+I*(1-2*(statex[1]^statex[5]^statex[6]));
	}
	for(long int i=len; i<len2; i++ ) // PICH needs an empty chunk at end
		vec[i]=0.0;
}

// 125.213 v7.2.0 Section 4.3.2.2 Fig 5.
// Richardson, W-CDMA Book (ISBN 978-0-521-18782-4) Section 3.7.2 Fig 3.39
void SRXLongUL( unsigned char *state )
{
	unsigned char fb=state[0]^state[3];
	for( unsigned char i=0; i<25; i++ )
		state[i]=state[i+1];
	state[24]=fb;
}

void SRYLongUL( unsigned char *state )
{
	unsigned char fb=state[0]^state[1]^state[2]^state[3];
	for( unsigned char i=0; i<25; i++ )
		state[i]=state[i+1];
	state[24]=fb;
}

// 125.213 v7.2.0 Section 5.2.2 Fig 10.
// Richardson, W-CDMA Book (ISBN 978-0-521-18782-4) Section 3.6.3 Fig 3.35
void SRXLongDL( unsigned char *state )
{
	unsigned char fb=state[0]^state[7];
	for( unsigned char i=0; i<17; i++ )
		state[i]=state[i+1];
	state[17]=fb;
}

void SRYLongDL( unsigned char *state )
{
	unsigned char fb=state[0]^state[5]^state[7]^state[10];
	for( unsigned char i=0; i<17; i++ )
		state[i]=state[i+1];
	state[17]=fb;
}

void PSCLongDL( float _Complex *psc, short n )
{
	unsigned char	clong1[PTS];
	unsigned char	clong2[PTS];
	unsigned char	statex[18];
	unsigned char	statey[18];
	for( unsigned char i=0; i<18; i++ )
	{
		statex[i]=0;
		statey[i]=1;
	}
	statex[0]=1;
	
	if( n>0 ) // if n is nonzero, advance statex by n steps
		for( long i=0; i<n; i++ )
			SRXLongDL( statex );
				
	for(long i=0; i<PTS; i++ )
	{
		clong1[i]=statex[0]^statey[0];
		clong2[i]=statex[4]^statex[6]^statex[15]^statey[5]^statey[6]^statey[8];
		clong2[i]=clong2[i]^statey[9]^statey[10]^statey[11]^statey[12]^statey[13]^statey[14]^statey[15];
		psc[i]=(1-2*clong1[i])+I*(1-2*clong2[i]); // WCDMA BPSK +1/-1 outputs
		SRXLongDL( statex );
		SRYLongDL( statey );
	}
}

void PSCLongUL( float _Complex *psc, short n )
{
	signed char	clong1[PTS];
	signed char	clong2[PTS];
	unsigned char	statex[25];
	unsigned char	statey[25];
	int		acc=1;
	for( short i=0; i<25; i++ )
	{
		statex[i]=(n&acc)/acc;
		statey[i]=1;
		acc*=2;  // 2^i  pow( double, double ), and unsigned int << unsigned int
	}
	statex[24]=1;
	for(long int i=0; i<PTS; i++ )
	{
		clong1[i]=statex[0]^statey[0];
		clong2[i]=statex[4]^statex[7]^statex[18]^statey[4]^statey[6]^statey[17];
		SRXLongUL( statex );
		SRYLongUL( statey );
	}
	for(long int i=0; i<PTS; i++ )
	{
		long int ci=2*floor(i/2);
		psc[i]=(1.0+I*(1-2*clong2[ci])*(1-2*(i%2)))*(1-2*clong1[i]);
	}
}

// 25213-920.pdf 3GPP TS 25.213 V9.2.0 (2010-09) p32 5.2.3.1
// transmitted for the first 256 chips of each slot
void psch0( signed char psch[] )
{
	signed char a[16]={1, 1, 1, 1, 1, 1, -1, -1, 1, -1, 1, -1, 1, -1, -1, 1};
	signed char b[16]={1,1,1,-1,-1,1,-1,-1,1,1,1,-1,1,-1,1,1};
	for( unsigned char cj=0; cj<16; cj++ )
		for( unsigned char ci=0; ci<16; ci++ )
			psch[cj*16+ci]=a[ci]*b[cj];	
}

void psch( float _Complex *signal, float lvl ) // multiply by 1+j
{
	signed char psch[256];
	psch0(psch);
	for( unsigned char ck=0; ck<15; ck++ )
		for( short cj=0; cj<256; cj++ )
			signal[ck*2560+cj]+=lvl*(1+I)*psch[cj];
/*	printf("psch1=[");
	for( short cj=0; cj<256; cj++ )
		printf("%i,", psch[cj]);
	printf("]\n");*/
}

// assume we have frame sync from CPICH
// leaving ssch in degrades ovsf scans
void pschRemove( float _Complex *signal )
{
	signed char psch[256];
	float _Complex pschlvl=0;;
	float _Complex pschlvl2=0;;
	psch0(psch);
	for( unsigned char ck=0; ck<15; ck++ )
		for( short cj=0; cj<256; cj++ )
			pschlvl+=signal[ck*2560+cj]*psch[cj]*(1-I); // (1-I)=conj(1+I)
	pschlvl/=256*15*2;
	for( unsigned char ck=0; ck<15; ck++ )
		for( short cj=0; cj<256; cj++ )
			signal[ck*2560+cj]-=pschlvl*(1+I)*psch[cj];
	for( unsigned char ck=0; ck<15; ck++ )
		for( short cj=0; cj<256; cj++ )
			pschlvl2+=signal[ck*2560+cj]*psch[cj]*(1-I); // (1-I)=conj(1+I)
	pschlvl2/=256*15*2;
	printf( "remove psch, level = |%g|dB <%go -> |%g|dB <%go \n", 20*log10(cabsf(pschlvl)), cargf(pschlvl)*180/_PI,
		20*log10(cabsf(pschlvl2)), cargf(pschlvl2)*180/_PI );
}

void ssch0( signed char **ssch, signed char **hadamardMat, short sc )
{
//	printf("ssch0\n");
	signed char a[16]={1, 1, 1, 1, 1, 1, -1, -1, 1, -1, 1, -1, 1, -1, -1, 1};
	signed char b[16];
	for( unsigned char cj=0; cj<16; cj++)
		if(cj<8)
			b[cj]=a[cj];
		else
			b[cj]=-a[cj];
	signed char c[16]={1,1,1,-1,1,1,-1,-1,1,-1,1,-1,-1,-1,-1,-1};
	for( unsigned char ck=0; ck<16; ck++ )
		for( unsigned char cj=0; cj<16; cj++ )
			for( unsigned char ci=0; ci<16; ci++ )
				ssch[ck][cj*16+ci]=b[ci]*c[cj]*hadamardMat[16*ck][cj*16+ci];
}

// 25213-920.pdf 3GPP TS 25.213 V9.2.0 (2010-09) p32 5.2.3.1
// transmitted for the first 256 chips of each slot
// k can be 1-16
// return a matrix with all 16 codes
void ssch( float _Complex *signal, float lvl,signed char **hadamardMat, short sc )
{
//	printf("ssch\n");
	unsigned char grp=(sc/8);
	unsigned char **ssu=(unsigned char **)malloc(sizeof(unsigned char*)*64);
	for(unsigned char ci=0; ci<64; ci++)
		ssu[ci]=(unsigned char *)malloc(sizeof(unsigned char)*15);
	ssc( ssu );
	signed char *ssch[16];
	for(unsigned char ci=0; ci<16; ci++)
		ssch[ci]=(signed char *)malloc(sizeof(signed char)*256);
	ssch0(ssch,hadamardMat,sc);
	for( unsigned char ck=0; ck<15; ck++ ) 
		for( short cj=0; cj<256; cj++ )
			signal[ck*2560+cj]+=lvl*(1+I)*ssch[ssu[grp][ck]-1][cj];
/*	printf("ssch1=[");
	for( short cj=0; cj<256; cj++ )
		printf("%i,", ssch[0][cj]);
	printf("]\n");*/
	for(unsigned char ci=0; ci<64; ci++)
		free(ssu[ci]);
	free(ssu);
	for(unsigned char ci=0; ci<16; ci++)
		free(ssch[ci]);
}

// assume we have frame sync from CPICH
// leaving ssch in degrades ovsf scans
void sschRemove( float _Complex *signal, signed char **hadamardMat, short sc )
{
//	printf("sschRemove\n");
	unsigned char grp=(sc/8);
	unsigned char **ssu=(unsigned char **)malloc(sizeof(unsigned char*)*64);
	for(unsigned char ci=0; ci<64; ci++)
		ssu[ci]=(unsigned char *)malloc(sizeof(unsigned char)*15);
	ssc( ssu );
	float _Complex sschlvl=0;;
	float _Complex sschlvl2=0;;
	signed char *ssch[16];
	for(unsigned char ci=0; ci<16; ci++)
		ssch[ci]=(signed char *)malloc(sizeof(signed char)*256);
	ssch0(ssch,hadamardMat,sc);
	for( unsigned char ck=0; ck<15; ck++ ) 
		for( short cj=0; cj<256; cj++ )
			sschlvl+=signal[ck*2560+cj]*(1-I)*ssch[ssu[grp][ck]-1][cj];
	sschlvl/=256*15*2;
	for( unsigned char ck=0; ck<15; ck++ )
		for( short cj=0; cj<256; cj++ )
			signal[ck*2560+cj]-=sschlvl*(1+I)*ssch[ssu[grp][ck]-1][cj];
	for( unsigned char ck=0; ck<15; ck++ ) 
		for( short cj=0; cj<256; cj++ )
			sschlvl2+=signal[ck*2560+cj]*(1-I)*ssch[ssu[grp][ck]-1][cj];
	sschlvl2/=256*15*2;
	printf( "remove ssch, level = |%g|dB <%go -> |%g|dB <%go \n", 20*log10(cabsf(sschlvl)), cargf(sschlvl)*180/_PI,
		20*log10(cabsf(sschlvl2)), cargf(sschlvl2)*180/_PI );
	for(unsigned char ci=0; ci<64; ci++)
		free(ssu[ci]);		
	free(ssu);
	for(unsigned char ci=0; ci<16; ci++)
		free(ssch[ci]);
}

// ssch sequence defined by sc, group number is a function of sc
// Table 4 of TS 25.213 9.2.0
// Fig 4.17 of Richardson W-CDMA book (ISBN 978-0-521-18782-4)
void ssc( unsigned char **ssclu ) // look up table of secondary sync codes 64x15
{
//	printf("ssc\n");
	unsigned char a[64][15]={{1,1,2,8,9,10,15,8,10,16,2,7,15,7,16},
	{1,1,5,16,7,3,14,16,3,10,5,12,14,12,10},
	{1,2,1,15,5,5,12,16,6,11,2,16,11,15,12},
	{1,2,3,1,8,6,5,2,5,8,4,4,6,3,7},
	{1,2,16,6,6,11,15,5,12,1,15,12,16,11,2},
	{1,3,4,7,4,1,5,5,3,6,2,8,7,6,8},
	{1,4,11,3,4,10,9,2,11,2,10,12,12,9,3},
	{1,5,6,6,14,9,10,2,13,9,2,5,14,1,13},
	{1,6,10,10,4,11,7,13,16,11,13,6,4,1,16},
	{1,6,13,2,14,2,6,5,5,13,10,9,1,14,10},
	{1,7,8,5,7,2,4,3,8,3,2,6,6,4,5},
	{1,7,10,9,16,7,9,15,1,8,16,8,15,2,2},
	{1,8,12,9,9,4,13,16,5,1,13,5,12,4,8},
	{1,8,14,10,14,1,15,15,8,5,11,4,10,5,4},
	{1,9,2,15,15,16,10,7,8,1,10,8,2,16,9},
	{1,9,15,6,16,2,13,14,10,11,7,4,5,12,3},
	{1,10,9,11,15,7,6,4,16,5,2,12,13,3,14},
	{1,11,14,4,13,2,9,10,12,16,8,5,3,15,6},
	{1,12,12,13,14,7,2,8,14,2,1,13,11,8,11},
	{1,12,15,5,4,14,3,16,7,8,6,2,10,11,13},
	{1,15,4,3,7,6,10,13,12,5,14,16,8,2,11},
	{1,16,3,12,11,9,13,5,8,2,14,7,4,10,15},
	{2,2,5,10,16,11,3,10,11,8,5,13,3,13,8},
	{2,2,12,3,15,5,8,3,5,14,12,9,8,9,14},
	{2,3,6,16,12,16,3,13,13,6,7,9,2,12,7},
	{2,3,8,2,9,15,14,3,14,9,5,5,15,8,12},
	{2,4,7,9,5,4,9,11,2,14,5,14,11,16,16},
	{2,4,13,12,12,7,15,10,5,2,15,5,13,7,4},
	{2,5,9,9,3,12,8,14,15,12,14,5,3,2,15},
	{2,5,11,7,2,11,9,4,16,7,16,9,14,14,4},
	{2,6,2,13,3,3,12,9,7,16,6,9,16,13,12},
	{2,6,9,7,7,16,13,3,12,2,13,12,9,16,6},
	{2,7,12,15,2,12,4,10,13,15,13,4,5,5,10},
	{2,7,14,16,5,9,2,9,16,11,11,5,7,4,14},
	{2,8,5,12,5,2,14,14,8,15,3,9,12,15,9},
	{2,9,13,4,2,13,8,11,6,4,6,8,15,15,11},
	{2,10,3,2,13,16,8,10,8,13,11,11,16,3,5},
	{2,11,15,3,11,6,14,10,15,10,6,7,7,14,3},
	{2,16,4,5,16,14,7,11,4,11,14,9,9,7,5},
	{3,3,4,6,11,12,13,6,12,14,4,5,13,5,14},
	{3,3,6,5,16,9,15,5,9,10,6,4,15,4,10},
	{3,4,5,14,4,6,12,13,5,13,6,11,11,12,14},
	{3,4,9,16,10,4,16,15,3,5,10,5,15,6,6},
	{3,4,16,10,5,10,4,9,9,16,15,6,3,5,15},
	{3,5,12,11,14,5,11,13,3,6,14,6,13,4,4},
	{3,6,4,10,6,5,9,15,4,15,5,16,16,9,10},
	{3,7,8,8,16,11,12,4,15,11,4,7,16,3,15},
	{3,7,16,11,4,15,3,15,11,12,12,4,7,8,16},
	{3,8,7,15,4,8,15,12,3,16,4,16,12,11,11},
	{3,8,15,4,16,4,8,7,7,15,12,11,3,16,12},
	{3,10,10,15,16,5,4,6,16,4,3,15,9,6,9},
	{3,13,11,5,4,12,4,11,6,6,5,3,14,13,12},
	{3,14,7,9,14,10,13,8,7,8,10,4,4,13,9},
	{5,5,8,14,16,13,6,14,13,7,8,15,6,15,7},
	{5,6,11,7,10,8,5,8,7,12,12,10,6,9,11},
	{5,6,13,8,13,5,7,7,6,16,14,15,8,16,15},
	{5,7,9,10,7,11,6,12,9,12,11,8,8,6,10},
	{5,9,6,8,10,9,8,12,5,11,10,11,12,7,7},
	{5,10,10,12,8,11,9,7,8,9,5,12,6,7,6},
	{5,10,12,6,5,12,8,9,7,6,7,8,11,11,9},
	{5,13,15,15,14,8,6,7,16,8,7,13,14,5,16},
	{9,10,13,10,11,15,15,9,16,12,14,13,16,14,11},
	{9,11,12,15,12,9,13,13,11,14,10,16,15,14,16},
	{9,12,10,15,13,14,9,14,15,11,11,13,12,16,10}};
	for( unsigned char ci=0;ci<64;ci++)
		for( unsigned char cj=0;cj<15;cj++)
			ssclu[ci][cj]=a[ci][cj];
}
// no restrictions on fir len. TS25101 (6.8.1),102 (6.8.1),104 (6.8.1),105 (6.8.1), Richardson W-CDMA Book 3.5.3
unsigned char  rrc( float *hrrc, float beta, unsigned char symb, unsigned char osr )
{
	float tothrrc=0.0;
	float ts=1.0;
	float t=0.0;
	float val=0.0;
	unsigned char len=2*osr*symb+1;
	for( unsigned char ci=0; ci<len; ci++ )
	{
		t=(-osr*symb+ci)*1.0/osr;
		if (t==0.0)
			val=(1-beta+4*beta/_PI)/sqrt(ts);
		else
			if (abs(t)==(ts/4/beta))
				val=beta*((1+2/_PI)*sin(_PI/4/beta)+(1-2/_PI)*cos(_PI/4/beta))/sqrt(2*ts);
			else
			{
				val=(sin(_PI*t/ts*(1-beta))+4*beta*t*cos(_PI*t/ts*(1+beta))/ts);
				val/=sqrt(ts)*(_PI*t*(1-(4*beta*t/ts)*(4*beta*t/ts))/ts);
			}
		hrrc[ci]=val;
		tothrrc+=hrrc[ci]*hrrc[ci];
	}
	tothrrc=sqrt(tothrrc); // use RMS as coefficients are signed numbers
	for( unsigned char ci=0; ci<len; ci++ )
		hrrc[ci]/=tothrrc; // normalise, so integral of impulse response is unity
	return(len);
}

// TX upsampling and interpolation filtering osr=N firosr=N
// RX predecimation filtering osr=1 firosr=N
void UpSampFIRScale(float _Complex *sigu,float _Complex *sig, unsigned char osr, unsigned char firosr, long ptsi)
{
	float _Complex *sigt;
	long ptso=ptsi*osr;
	float alpha=0.22;
	unsigned char symb=5;
	float *hrrc=(float*)malloc( sizeof(float)*(2*firosr*symb+1) );
	unsigned char hpts=rrc( hrrc, alpha, symb, firosr );
	sigt=(float _Complex*)malloc(sizeof(float _Complex)*ptso);
//	printf("RRC osr=%i ptsi=%li ptso=%li\n",osr,ptsi,ptso);
	for( long cj=0; cj<ptso; cj++ ) // zero vector
	{
		sigu[cj]=0.0;
		sigt[cj]=0.0;
	}
	if( osr!=1 )  // UpSample() function - insert points with zeros between
		for( long cj=0; cj<ptsi; cj++ )
			sigt[osr*cj]=sig[cj];
	else
		for( long cj=0; cj<ptsi; cj++ )
			sigt[cj]=sig[cj];
	long	tmpl=0;
	for(long ci=0; ci<ptso; ci++ )
		for( unsigned char cj=0; cj<hpts; cj++ )
		{
			tmpl=ci-cj;
			if( tmpl<0 )
				tmpl=(tmpl % ptso)+ptso; // tmpl=tmpl+pts fails if pts<hrrc
//printf("ci=%li cj=%i tmpl=%li hrrc=%f \n",ci,cj,tmpl,hrrc[cj]);
			sigu[ci] += (float _Complex)(sigt[tmpl]*hrrc[cj]);
		}
	free(hrrc);
	float maxval=0.0;
	float temp=0.0;
	for(long ci=0; ci<ptso; ci++ ) // AutoScale function
	{
		temp = cabsf(sigu[ci]);
		if( temp>maxval )
			maxval=temp;
	}
	maxval=1.0/maxval;
	for(long ci=0; ci<ptso; ci++ )
		sigu[ci]*=maxval;
}

void printCVec( float _Complex *sig, long start, long stop ) // for debug
{
	for( long ci=start; ci<stop; ci++ )
		printf("p%li{%f,%f},",ci,crealf(sig[ci]),cimagf(sig[ci]));
	printf("\n");
}
