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
% just for fun now, uses compressed ASCII (6 bit) and BCH(15,11) FEC
% Note real encoding uses Viterbi over several radio frames!  Viterbi is more efficient than block coding.
% also have not muxed DPCCH into DPDCH
function [y,din,dout]=WCDMADLtxtMsgWrite2( txt, bitsPerFrame )
	m=4;
	n=2^m-1; % also from bchpoly (1)
	k=11; % from bchpoly (2) % 21 maybe better than 16, as gives 14 chars instead of 10, with t=2 bit error correct
	t=1; % from bchpoly (3)
	maxMsg=floor(k*floor(bitsPerFrame/n)/6);
	qpsk=[1+i,1-i,-1+i,-1-i];
	% if message too short, add ' 's
	if length(txt)<maxMsg
		chars=maxMsg-length(txt);
		tmpTxt=[txt,repmat(32,1,chars)];
	% if message too long, cut
	elseif length(txt)>maxMsg
		tmpTxt=txt(1:maxMsg);
	else % length(txt)==maxMsg
		tmpTxt=txt;
	end
	pad1=randint(1,(k*ceil(maxMsg*6/k)-maxMsg*6)); % unused bits prior to encoding
	pad2=randint(1,(bitsPerFrame-n*floor(bitsPerFrame/n))); % unused part of encoded message, pad with random numbers 26
	printf('WCDMAtxtMsgULWrite[%s],BCH(%g,%g)\n', tmpTxt, n, k );	
	din=[reshape(de2bi(ASCII6enc(tmpTxt),6,2,"left-msb")',1,[])];
  data=[din,pad1]; % pad to fit FEC
	% convert to ?xk matrix prior to encoding 
	data=reshape(data,length(data)/k,k);
	data=bchenco(data,n,k);	
	% convert back to linear matrix and pad to bits per frame
	l=size(data);
	data=reshape(data,1,n*l(1));
	idx=[data,pad2]; % pad unused bits with random data
	% interleave to reduce effect of burst errors
%	idx=reshape(reshape(idx,15,40)',1,600); % was 15 10 150	
  dout=matintrlv(idx,15,40);	
	idx=sum( ( (reshape(dout,2,(length(dout)/2))').*[2,1])' )+1;
	y=qpsk(idx); % convert to qpsk
end
