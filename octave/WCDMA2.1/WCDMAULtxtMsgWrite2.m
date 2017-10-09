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
% just for fun, uses compressed ASCII (6 bit) and BCH(15,11), BCH(15,7), BCH(15,5) FEC
% note real WCDMA uses Viterbi
function [y,din,dout]=WCDMAULtxtMsgWrite2( txt, bitsPerFrame, feclevel )
	if feclevel==0
		m=4;
		n=2^m-1; % also from bchpoly (1)
		k=11; % from bchpoly (2) % 21 maybe better than 16, as gives 14 chars instead of 10, with t=2 bit error correct
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
	maxMsg=floor(k*floor(bitsPerFrame/n)/6); % floor(floor(150/31)*21/6) => 10 characters
	bpsk=[1,-1];
	% if message too short, apend with spaces
	if length(txt)<maxMsg
		chars=maxMsg-length(txt);
		tmpTxt=[txt,repmat(32,1,chars)];
	% if message too long, snip
	elseif length(txt)>maxMsg
		tmpTxt=txt(1:maxMsg);
	else % length(txt)==maxMsg
		tmpTxt=txt;
	end
	pad1=randint(1,(k*ceil(maxMsg*6/k)-maxMsg*6)); % unused bits prior to encoding
	pad2=randint(1,(bitsPerFrame-n*floor(bitsPerFrame/n))); % unused part of encoded message, pad with random numbers 26
	printf('WCDMAtxtMsgULWrite[%s],BCH(%g,%g)\n', tmpTxt, n, k );	
	% convert compressed 6 bit ascii into binary stream
	din=[reshape(de2bi(ASCII6enc(tmpTxt),6,2,"left-msb")',1,[])];
  data=[din,pad1];	
	data=reshape(data,length(data)/k,k); % convert to ?xk matrix prior to encoding 
	data=bchenco(data,n,k);	
%	l=size(data);
%	data=reshape(data,1,n*l(1)); % convert back to linear matrix and pad to bits per frame
	data=reshape(data,1,[]); % convert back to linear matrix and pad to bits per frame
	idx=[data,pad2]; % pad unused bits with random data
	% interleave around here if you want 15x10 or 21x7
	sz=length(idx); % sz always a multiple of 15, as there are 15 subframes
%	idx=reshape(reshape(idx,15,sz/15)',1,sz);
  dout=matintrlv(idx,15,sz/15);	
	idx=dout+1; % convert to bpsk
	y=bpsk(idx);
end
