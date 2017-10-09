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
% 3GPP TS 25.211 7.2.0 r7 p12 Table 3&4
% slots 0-14
% bits 3,4,5,6,7,8
function y=WCDMAULPilots( slot, bits )
	if bits==3 % col 1&2 can be used as FSW
		pilots=[1,1,1;0,0,1;0,1,1;0,0,1; \
		1,0,1;1,1,1;1,1,1;1,0,1; \
		0,1,1;1,1,1;0,1,1;1,0,1; \
		1,0,1;0,0,1;0,0,1];
	elseif bits==4 % col 2&3 can be used as FSW
		pilots=[1,1,1,1;1,0,0,1;1,0,1,1;1,0,0,1; \
		1,1,0,1;1,1,1,1;1,1,1,1;1,1,0,1; \
		1,0,1,1;1,1,1,1;1,0,1,1;1,1,0,1; \
		1,1,0,1;1,0,0,1;1,0,0,1];
	elseif bits==5 % col 1,2 and 4,5 can be used as FSW
		pilots=[1,1,1,1,0;0,0,1,1,0;0,1,1,0,1;0,0,1,0,0; \
		1,0,1,0,1;1,1,1,1,0;1,1,1,0,0;1,0,1,0,0; \
		0,1,1,1,0;1,1,1,1,1;0,1,1,0,1;1,0,1,1,1; \
		1,0,1,0,0;0,0,1,1,1;0,0,1,1,1];
	elseif bits==6 % col 2,3 and 5,6
		pilots=[1,1,1,1,1,0;1,0,0,1,1,0;1,0,1,1,0,1;1,0,0,1,0,0; \
		1,1,0,1,0,1;1,1,1,1,1,0;1,1,1,1,0,0;1,1,0,1,0,0; \ 
		1,0,1,1,1,0;1,1,1,1,1,1;1,0,1,1,0,1;1,1,0,1,1,1; \
		1,1,0,1,0,0;1,0,0,1,1,1;1,0,0,1,1,1];
	elseif bits==7 % col 2,3 and 5,6
		pilots=[1,1,1,1,1,0,1;1,0,0,1,1,0,1;1,0,1,1,0,1,1;1,0,0,1,0,0,1; \
		1,1,0,1,0,1,1;1,1,1,1,1,0,1;1,1,1,1,0,0,1;1,1,0,1,0,0,1; \
		1,0,1,1,1,0,1;1,1,1,1,1,1,1;1,0,1,1,1,0,1;1,1,0,1,1,1,1; \
		1,1,0,1,0,0,1;1,0,0,1,1,1,1;1,0,0,1,1,1,1];
	else % bits=8 % col 1,3 and 5,7
		pilots=[1,1,1,1,1,1,1,0;1,0,1,0,1,1,1,0;1,0,1,1,1,0,1,1;1,0,1,0,1,0,1,0;
		1,1,1,0,1,0,1,1;1,1,1,1,1,1,1,0;1,1,1,1,1,0,1,0;1,1,1,0,1,0,1,0;
		1,0,1,1,1,1,1,0;1,1,1,1,1,1,1,1;1,0,1,1,1,0,1,1;1,1,1,0,1,1,1,1;
		1,1,1,0,1,0,1,0;1,0,1,0,1,1,1,1;1,0,1,0,1,1,1,1];	
	end
	size(pilots);
	y=pilots(slot+1,:);
end
