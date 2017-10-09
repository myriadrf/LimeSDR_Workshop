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
// Carries out low level physical channel modulation of 3G UL signals
// requires liboctave-dev to compile...
// mkoctfile WCDMAULmake.cpp WCDMAlib.cpp FFTlib.cpp -O3
// to test...
// octave WCDMAUL.m >> log.txt
#include <octave/oct.h>
#include <oct-cmplx.h>
#include <iostream>
#include <complex>
#include <complex.h> // float _Complex
#include <math.h> // floor, pow
#include <time.h> // clock
#include "WCDMAlib.hpp"
#include "FFTlib.hpp"

// Carries out low level physical channel modulation of 3G UL signals
// assuming user is providing one radio frame length of data
// real W-CDMA spreads data over 4 radio frames.

DEFUN_DLD (WCDMAULmake, args, , "WCDMAULmake( sc,osr,slotFormat,DPCCH,DPDCH )")
{
clock_t mytref = clock();
	short nargin = args.length();
	if (nargin != 5)
		print_usage ();
	else
	{
		short sc=-1;
		unsigned char osr=-1;
		unsigned char slotFormat=-1;
					sc=(int)args(0).int_value();
					osr=(int)args(1).int_value();
					slotFormat=(int)args(2).int_value();
		ComplexRowVector	DPCCH=args(3).complex_row_vector_value();
		ComplexRowVector	DPDCH=args(4).complex_row_vector_value();
    		dim_vector		dpcchSize=DPCCH.dims();
    		dim_vector		dpdchSize=DPDCH.dims();
// 		printf("DPCCH\n");
		short sizeDPCCH=dpcchSize(1);
		float _Complex *dpcch=(float _Complex *)malloc(sizeof(float _Complex)*sizeDPCCH);	
		for(long ci=0; ci<sizeDPCCH; ci++ )
			dpcch[ci]=real(DPCCH(ci))+I*imag(DPCCH(ci));
//		printf("DPDCH\n");
		short sizeDPDCH=dpdchSize(1);
		float _Complex *dpdch=(float _Complex *)malloc(sizeof(float _Complex)*sizeDPDCH);
		for(long ci=0; ci<sizeDPDCH; ci++ )
			dpdch[ci]=real(DPDCH(ci))+I*imag(DPDCH(ci));
//		printf("sc=%i osr=%i slotFormat=%i sizeDPCCH=%i sizeDPDCH=%i\n", sc,osr,slotFormat,sizeDPCCH,sizeDPDCH);
		unsigned char hsize=8;
		signed char **hadamardMat=(signed char **)malloc(sizeof(signed char*)*(1<<hsize));
		for(short ci=0; ci<(1<<hsize); ci++ )
			hadamardMat[ci]=(signed char *)malloc(sizeof(signed char)*(1<<hsize));
		hadamard(hadamardMat,hsize);
		long ptsi=PTS; // could be more than one frame long - what to do.
		float _Complex psc[PTS];
		float _Complex sig[PTS];
		for(long ci=0; ci<PTS; ci++ )
			sig[ci]=0.0;
		float _Complex *sigu=(float _Complex *)malloc(sizeof(float _Complex)*PTS*osr);
		long dataLen=PTS*osr;
		ComplexRowVector	iqData( dataLen, 0 );

		short sfdpdch=1<<(8-slotFormat); //2^(8-slotFormat) incorrect, xor not power
		short sfdpcch=256; // sf=256 always for control channel
		short dpdchno=sfdpdch/4; // single dpdch
		short dpcchno=0; // always 0, use like C-PICH
		float dpdchlvl=-1.0872; // depends on slot format -see 25.214 Section 5.1.2.5
		float dpcchlvl=-4.56;
		if( slotFormat==4 )
			dpdchlvl=0.0;
//		printf("sfdpcch=%i sfdpdch=%i ovsf=%i ovsf=%i\n",sfdpcch,sfdpdch,ovsfCode(dpdchno,(8-slotFormat)),ovsfCode(dpcchno,8));
		spread( sig, dpdch, hadamardMat[ovsfCode(dpdchno,(8-slotFormat))], sfdpdch, gaindb(dpdchlvl) );
		spread( sig, dpcch, hadamardMat[ovsfCode(dpcchno,8)], sfdpcch, gaindb(dpcchlvl) );
		PSCLongUL(psc,sc);
		for( long ci=0; ci<PTS; ci++ )
			sig[ci]*=psc[ci]; // apply scamble code
		// upsample FIR autoscale signal
		UpSampFIRScale(sigu,sig,osr,osr,ptsi);
		for( long ci=0; ci<(ptsi*osr); ci++ )
			iqData(ci)=sigu[ci]; // convert back to octave object
		for(short ci=0; ci<(1<<hsize); ci++ )
			free(hadamardMat[ci]);
		free(hadamardMat);
		free(dpdch);
		free(dpcch);
		free(sigu);
printf ("WCDMAULmake: %f seconds\n",((float)(clock()-mytref))/CLOCKS_PER_SEC);
		return octave_value ( iqData );
	}
	return octave_value_list ();
}


