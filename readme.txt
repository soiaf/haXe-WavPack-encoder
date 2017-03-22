////////////////////////////////////////////////////////////////////////////
//                   Haxe Implementation of WavPack Encoder               //
//                   Copyright (c) 2011-2017 Peter McQuillan              //
//                          All Rights Reserved.                          //
//      Distributed under the BSD Software License (see license.txt)      //
////////////////////////////////////////////////////////////////////////////

This package contains a Haxe implementation of the tiny version of the WavPack 
4.40 encoder. It is packaged with a demo command-line program that accepts a
RIFF wav file as input and outputs a WavPack encoded file.
It is possible to generate outputs in the following lanaguages:
neko, c++, c sharp, java
There is also a demo Flash WavPack encoder.
This code has been tested against Haxe 3.4.2

===
To compile the .hx files for use with Neko, use the following command

haxe nekoWavPack.hxml

To run the demo program, use the following command

Usage:   neko wavpack.n [-options] infile.wav outfile.wv [outfile.wvc]
 (default is lossless)

Options: -bn = enable hybrid compression, n = 2.0 to 16.0 bits/sample 
         -c  = create correction file (.wvc) for hybrid mode (=lossless)
         -cc = maximum hybrid compression (hurts lossy quality & decode speed)
         -f  = fast mode (fast, but some compromise in compression ratio)
         -h  = high quality (better compression in all modes, but slower)
         -hh = very high quality (best compression in all modes, but slowest
                              and NOT recommended for portable hardware use)
         -jn = joint-stereo override (0 = left/right, 1 = mid/side)
         -sn = noise shaping override (hybrid only, n = -1.0 to 1.0, 0 = off)

To make the demo Flash file, use the following command

haxe flashtest.hxml

This will produce the file

wavpack_encoder_demo.swf

This demo encodes at 8kHz, lossy. This can be simply modified by changing the values in 
the new method of MicRecorder.hx 

Please direct any questions or comments to beatofthedrum@gmail.com
