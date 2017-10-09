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
function WCDMADLplotAll(fpltname,saveGraphs,iqdataraw,iqdata,data2,cpich,pich,pccpch,sccpch,evmd,evmcpich,evmpich,evmpccpch,evmsccpch,ovsf128,ovsf256)
	fpltsum=strcat(fpltname,"_sum.png");
  fsr=30.72; % MHz
  myfft1=fftshift(fft(iqdataraw)/length(iqdataraw));
  myfft2=fftshift(fft(iqdata)/length(iqdata));
  myfftf=fsr*((-length(iqdata)/2+0):(length(iqdata)/2-1))/(length(iqdata)-1);

	subplot(3,4,1)
  plot( myfftf, mag2db(abs(myfft1)+1e-7), "r-",myfftf, mag2db(abs(myfft2)+1e-7), "b-" );
  title( "Raw and RRC Spectrum: " );
  xlabel( "frequency MHz" );
  ylabel( "dB" );
%  legend( "raw","|I,Q|" );
  grid on;
  subplot(3,4,2);
  plot(iqdata(1:16384),"b.");
  title("IQ Data Raw Constellation");
  xlabel("I");
  ylabel("Q");
  subplot(3,4,3)
  plot(data2,"b.",cpich,"r.",pich,"g.",pccpch,"c.",sccpch,"m.");%,data4,"bo");
  grid on;
  title("QPSK IQ Data After Despread");
  xlabel("I");
  ylabel("Q");
	subplot(3,4,4)
	plot(real(data2),"r-",imag(data2),"b-"); %,real(data4),"g-",imag(data4),"m-"); % demodulated cpich 1-i, not 1+i, why?
	title("Data ch2");
  xlabel("Symbol");
  ylabel("Level");
%	legend("data2r","data2i"); % ,"data4r","data4i");
	grid on;
	axis("tight");
	subplot(3,4,5)
	plot(real(cpich),"r-",imag(cpich),"b-",real(pich),"g-",imag(pich),"m-"); % demodulated cpich 1-i, not 1+i, why?
	title("CPICH, PICH");
  xlabel("Symbol");
  ylabel("Level");
%	legend("CPICHr","CPICHi","PICHr","PICHi");
	grid on;
	axis("tight");
	subplot(3,4,6)
	plot(real(pccpch),"r-",imag(pccpch),"b-",real(sccpch),"g-",imag(sccpch),"m-"); % demodulated cpich 1-i, not 1+i, why?
	title("PCCPCH, SCCPCH");
  xlabel("Symbol");
  ylabel("Level");
%	legend("PCCPCHr","PCCPCHi","SCCPCHr","SCCPCHi");
	grid on;
	axis("tight");
	subplot(3,4,7:8)
	bar(ovsf128, 1.0, "basevalue", -80,"facecolor","g","edgecolor","b");
	axis("tight");
	title("OVSF 128 Scan");
  xlabel("OVSF Code");
  ylabel("Level dB");
	grid on;
  subplot(3,4,10);
  evm=[evmcpich,evmpich,evmpccpch,evmsccpch,evmd];
  evmt=sqrt(sum(evm.*evm)/length(evm))*100;
  evmt=evmt*ones(1,length(evmd));
  plot(evmd*100,"bo",evmcpich*100,"ro",evmpich*100,"co",evmpccpch,"bo",evmsccpch,"go", evmt,"g-");
  grid on;
  title("DL EVM");
  xlabel("symbol");
  ylabel("EVM %");
%  legend("PDDCH","CPICH","PICH","PCCPCH","SCCPCH","EVMT");
	subplot(3,4,11:12)
	bar(ovsf256, 1.0, "basevalue", -80,"facecolor","g","edgecolor","b");
	title("OVSF 256 Scan");
  xlabel("OVSF Code");
  ylabel("Level dB");
	axis("tight");
	grid on;
  drawnow(); % force screen update
	if saveGraphs==true
		print( fpltsum, "-dpng" );
		close;
	end
end