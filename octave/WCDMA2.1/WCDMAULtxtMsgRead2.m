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
% Just for fun, recover compressed 6 bit ASCII text from DPDCH with BCH(15,11), BCH(15,7), BCH(15,5) FEC
% note real WCDMA uses Viterbi
function [y,evm,din,dout]=WCDMAULtxtMsgRead2( x, feclevel ) % working
	if feclevel==0
		m=4;
		n=2^m-1; % also from bchpoly (1)
		k=11; % from bchpoly (2)
		t=1; % from bchpoly (3)
	elseif feclevel==1
		m=4;
		n=2^m-1;
		k=7;
		t=2;
	else % feclevel==2
		m=4;
		n=2^m-1;
		k=5;
		t=3;
	end  
  agc=1/abs(sqrt(sum(x.*x)/length(x))); % agc as each channel is not a fixed level
  y=x*agc;  
	% convert bpsk to bit stream
  qam=[1,-1];
  bitsPerQAMSymbol=1;
	% convert qpsk to bit stream
%	y=WCDMAbpskDemod(x);
	evmref2=sum(abs(qam))/length(qam);
	[evm,loc]=min(abs(repmat(conj(qam'),1,length(y))-repmat(y,length(qam),1))); % decode QAM symbols
%	evm=evm./abs(qam(loc)); % some EVMs define relative to desired symbol
	evm/=evmref2; % some EVMs define relative to rms of QAM symbol table
	din=reshape(de2bi(loc-1,bitsPerQAMSymbol,2,"left-msb")',1,bitsPerQAMSymbol*length(loc)); % convert to binary stream
	bitsPerFrame=length(din);
	chars6b=floor(floor(length(din)/n)*k/6);
	symbols=floor(length(din)/n); % BCH symbols
	framelen=symbols*n; 
  y=din(1:framelen); % discarding padding
%	y=reshape(reshape(din,sz,15)',1,15*sz);
  y=matdeintrlv(din,n,framelen/n);% deinterleave	
	y=reshape(y,symbols,n); % group into a n x symbols matrix  decoding
	y=bchdeco(y,k,t);
	y=reshape(y,1,[]);
	dout=y(1:(6*chars6b)); % discarding padding
	y=ASCII6dec(dout);
	printf('WCDMAtxtMsgULRead[%s],BCH(%g,%g)\n', y, n, k );
end

