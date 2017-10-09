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
#define PTS 38400 // chip rate 3.84Ms/s.  Up sample by 8 for 30.72Ms/s baseband

void SRXLongDL( unsigned char *state );
void SRYLongDL( unsigned char *state );
void SRXLongUL( unsigned char *state );
void SRYLongUL( unsigned char *state );
void PSCLongDL( float _Complex *psc, short n );
void PSCLongUL( float _Complex *psc, short n );

void spread( float _Complex *signal, float _Complex *data, signed char *code, short sprdFac, float gain );
void despread( float _Complex *data, float _Complex *signal, signed char *code, short sprdFac );

//float _Complex sum( float _Complex *data, short dataLen );
//float _Complex sumabs( float _Complex *data, short dataLen );
float rms( float _Complex *data, short dataLen );
float gaindb( float leveldB );
float dB( float _Complex level );

void hadamard( signed char **hadamardMat, unsigned char k );
unsigned short ovsfCode( unsigned short code, unsigned char bits );
void ovsfScan( float *res, float _Complex *data, signed char ** hadamardMat, short sprdFac, unsigned char bits );

void psch0( signed char psch[] );
void psch( float _Complex *signal, float lvl );
void pschRemove( float _Complex *signal );
void ssch0( signed char **ssch, signed char **hadamardMat, short sc );
void ssch( float _Complex *signal, float lvl,signed char **hadamardMat, short sc );
void ssc( unsigned char **ssclu );
void sschRemove( float _Complex *signal, signed char **hadamardMat, short sc );

unsigned char rrc( float *hrrc, float beta, unsigned char symb, unsigned char osr );
void UpSampFIRScale(float _Complex *sigu,float _Complex *sig, unsigned char osr, unsigned char firosr, long ptsi);

void printCVec( float _Complex *sig, long start, long stop );

void makeRandIQ( float _Complex *vec, short len, short len2, short seed );
