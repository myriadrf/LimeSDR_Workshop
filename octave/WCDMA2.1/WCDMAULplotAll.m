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
function WCDMAULplotAll(fpltname,saveGraphs,iqdataraw,iqdata,dpdch,dpcch,evmd,evmc,sfdpdch,ovsfscan,ovsfscan256)
	fpltsum=strcat(fpltname,"_sum.png");
titlestr=strcat("Spectrum: " );
fsr=30.72;
myfft=fftshift(fft(iqdataraw)/length(iqdataraw));
myfft2=fftshift(fft(iqdata)/length(iqdata));
myfftf=fsr*((-length(iqdata)/2+0):(length(iqdata)/2-1))/(length(iqdata)-1);
%	figure;
  subplot(3,3,1);
  plot( myfftf, mag2db(abs(myfft)+1e-8), "r-",myfftf, mag2db(abs(myfft2)+1e-8), "b-" );
  title( titlestr );
  xlabel( "frequency (relative to nyquist)" );
  ylabel( "dB" );
%  legend( "raw","|RRC(I,Q)|" );
  grid on;
  subplot(3,3,2);
  plot(iqdata(1:8192),"b.");
  title("IQ Data Raw Constellation");
  xlabel("I");
  ylabel("Q");
  subplot(3,3,3)
  plot(dpdch,"b.",dpcch,"r.") %,iqdatassds,"m.");
  grid on;
  title("IQ Data Before and After Despread");
  xlabel("I");
  ylabel("Q");
%  legend("dpdch","dpcch") %,"iqdatassds");
	subplot(3,3,4);
	plot(real(dpdch),"r-",imag(dpdch),"b-",real(dpcch),"g-",imag(dpcch),"m-"); % demodulated cpich 1-i, not 1+i, why?
	title("UL DPCCH and DPDCH");
%	legend("dpdchr","dpdchi","dpcchr","dpcchi");
	xlabel("symbol");
	ylabel("level");
	grid on;
	axis("tight");
	axis("tight");
	subplot(3,3,5:6);
	bar(ovsfscan, 1.0, "basevalue", -80,"facecolor","g","edgecolor","b");
	axis("tight");
  ovsfTitle=["OVSF ",num2str(sfdpdch)," Scan"];
	title(ovsfTitle);
  xlabel("OVSF Code");
  ylabel("Level dB");
	grid on;
  subplot(3,3,7);
  evm=[evmc,evmd];
  evmt=sqrt(sum(evm.*evm)/length(evm))*100;
  evmt=evmt*ones(1,length(evmd));
  plot(evmd*100,"bo",evmc*100,"ro",evmt,"g-");
  grid on;
  title("UL EVM");
  xlabel("symbol");
  ylabel("EVM %");
%  legend("PDCCH","PDDCH","EVMT");
	subplot(3,3,8:9);
	bar(ovsfscan256, 1.0, "basevalue", -80,"facecolor","g","edgecolor","b");
	title("OVSF 256 Scan");
  xlabel("OVSF Code");
  ylabel("Level dB");
	axis("tight");
	grid on;
	if saveGraphs
		print( fpltsum, "-dpng" );
		close;
	end
  drawnow();
end