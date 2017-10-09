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
% Primary Common Control Physical Channel
% spread with C(256,1) 256, 30kHz 18bits long
% 2304 chips long (switched off for the first 256 chips)
% Radio framewidth SFN modulo 2 = 0
% 25211.920 5.3.1.1.1 (STTD coding) and 5.3.3.3.1
% Just use random bits for now ;)
function y=WCDMADLpccpch(ant)
	y=((1-2*randint( 1,150 ))+i*(1-2*randint( 1,150 )))/sqrt(2);
end
