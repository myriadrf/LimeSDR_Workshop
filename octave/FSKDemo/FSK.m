%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Simple FSK data link
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% run FSK.m
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   S E T T I N G S
%
clear all;
close all;
useLimeSDR=true;
leaveSDRrunningAfter=false;
saveGraphs=true;
minPktLength=8192; % Current LimeSDR requirement
itt=3;
fpltname='FSK';
fwfm=strcat(fpltname,'.wfm');
FSR=1; % Sample rate frequency
fLMSsettings='DEMO_1Msps_866MHz_-50dBm.ini';
pkg load communications
fftSize=32;
frames=32;
%
%   G E N E R A T E   T R A N S M I T   S I G N A L
%
t=0:1023;
fc=0.5;
fm=0.1
k=2*pi;
m=[2,-1,2,0,1,-2,2,-2];
rep=fftSize*frames/length(m);
m=reshape(repmat(m,rep,1),1,[]);
ph=(2*pi*fc*t+k*m.*t)/fftSize; % FSK
iqDataTx=0.1*exp(i*ph);
%
%   R A D I O   S E T U P
%
if useLimeSDR==true 
	LoadLimeSuite; 	% LimeSDR initialisation and use
	LimeInitialize();
  LimeLoadConfig(fLMSsettings); % use settings file from LimeSuite
  iqDataTxo=reshape(repmat(iqDataTx,2,1),1,[]); % convert to MIMO format
	LimeStartStreaming(length(iqDataTxo));
	LimeLoopWFMStart(iqDataTxo); % play back data
end

figure;
%cm=[0:0.01:1;zeros(1,101);1:-0.01:0]'; % 101 pt RGB map
cm=[0:0.01:1;(0:0.01:1).^2;1:-0.01:0]'; % 101 pt RGB map
colormap(cm);
for cint=1:itt  
  %
  %   P R O C E S S   R E C E I V E   S I G N A L
  %
 if useLimeSDR==true 
	  iqDataRx = LimeReceiveSamples(length(iqDataTx));
  else % if not using LimeSDR, patch transmit stream direct to RX
  	iqDataRx=iqDataTx;
  end
  dfm=diff(unwrap(arg(iqDataRx))); % basic FM demodulator
  subplot(2,2,1);
  plot(real(iqDataRx),'b-',imag(iqDataRx),'r-');
  grid on;
  title('Raw Waveform');
  xlabel('Time Points');
  ylabel('Level');
  subplot(2,2,2);
  plot(dfm,'b-');
  grid on;
  title('Demodulated FSK Waveform');
  xlabel('Time Points');
  ylabel('Level');
 
  subplot(2,2,3);  % basic water fall type graph
  wtfl=fft(conj(reshape(iqDataRx,fftSize,[])').*hanning(fftSize)',fftSize,2)/fftSize;% windowed horizontal multiple FFT
  wtfl2=zeros((frames),fftSize);
  wtfld=mag2db(abs(fftshift(wtfl,2))+1e-5);
  img=imagesc(wtfld);
  grid on;
  title('Waterfall Graph');
  xlabel('Frequency');
  ylabel('Time');
  
  subplot(2,2,4);  % windowed fft 
  len=length(iqDataRx);
  fscale=(-(len/2):(len/2-1))/len*FSR; % MHz
  spctrm=fftshift(fft(iqDataRx.*hanning(len)')/len); % note hamming is column vector, transpose
  spctrm=20*log10(abs(spctrm)+1e-6);
  plot(fscale,spctrm,'bo-');
  grid on;
  title('Windowed Received Data Spectrum');
  xlabel('Frequency MHz');
  ylabel('Magnitude dBFS');
  legend('level dB');
  if saveGraphs
    print( fpltname, '-dpng' );
  end
end
%
%   R A D I O   S H U T D O W N
%
if (leaveSDRrunningAfter==false) && (useLimeSDR==true)
  printf('Purging LimeSDR resources\n'); 
  LimeLoopWFMStop(); % stop streaming
  LimeStopStreaming(); % also resets Rx Tx buffers 
  LimeDestroy(); % deallocate resources
end
