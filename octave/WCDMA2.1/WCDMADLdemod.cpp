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
// requires liboctave-dev to compile...
// mkoctfile WCDMADLdemod.cpp WCDMAlib.cpp FFTlib.cpp -O3
// to test...
// octave WCDMADL.m >> log.txt
#include <octave/oct.h>
#include <oct-cmplx.h>
#include <iostream>
#include <complex.h> // float _Complex
#include <math.h> // floor, pow
#include <time.h> // clock
#include "WCDMAlib.hpp"
#include "FFTlib.hpp"

// Carries out low level physical channel demodulation of 3G DL signals
// includes RRC based decimation, CPICH based sync, PSCH and SSCH removal, descramble and despread, ovsf scaning
// basic AGC of CPICH, other channels will need scaling by external code
// no echo or doppler shift cancellation or scramble code search included

DEFUN_DLD (WCDMADLdemod, args, , "WCDMADLdemod( iqDataRx,sc,sf,dch,osr )")
{
clock_t mytref = clock();
	short nargin = args.length();
	if (nargin != 5)
		print_usage ();
	else
	{
		ComplexRowVector	iqDataRx=args(0).complex_row_vector_value();
		short 			sc=(int)args(1).int_value();
		short	 		sf=(int)args(2).int_value();
		short	 		dchno=(int)args(3).int_value();
		unsigned char 		osr=(int)args(4).int_value();
   		dim_vector		iqDataSize=iqDataRx.dims();
 		long 			iqDataSizeL=iqDataSize(1);
//		printf("sc=%i sf=%i dch=%i osr=%i iqDataSizeL=%li\n",sc,sf,dchno,osr,iqDataSizeL);
		float _Complex *sigraw=(float _Complex *)malloc(sizeof(float _Complex)*iqDataSizeL);
		float _Complex *sig=(float _Complex *)malloc(sizeof(float _Complex)*iqDataSizeL);
		float _Complex *sigds=(float _Complex *)malloc(sizeof(float _Complex)*65536); // was PTS
		for(long ci=0; ci<iqDataSizeL; ci++ )
			sigraw[ci]=real(iqDataRx(ci))+I*imag(iqDataRx(ci));
//		printf("RRC\n"); // RRC/autoscale suppress out of band noise before decimation
		UpSampFIRScale(sig,sigraw,1,osr,iqDataSizeL); 
		ComplexRowVector	iqDataRRC(iqDataSizeL,0);
		for(long ci=0;ci<iqDataSizeL;ci++)
			iqDataRRC(ci)=sig[ci]; // RRC filtered data for pretty graph	
//		printf("Hadamard\n");
		unsigned char hsize=8;
		signed char **hadamardMat=(signed char **)malloc(sizeof(signed char*)*(1<<hsize));
		for(short ci=0; ci<(1<<hsize); ci++ )
			hadamardMat[ci]=(signed char *)malloc(sizeof(signed char)*(1<<hsize));
		hadamard(hadamardMat,hsize);
//		printf("PSC\n");
		float _Complex psc[PTS];
		float _Complex psc2[65536];
		float _Complex psc2fft[65536];
		PSCLongDL(psc,sc);
		for(long ci=0;ci<65536;ci++)
			if(ci<PTS)
				psc2[ci]=psc[ci]*(1+I)/sqrt(2);
			else
				psc2[ci]=0.0;
		FFT(psc2,psc2fft,65536); // only need to compute this once
		conj(psc2fft,65536);

//		printf("ACF\n"); // 32768 (2^15) < 38400 (WCDMA Frame) < 65536 (2^16) < 307200 (WCDMA Frame*osr)
		float _Complex	sigfft1[65536]; 
		unsigned char	doff=0;
		long		cj=0;
		long		ck=0;
		float		bestMg=0.0;
		float		bestPh=0.0;
		long		bestPos=0;
		unsigned char	bestOff=0;
		float		bestAGC=1.0;
		float	mg,ph;
		long	pos;
//		printf("Subsampling...\n");
		for(unsigned char doff=0;doff<osr;doff++)
		{
			for(long ci=0;ci<65536;ci++)
			{
				cj=(osr*ci+doff)%(osr*PTS);
				sigfft1[ci]=sig[cj]; // decimation with variable offset for best symbol 'eye'
			}
			acf2( sigfft1, psc2fft, 65536, &pos, &mg, &ph );
//			printf( "doff=%i pos=%li mag=%f arg=%f\n",doff,pos,mg,ph); // debug only
			if(mg>bestMg)
			{
				bestMg=mg;
				bestPh=ph;
				bestPos=pos;
				bestOff=doff;
				bestAGC=1/mg/sqrt(sqrt(2)); // sqrt(sqrt(2)) crept in somewhere
			}
		}
		for(long ci=0;ci<65536;ci++) // shift and rotate // was PTS but need longer for double check ACF
		{
			cj=(osr*(ci+bestPos)+bestOff)%(osr*PTS);
			sigds[ci]=sig[cj]*cexpf(-I*bestPh)*bestAGC; // decimation with variable offset
		}
//		acf2( sigds, psc2fft, 65536, &pos, &mg, &ph ); // debug only
//		printf( "pos=%li mag=%f arg=%f bestAGS=%f\n",pos,mg,ph,bestAGC);
		
		pschRemove( sigds );
		sschRemove( sigds,hadamardMat,sc);

//		printf("Descramble\n");
		for( long ci=0; ci<PTS; ci++ )
			sigds[ci]*=conjf(psc[ci]); // remove scamble code
//		printf("OVSF Scan\n");
		float ovsf64dB[64];
		float ovsf128dB[128];
		float ovsf256dB[256];
		ovsfScan( ovsf64dB, sigds, hadamardMat, 64, 6 );
		ovsfScan( ovsf128dB, sigds, hadamardMat, 128, 7 );
		ovsfScan( ovsf256dB, sigds, hadamardMat, 256, 8 );
		RowVector	OVSF64( 64, 0 );
		RowVector	OVSF128( 128, 0 );
		RowVector	OVSF256( 256, 0 );
		for( long ci=0; ci<64; ci++)
			OVSF64(ci)=ovsf64dB[ci];
		for( long ci=0; ci<128; ci++)
			OVSF128(ci)=ovsf128dB[ci];
		for( long ci=0; ci<256; ci++)
			OVSF256(ci)=ovsf256dB[ci];
		
//		printf("Despread\n");
		short sfcch=256; // sf=256 always for control channel
		short log2sf=(short)floor(log10(sf+0.001)/log10(2));
		short sizeDCH=150*256/sf; 
		short sizeCCH=150;
		float _Complex *cpich=(float _Complex *)malloc(sizeof(float _Complex)*sizeCCH);
		float _Complex *pich=(float _Complex *)malloc(sizeof(float _Complex)*sizeCCH);
		float _Complex *pccpch=(float _Complex *)malloc(sizeof(float _Complex)*sizeCCH);
		float _Complex *sccpch=(float _Complex *)malloc(sizeof(float _Complex)*sizeCCH);
		float _Complex *dch=(float _Complex *)malloc(sizeof(float _Complex)*sizeDCH);
		despread( cpich, sigds, hadamardMat[ovsfCode(0,8)], sfcch );
		despread( pccpch, sigds, hadamardMat[ovsfCode(1,8)], sfcch );
		despread( sccpch, sigds, hadamardMat[ovsfCode(3,8)], sfcch );
		despread( pich, sigds, hadamardMat[ovsfCode(16,8)], sfcch );
		despread( dch, sigds, hadamardMat[ovsfCode(dchno,log2sf)], sf ); // should be programmable
		ComplexRowVector	CPICH( sizeCCH, 0 );
		ComplexRowVector	PICH( sizeCCH, 0 );
		ComplexRowVector	PCCPCH( sizeCCH, 0 );
		ComplexRowVector	SCCPCH( sizeCCH, 0 );
		ComplexRowVector	DCH( sizeDCH, 0 );
		for( long ci=0; ci<sizeDCH; ci++)
			DCH(ci)=dch[ci];
		for( long ci=0; ci<sizeCCH; ci++)
		{
			CPICH(ci)=cpich[ci];
			PICH(ci)=pich[ci];
			PCCPCH(ci)=pccpch[ci];
			SCCPCH(ci)=sccpch[ci];
		}

//		printf("Free\n");
		for(short ci=0; ci<(1<<hsize); ci++ )
			free(hadamardMat[ci]);
		free(hadamardMat);
		free(cpich);
		free(pich);
		free(pccpch);
		free(sccpch);
		free(dch);
		free(sigraw);
		free(sig);
		free(sigds);

printf ("WCDMADLdemod: %f seconds\n",((float)(clock()-mytref))/CLOCKS_PER_SEC);
		return ovl( iqDataRRC,DCH,CPICH,PICH,PCCPCH,SCCPCH,OVSF64,OVSF128,OVSF256 ); // return multiple data
	}
	return octave_value_list ();
}

