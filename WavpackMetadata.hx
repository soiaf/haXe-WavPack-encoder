/*
** WavpackMetadata.hx
**
** Copyright (c) 2011 Peter McQuillan
**
** All Rights Reserved.
**
** Distributed under the BSD Software License (see license.txt)
**
*/

class WavpackMetadata
{
    public var byte_length:Int;
    public var temp_data:Array<Int>;
    public var data:Array<Int>;
    public var id:Int; // was uchar in C

    public function new()
    {
    data = new Array();
    temp_data = new Array();
    byte_length = 0;
    id = 0;
    }
}
