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
% Just for fun, recover ASCII text from DPDCH with BCH(15,11) etc FEC
% Note real encoding uses Viterbi over several radio frames!  Viterbi is more efficient than block coding.
% also have not muxed DPCCH into DPDCH
function [y,evm,din,dout]=WCDMADLtxtMsgRead2( x )
	m=4;
	n=2^m-1; % also from bchpoly (1)
  ply=bchpoly(n);
  szp=size(ply);
  fecLevel=1;
  if fecLevel>szp(1)
    printf("Required FEClevel=%i too high for m=%i reduced to %i\n", fecLevel, m, szp(1));
    fecLevel=szp(1);
  end
	k=ply(fecLevel,2); % from bchpoly (2)
	t=ply(fecLevel,3); % from bchpoly (3)
  agc=1/abs(sqrt(sum(x.*conj(x))/length(x))); % agc as each channel is not a fixed level
  y=x*agc;
	% convert qpsk to bit stream
  qam=[1+i,1-i,-1+i,-1-i]/sqrt(2);
  bitsPerQAMSymbol=2;
	% convert qpsk to bit stream
%	y=WCDMAbpskDemod(x);
	evmref2=sum(abs(qam))/length(qam);
	[evm,loc]=min(abs(repmat(conj(qam'),1,length(y))-repmat(y,length(qam),1))); % decode QAM symbols
%	evm=evm./abs(qam(loc)); % some EVMs define relative to desired symbol
	evm/=evmref2; % some EVMs define relative to rms of QAM symbol table
	din=reshape(de2bi(loc-1,bitsPerQAMSymbol,2,"left-msb")',1,bitsPerQAMSymbol*length(loc)); % convert to binary stream
	bitsPerFrame=length(din);
	%convert bistream back to text
	chars6b=floor(floor(2*length(x)/n)*k/6); % DPDCH is complex x2 data
	symbols=floor(2*length(x)/n);
	framelen=symbols*n; 
  y=din(1:framelen); % discarding padding
  y=matdeintrlv(y,n,symbols);% deinterleave	
%	y=reshape(reshape(y,40,15)',1,600); % was 10 15 150
	% discard padding bits at end 
	y=y(1:framelen);
	% convert into a nx? matrix 
	l=size(y);
	y=reshape(y,l(2)/n,n); % group n bits for decoding
	y=bchdeco(y,k,t);
	y=reshape(y,1,k*l(2)/n);
	% convert back to binary, convert to 6 bit words, discarding padding
	dout=y(1:(6*chars6b));
	y=ASCII6dec(dout);
	printf('WCDMAtxtMsgDLRead[%s],BCH(%g,%g)\n', y, n, k );
end

% testing
% a=WCDMAtxtMsgDLWrite2("HelloZ",300);
% WCDMAtxtMsgDLRead2(a)
