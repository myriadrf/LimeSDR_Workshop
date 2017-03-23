/*
 Copyright 2016 Lime Microsystems Ltd.

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
// requires liboctave-dev
// to compile...
// mkoctfile FIRTimeCP.cpp
// to test...
// octave
// x=[ones(1,4),zeros(1,4),i*ones(1,4),zeros(1,4)];
// h=[-0.2,0,0.5,1,0.5,0,-0.2];
// y=FIRTimeCP(x,h);
// plot(x,"b-",y,"r-");
// note impulse function h() must be wholly real to preserve orthogonality of I and Q channels (x(t)=i(t)+j*q(t))
// this is circular version of impulse function response, so last point connects seemlessly with first point.
// this is useful if we have a single frame signal 
// and we can use the end of the frame as part of the FIR history for the first part of the signal
#include <octave/oct.h>
#include <oct-cmplx.h>

DEFUN_DLD (FIRTimeCP, args, , "FIRTimeCP( iqData, impulseResponse )")
{
	int nargin = args.length ();
	if (nargin != 2)
		print_usage ();
	else
	{
		// inputs
		// https://www.gnu.org/software/octave/doc/v4.0.1/Matrices-and-Arrays-in-Oct_002dFiles.html
		ComplexRowVector	iqdatax=args(0).complex_row_vector_value();
		RowVector			h=args(1).row_vector_value();	
		dim_vector			iqdataSize=iqdatax.dims();
		dim_vector			hSize=h.dims();
		// outputs
		ComplexRowVector			iqdatay( iqdataSize(1), 0 );	// assuming we are getting row vector input! Should really check!!!	
		long int pts=iqdataSize(1);
		int		hpts=hSize(1);
		double	arg=0;
		for( int j=0; j<hpts; j++ )
		{
			octave_value htemp=h(j);
			double	hvalue=htemp.double_value();
			for(long int i=0; i<pts; i++ )
			{
				// note typedef Complex is defined as std::complex<double> defined in /usr/include/octave-3.6.2/oct-cmplx.h
				arg=i-j;
				if( arg<0 )
					arg=arg+pts;
				octave_value xtemp=iqdatax(arg);
				Complex xvalue=xtemp.complex_value();				
				iqdatay(i) += xvalue*hvalue;
			}
		}
		return octave_value ( iqdatay );
	}
	return octave_value_list ();
}

