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
function WCDMAULDemod( iqdataraw,sc,slotFormat,osr,deuet,duet,fpltname,feclevel,saveGraphs )
	printf( 'WCDMAdemod:\n');
	sfdpdch=2^(8-slotFormat);
	sfdpcch=256; % sf=256 always for control channel - can use like CPICH for sync?
	dpdchno=sfdpdch/4; % single dpdcg
	dpcchno=0; % always 0, use like CPICH
	[dpcch,npilots]=WCDMAULdpcch(slotFormat);
	pilots=i*repmat([ones(1,npilots),zeros(1,(10-npilots))],1,15); % blank out nonpilot bits
  sum(pilots)
  [iqdata,dpdch,dpcch,ovsf,ovsf256]=WCDMAULdemod(iqdataraw,sc,slotFormat,osr,pilots);
  evmc=WCDMAULevm(dpcch,i*[1,-1]);
  [msg,evmd,deuer,duer]=WCDMAULtxtMsgRead2(-dpdch,feclevel); %%% temp fix
  if length(deuer)==length(deuet)
  	[nBERenc,rBERenc]=biterr(deuet,deuer);
  	[nBERasc,rBERasc]=biterr(duet,duer);
  	printf("BER (Encoded Bits) bits=%i errs=%i rate=%g \n",length(deuet),nBERenc,rBERenc );
  	printf("BER (Data Bits) bits=%i errs=%i rate=%g\n",length(duet),nBERasc,rBERasc );
  end
  evmcrms=sqrt(sum(evmc.*evmc)/length(evmc));
  evmdrms=sqrt(sum(evmd.*evmd)/length(evmd));
  printf("EVM PDCCH(BPSK)=%g%% EVM PDDCH(BPSK)=%g%%\n",evmcrms*100,evmdrms*100);
  WCDMAULplotAll(fpltname,saveGraphs,iqdataraw,iqdata,dpdch,dpcch,evmd,evmc,sfdpdch,ovsf,ovsf256)
end
