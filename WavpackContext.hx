/*
** WavpackContext.hx
**
** Copyright (c) 2011 Peter McQuillan
**
** All Rights Reserved.
**
** Distributed under the BSD Software License (see license.txt)
**
*/

class WavpackContext
{
    public var config:WavpackConfig;
    public var stream:WavpackStream;
    public var error_message:String;
    public var infile:haxe.io.Input;
    public var outfile:haxe.io.Output;
    public var correction_outfile:haxe.io.Output;
    public var total_samples:Int; // was uint32_t in C
    public var lossy_blocks:Int;
    public var wvc_flag:Int;
    public var block_samples:Int;
    public var acc_samples:Int;
    public var filelen:Int;
    public var file2len:Int;
    public var stream_version:Int;
    public var byte_idx:Int; // holds the current buffer position for the input WAV data

    public function new()
    {
        config = new WavpackConfig();
        stream = new WavpackStream();
        error_message = "";
        total_samples = 0;
        lossy_blocks = 0;
        wvc_flag = 0;
        block_samples = 0;
        acc_samples = 0;
        filelen = 0;
        file2len = 0;
        stream_version = 0;
        byte_idx = 0;
    }

}