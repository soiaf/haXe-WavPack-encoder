/*
** WordsData.hx
**
** Copyright (c) 2011 Peter McQuillan
**
** All Rights Reserved.
**
** Distributed under the BSD Software License (see license.txt)
**
*/

class WordsData
{
    public var bitrate_delta:Array<Int>; // was uint32_t  in C
    public var bitrate_acc:Array<Int>; // was uint32_t  in C
    public var pend_data:Int; // was uint32_t  in C
    public var holding_one:Int; // was uint32_t  in C
    public var zeros_acc:Int; // was uint32_t  in C
    public var median:Array<Array<Int>> ;
    public var slow_level:Array<Int>; // was uint32_t  in C
    public var error_limit:Array<Int>; // was uint32_t  in C
    public var holding_zero:Int;
    public var pend_count:Int;
    
    public function new()
    {
        bitrate_delta = new Array();
        bitrate_delta[0] = 0;
        bitrate_delta[1] = 0;
        bitrate_acc = new Array();
        bitrate_acc[0] = 0;
        bitrate_acc[1] = 0;
        pend_data = 0;
        holding_one = 0;
        zeros_acc = 0;
        median = new Array();
        median[0] = new Array();
        median[1] = new Array();
        median[2] = new Array();
        median[0][0] = 0;
        median[1][0] = 0;
        median[2][0] = 0;
        median[0][1] = 0;
        median[1][1] = 0;
        median[2][1] = 0;
        slow_level = new Array();
        slow_level[0] = 0;
        slow_level[1] = 0;
        error_limit = new Array();
        error_limit[0] = 0;
        error_limit[1] = 0;
        holding_zero = 0;
        pend_count = 0;
    }
}