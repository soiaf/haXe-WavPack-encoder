/*
** WavpackStream.hx
**
** Copyright (c) 2011 Peter McQuillan
**
** All Rights Reserved.
**
** Distributed under the BSD Software License (see license.txt)
**
*/

class WavpackStream
{
    public var wphdr:WavpackHeader;
    public var wvbits:Bitstream;
    public var wvcbits:Bitstream;
    public var dc:DeltaData;
    public var w:WordsData;
    public var blockbuff:Array<Int>;
    public var blockend:Int;
    public var block2buff:Array<Int>;
    public var block2end:Int;
    public var bits:Int;
    public var lossy_block:Int;
    public var num_terms:Int;
    public var sample_index:Int; // was uint32_t in C
    public var dp1:DecorrPass;
    public var dp2:DecorrPass;
    public var dp3:DecorrPass;
    public var dp4:DecorrPass;
    public var dp5:DecorrPass;
    public var dp6:DecorrPass;
    public var dp7:DecorrPass;
    public var dp8:DecorrPass;
    public var dp9:DecorrPass;
    public var dp10:DecorrPass;
    public var dp11:DecorrPass;
    public var dp12:DecorrPass;
    public var dp13:DecorrPass;
    public var dp14:DecorrPass;
    public var dp15:DecorrPass;
    public var dp16:DecorrPass;
    public var decorr_passes: Array < DecorrPass >;

    public function new()
    {
        blockbuff = new Array();
        block2buff = new Array();
        blockend = Defines.BIT_BUFFER_SIZE;
        block2end = Defines.BIT_BUFFER_SIZE;
        wphdr = new WavpackHeader();
        wvbits = new Bitstream();
        wvcbits = new Bitstream();
        w = new WordsData();
        bits = 0;
        lossy_block = 0;
        num_terms = 0;
        sample_index = 0;
        dc = new DeltaData();
        dp1 = new DecorrPass();
        dp2 = new DecorrPass();
        dp3 = new DecorrPass();
        dp4 = new DecorrPass();
        dp5 = new DecorrPass();
        dp6 = new DecorrPass();
        dp7 = new DecorrPass();
        dp8 = new DecorrPass();
        dp9 = new DecorrPass();
        dp10 = new DecorrPass();
        dp11 = new DecorrPass();
        dp12 = new DecorrPass();
        dp13 = new DecorrPass();
        dp14 = new DecorrPass();
        dp15 = new DecorrPass();
        dp16 = new DecorrPass();  
        decorr_passes = [ dp1, dp2, dp3, dp4, dp5, dp6, dp7, dp8, dp9, dp10, dp11, dp12, dp13, dp14, dp15, dp16 ];
    }
}