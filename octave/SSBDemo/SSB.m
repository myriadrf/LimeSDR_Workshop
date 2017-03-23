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
% 866MHz Transceiver Demo in Octave
% Digitally generates SSB sinewave, send through LimeSDR
% then recovered digital waveform and carry out spectrum analysis 
% connect TX1_1 to RX1_L via SMA adapter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% run SSB.m
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   S E T T I N G S
%
close all;
clear all;
TxPts=8192; % min is 8192
RxPts=256; % was 256
useLimeSDR=true;
leaveSDRrunningAfter=false;
saveGraphs=false;
fpltname='SSB';
itt=3;
FSR=1;% Sampling frequency Msps
Fssb=0.25;% Frequency of SSB signal (relative to sample rate)
fLMSsettings='DEMO_1Msps_866MHz_-50dBm.ini'
% 
% G E N E R A T E   S S B   W A V E F O R M
%
t=(0:(RxPts-1))/10; % sample rate 10Ms/s
iqDataTx = exp(i*2*pi*Fssb*(0:(TxPts-1))/FSR); % complex vector
%WFMwrite(fWfmName,iqDataTx); % save waveform to file
%iqDataTx=WFMread('ssb2MHz_10Msps.wfm'); % read waveform from file 
%
%   R A D I O   S E T U P
%
if useLimeSDR==true 
  LoadLimeSuite; % initialize LimeSuite and imports shared library functions
  %deviceList = LimeGetDeviceList(); % if several boards are connected
  %selectedDevice = 1;
  LimeInitialize(); %LimeInitialize(deviceList(selectedDevice));
  LimeLoadConfig(fLMSsettings); % load initial chip configuration
  %
  iqDataTxo=reshape(repmat(iqDataTx,2,1),1,[]); % convert to MIMO format
  LimeStartStreaming(length(iqDataTxo));
  LimeLoopWFMStart(iqDataTxo); %Load waveform to be continuosly transmitted
end
%
%   R E C E I V E   S S B    W A V E F O R M
%
figure;
for citt=1:itt
  if useLimeSDR==true 
	  iqDataRx = LimeReceiveSamples(RxPts); 
  else
    iqDataRx = iqDataTx;
  end
	plot(t,real(iqDataRx),'ro-',t,imag(iqDataRx),'go-',t,real(iqDataTx(1:RxPts)),'b+-');
  grid on;
  title('Received Data');
  xlabel('Time us');
  ylabel('Magnitude');
  legend('RX I','RX Q','TX I');
	pause(0.25); % seconds
end
% windowed fft of last result
len=length(iqDataRx);
fscale=(-(len/2):(len/2-1))/len*FSR; % MHz
spctrm=fftshift(fft(iqDataRx.*hanning(len)')/len); % note hamming is column vector, transpose
spctrm=20*log10(abs(spctrm)+1e-6);
[mg,loc]=max(spctrm);
fpk=((loc-1)-(len/2))/len*FSR; % MHz
printf('Peak=%fdB at %fMHz\n',mg,fpk);
figure;
plot(fscale,spctrm,'bo-');
grid on;
title('Windowed Received Data Spectrum');
xlabel('Frequency MHz');
ylabel('Magnitude dBFS');
legend('level dB');
if saveGraphs
  print( fpltname, '-dpng' );
end
%
%   R A D I O   S H U T D O W N
%
if (leaveSDRrunningAfter==false) && (useLimeSDR==true)
  printf('Purging LimeSDR resources\n');
  LimeLoopWFMStop(); %stop streaming
  LimeStopStreaming(); %also resets Rx Tx buffers  
  LimeDestroy(); %deallocate resources
 end
 
