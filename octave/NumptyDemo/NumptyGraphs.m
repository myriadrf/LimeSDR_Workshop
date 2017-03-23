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
function NumptyGraphs(fpltname,iqDataTx,iqDataRxRaw,iqDataRx,binData,din,dout,FSR,osr,msgLen,saveGraphs)
  %
  %   D I S P L A Y   G R A P H I C A L   S U M M A R Y
  %
  subplot(2,3,1);
  plot(iqDataTx(1:((msgLen+1)*osr)),'b');
  xlabel('Time');
  ylabel('Level');
  title('Filtered BPSK Message');
  grid on;
  subplot(2,3,2);
  plot(binData,'go',dout,'rx-');
  legend('transmitted','received');
  xlabel('Time');
  ylabel('Level');
  title('Binary Message');
  grid on;
  subplot(2,3,3);
  fsc=FSR*((-(length(iqDataRx)-1)/2):((length(iqDataRx)-1)/2))/length(iqDataRx);
  fftr=fftshift(mag2db(abs(fft(iqDataTx)/length(iqDataTx))+1e-5));
  plot(fsc,fftr);
  grid on;
	title('Spectrum of RRC Filtered Tx Signal');
	xlabel('Frequency MHz');
	ylabel('Level (dB)');
	axis('tight');
  subplot(2,3,4);
  fftr=fftshift(mag2db(abs(fft(iqDataRxRaw)/length(iqDataRxRaw))+1e-5));
  plot(fsc,fftr);
  grid on;
	title('Spectrum of Raw Rx Signal');
	xlabel('Frequency MHz');
	ylabel('Level (dB)');
	axis('tight');
  subplot(2,3,5);
  fftr=fftshift(mag2db(abs(fft(iqDataRx)/length(iqDataRx))+1e-5));
  plot(fsc,fftr);
  grid on;
	title('Spectrum of RRC Filtered Rx Signal');
	xlabel('Frequency MHz');
	ylabel('Level (dB)');
	axis('tight');
  subplot(2,3,6);
 	plot(iqDataRx,'b-',din,'rx');
	grid on;
	title('Trajectory of RRC Filtered RX signal');
	xlabel('I level');
	ylabel('Q level');
  legend('Traj','Locked');
  if saveGraphs
    print( fpltname, '-dpng' );
  end
end
