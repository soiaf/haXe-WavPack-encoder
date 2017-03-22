/*
** WavpackConfig.hx
**
** Copyright (c) 2011-2017 Peter McQuillan
**
** All Rights Reserved.
**
** Distributed under the BSD Software License (see license.txt)
**
*/

class WavpackConfig
{
    public var bitrate:Int;
    public var shaping_weight:Int;
    public var bits_per_sample:Int;
    public var bytes_per_sample:Int;
    public var num_channels:Int;
    public var block_samples:Int;
    public var flags : Int; 
    public var sample_rate:Int;

    public function new()
    {
        flags = 0;
    } 
}