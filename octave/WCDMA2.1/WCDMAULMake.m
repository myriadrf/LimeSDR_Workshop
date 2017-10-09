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
% slotFormat selects data rate,
% TS 25 211 Section 5.2.1.1 Table 1 and 2
% Slot Format 0 15kbps SF=256 10 bits/slot 150bits/frame
% Slot Format 1 30kbps SF=128 20 bits/slot 300bits/frame
% Slot Format 2 60kbps SF=64 40 bits/slot 600bits/frame
% Slot Format 3 120kbps SF=32 80 bits/slot 1200bits/frame
% Slot Format 4 240kbps SF=16 160 bits/slot 2400bits/frame
% Slot Format 5 480kbps SF=8 320 bits/slot 4800bits/frame
% Slot Format 6 960kbps SF=4 640 bits/slot 9600bits/frame
function [iqDataU,deue,due]=WCDMAULMake( sc,slotFormat, osr, symbols, feclevel )
	printf( 'WCDMAULMake:\n');
	sfdpdch=2^(8-slotFormat);
	dpdchlvl=10^(-1.0872/20); % depends on slot format -see 25.214 Section 5.1.2.5
	if slotFormat==4
		dpdchlvl=10^(0.0);
	end
	dpcchlvl=10^(-4.56/20);
	txt=strcat( 'WCDMA UL DPCH demonstration channel generated from Octave for your viewing info!');
	[PDDCH,due,deue]=WCDMAULtxtMsgWrite2(txt,2560*15/sfdpdch,feclevel);
  WCDMAULtxtMsgRead2(PDDCH,feclevel);
	PDCCH=i*WCDMAULdpcch( slotFormat);
	iqDataU=WCDMAULmake( sc,osr,slotFormat,PDCCH,PDDCH );
	WFMwrite( 'WCDMAUL_oct.wfm', iqDataU );
end

% based on Annex A2 of TS 125.141
% info=12.2kb/s
% dpch=60.0kb/s
% power control off
% TFCI on
% repetition 22%

% spreading factor 64
% interleaving 20
% number of DPDCH 1
% DPDCCH pilots 6/slot, power control 2/slot, TFCI 2/slot f=256
% ratio of DPCCH:DPDCH -2.69dB
% amplitude ratio 0.7333 (10^(-2.69/20))
%
% TS 25 211 each frame is 5 subframes long, with each subframe made of 3 slots.

