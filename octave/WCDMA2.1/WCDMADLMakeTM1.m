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
% working in Octave
% TS 25.141 6.11.0 Rel 6 p. 33 table 6.2
% PCCPCH needs correct definition
% SCCPCH needs correct definition
% PICH needs correct definition
% PSCH code sequence verified
% SSCH code sequence verified
% CPICH is safest way to synchronise if you know PSC, note not all test signals have PSCH!
% text data messages are not random enough! Use only one channel with text.
% DPDCH needs FEC/Interleaving, use simplified single frame interleaved BCH code for now.

% issue with scaling as TM is put to gether
% rms sum of all the amplitudes for 16ch -> 1
% however, the scaling does not work with hadamard matrices and fixed amplitude prs
% pk->1 std->0, mean->0
% a true random signal has pk->1, std->0.3 and mean->0
% so the sum of all the channels is +10dB, not 0dB
% does this change when rc filtered?
% also 3dB of gain due to complex data
% also note scrambling adds 3dB gain

function [y,due,deue]=WCDMADLMakeTM1(nch,osr,feclevel)
	printf( 'WCDMAMakeTM1:\n');
	a=-1; % +1 if transmit diversity is on, -1 if off in PCCPCH
	sc=0;
	sfdpdch=128;
	txt=strcat( 'WCDMA DL demonstration Channel Number ',num2str(2),' generated from Octave for your info!');
	[data,due,deue]=WCDMADLtxtMsgWrite2(txt,2*2560*15/sfdpdch);
	pccpch=WCDMADLpccpch(1);
	sccpch=WCDMADLsccpch(0);
	pich=WCDMADLpich(0,0); % pich dly is 30 earlier than sccpch
	y=WCDMADLmake(sc,osr,data,pich,pccpch,sccpch);
	WCDMApar( y );
	WFMwrite( 'WCDMADL_TM1oct.wfm', y );
end

