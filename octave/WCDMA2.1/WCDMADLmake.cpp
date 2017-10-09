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
// mkoctfile WCDMADLmake.cpp WCDMAlib.cpp FFTlib.cpp -O3
// to test...
// octave WCDMADL.m >> log.txt
#include <octave/oct.h>
#include <oct-cmplx.h>
#include <iostream>
#include <complex>
#include <complex.h> // float _Complex
#include <math.h> // floor, pow
#include <time.h> // clock
#include "WCDMAlib.hpp"
#include "FFTlib.hpp"

// need variable spreading for data channel

// Carries out low level physical channel modulation of 3G DL signals
// 16,32 or 64 ch operation - hard wired to 64 channels for now
// assuming user is providing one radio frame length of data
// real W-CDMA spreads data over 4 radio frames.
// only channel 2 and control signals provided externally
// all other TM data channels are random
DEFUN_DLD (WCDMADLmake, args, , "WCDMADLmake( sc,osr,Data,PICH,PCCPCH,SCCPCH )")
{
clock_t mytref = clock();
	short nargin = args.length();
	if (nargin != 6)
		print_usage ();
	else
	{
		short sc=-1;
		unsigned char osr=-1;
					sc=(int)args(0).int_value();
					osr=(int)args(1).int_value();
		ComplexRowVector	DATA=args(2).complex_row_vector_value();  // hard wired to ch 2
		ComplexRowVector	PICH=args(3).complex_row_vector_value();
		ComplexRowVector	PCCPCH=args(4).complex_row_vector_value();
		ComplexRowVector	SCCPCH=args(5).complex_row_vector_value();
    		dim_vector		dataSize=DATA.dims(); 
    		dim_vector		pichSize=PICH.dims();
    		dim_vector		pccpchSize=PCCPCH.dims();
    		dim_vector		sccpchSize=SCCPCH.dims();
		short sizeDATA=dataSize(1);
//		printf("CPICH\n");
		float _Complex cpich[150];
		for( short ci=0; ci<150; ci++ )
			cpich[ci]=1+I; // common pilot channel
//		printf("PICH\n");
		short sizePICH=pichSize(1);
		float _Complex *pich=(float _Complex *)malloc(sizeof(float _Complex)*sizePICH);
		for(long ci=0; ci<sizePICH; ci++ )
			pich[ci]=real(PICH(ci))+I*imag(PICH(ci));
//		printf("PCCPCH\n");
		short sizePCCPCH=pccpchSize(1);
		float _Complex *pccpch=(float _Complex *)malloc(sizeof(float _Complex)*sizePCCPCH);
		for(long ci=0; ci<sizePCCPCH; ci++ )
			pccpch[ci]=real(PCCPCH(ci))+I*imag(PCCPCH(ci));
//		printf("SCCPCH\n");
		short sizeSCCPCH=sccpchSize(1);
		float _Complex *sccpch=(float _Complex *)malloc(sizeof(float _Complex)*sizeSCCPCH);
		for(long ci=0; ci<sizeSCCPCH; ci++ )
			sccpch[ci]=real(SCCPCH(ci))+I*imag(SCCPCH(ci));
//		printf("Hadamard\n");
		unsigned char hsize=8;
		signed char **hadamardMat=(signed char **)malloc(sizeof(signed char*)*(1<<hsize));
		for(short ci=0; ci<(1<<hsize); ci++ )
			hadamardMat[ci]=(signed char *)malloc(sizeof(signed char)*(1<<hsize));
		hadamard(hadamardMat,hsize);
		long ptsi=PTS; // could be more than one frame long - what to do.

/*		short ndch=16; % see fig 4.18 book. Disagree with 25.141
		unsigned char dch[16]={2,11,17,23,31,38,47,55,62,69,78,85,94,102,113,119};
		float dlvl[16]={-10.4,-11.1,-12.0,-14.2,-11.4,-13.0,-16.5,-15.6,-12.5,
				-15.3,-13.7,-17.6,-18.8,-16.9,-15.0,-9.4};
		unsigned char doff[16]={2,0,2,1,6,1,7,6,1,9,1,0,0,0,5,2};*/

/*		short ndch=32;
		unsigned char dch[32]={2,11,17,23,31,38,47,55,62,69, 78, 85, 94,102,113,119,
			7,13,20,27,35,41,51,58,64,74, 82, 88, 97,108,117,125};
		float dlvl[32]=-13.0,-13.0,-14.0,-15.0,-17.0,-14,0,-16.0,-18.0,-16.0,-19.0,-17.0,-15.0,
				-17.0,-22.0,-20.0,-24.0,-20.0,-18.0,-14.0,-14.0,-16.0,-19.0,-18.0,
				-17.0,-22.0,-19.0,-19.0,-16.0,-18.0,-15.0,-17.0,-12.0};
		unsigned char doff[32]={86,134, 52, 45,143,112, 59, 23,  1, 88, 30, 18, 30, 61,128,143,
					83, 25,103, 97, 56,104, 51, 26,137, 65, 37,125,149,123, 83,  5};*/

		short ndch=64;
		unsigned char dch[64]={2,11,17,23,31,38,47,55,62,69, 78, 85, 94,102,113,119,
				7,13,20,27,35,41,51,58,64,74, 82, 88, 97,108,117,125,4, 				9,12,14,19,22,26,28,34,36, 40, 44, 49, 53,56,61,
				63,66,71,76,80,84,87,91,95,99,105,110,116,118,122,126};
		float dlvl[64]={-16.0,-16.0,-16.0,-17.0,-18.0,-20.0,-16.0,-17.0,-16.0,-19.0,-22.0,
			-20.0,-16.0,-17.0,-19.0,-21.0,-19.0,-21.0,-18.0,-20.0,-24.0,-24.0,
			-22.0,-21.0,-18.0,-20.0,-17.0,-18.0,-19.0,-23.0,-22.0,-21.0, 				-17.0,-18.0,-20.0,-17.0,-19.0,-21.0,-19.0,-23.0,-22.0,-19.0,
			-24.0,-23.0,-22.0,-19.0,-22.0,-21.0,-18.0,-19.0,-22.0,-21.0,
			-19.0,-21.0,-19.0,-21.0,-20.0,-25.5,-25.5,-25.5,-24.0,-22.0,-20.0,-15.0};
		unsigned char doff[64]={86,134, 52, 45,143,112, 59, 23,  1, 88, 30, 18, 30, 61,128,143,
				83, 25,103, 97, 56,104, 51, 26,137, 65, 37,125,149,123, 83,  5,
				91,  7, 32, 21, 29, 59, 22,138, 31, 17,  9, 69, 49, 20, 57,121,
				127,114,100, 76,141, 82, 64,149, 87, 98, 46, 37, 87,149, 85, 69};
		float _Complex *datach[64];
		for(unsigned char ci=0;ci<ndch;ci++)
		{
			datach[ci]=(float _Complex*)malloc(sizeof(float _Complex)*sizeDATA);
			if( dch[ci]!=2 )
				makeRandIQ( datach[ci],sizeDATA,sizeDATA,dch[ci] );
			else
				for( long cj=0;cj<sizeDATA;cj++ )
					datach[ci][cj]=real(DATA(cj))+I*imag(DATA(cj)); // ch2 copy user data
		}

		float _Complex sig[PTS];
		for(long ci=0; ci<PTS; ci++ )
			sig[ci]=0.0;
		float _Complex *sigu=(float _Complex *)malloc(sizeof(float _Complex)*PTS*osr);
		long dataLen=PTS*osr;
		ComplexRowVector	iqData( dataLen, 0 );

//		printf("Spread\n");
		short sfdatalg=7;
		short sfdata=128;
		short sfconlg=8;
		short sfcon=256; // sf=256 always for control channels
		spread( sig, cpich, hadamardMat[ovsfCode(0,sfconlg)], sfcon, gaindb(-15) ); // x4 0.8ms
		spread( sig, pccpch, hadamardMat[ovsfCode(1,sfconlg)], sfcon, gaindb(-10) );
		spread( sig, sccpch, hadamardMat[ovsfCode(3,sfconlg)], sfcon, gaindb(-15) );
		spread( sig, pich, hadamardMat[ovsfCode(16,sfconlg)], sfcon, gaindb(-15) );
		for( unsigned char ci=0; ci<ndch; ci++ )
			spread( sig,datach[ci],hadamardMat[ovsfCode(dch[ci],sfdatalg)],sfdata,gaindb(dlvl[ci]));
	
//		printf("PSC\n");
		float _Complex psc[PTS];
		PSCLongDL(psc,sc); // 3-9ms
		for( long ci=0; ci<PTS; ci++ )
			sig[ci]*=psc[ci]; // apply scamble code

		psch( sig, gaindb(-16) );	
		ssch( sig, gaindb(-16), hadamardMat,sc );
//		printf("UpsampleRRC\n");
		UpSampFIRScale(sigu,sig,osr,osr,ptsi); // upsample FIR autoscale signal
//		printf("Copy output\n");
		for( long ci=0; ci<(ptsi*osr); ci++ )
			iqData(ci)=sigu[ci]; // convert back to octave object
//		printf("Free Memory\n");
		for(short ci=0; ci<(1<<hsize); ci++ )
			free(hadamardMat[ci]);
		free(hadamardMat);
		for(unsigned char ci=0; ci<64; ci++)
			free(datach[ci]);
//		free(data);
		free(pich);
		free(pccpch);
		free(sccpch);
		free(sigu);
printf ("WCDMADLmake: %f seconds\n",((float)(clock()-mytref))/CLOCKS_PER_SEC);
		return octave_value ( iqData );
	}
	return octave_value_list ();
}

