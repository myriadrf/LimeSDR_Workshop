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
% simple scheme to compress arbitrary ASCII into 6 bit symbols for use with FEC
% restrict ascii to 'a'-'z', 'A'-'Z', '0'-'9', '.', and ' '
% note there are more efficient algorithms for natural language, but we are using acronyms WCDMA DPCH etc etc
function y=ASCII6dec( z )
	y=[];
	x=sum((reshape(z,6,length(z)/6)'.*[32,16,8,4,2,1])');
	for k=1:length(x)
		if x(k)<26
			x(k)=toascii('a')+x(k);
		elseif (26<=x(k))&&(x(k)<=51)
			x(k)=toascii('A')+x(k)-26;
		elseif (52<=x(k))&&(x(k)<=61)
			x(k)=toascii('0')+x(k)-52;
		elseif x(k)==62
			x(k)=toascii('.');
		else % 63
			x(k)=toascii(' ');
		end
    y=char(x);
	end
end
