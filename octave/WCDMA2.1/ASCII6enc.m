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
% note there are more efficient algorithms for normal language, but we are using acronyms WCDMA DPCH etc!!!
function y=ASCII6enc( x )
	s=toascii(x); % note using ascii characters as numbers does not work reliably in octave
	for k=1:length(x)
		if (toascii('a')<=s(k))&&(x(k)<=toascii('z'))
			y(k)=toascii(x(k))-toascii('a');
		elseif (toascii('A')<=x(k)) && (x(k)<=toascii('Z'))
			y(k)=toascii(x(k))-toascii('A')+26;
		elseif (toascii('0')<=x(k)) && (x(k)<=toascii('9'))
			y(k)=toascii(x(k))-toascii('0')+52;
		elseif toascii('.')==x(k)
			y(k)=62;
		else % x(k)=" "
			y(k)=63;
		end
	end
end


