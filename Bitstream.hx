/*
** Bitstream.hx
**
** Copyright (c) 2011 Peter McQuillan
**
** All Rights Reserved.
**
** Distributed under the BSD Software License (see license.txt)
**
*/

class Bitstream
{
    public var end:Int; // was uchar in c
    public var sr:Int; // was uint32_t in C
    public var error:Int;
    public var bc:Int;
    public var buf_index:Int;
    public var start_index:Int;
    public var active:Int; // if 0 then this bitstream is not being used
    
    public function new()
    {
        end = 0;
        sr = 0;
        error = 0;
        bc = 0;
        buf_index = 0;
        start_index = 0;
        active = 0;
    }
}
