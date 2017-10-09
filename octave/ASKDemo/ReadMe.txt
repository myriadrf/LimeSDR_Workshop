

What is this
============

This software module is a simple 866MHz ASK transceiver example for education purposes with the LimeSDR.  It runs using Octave, an open source numerical package that provides a relatively easy programming environment for communication systems.


Getting Started
===============

You will require the following software installed on your machine.

Octave 3.8.2 - 4.0.3 
--------------------

Please see separate readme file.

LimeSuite
---------

Please see separate readme file.

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

Start octave on your computer

run ASK.m % to execute the ASK Demo

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

