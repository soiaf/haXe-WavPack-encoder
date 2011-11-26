/*
** WavpackHeader.hx
**
** Copyright (c) 2011 Peter McQuillan
**
** All Rights Reserved.
**
** Distributed under the BSD Software License (see license.txt)
**
*/

class WavpackHeader
{
    public var ckID:Array<Int>;
    public var ckSize:Int; // was uint32_t in C
    public var version:Int;
    public var track_no:Int; // was uchar in C
    public var index_no:Int; // was uchar in C
    public var total_samples:Int; // was uint32_t in C
    public var block_index:Int; // was uint32_t in C
    public var block_samples:Int; // was uint32_t in C
    public var flags: haxe.Int32; // was uint32_t in C
    public var crc:Int; // was uint32_t in C
    
    public function new()
    {
        ckID = new Array();
        ckSize = 0;
        version = 0;
        track_no = 0;
        index_no = 0;
        total_samples = 0;
        block_index = 0;
        block_samples = 0;
        crc = 0;
    }
}