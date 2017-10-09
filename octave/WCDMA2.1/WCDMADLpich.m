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
% Page indication channel
% requires STTD?
% 288 bits/frame in 15 slots, last 12 bits not used
% PI relates to system frame number SFN
% table 4.3 and section 4.4.5 of Richardson W-CDMA book (ISBN 978-0-521-18782-4)
function y=WCDMADLpich(sfn,dly) % delay is 30x256 chips earlier than sccpch
	y=[((1-2*randint(1,144))+i*(1-2*randint(1,144))),zeros(1,6)]/sqrt(2); % last 6x2 bits unused
	y=shift( y, dly );
end
