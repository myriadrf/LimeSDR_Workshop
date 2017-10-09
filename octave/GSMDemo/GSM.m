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
% Simple GSM data link - demo is sensitive to noise 
% RRC helps, but needs inertia in unwrap function
% also need ACF timing extractor for down sample data for BER
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% run GSM.m
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   S E T T I N G S
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;
close all;
useLimeSDR=true;
leaveSDRrunningAfter=false;
saveGraphs=false;
minPktLength=8192; % Current LimeSDR requirement
itt=3;
fpltname='ASK';
fwfm=strcat(fpltname,'.wfm');
FSR=1; % Sample rate frequency
fLMSsettings='DEMO_1Msps_866MHz_-50dBm.ini';
fftSize=32;
frames=32;
% what do I do different for EDGE
% what do I do different for Bluetooth
% what about training sequence and power busrt for proper GSM/Edge
pkg load communications;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   G E N E R A T E   T R A N S M I T   S I G N A L
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
osr=8;
symb=2;
bt=0.3;
FSR=1.0;
x=2*randint(1,64)-1; % BPSK
iqDataTx=FIRCycGaussInt(x,bt,symb,osr,1); % GMSK modulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   R A D I O   S E T U P
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  %   P R O C E S S   R E C E I V E   S I G N A L
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 if useLimeSDR==true 
	  iqDataRx = LimeReceiveSamples(length(iqDataTx));
  else % if not using LimeSDR, patch transmit stream direct to RX
  	iqDataRx=iqDataTx;
  end
  iqDataRxRaw=iqDataRx;
  iqDataRx=FIRCycRC(iqDataRx,0.22,symb,osr/2,0);
  dd=diff(unwrap(arg(iqDataRx)),1); % FM demodulation of GMSK
  tt=diff(unwrap(arg(iqDataTx)),1);
  % how to get bit sync for sub sample? ACF on say 8 bits?  Ref waveform upsample of sync or something?
  xref=UpSample(x(1:8),osr);
  xrefconjfft=conj(fft(xref));
  % fft search for xref - no phase info needed from ACF for GMSK, just timing.
  d=dd>0;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  %   G R A P H I C A L   S U M A R Y
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  subplot(2,3,1);
  plot(real(iqDataRx),"b-",imag(iqDataRx),"r-");
  grid on;
  title("GMSK Time Domain");
  xlabel("time");
  ylabel("level");
  subplot(2,3,2);
  zfft=fftshift(fft(iqDataRxRaw.*hanning(length(iqDataRxRaw))'))/length(iqDataRxRaw);
  yfft=fftshift(fft(iqDataRx.*hanning(length(iqDataRx))'))/length(iqDataRx);
  fyfft=FSR*((-length(iqDataRx)/2):(length(iqDataRx)/2-1))/length(iqDataRx);
  plot(fyfft,mag2db(abs(zfft)+1e-5),"r-",fyfft,mag2db(abs(yfft)+1e-5),"b-");
  grid on;
  title("GMSK Spectrum");
  xlabel("frequency");
  ylabel("level");
  legend('Raw','Gausian');
  subplot(2,3,3);
  plot(dd,"r-",tt,"b-");
  grid on;
  title("Demodulated GMSK");
  xlabel("time");
  ylabel("level");
  subplot(2,3,4);
  plot(d,"b-");
  grid on;
  title("Recovered Data");
  xlabel("time");
  ylabel("level");
  subplot(2,3,5);  % basic windowed water fall type graph. 
  wtfl=fft(conj(reshape(iqDataRx,fftSize,[])').*hanning(fftSize)',fftSize,2)/fftSize; % windowed horizontal multiple FFT
  wtfl2=zeros((frames),fftSize);
  wtfld=mag2db(abs(fftshift(wtfl,2))+1e-5);
  img=imagesc(wtfld);
  grid on;
  title('Waterfall Graph');
  xlabel('Frequency');
  ylabel('Time');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   R A D I O   S H U T D O W N
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (leaveSDRrunningAfter==false) && (useLimeSDR==true)
  printf('Purging LimeSDR resources\n'); 
  LimeLoopWFMStop(); % stop streaming
  LimeStopStreaming(); % also resets Rx Tx buffers 
  LimeDestroy(); % deallocate resources
end
