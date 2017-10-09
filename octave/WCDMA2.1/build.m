% Copyright 2017 Lime Microsystems Ltd.
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%    http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% Compile Oct functions to speed up Octave
%
% run build.m
%
printf "(c) 2017 Lime Microsystems Ltd.\n"
printf "Compiling Oct functions...\n"
if version >= "4.0.0"
	mkoctfile WCDMADLmake.cpp WCDMAlib.cpp FFTlib.cpp -O3
	mkoctfile WCDMADLdemod.cpp WCDMAlib.cpp FFTlib.cpp -O3
	mkoctfile WCDMAULmake.cpp WCDMAlib.cpp FFTlib.cpp -O3
	mkoctfile WCDMAULdemod.cpp WCDMAlib.cpp FFTlib.cpp -O3
else % 3.8.2 or earlier, no -O3 flag support
	mkoctfile WCDMADLmake.cpp WCDMAlib.cpp FFTlib.cpp
	mkoctfile WCDMADLdemod.cpp WCDMAlib.cpp FFTlib.cpp
	mkoctfile WCDMAULmake.cpp WCDMAlib.cpp FFTlib.cpp
	mkoctfile WCDMAULdemod.cpp WCDMAlib.cpp FFTlib.cpp
end
printf "cleaning up...\n"
delete *.o
delete *~
printf "Done.\n"

