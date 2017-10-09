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
// mkoctfile WCDMAULdemod.cpp WCDMAlib.cpp FFTlib.cpp -O3
// to test...
// octave WCDMAUL.m >> log.txt
#include <octave/oct.h>
#include <oct-cmplx.h>
#include <iostream>
#include <complex.h> // float _Complex
#include <math.h> // floor, pow
#include <time.h> // clock
#include "WCDMAlib.hpp"
#include "FFTlib.hpp"

// ACF scale factor - need to fix, but demo is ok
// ACF sign i*i=-1 need to invert outputs - need to fix, but demo is ok -dpdch

// Carries out low level physical channel demodulation of 3G UL signals
// includes RRC based decimation, pilot based sync, descramble and despread, ovsf scaning
// basic AGC of pilot, other channels will need scaling by external code
// no echo or doppler shift cancellation or scramble code search included

DEFUN_DLD (WCDMAULdemod, args, , "WCDMAULdemod( iqDataRx,sc,slotFormat,osr,pilots )")
{
clock_t mytref = clock();
	short nargin = args.length();
	if (nargin != 5)
		print_usage ();
	else
	{
		ComplexRowVector	iqDataRx=args(0).complex_row_vector_value();
		short 			sc=(int)args(1).int_value();
		unsigned char 		slotFormat=(int)args(2).int_value();
		unsigned char 		osr=(int)args(3).int_value();
		ComplexRowVector	pilots=args(4).complex_row_vector_value();
   		dim_vector		iqDataSize=iqDataRx.dims();
   		dim_vector		pilotSize=pilots.dims();
 		long 			iqDataSizeL=iqDataSize(1);
 		long 			pilotSizeL=pilotSize(1);
		float _Complex *sigraw=(float _Complex *)malloc(sizeof(float _Complex)*iqDataSizeL);
		float _Complex *sig=(float _Complex *)malloc(sizeof(float _Complex)*iqDataSizeL);
		float _Complex *sigds=(float _Complex *)malloc(sizeof(float _Complex)*65536); // was PTS
		float _Complex *pilotsc=(float _Complex *)malloc(sizeof(float _Complex)*pilotSizeL);
		for(long ci=0; ci<iqDataSizeL; ci++ )
			sigraw[ci]=real(iqDataRx(ci))+I*imag(iqDataRx(ci));
		for(long ci=0; ci<pilotSizeL; ci++ )
			pilotsc[ci]=real(pilots(ci))+I*imag(pilots(ci));
//		printf("RRC\n"); // RRC/autoscale suppress out of band noise before decimation
		UpSampFIRScale(sig,sigraw,1,osr,iqDataSizeL); 
		ComplexRowVector	iqDataRRC(iqDataSizeL,0);  // RRC filtered data for pretty graph
		for(long ci=0;ci<iqDataSizeL;ci++)
			iqDataRRC(ci)=sig[ci];		
//		printf("Hadamard\n");
		unsigned char hsize=8;
		signed char **hadamardMat=(signed char **)malloc(sizeof(signed char*)*(1<<hsize));
		for(short ci=0; ci<(1<<hsize); ci++ )
			hadamardMat[ci]=(signed char *)malloc(sizeof(signed char)*(1<<hsize));
		hadamard(hadamardMat,hsize);
//		printf("PSC\n");
		short sfdpdch=1<<(8-slotFormat); //2^(8-slotFormat) incorrect, xor not power
		short sfdpcch=256; // sf=256 always for control channel
		short dpdchno=sfdpdch/4; // single dpdch
		short dpcchno=0; // always 0, use like CPICH
		short sizeDPDCH=150*256/sfdpdch;
		short sizeDPCCH=150;
		short nPilots=0;
		for( short ci=0; ci<sizeDPCCH; ci++ ) // count active pilots
			if( cabsf(pilotsc[ci])>0 )
				nPilots++;
		float scaleF=nPilots/150.0;
		printf("pilots=%i scaleF=%f\n",nPilots,scaleF);
		float _Complex psc[PTS];
		float _Complex psc2[65536];
		float _Complex psc2fft[65536];
		for(long ci=0;ci<65536;ci++)
			psc2[ci]=0.0;
		spread( psc2, pilotsc, hadamardMat[ovsfCode(dpcchno,8)], sfdpcch, 1 );
		PSCLongUL(psc,sc);
		for(long ci=0;ci<65536;ci++)
			if(ci<PTS)
				psc2[ci]*=psc[ci];
//			else
//				psc2[ci]=0.0;
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
				bestAGC=scaleF*scaleF/mg; // sqrt(sqrt(2)) crept in somewhere
			}
		}
		for(long ci=0;ci<65536;ci++) // shift and rotate // was PTS but need longer for double check ACF
		{
			cj=(osr*(ci+bestPos)+bestOff)%(osr*PTS);
			sigds[ci]=sig[cj]*cexpf(-I*bestPh)*bestAGC; // decimation with variable offset
		}
//		acf2( sigds, psc2fft, 65536, &pos, &mg, &ph ); // debug only
//		printf( "pos=%li mag=%f arg=%f bestAGS=%f\n",pos,mg,ph,bestAGC);
		
//		printf("Descramble\n");
		for( long ci=0; ci<PTS; ci++ )
			sigds[ci]*=conjf(psc[ci]); // remove scamble code
//		printf("OVSF Scan\n");
		float *ovsfdB=(float *)malloc(sizeof(float)*sfdpdch);
		float ovsf256dB[256];
		ovsfScan( ovsfdB, sigds, hadamardMat, sfdpdch, (8-slotFormat) );
		ovsfScan( ovsf256dB, sigds, hadamardMat, 256, 8 );
		RowVector	OVSF( sfdpdch, 0 ); // variable length depends on SlotFormat
		RowVector	OVSF256( 256, 0 );
		for( long ci=0; ci<sfdpdch; ci++)
			OVSF(ci)=ovsfdB[ci];
		for( long ci=0; ci<256; ci++)
			OVSF256(ci)=ovsf256dB[ci];
		
//		printf("Despread\n");
		float _Complex *dpdch=(float _Complex *)malloc(sizeof(float _Complex)*sizeDPDCH);
		float _Complex *dpcch=(float _Complex *)malloc(sizeof(float _Complex)*sizeDPCCH);	
		despread( dpdch, sigds, hadamardMat[ovsfCode(dpdchno,(8-slotFormat))], sfdpdch );
		despread( dpcch, sigds, hadamardMat[ovsfCode(dpcchno,8)], sfdpcch );
		ComplexRowVector	DPDCH( sizeDPDCH, 0 );
		ComplexRowVector	DPCCH( sizeDPCCH, 0 );
		for( long ci=0; ci<sizeDPDCH; ci++)
			DPDCH(ci)=dpdch[ci];
		for( long ci=0; ci<sizeDPCCH; ci++)
			DPCCH(ci)=dpcch[ci];

//		printf("Free\n");
		for(short ci=0; ci<(1<<hsize); ci++ )
			free(hadamardMat[ci]);
		free(hadamardMat);
		free(dpdch);
		free(dpcch);
		free(pilotsc);
		free(sigraw);
		free(sig);
		free(sigds);
		free(ovsfdB);
printf ("WCDMADLdemod: %f seconds\n",((float)(clock()-mytref))/CLOCKS_PER_SEC);
		return ovl( iqDataRRC,DPDCH,DPCCH,OVSF,OVSF256 ); // return multiple objects
	}
	return octave_value_list ();
}

