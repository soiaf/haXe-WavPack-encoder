/*
** WvEncode.hx
**
** Copyright (c) 2011-2017 Peter McQuillan
**
** All Rights Reserved.
**
** Distributed under the BSD Software License (see license.txt)
**
*/
class WvEncode
{
    public static function main()
    {
        // This is the main module for the demonstration WavPack command-line
        // encoder using the "tiny encoder". It accepts a source WAV file, a
        // destination WavPack file (.wv) and an optional WavPack correction file
        // (.wvc) on the command-line. It supports all 4 encoding qualities in
        // pure lossless, hybrid lossy and hybrid lossless modes. Valid input are
        // mono or stereo integer WAV files with bitdepths from 8 to 24.
        // This program (and the tiny encoder) do not handle placing the WAV RIFF
        // header into the WavPack file. The latest version of the regular WavPack
        // unpacker (4.40) and the "tiny decoder" will generate the RIFF header
        // automatically on unpacking. However, older versions of the command-line
        // program will complain about this and require unpacking in "raw" mode.
        ///////////////////////////// local variable storage //////////////////////////
        var VERSION_STR:String= "4.40";
        var DATE_STR:String= "2007-01-16";

        var sign_on1:String= "Haxe WavPack Encoder (c) 2011-2017 Peter McQuillan";
        var sign_on2:String= "based on TINYPACK - Tiny Audio Compressor  Version " + VERSION_STR +
            " " + DATE_STR + " Copyright (c) 1998 - 2017 Conifer Software.  All Rights Reserved.";

        var usage0:String= "";
        var usage1:String= " Usage:   WvEncode [-options] infile.wav outfile.wv [outfile.wvc]";
        var usage2:String= " (default is lossless)";
        var usage3:String= "";
        var usage4:String= "  Options: -bn = enable hybrid compression, n = 2.0 to 16.0 bits/sample";
        var usage5:String= "       -c  = create correction file (.wvc) for hybrid mode (=lossless)";
        var usage6:String= "       -cc = maximum hybrid compression (hurts lossy quality & decode speed)";
        var usage7:String= "       -f  = fast mode (fast, but some compromise in compression ratio)";
        var usage8:String= "       -h  = high quality (better compression in all modes, but slower)";
        var usage9:String= "       -hh = very high quality (best compression in all modes, but slowest";
        var usage10:String= "                              and NOT recommended for portable hardware use)";
        var usage11:String= "       -jn = joint-stereo override (0 = left/right, 1 = mid/side)";
        var usage12:String= "       -sn = noise shaping override (hybrid only, n = -1.0 to 1.0, 0 = off)";

        //////////////////////////////////////////////////////////////////////////////
        // The "main" function for the command-line WavPack compressor.             //
        //////////////////////////////////////////////////////////////////////////////
        var infilename:String= "";
        var outfilename:String= "";
        var out2filename:String= "";
        var config:WavpackConfig= new WavpackConfig();
        var error_count:Int= 0;
        var result:Int;
        var i:Int;
        var arg_idx:Int= 0;


        // loop through command-line arguments
        while (arg_idx < Sys.args().length)
        {
            if (StringTools.startsWith(Sys.args()[arg_idx], "-"))
            {
                if (StringTools.startsWith(Sys.args()[arg_idx], "-c") || StringTools.startsWith(Sys.args()[arg_idx], "-C") )
                {
                    if (StringTools.startsWith(Sys.args()[arg_idx], "-cc") || StringTools.startsWith(Sys.args()[arg_idx], "-CC"))
                    {
                        config.flags = config.flags | Defines.CONFIG_CREATE_WVC;
                        config.flags = config.flags | Defines.CONFIG_OPTIMIZE_WVC;
                    }
                    else
                    {
					    config.flags = config.flags | Defines.CONFIG_CREATE_WVC;
                    }
                }
                else if (StringTools.startsWith(Sys.args()[arg_idx], "-f") || StringTools.startsWith(Sys.args()[arg_idx], "-F"))
                {
				    config.flags = config.flags | Defines.CONFIG_FAST_FLAG;
                }
                else if (StringTools.startsWith(Sys.args()[arg_idx], "-h") || StringTools.startsWith(Sys.args()[arg_idx], "-H"))
                {
                    if (StringTools.startsWith(Sys.args()[arg_idx], "-hh") || StringTools.startsWith(Sys.args()[arg_idx], "-HH"))
                    {
					    config.flags = config.flags | Defines.CONFIG_VERY_HIGH_FLAG;
                    }
                    else
                    {
					    config.flags = config.flags | Defines.CONFIG_HIGH_FLAG;
                    }
                }
                else if (StringTools.startsWith(Sys.args()[arg_idx], "-k") || StringTools.startsWith(Sys.args()[arg_idx], "-K"))
                {
                    var passedInt:Int= 0;

                    if (Sys.args()[arg_idx].length > 2)
                    {
                        try
                        {
                            var substring:String= Sys.args()[arg_idx].substr(2);
                            passedInt = Std.parseInt(substring);
                        }
                        catch (err: Dynamic)
                        {
                        }
                    }
                    else
                    {
                        arg_idx++;

                        try
                        {
                            passedInt = Std.parseInt(Sys.args()[arg_idx]);
                        }
                        catch (err: Dynamic)
                        {
                        }
                    }

                    config.block_samples = passedInt;
                }
                else if (StringTools.startsWith(Sys.args()[arg_idx], "-b") || StringTools.startsWith(Sys.args()[arg_idx], "-B"))
                {
                    var passedDouble:Float= 0;
					config.flags = config.flags | Defines.CONFIG_HYBRID_FLAG;

                    if (Sys.args()[arg_idx].length > 2)    // handle the case where the string is passed in form -b0 (number beside b)
                    {
                        try
                        {
                            var substring:String= Sys.args()[arg_idx].substr(2);
                            passedDouble = Std.parseFloat(substring);
                            config.bitrate = Math.floor((passedDouble * 256.0));
                        }
                        catch (err: Dynamic)
                        {
                            config.bitrate = 0;
                        }
                    }
                    else
                    {
                        arg_idx++;

                        try
                        {
                            passedDouble = Std.parseFloat(Sys.args()[arg_idx]);
                            config.bitrate = Math.floor((passedDouble * 256.0));
                        }
                        catch (err: Dynamic)
                        {
                            config.bitrate = 0;
                        }
                    }

                    if ((config.bitrate < 512) || (config.bitrate > 4096))
                    {
                        Sys.println("hybrid spec must be 2.0 to 16.0!");
                        ++error_count;
                    }
                }
                else if (StringTools.startsWith(Sys.args()[arg_idx], "-j") || StringTools.startsWith(Sys.args()[arg_idx], "-J"))
                {
                    var passedInt:Int= 2;

                    if (Sys.args()[arg_idx].length > 2) // handle the case where the string is passed in form -j0 (number beside j)
                    {
                        try
                        {
                            var substring:String= Sys.args()[arg_idx].substr(2);
                            passedInt = Std.parseInt(substring);
                        }
                        catch (err: Dynamic)
                        {
                        }
                    }
                    else // handle the case where the string is passed in form -j 0 (space between number and j)
                    {
                        arg_idx++;

                        try
                        {
                            passedInt = Std.parseInt(Sys.args()[arg_idx]);
                        }
                        catch (err: Dynamic)
                        {
                        }
                    }

                    if (passedInt == 0)
                    {
					    config.flags = config.flags | Defines.CONFIG_JOINT_OVERRIDE;
						config.flags = config.flags & ~Defines.CONFIG_HYBRID_FLAG;
                    }
                    else if (passedInt == 1)
                    {
					    config.flags = config.flags | (Defines.CONFIG_JOINT_OVERRIDE | Defines.CONFIG_JOINT_STEREO);
                    }
                    else
                    {
                        Sys.println("-j0 or -j1 only!");
                        ++error_count;
                    }
                }
                else if (StringTools.startsWith(Sys.args()[arg_idx], "-s") || StringTools.startsWith(Sys.args()[arg_idx], "-S"))
                {
                    var passedDouble:Float= 0; // noise shaping off

                    if (Sys.args()[arg_idx].length > 2) // handle the case where the string is passed in form -s0 (number beside s)
                    {
                        try
                        {
                            var substring:String= Sys.args()[arg_idx].substr(2);
                            passedDouble = Std.parseFloat(substring);
                        }
                        catch (err: Dynamic)
                        {
                        }
                    }
                    else // handle the case where the string is passed in form -s 0 (space between number and s)
                    {
                        arg_idx++;

                        try
                        {
                            passedDouble = Std.parseFloat(Sys.args()[arg_idx]);
                        }
                        catch (err: Dynamic)
                        {
                        }
                    }

                    config.shaping_weight = Math.floor(passedDouble * 1024.0);

                    if (config.shaping_weight == 0)
                    {
                        config.flags = config.flags | Defines.CONFIG_SHAPE_OVERRIDE;
					    config.flags = config.flags & ~Defines.CONFIG_HYBRID_SHAPE;
                    }
                    else if ((config.shaping_weight >= -1024) && (config.shaping_weight <= 1024))
                    {
                        config.flags = config.flags | (Defines.CONFIG_HYBRID_SHAPE | Defines.CONFIG_SHAPE_OVERRIDE);
                    }
                    else
                    {
                        Sys.println("-s-1.00 to -s1.00 only!");
                        ++error_count;
                    }
                }
                else
                {
                    Sys.println("illegal option: " + Sys.args()[arg_idx]);
                    ++error_count;
                }
            }
            else if (infilename.length == 0)
            {
                infilename = Sys.args()[arg_idx];
            }
            else if (outfilename.length == 0)
            {
                outfilename = Sys.args()[arg_idx];
            }
            else if (out2filename.length == 0)
            {
                out2filename = Sys.args()[arg_idx];
            }
            else
            {
                Sys.println("extra unknown argument: " + Sys.args()[arg_idx]);
                ++error_count;
            }

            arg_idx++;
        }

        // check for various command-line argument problems
		if ((~config.flags & (Defines.CONFIG_HIGH_FLAG | Defines.CONFIG_FAST_FLAG)) == 0)
        {
            Sys.println("high and fast modes are mutually exclusive!");
            ++error_count;
        }
        
		if ((config.flags & Defines.CONFIG_HYBRID_FLAG) != 0)
        {
            if(((config.flags & Defines.CONFIG_CREATE_WVC) != 0 ) && (out2filename.length == 0))
            {
                Sys.println("need name for correction file!");
                ++error_count;
            }
        }
        else
        {
		    if((config.flags & (Defines.CONFIG_SHAPE_OVERRIDE | Defines.CONFIG_CREATE_WVC)) != 0)
            {
                Sys.println("-s and -c options are for hybrid mode (-b) only!");
                ++error_count;
            }
        }

        if ((out2filename.length != 0) && ((config.flags & Defines.CONFIG_CREATE_WVC) == 0 ))
        {
            Sys.println("third filename specified without -c option!");
            ++error_count;
        }

        if (error_count == 0)
        {
            Sys.println(sign_on1);
            Sys.println(sign_on2);
        }
        else
        {
            Sys.exit(1);
        }

        if ((infilename.length == 0) || (outfilename.length == 0) || ((out2filename.length == 0) && (config.flags & Defines.CONFIG_CREATE_WVC) != 0 ))
        {
            Sys.println(usage0);
            Sys.println(usage1);
            Sys.println(usage2);
            Sys.println(usage3);
            Sys.println(usage4);
            Sys.println(usage5);
            Sys.println(usage6);
            Sys.println(usage7);
            Sys.println(usage8);
            Sys.println(usage9);
            Sys.println(usage10);
            Sys.println(usage11);
            Sys.println(usage12);

            Sys.exit(1);
        }


        var start : Float = 0;
        var end : Float = 0;

        var currentDate : Date = Date.now();

        start = currentDate.getTime();

        result = pack_file(infilename, outfilename, out2filename, config);

        currentDate = Date.now();
            
        end = currentDate.getTime();

        Sys.println(end - start + " milli seconds to process WavPack file in main loop");


        if (result > 0)
        {
            Sys.println("error occured!");
            ++error_count;
        }
    }

    // This function packs a single file "infilename" and stores the result at
    // "outfilename". If "out2filename" is specified, then the "correction"
    // file would go there. The files are opened and closed in this function
    // and the "config" structure specifies the mode of compression.
    static function pack_file(infilename:String, outfilename:String, out2filename:String,
        config:WavpackConfig):Int {
        var total_samples:Int = 0;
        var bcount:Int;
        var loc_config:WavpackConfig= config;
        var riff_chunk_header:Array < Int >= new Array();
        var chunk_header:Array < Int > = new Array();
        var WaveHeader:Array < Int >= new Array();
        var whBlockAlign:Int= 1;
        var whFormatTag:Int= 0;
        var whSubFormat:Int= 0;
        var whBitsPerSample:Int= 0;
        var whValidBitsPerSample:Int= 0;
        var whNumChannels:Int= 0;
        var whSampleRate:Int= 0;
        var wvc_file;

        var wpc:WavpackContext= new WavpackContext();
        var result:Int;
        
        var din = sys.io.File.read(infilename,true);
        
        var wv_file = sys.io.File.write(outfilename,true);

        wpc.outfile = wv_file;

        bcount = 0;

        // 12 is the size of the RIFF Chunk header
        bcount = DoReadFile(din, riff_chunk_header, 12);

        // ASCII values R = 82, I = 73, F = 70 (RIFF)
        // ASCII values W = 87, A = 65, V = 86, E = 69 (WAVE)
        if ((bcount != 12) || (riff_chunk_header[0] != 82) || (riff_chunk_header[1] != 73) ||
                (riff_chunk_header[2] != 70) || (riff_chunk_header[3] != 70) ||
                (riff_chunk_header[8] != 87) || (riff_chunk_header[9] != 65) ||
                (riff_chunk_header[10] != 86) || (riff_chunk_header[11] != 69))
        {
            Sys.println(infilename + " is not a valid .WAV file!");

            try
            {
                wv_file.close();
            }
            catch (err: Dynamic)
            {
            }

            return Defines.SOFT_ERROR;
        }

        // loop through all elements of the RIFF wav header (until the data chuck)
        var chunkSize:Int= 0;

        while (true)
        {
            // ChunkHeader has a size of 8
            bcount = DoReadFile(din, chunk_header, 8);

            if (bcount != 8)
            {
                Sys.println(infilename + " is not a valid .WAV file!");

                try
                {
                    wv_file.close();
                }
                catch (err: Dynamic)
                {
                }

                return Defines.SOFT_ERROR;
            }

            chunkSize = (chunk_header[4] & 0xFF) + ((chunk_header[5] & 0xFF) << 8) +
                ((chunk_header[6] & 0xFF) << 16) + ((chunk_header[7] & 0xFF) << 24);

            // if it's the format chunk, we want to get some info out of there and
            // make sure it's a .wav file we can handle
            // ASCII values f = 102, m = 109, t = 116, space = 32 ('fmt ')
            if ((chunk_header[0] == 102) && (chunk_header[1] == 109) && (chunk_header[2] == 116) &&
                    (chunk_header[3] == 32))
            {
                var supported:Int= Defines.TRUE;
                var format:Int;
                var check:Int= 0;

                if ((chunkSize >= 16) && (chunkSize <= 40))
                {
                    var ckSize:Int= chunkSize;

                    bcount = DoReadFile(din, WaveHeader, ckSize);

                    if (bcount != ckSize)
                    {
                        check = 1;
                    }
                }
                else
                {
                    check = 1;
                }

                if (check == 1)
                {
                    Sys.println(infilename + " is not a valid .WAV file!");

                    try
                    {
                        wv_file.close();
                    }
                    catch (err: Dynamic)
                    {
                    }

                    return Defines.SOFT_ERROR;
                }

                whFormatTag = (WaveHeader[0] & 0xFF) + ((WaveHeader[1] & 0xFF) << 8);

                if ((whFormatTag == 0xe) && (chunkSize == 40))
                {
                    whSubFormat = (WaveHeader[24] & 0xFF) + ((WaveHeader[25] & 0xFF) << 8);
                    format = whSubFormat;
                }
                else
                {
                    format = whFormatTag;
                }

                whBitsPerSample = (WaveHeader[14] & 0xFF) + ((WaveHeader[15] & 0xFF) << 8);

                if (chunkSize == 40)
                {
                    whValidBitsPerSample = (WaveHeader[18] & 0xFF) +
                        ((WaveHeader[19] & 0xFF) << 8);
                    loc_config.bits_per_sample = whValidBitsPerSample;
                }
                else
                {
                    loc_config.bits_per_sample = whBitsPerSample;
                }

                if (format != 1)
                {            
                    supported = Defines.FALSE;
                }

                whBlockAlign = (WaveHeader[12] & 0xFF) + ((WaveHeader[13] & 0xFF) << 8);
                whNumChannels = (WaveHeader[2] & 0xFF) + ((WaveHeader[3] & 0xFF) << 8);

                if ((whNumChannels == 0) || (whNumChannels > 2) ||
                        ( Math.floor(whBlockAlign / whNumChannels) < Math.floor((loc_config.bits_per_sample + 7) / 8)) ||
                        ( Math.floor(whBlockAlign / whNumChannels) > 3) ||
                        ((whBlockAlign % whNumChannels) > 0))
                {            
                    supported = Defines.FALSE;
                }

                if ((loc_config.bits_per_sample < 1) || (loc_config.bits_per_sample > 24))
                {                
                    supported = Defines.FALSE;
                }

                whSampleRate = (WaveHeader[4] & 0xFF) + ((WaveHeader[5] & 0xFF) << 8) +
                    ((WaveHeader[6] & 0xFF) << 16) + ((WaveHeader[7] & 0xFF) << 24);

                if (supported != Defines.TRUE)
                {
                    Sys.println(infilename + " is an unsupported .WAV format!");

                    try
                    {
                        wv_file.close();
                    }
                    catch (err: Dynamic)
                    {
                    }

                    return Defines.SOFT_ERROR;
                }
            }
            // ASCII values d = 100, a = 97, t = 116
            // looking for string 'data'
            else if ((chunk_header[0] == 100) && (chunk_header[1] == 97) &&
                    (chunk_header[2] == 116) && (chunk_header[3] == 97))
            {
                // on the data chunk, get size and exit loop
                total_samples = Math.floor(chunkSize / whBlockAlign);

                break;
            }
            else
            { // just skip over unknown chunks

                var bytes_to_skip:Int= ((chunkSize + 1) & ~1);
                var buff:Array < Int > = new Array();

                bcount = DoReadFile(din, buff, bytes_to_skip);

                if (bcount != bytes_to_skip)
                {
                    Sys.println("error occurred in skipping bytes");

                    try
                    {
                        wv_file.close();
                    }
                    catch (err: Dynamic)
                    {
                    }

                    //remove (outfilename);
                    return Defines.SOFT_ERROR;
                }
            }
        }

        loc_config.bytes_per_sample = Math.floor(whBlockAlign / whNumChannels);
        loc_config.num_channels = whNumChannels;
        loc_config.sample_rate = whSampleRate;

        WavPackUtils.WavpackSetConfiguration(wpc, loc_config, total_samples);

        // if we are creating a "correction" file, open it now for writing
        if (out2filename.length > 0)
        {
            wvc_file = sys.io.File.write(out2filename,true);
            wpc.correction_outfile = wvc_file;
        }
    
        // pack the audio portion of the file now
        result = pack_audio(wpc, din);

        try
        {
            din.close(); // we're now done with input file, so close
        }
        catch (err: Dynamic)
        {
        }

        // we're now done with any WavPack blocks, so flush any remaining data
        if ((result == Defines.NO_ERROR) && (WavPackUtils.WavpackFlushSamples(wpc) == 0))
        {
            Sys.println(WavPackUtils.WavpackGetErrorMessage(wpc));
            result = Defines.HARD_ERROR;
        }

        // At this point we're done writing to the output files. However, in some
        // situations we might have to back up and re-write the initial blocks.
        // Currently the only case is if we're ignoring length.
        if ((result == Defines.NO_ERROR) &&
                (WavPackUtils.WavpackGetNumSamples(wpc) != WavPackUtils.WavpackGetSampleIndex(wpc)))
        {
            Sys.println("couldn't read all samples, file may be corrupt!!");
            result = Defines.SOFT_ERROR;
        }

        // at this point we're done with the files, so close 'em whether there
        // were any other errors or not
        try
        {
            wv_file.close();
        }
        catch (err: Dynamic)
        {
            Sys.println("Can't close WavPack file!");

            if (result == Defines.NO_ERROR)
            {
                result = Defines.SOFT_ERROR;
            }
        }

        // if there were any errors then return the error
        if (result != Defines.NO_ERROR)
        {
            return result;
        }

        return Defines.NO_ERROR;
    }

    // This function handles the actual audio data compression. It assumes that the
    // input file is positioned at the beginning of the audio data and that the
    // WavPack configuration has been set. This is where the conversion from RIFF
    // little-endian standard the executing processor's format is done.
    static function pack_audio(wpc:WavpackContext, din: haxe.io.Input):Int {
        var samples_remaining:Int;
        var bytes_per_sample:Int;

        WavPackUtils.WavpackPackInit(wpc);

        bytes_per_sample = WavPackUtils.WavpackGetBytesPerSample(wpc) * WavPackUtils.WavpackGetNumChannels(wpc);

        
        samples_remaining = WavPackUtils.WavpackGetNumSamples(wpc);
        

        var input_buffer:Array < Int >= new Array();
        var sample_buffer:Array < Int > = new Array();

        var temp:Int= 0;

        //while (temp < 1)
        while (true)
        {
            var sample_count:Int;
            var bytes_read:Int= 0;
            var bytes_to_read:Int;

            temp = temp + 1;

            if (samples_remaining > Defines.INPUT_SAMPLES)
            {
                bytes_to_read = Defines.INPUT_SAMPLES * bytes_per_sample;
            }
            else
            {
                bytes_to_read = (samples_remaining * bytes_per_sample);
            }

            samples_remaining -= Math.floor(bytes_to_read / bytes_per_sample);
            bytes_read = DoReadFile(din, input_buffer, bytes_to_read);
            sample_count = Math.floor(bytes_read / bytes_per_sample);

            if (sample_count == 0)
            {
                break;
            }

            if (sample_count > 0)
            {
                var cnt:Int= (sample_count * WavPackUtils.WavpackGetNumChannels(wpc));

                var sptr:Array < Int >= input_buffer;

                var loopBps:Int= 0;
                loopBps = WavPackUtils.WavpackGetBytesPerSample(wpc);
                if (loopBps == 1)
                {
                    var internalCount:Int= 0;

                    sample_buffer[cnt-1] = 0;    // initialize array
                    while (cnt > 0)
                    {
                        sample_buffer[internalCount] = (sptr[internalCount] & 0xff) - 128;
                        internalCount++;
                        cnt--;
                    }
                }
                else if (loopBps == 2)
                {
                    var dcounter:Int= 0;
                    var scounter:Int= 0;

                    sample_buffer[cnt-1] = 0;    // initialize array
                    while (cnt > 0)
                    {
                        sample_buffer[dcounter] = (sptr[scounter] & 0xff) | (sptr[scounter + 1] << 8);
                        scounter = scounter + 2;
                        dcounter++;
                        cnt--;
                    }
                }
                else if (loopBps == 3)
                {
                    var dcounter:Int= 0;
                    var scounter:Int= 0;

                    sample_buffer[cnt-1] = 0;    // initialize array
                    while (cnt > 0)
                    {
                        sample_buffer[dcounter] = (sptr[scounter] & 0xff) |
                            ((sptr[scounter + 1] & 0xff) << 8) | (sptr[scounter + 2] << 16);
                        scounter = scounter + 3;
                        dcounter++;
                        cnt--;
                    }
                }
            }

            wpc.byte_idx = 0; // new WAV buffer data so reset the buffer index to zero
            if (WavPackUtils.WavpackPackSamples(wpc, sample_buffer, sample_count) == 0)
            {
                Sys.println(WavPackUtils.WavpackGetErrorMessage(wpc));

                return Defines.HARD_ERROR;
            }
        }
trace("main loop complete");

        if (WavPackUtils.WavpackFlushSamples(wpc) == 0)
        {
            Sys.println(WavPackUtils.WavpackGetErrorMessage(wpc));

            return Defines.HARD_ERROR;
        }

        return Defines.NO_ERROR;
    }

    //////////////////////////// File I/O Wrapper ////////////////////////////////
    static function DoReadFile(hFile:haxe.io.Input, lpBuffer:Array < Int >, nNumberOfBytesToRead:Int):Int {
        var bcount:Int;
        var tempBufferAsBytes = haxe.io.Bytes.alloc(nNumberOfBytesToRead + 1);
        var lpNumberOfBytesRead: Int = 0;
        var tempI : Int = 0;

        
        while (nNumberOfBytesToRead > 0)
        {
            try
            {
                bcount = hFile.readBytes(tempBufferAsBytes, 0, nNumberOfBytesToRead);
            }
            catch (err: Dynamic)
            {
                bcount = 0;
            }

            if (bcount > 0)
            {
                lpBuffer[bcount - 1] = 0;
                for(i in 0 ... bcount)
                {
                    tempI = tempBufferAsBytes.get(i);
                    // the following is a very inelegant way to convert unsigned to signed bytes
                    // must be a better way in haXe!
                    if(tempI > 127)
                    {
                        tempI= tempI - 256;
                    }
                    lpBuffer[i] = tempI;
                    if(i % 1000 == 0)
                    {
//                        Lib.print(".");
                    }
                }

                lpNumberOfBytesRead += bcount;
                nNumberOfBytesToRead -= bcount;
            }
            else
            {
                break;
            }
        }

        return lpNumberOfBytesRead;
    }
}
