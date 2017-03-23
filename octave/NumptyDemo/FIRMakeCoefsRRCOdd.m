%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright 2017 Lime Microsystems Ltd.
%
% Licensed under the Apache License, Version 2.0 (the 'License');
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%    http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an 'AS IS' BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% rrc_alpha - shape factor for the Root Raised Cosine filter
% symbols - length of impulse response each side of center in terms of symbols
% osr - oversample ratio
%
function hrrc=FIRMakeCoefsRRCOdd( rrc_alpha, symbols, osr )
	% vector version
	t=(-osr*symbols:osr*symbols)/osr; % odd number of points, symmetrical both sides, passing through 0
	hrrc=FIRMakeCoefsRRC(1,rrc_alpha,t);
end

