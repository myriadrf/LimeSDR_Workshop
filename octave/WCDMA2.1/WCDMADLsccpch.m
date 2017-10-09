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
% Secondary Common Control Physical Channel
% Each slot TFCI data Pilots
% use random bits for now ;)
function y=WCDMADLsccpch(dly)
	TFCI=[];
	Data=[];
	Pilots=[];
	y=[TFCI,Data,Pilots]; 
%	y=WCDMAqpskMod( y );
	y=((1-2*randint(1,150))+i*(1-2*randint(1,150)))/sqrt(2);
	y=shift( y, dly );
end
