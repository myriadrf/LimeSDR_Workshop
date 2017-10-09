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
function par=WCDMApar( x )
	av=mag2db(abs(std(x,1)));
	pk=mag2db(abs(max(abs(x))));
	par=pk-av;
%	printf( 'WCDMApar: pk=%gdB av=%gdB par=%gdB\n', pk, av, par );
	printf( 'PAR: pk=%gdB av=%gdB par=%gdB\n', pk, av, par );
end
