/*
** WaveHeader.hx
**
** Copyright (c) 2008 - 2009 Peter McQuillan
**
** All Rights Reserved.
**
** Distributed under the BSD Software License (see license.txt)
**
*/

internal class WaveHeader
{
    var FormatTag:Int; // was ushort in C
    var NumChannels:Int; // was ushort in C
    var SampleRate:Float; // was uint32_t in C
    var BytesPerSecond:Float; // was uint32_t in C
    var BlockAlign:Int; // was ushort in C
    var BitsPerSample:Int; // was ushort in C
    var cbSize:Int; // was ushort in C
    var ValidBitsPerSample:Int; // was ushort in C
    var ChannelMask:Int; // int32_t
    var SubFormat:Int; // was ushort in C
    var GUID:Array<Dynamic>;
}