/*
** BitsUtils.hx
**
** Copyright (c) 2011 Peter McQuillan
**
** All Rights Reserved.
**
** Distributed under the BSD Software License (see license.txt)
**
*/

class BitsUtils
{
    ////////////////////////// Bitstream functions ////////////////////////////////
    // Open the specified BitStream using the specified buffer pointers. It is
    // assumed that enough buffer space has been allocated for all data that will
    // be written, otherwise an error will be generated.
    public static function bs_open_write(bs:Bitstream, buffer_start:Int, buffer_end:Int):Void {
        bs.error = 0;
        bs.sr = 0;
        bs.bc = 0;
        bs.buf_index = buffer_start;
        bs.start_index = bs.buf_index;
        bs.end = buffer_end;
        bs.active = 1; // indicates that the bitstream is being used
    }

    // This function is only called from the putbit() and putbits() when
    // the buffer is full, which is now flagged as an error.
    public static function bs_wrap(bs:Bitstream):Void {
        bs.buf_index = bs.start_index;
        bs.error = 1;
    }

    // This function calculates the approximate number of bytes remaining in the
    // bitstream buffer and can be used as an early-warning of an impending overflow.
    public static function bs_remain_write(bs:Bitstream):Int {

        if (bs.error != 0)
        {
            return -1;
        }

        return bs.end - bs.buf_index;
    }

    // This function forces a flushing write of the standard BitStream, and
    // returns the total number of bytes written into the buffer.
    public static function bs_close_write(wps:WavpackStream):Int {
        var bs:Bitstream= wps.wvbits;
        var bytes_written:Int= 0;

        if (bs.error != 0)
        {
            return -1;
        }
        
        while ((bs.bc != 0) || (((bs.buf_index - bs.start_index) & 1) != 0))
        {
            WordsUtils.putbit_1(wps);
        }

        bytes_written = bs.buf_index - bs.start_index;

        return bytes_written;
    }

    // This function forces a flushing write of the correction BitStream, and
    // returns the total number of bytes written into the buffer.
    public static function bs_close_correction_write(wps:WavpackStream):Int
    {
        var bs:Bitstream= wps.wvcbits;
        var bytes_written:Int= 0;

        if (bs.error != 0)
        {
            return -1;
        }

        while ((bs.bc != 0) || (((bs.buf_index - bs.start_index) & 1) != 0))
        {
            WordsUtils.putbit_correction_1(wps);
        }

        bytes_written = bs.buf_index - bs.start_index;

        return bytes_written;
    }
}