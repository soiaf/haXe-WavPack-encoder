////////////////////////////////////////////////////////////////////////////
//                   Haxe Implementation of WavPack Encoder               //
//                   Copyright (c) 2011-2012 Peter McQuillan              //
//                          All Rights Reserved.                          //
//      Distributed under the BSD Software License (see license.txt)      //
////////////////////////////////////////////////////////////////////////////

This package contains a Haxe implementation of the tiny version of the WavPack 
4.40 encoder. It is packaged with 2 demo command-line programs that accept a
RIFF wav file as input and output a WavPack encoded file.
One demo command-line program is designed to run with Neko, the
other uses your C++ compiler to produce a native executable.
This code has been tested against Haxe 2.09

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


Please direct any questions or comments to beatofthedrum@gmail.com
