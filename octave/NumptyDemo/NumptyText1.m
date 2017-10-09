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
% Simple ASCII to BPSK data link
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% run NumptyText1.m
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
fpltname='Numpty1';
fwfm=strcat(fpltname,'.wfm');
FSR=1; % Sample rate frequency
fLMSsettings='DEMO_1Msps_866MHz_-50dBm.ini';
pkg load communications % not loaded automatically in Octave >3.8.2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   G E N E R A T E   T R A N S M I T   S I G N A L
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% generate BPSK sync word
% '+' similar to 'k' and opposite of 'T', use double sync word to avoid false lock
sync=2*reshape(de2bi('++',8,2,'left-msb')',1,[])-1; % convert binary sync word to BPSK
%
wordTx='Hello LimeSDR'; % Message to be transmitted
binData=reshape(de2bi(wordTx,8,2,'left-msb')',1,[]); % convert ASCII message to binary stream
bpskData=[sync,2*binData-1]; % convert binary to BPSK, attach Sync word
msgLen=length(bpskData);
%
osr=8; % x8 Oversampling
rpt=ceil(minPktLength/osr/length(bpskData)); % calculate repeat factor for LimeSDR buffer
iqDataTx=repmat(bpskData,1,rpt); % repeat message to fill buffer
%
% Apply RRC filtering to limit adjacent channel interference
osr; % defined above
alpha=0.22; % define roll off of the RRC filter
symbols=6; % length of FIR in BPSK symbols
%hrrc=FIRMakeCoefsRRCOdd( alpha,symbols,osr ); % make RRC FIR impulse response
%iqDataTx=AutoScalePk(FIRTimeCP(UpSample(iqDataTx,osr), hrrc )); % do RRC filtering
iqDataTx=FIRCycRRC(iqDataTx,alpha,symbols,osr,1); % do RRC filtering
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
%  iqDataRx=FIRTimeCP(iqDataRx,hrrc);  % use FIR to improve receive SNR after subsampling 
  iqDataRx=FIRCycRRC(iqDataRx,alpha,symbols,osr,0); % use FIR to improve receive SNR after subsampling 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   S Y N C H R O N I S A T I O N
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  macfBest=0;
  phBest=0;
  cstart=1;
  syncConjFFT=conj(fft(sync)); % prep for Auto Correlation Function
  for cc=1:(msgLen*osr*2)
    decData=iqDataRx(cc:osr:(cc+osr*length(sync)-1)); % subsampling
    acf=ifft(fft(decData).*syncConjFFT); % Auto Correlation Function
    [macf,lacf]=max(abs(acf)); % find best match
    if (macfBest<macf)&&(lacf==1)
      macfBest=macf;
      cstart=cc;
      phBest=arg(acf(lacf)); % phase of best ACF result
      printf('cc=%i macf=%i phacf=%g\n', cc, macfBest,phBest*180/pi);
    end
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  %   R E A D    M E S S A G E
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  din=exp(-i*phBest)*iqDataRx(cstart+osr*length(sync):osr:(cstart-1+osr*msgLen)); % phase correct signal
  dout=real(din)>0; % convert BPSK back to binary without AGC
  wordRx=char(bi2de(reshape(dout,8,length(dout)/8)',2,'left-msb'))'; % convert binary stream to text message
  printf('Received Word = %s \n', wordRx );
  NumptyGraphs(fpltname,iqDataTx,iqDataRxRaw,iqDataRx,binData,din,dout,FSR,osr,msgLen,saveGraphs);
  ber=biterr(binData,dout); % calculate Bit Errors and report quality
  printf('BER=%i in %i bits\n',ber,length(din));
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
