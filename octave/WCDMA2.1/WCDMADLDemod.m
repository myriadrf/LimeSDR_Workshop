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
% assume RRC done externally, and data is osr*3.84Ms/s
function WCDMADLDemod( iqdataraw,osr,fpltname,feclevel,saveGraphs,deuet,duet )
	printf( 'WCDMADLdemod:\n');
	sc=0; % scramble code
  dch=2; % decode channel 2 of TM1 with sf=128
  sf=128;
  [iqdata,data2,cpich,pich,pccpch,sccpch,ovsf64,ovsf128,ovsf256]=WCDMADLdemod(iqdataraw,sc,sf,dch,osr);
	WCDMApar( iqdata );
  evmcpich=WCDMADLevm(cpich);
  evmpccpch=WCDMADLevm(pccpch);
  pich=pich(1:144);
  evmpich=WCDMADLevm(pich); 
  evmsccpch=WCDMADLevm(sccpch);
	% delay TimingOffset*256/sf SCCPCH
	[msg,evmd,deuer,duer]=WCDMADLtxtMsgRead2(data2);
  if length(deuer)==length(deuet)
  	[nBERenc,rBERenc]=biterr(deuet,deuer);
  	[nBERasc,rBERasc]=biterr(duet,duer);
  	printf("BER (Encoded Bits) bits=%i errs=%i rate=%g \n",length(deuet),nBERenc,rBERenc );
  	printf("BER (Data Bits) bits=%i errs=%i rate=%g\n",length(duet),nBERasc,rBERasc );
  end
  evmdrms=sqrt(sum(evmd.*evmd)/length(evmd));
  printf("EVM PDDCH(QPSK)=%g%%\n",evmdrms*100);
  evmcpichrms=sqrt(sum(evmcpich.*evmcpich)/length(evmcpich));
  evmpichrms=sqrt(sum(evmpich.*evmpich)/length(evmpich));
  printf("EVM PICH(QPSK)=%g%% EVM CPICH(QPSK)=%g%%\n",evmpichrms*100,evmcpichrms*100);
  evmpccpchrms=sqrt(sum(evmpccpch.*evmpccpch)/length(evmpccpch));
  evmsccpchrms=sqrt(sum(evmsccpch.*evmsccpch)/length(evmsccpch));
  printf("EVM PCCPCH(QPSK)=%g%% EVM SCCPCH(QPSK)=%g%%\n",evmpccpchrms*100,evmsccpchrms*100);
  WCDMADLplotAll(fpltname,saveGraphs,iqdataraw,iqdata,data2,cpich,pich,pccpch,sccpch,evmd,evmcpich,evmpich,evmpccpch,evmsccpch,ovsf128,ovsf256);
end
