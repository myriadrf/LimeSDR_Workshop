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
% Simple Spread Spectrum ASCII to BPSK data link with BCH Error Correction
% with scaled  amplitude quadrature pilot channel
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% run NumptyText3.m
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
pilotRatio=0.25; % ratio of pilot to data.
sprdFac=4; % spreading factor for spread spectrum 256 for no antennas
% spreadingGain=10*log10(sprdFac); % Code gain in dB
fpltname='Numpty';
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
k=4; % Hamming 4,7 Code
n=7;
t=1;
encBinData=reshape(bchenco(reshape(binData,length(binData)/k,k),n,k),1,[]); % add Error Correct Code
encBinData=matintrlv(encBinData,n,length(encBinData)/n); % interleave data
encMsgLen=length(encBinData);
bpskData=[2*encBinData-1]; % convert binary to BPSK, attach Sync word
msgLen=length(bpskData);
% convert to spread spectrum
prs=(2*randint(1,sprdFac*msgLen)-1); % BPSK Pseudo Random Sequence
pilot=i*pilotRatio*ones(1,msgLen*sprdFac).*prs; % pilot signal for frame lock
msg=reshape(repmat(bpskData,sprdFac,1),1,[]).*prs; % data signal
sprdSpecSig=pilot+msg; % CDMA type signal
%
% Apply RRC filtering to limit adjacent channel interference
osr=8; % x8 Oversampling
alpha=0.22; % define roll off of the RRC filter
symbols=6; % length of FIR in BPSK symbols
%hrrc=FIRMakeCoefsRRCOdd( alpha,symbols,osr ); % make RRC FIR impulse response
%iqDataTx=AutoScalePk(FIRTimeCP(UpSample(sprdSpecSig,osr), hrrc )); % do RRC filtering
iqDataTx=FIRCycRRC(sprdSpecSig,alpha,symbols,osr,1); % do RRC filtering
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
  	iqDataRx=shift(iqDataTx,13);
  end
  iqDataRxRaw=iqDataRx;
%  iqDataRx=FIRTimeCP(iqDataRx,hrrc); % use FIR to improve receive SNR after subsampling 
  iqDataRx=FIRCycRRC(iqDataRx,alpha,symbols,osr,0); % use FIR to improve receive SNR after subsampling 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   S Y N C H R O N I S A T I O N
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  macfBest=0;
  lacfBest=0;
  acfBest=0;
  phBest=0;
  cstart=1;
  syncConjFFT=conj(fft(pilot)); % prep for Auto Correlation Function
  % obtain frame sync to pilot channel, with timing correction for best eye.
  for cc=0:(osr-1)
    decData=shift(iqDataRx,cc); % timing correction for eye
    decData=decData(1:osr:(osr*length(pilot))); % subsample
    acf=ifft(fft(decData).*syncConjFFT)/length(pilot); % Auto Correlation Function
    [macf,lacf]=max(abs(acf)); % find best match
    if macf>macfBest
      macfBest=macf;
      lacfBest=lacf;
      acfBest=acf(lacf);
      cstart=cc;
      phBest=arg(acf(lacf)); % phase of best ACF result
      printf('cstart=%i lacf=%i macf=%i phacf=%g\n', cstart,lacfBest,macfBest,phBest*180/pi);
    end
  end 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  %   R E A D    M E S S A G E
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % align message for demod
  din=shift(iqDataRx,cstart+osr*(1-lacfBest)); % 
  din=exp(-i*phBest)*din(1:osr:(osr*length(pilot))); % phase correct signal
%  acf=ifft(fft(din).*syncConjFFT)/length(pilot); % Check alignment of pilot
%  [macf,lacf]=max(abs(acf)) % find best match
  din=pilotRatio*pilotRatio*din/abs(acfBest)-pilot; % remove pilot, pilotRatio*
%  acf=ifft(fft(din).*syncConjFFT)/length(pilot); % Measure residual pilot
%  [macf,lacf]=max(abs(acf)) % find best match
  doutDsprd=sum(reshape(din.*prs,sprdFac,[]))/sprdFac; % despread signal
  doutEnc=real(doutDsprd)>0; % convert bpsk back to binary without AGC
  doutDec=matdeintrlv(doutEnc,n,length(doutEnc)/n);
  doutDec=reshape(bchdeco(reshape(doutDec,length(doutDec)/n,n),k,t),1,[]);
  wordRx=char(bi2de(reshape(doutDec,8,length(doutDec)/8)',2,'left-msb'))'; % convert binary stream to text message
  printf('Received Word = %s \n', wordRx );
  NumptyGraphs(fpltname,iqDataTx,iqDataRxRaw,iqDataRx,binData,doutDsprd,doutDec,FSR,osr,msgLen,saveGraphs);
  berunc=biterr(binData,doutDec); % calculate Bit Errors and report quality
  berenc=biterr(encBinData,doutEnc); % calculate Bit Errors and report quality
  printf('Encoded BER=%i in %i bits\n',berenc,length(doutEnc));
  printf('Decoded BER=%i in %i bits\n',berunc,length(doutDec));
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
