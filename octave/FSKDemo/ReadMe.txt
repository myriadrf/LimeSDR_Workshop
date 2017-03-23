

What is this
============

This software module is a simple 866MHz FSK transceiver example for education purposes with the LimeSDR.  It runs using Octave, an open source numerical package that provides a relatively easy programming environment for communication systems.


Getting Started
===============

You will require the following software installed on your machine.

Octave 3.8.2 - 4.0.3 
--------------------

Needs communications, signal, control, general packages installed

Linux users can usually install these with a package manager, e.g. Synaptic

Windows users, the download contains the packages.

Otherwise
https://www.gnu.org/software/octave/
https://octave.sourceforge.io/communications/
https://octave.sourceforge.io/control/
https://octave.sourceforge.io/signal/
https://octave.sourceforge.io/general/

LimeSuite
---------

Follow the instructions at
https://wiki.myriadrf.org/Lime_Suite

Linux users, you will need to download the source and build, so as to have access to the octave library.  After building...
cd ~/LimeSuite/octave
make
Then copy LimeSuite.oct and LimeSuite.m file into this directory

Windows users, execute build.m octave script in the library provided.  Copy LimeSuite.dll, LimeSuite.oct and LoadLimeSuite.m into this directory.

LimeSDR
-------

Although it is possible to run this software without a LimeSDR, the LimeSDR is intended to be part of the learning experience.  You can obtain your LimeSDR from
https://www.crowdsupply.com/lime-micro/limesdr



Staying Legal
=============

Unlike some other products available, the LimeSDR is a transceiver, allowing users to both transmit and receive.  Using any general purpose transmitter carrys a level of responsibility to others using radio in the community.  If you intend to transmit using an antenna, please use the following code of good practice.  

(1) Use only either frequencies that you have a license to use, or are license exempt.  e.g. UK 866MHz.
https://www.ofcom.org.uk/__data/assets/pdf_file/0020/69050/statement.pdf 

(2) Pay particular attention to maximum permissible antenna power (ERP) specified in the license or in the license exemption.  +10dBm is a fairly common upper limit for License exempt transmission.

(3) Pay particular attention to maximum permissible bandwidth your signal may occupy.

(4) Where necessary, use RF filters to prevent harmonic responses and spurs affecting other users

(5) Use the minimum amount of transmitted power required for your experiments.  -50dBm is sufficient for many desk top experiments.

(6) Carry out digital and analogue filtering necessary to prevent transmitting in adjacent bands.


Using this Software Module
==========================

Ensure the .oct files from LimeSuite are added to this library.

Start octave on your computer

pkg list % to see if the communications package is present.

run build.m % to build any required .oct functions

run FSK.m % to execute the ASK Demo


Software License
================

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

