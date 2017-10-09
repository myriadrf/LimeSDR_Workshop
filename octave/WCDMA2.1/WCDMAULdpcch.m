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
% TS 25 211 Section 5.2.11 
% Table 1
% Table 2
% Table 3&4 Pilot Patterns
% Slot Format 0 15kbps SF=256 10 bits/slot 150bits/frame
% Slot Format 1 30kbps SF=128 20 bits/slot 300bits/frame
% Slot Format 2 60kbps SF=64 40 bits/slot 600bits/frame
% Slot Format 3 120kbps SF=32 80 bits/slot 1200bits/frame
% Slot Format 4 240kbps SF=16 160 bits/slot 2400bits/frame
% Slot Format 5 480kbps SF=8 320 bits/slot 4800bits/frame
% Slot Format 6 960kbps SF=4 640 bits/slot 9600bits/frame
% Note TS 25 213 talks about high speed ul signals I think

% assume for now we use entire frame
function [dpcch,npilots]=WCDMAULdpcch( slotFormat )
	NTPC2=[1,1;0,0];
	NTPC4=[1,1,1,1;0,0,0,0];
	sf=256;
	dpcch=[];
	for slot=0:14
		if slotFormat=='0'
			npilots=6;
			pilots=WCDMAULPilots( slot, npilots ); % 15 slots per frame
			tfci=[0,0]; % format - described in detail in [3]
			fbi=[]; % feedback - described in [5]
			tpc=NTPC2(1,:); % power control
		elseif slotFormat=='0A' % 0A - Compressed Slot Format A
			npilots=5;
			pilots=WCDMAULPilots( slot, npilots ); % 10-14 slots per frame
			tfci=[0,0,0]; % format - described in detail in [3]
			fbi=[]; % feedback - described in [5]
			tpc=NTPC2(1,:); % power control
		elseif slotFormat=='0B' % 0B - Compressed Slot Format B
			npilots=4;
			pilots=WCDMAULPilots( slot, npilots ); % 8-9 slots per frame
			tfci=[0,0,0,0]; % format - described in detail in [3]
			fbi=[]; % feedback - described in [5]
			tpc=NTPC2(1,:); % power control
		elseif slotFormat=='1'
			npilots=8;
			pilots=WCDMAULPilots( slot, npilots ); % 8-15 slots per frame
			tfci=[]; % format - described in detail in [3]
			fbi=[]; % feedback - described in [5]
			tpc=NTPC2(1,:); % power control
		elseif slotFormat=='2'
			npilots=5;
			pilots=WCDMAULPilots( slot, npilots ); % 15 slots per frame
			tfci=[0,0]; % format - described in detail in [3]
			fbi=[1]; % feedback - described in [5]
			tpc=NTPC2(1,:); % power control
		elseif slotFormat=='2A' % 2A - Compressed Slot Format A
			npilots=4;
			pilots=WCDMAULPilots( slot, npilots ); % 10-14 slots per frame
			tfci=[0,0,0]; % format - described in detail in [3]
			fbi=[1]; % feedback - described in [5]
			tpc=NTPC2(1,:); % power control
		elseif slotFormat=='2B' % 2B - Compressed Slot Format B
			npilots=3;
			pilots=WCDMAULPilots( slot, npilots ); % 8-9 slots per frame
			tfci=[0,0,0,0]; % format - described in detail in [3]
			fbi=[1]; % feedback - described in [5]
			tpc=NTPC2(1,:); % power control
		elseif slotFormat=='3'
			npilots=7;
			pilots=WCDMAULPilots( slot, npilots ); % 8-15 slots per frame
			tfci=[]; % format - described in detail in [3]
			fbi=[1]; % feedback - described in [5]
			tpc=NTPC2(1,:); % power control
		else % slotFormat=='4'
			npilots=6;
			pilots=WCDMAULPilots( slot, npilots ); % 8-15 slots per frame
			tfci=[]; % format - described in detail in [3]
			fbi=[]; % feedback - described in [5]
			tpc=NTPC4(1,:); % power control
		end
		dpcch=[dpcch,pilots,tfci,fbi,tpc]; % 10 bits/slot
	end;
	% bpsk, map {0,1} -->  {1,-1}
	dpcch=1-2*dpcch;
end;
% see [5] for DPCCH use during power control before data transmission
