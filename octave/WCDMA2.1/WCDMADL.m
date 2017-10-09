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
% octave WCDMADL.m >> log.txt
% run WCDMADL.m
% demod takes about 3.5 seconds
printf("\n\nWCDMADL Demo\n");
clear all;
close all;
useLimeSDR=true;
leaveSDRrunningAfter=false;
saveGraphs=false; % bug in Octave 4.0
itt=2;
osr=8;
nch=64; % 16,32,64
fsr=3.84*osr; % sample rate MHz 3.84Ms/s is the chip rate.
feclevel=2; % compressed ascii with BCH(15,11)

fplt="WCDMAtestDL"; % auto generate graph names
fpltspec1=strcat(fplt,"_spec1");
fpltspec2=strcat(fplt,"_spec2");
titlestr=strcat("Spectrum: " );
fLMSsettings="DEMO_WCDMA_866MHz_-50dBm_v2.ini"; % 30.72Ms/s

pkg load communications % needed for Octave 4.0 Windows

% generate TM1 signal 3.84Ms/s (upsampled to 30.72Ms/s and RRC filtered)
[iqDataTx,duet,deuet]=WCDMADLMakeTM1(nch,osr,feclevel); % includes oversampling and rrc filtering

if useLimeSDR==true 	
	LoadLimeSuite; % LimeSDR initialisation and use
	LimeInitialize();
  LimeLoadConfig(fLMSsettings);
  iqDataTxo=reshape(repmat(iqDataTx,2,1),1,[]); % convert to MIMO
	LimeStartStreaming(length(iqDataTxo));
	LimeLoopWFMStart(iqDataTxo);
end

figure;
pause(3); % pause 3s to allow Lime to stream properly
for citt=1:itt
  if useLimeSDR==true 
	  iqDataRx = LimeReceiveSamples(length(iqDataTx));
  else % if not using LimeSDR, patch transmit stream direct to RX
  	iqDataRx=iqDataTx;
  end
  WCDMADLDemod( iqDataRx,osr,fplt,feclevel,saveGraphs,deuet,duet );
end

if (leaveSDRrunningAfter==false) && (useLimeSDR==true)
  printf("Purging LimeSDR resources\n"); 
  LimeLoopWFMStop(); %stop streaming
  LimeStopStreaming(); %also resets Rx Tx buffers 
  LimeDestroy(); %deallocate resources
end





