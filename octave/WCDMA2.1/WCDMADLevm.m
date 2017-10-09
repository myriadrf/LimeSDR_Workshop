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
% provide EVM for random sequences
% W-CDMA does not enforce equal amplitude signals, so we need AGC for each signal
% we assume we are dealing with BPSK or QAM, so rms amplitude should be unity
function evm=WCDMADLevm(x,qam)
	qam=[1+i,1-i,-1+i,-1-i];
  agc=sqrt(2)/sqrt(sum(x.*conj(x))/length(x));
  y=x*agc;
	evmref2=sum(abs(qam))/length(qam);
	[evm,loc]=min(abs(repmat(conj(qam'),1,length(y))-repmat(y,length(qam),1))); % decode QAM symbols
%	evm=evm./abs(qam(loc)); % some EVMs define relative to desired symbol
	evm/=evmref2; % some EVMs define relative to rms of QAM symbol table
end