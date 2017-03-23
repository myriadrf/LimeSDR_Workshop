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
% 3GPP TS 25.101 v 12.6.0 Release 12 Section 6.8.1
%
% modified to remove divide by 0 problems
function hrrc=FIRMakeCoefsRRC( ts, beta, tt ) % beta is the same as alpha!
	hrrc=1:length(tt);
	for ci=1:length(tt)
		t=tt(ci);
		if (t==0)
			val=(1-beta+4*beta/pi)/sqrt(ts);
		elseif (abs(t)==(ts/4/beta))
			val=beta*((1+2/pi)*sin(pi/4/beta)+(1-2/pi)*cos(pi/4/beta))/sqrt(2*ts);
		else
			val=(sin(pi*t/ts*(1-beta))+4*beta*t*cos(pi*t/ts*(1+beta))/ts);
			val/=sqrt(ts)*(pi*t*(1-(4*beta*t/ts)^2)/ts);
		end
		hrrc(ci)=val;
		%printf( '%g %g\n', t, val );
	end
	tothrrc=sqrt(sum(hrrc.*hrrc)); % use RMS as coefficients are signed numbers
	hrrc/=tothrrc; % normalise, so integral of impulse response is unity
end

