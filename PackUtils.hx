/*
** PackUtils.hx
**
** Copyright (c) 2011 Peter McQuillan
**
** All Rights Reserved.
**
** Distributed under the BSD Software License (see license.txt)
**
*/

class PackUtils
{
    //////////////////////////////// local tables ///////////////////////////////
    // These two tables specify the characteristics of the decorrelation filters.
    // Each term represents one layer of the sequential filter, where positive
    // values indicate the relative sample involved from the same channel (1=prev),
    // 17 & 18 are special functions using the previous 2 samples, and negative
    // values indicate cross channel decorrelation (in stereo only).
    static var very_high_terms:Array < Int >= [ 18, 18, 2, 3, -2, 18, 2, 4, 7, 5, 3, 6, 8, -1, 18, 2, 0];
    static var high_terms:Array < Int >= [ 18, 18, 18, -2, 2, 3, 5, -1, 17, 4, 0];
    static var default_terms:Array < Int >= [ 18, 18, 2, 17, 3, 0];
    static var fast_terms:Array < Int >= [ 18, 17, 0];

    ///////////////////////////// executable code ////////////////////////////////
    // This function initializes everything required to pack WavPack bitstreams
    // and must be called BEFORE any other function in this module.
    public static function pack_init(wpc:WavpackContext):Void {
        var wps:WavpackStream= wpc.stream;
        var flags:haxe.Int32= wps.wphdr.flags;
        var term_string:Array<Dynamic>;
        var dpp_idx:Int= 0;
        var ti:Int;
        var zeroCheck : haxe.Int32 = haxe.Int32.ofInt(0);

        wps.sample_index = 0;

        if(haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.HYBRID_SHAPE))) != 0 )
        {
            var weight:Int= wpc.config.shaping_weight;

            if (weight <= -1000)
            {
                weight = -1000;
            }

            wps.dc.shaping_acc[1] = weight << 16;
            wps.dc.shaping_acc[0] = wps.dc.shaping_acc[1];
        }

        if(haxe.Int32.compare(zeroCheck, haxe.Int32.and(wpc.config.flags, haxe.Int32.ofInt(Defines.CONFIG_VERY_HIGH_FLAG))) != 0 )
        {
            term_string = very_high_terms;
        }
        else if(haxe.Int32.compare(zeroCheck, haxe.Int32.and(wpc.config.flags, haxe.Int32.ofInt(Defines.CONFIG_HIGH_FLAG))) != 0 )
        {
            term_string = high_terms;
        }
        else if(haxe.Int32.compare(zeroCheck, haxe.Int32.and(wpc.config.flags, haxe.Int32.ofInt(Defines.CONFIG_FAST_FLAG))) != 0 )
        {
            term_string = fast_terms;
        }
        else
        {
            term_string = default_terms;
        }

        for (ti in 0...(term_string.length - 1))
        {
            if ((term_string[ti] >= 0) || (haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.CROSS_DECORR))) != 0 ))
            {
                wps.decorr_passes[dpp_idx].term = term_string[ti];

                wps.decorr_passes[dpp_idx].delta = 2;
                dpp_idx++;
            }
            else if(haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.MONO_FLAG))) == 0 )
            {
                wps.decorr_passes[dpp_idx].term = -3;

                wps.decorr_passes[dpp_idx].delta = 2;
                dpp_idx++;
            }
        }

        wps.num_terms = dpp_idx;

        WordsUtils.init_words(wps);
    }

    // Allocate room for and copy the decorrelation terms from the decorr_passes
    // array into the specified metadata structure. Both the actual term id and
    // the delta are packed into single characters.
    static function write_decorr_terms(wps:WavpackStream, wpmd:WavpackMetadata):Void {
        var tcount:Int;
        var byteptr:Array<Int> = new Array();
        var byte_idx:Int= 0;
        var dpp_idx:Int= 0;

        wpmd.id = Defines.ID_DECORR_TERMS;

        tcount = wps.num_terms;    
        while (tcount > 0)
        {
            byteptr[byte_idx] = ((((wps.decorr_passes[dpp_idx].term + 5) & 0x1f) | ((wps.decorr_passes[dpp_idx].delta << 5) & 0xe0)));
            byte_idx++;
            tcount--;
            ++dpp_idx;
        }

        wpmd.byte_length = byte_idx;
        wpmd.data = byteptr;
    }

    // Allocate room for and copy the decorrelation term weights from the
    // decorr_passes array into the specified metadata structure. The weights
    // range +/-1024, but are rounded and truncated to fit in signed chars for
    // metadata storage. Weights are separate for the two channels
    static function write_decorr_weights(wps:WavpackStream, wpmd:WavpackMetadata):Void {
        var tcount:Int;
        var i:Int;
        var byteptr:Array<Int> = new Array();
        var byte_idx:Int= 0;
        var zeroCheck : haxe.Int32 = haxe.Int32.ofInt(0);

        wpmd.id = Defines.ID_DECORR_WEIGHTS;

        i = wps.num_terms - 1;
        while (i >= 0)
        {
            if ((WordsUtils.store_weight(wps.decorr_passes[i].weight_A) != 0) ||
                    ((haxe.Int32.compare(zeroCheck, haxe.Int32.and(wps.wphdr.flags, haxe.Int32.ofInt(Defines.MONO_FLAG | Defines.FALSE_STEREO))) == 0 ) &&
                    (WordsUtils.store_weight(wps.decorr_passes[i].weight_B) != 0)))
            {
                break;
            }
            --i;
        }

        tcount = i + 1;

        for (i in 0...wps.num_terms)
        {
            if (i < tcount)
            {
                byteptr[byte_idx] = WordsUtils.store_weight(wps.decorr_passes[i].weight_A);
                wps.decorr_passes[i].weight_A = WordsUtils.restore_weight(byteptr[byte_idx]);
                byte_idx++;

                if(haxe.Int32.compare(zeroCheck, haxe.Int32.and(wps.wphdr.flags, haxe.Int32.ofInt(Defines.MONO_FLAG | Defines.FALSE_STEREO))) == 0 )
                {
                    byteptr[byte_idx] = WordsUtils.store_weight(wps.decorr_passes[i].weight_B);
                    wps.decorr_passes[i].weight_B = WordsUtils.restore_weight(byteptr[byte_idx]);
                    byte_idx++;
                }
            }
            else
            {
                wps.decorr_passes[i].weight_A = wps.decorr_passes[i].weight_B = 0;
            }
        }

        wpmd.byte_length = byte_idx;
        wpmd.data = byteptr;
    }

    // Allocate room for and copy the decorrelation samples from the decorr_passes
    // array into the specified metadata structure. The samples are signed 32-bit
    // values, but are converted to signed log2 values for storage in metadata.
    // Values are stored for both channels and are specified from the first term
    // with unspecified samples set to zero. The number of samples stored varies
    // with the actual term value, so those must obviously be specified before
    // these in the metadata list. Any number of terms can have their samples
    // specified from no terms to all the terms, however I have found that
    // sending more than the first term's samples is a waste. The "wcount"
    // variable can be set to the number of terms to have their samples stored.
    static function write_decorr_samples(wps:WavpackStream, wpmd:WavpackMetadata):Void {
        var tcount:Int;
        var wcount:Int= 1;
        var temp:Int;
        var byteptr:Array<Int> = new Array();
        var byte_idx:Int= 0;
        var dpp_idx:Int= 0;
        var zeroCheck : haxe.Int32 = haxe.Int32.ofInt(0);

        wpmd.id = Defines.ID_DECORR_SAMPLES;

        tcount = wps.num_terms;
        while (tcount > 0)
        {
            if (wcount != 0)
            {
                if (wps.decorr_passes[dpp_idx].term > Defines.MAX_TERM)
                {
                    wps.decorr_passes[dpp_idx].samples_A[0] = WordsUtils.exp2s(temp = WordsUtils.log2s(
                                    wps.decorr_passes[dpp_idx].samples_A[0]));
                                    
                    byteptr[byte_idx] = temp & 0xFF;
                    if(byteptr[byte_idx] > 127)
                    {
                        byteptr[byte_idx] = byteptr[byte_idx] - 256;
                    }
                    
                    byte_idx++;
                    byteptr[byte_idx] = (temp >> 8) & 0xFF;
                    if(byteptr[byte_idx] > 127)
                    {
                        byteptr[byte_idx] = byteptr[byte_idx] - 256;
                    }                    
                    
                    byte_idx++;
                    wps.decorr_passes[dpp_idx].samples_A[1] = WordsUtils.exp2s(temp = WordsUtils.log2s(
                                    wps.decorr_passes[dpp_idx].samples_A[1]));
                    byteptr[byte_idx] = temp & 0xFF;
                    if(byteptr[byte_idx] > 127)
                    {
                        byteptr[byte_idx] = byteptr[byte_idx] - 256;
                    }
                    byte_idx++;
                    byteptr[byte_idx] = (temp >> 8) & 0xFF;
                    if(byteptr[byte_idx] > 127)
                    {
                        byteptr[byte_idx] = byteptr[byte_idx] - 256;
                    }    
                    byte_idx++;

                    if(haxe.Int32.compare(zeroCheck, haxe.Int32.and(wps.wphdr.flags, haxe.Int32.ofInt(Defines.MONO_FLAG | Defines.FALSE_STEREO))) == 0 )
                    {
                        wps.decorr_passes[dpp_idx].samples_B[0] = WordsUtils.exp2s(temp = WordsUtils.log2s(
                                        wps.decorr_passes[dpp_idx].samples_B[0]));
                        byteptr[byte_idx] = temp & 0xFF;
                        if(byteptr[byte_idx] > 127)
                        {
                            byteptr[byte_idx] = byteptr[byte_idx] - 256;
                        }
                        byte_idx++;
                        byteptr[byte_idx] = (temp >> 8) & 0xFF;
                        if(byteptr[byte_idx] > 127)
                        {
                            byteptr[byte_idx] = byteptr[byte_idx] - 256;
                        }
                        byte_idx++;
                        wps.decorr_passes[dpp_idx].samples_B[1] = WordsUtils.exp2s(temp = WordsUtils.log2s(
                                        wps.decorr_passes[dpp_idx].samples_B[1]));
                        byteptr[byte_idx] = temp & 0xFF;
                        if(byteptr[byte_idx] > 127)
                        {
                            byteptr[byte_idx] = byteptr[byte_idx] - 256;
                        }
                        byte_idx++;
                        byteptr[byte_idx] = (temp >> 8) & 0xFF;
                        if(byteptr[byte_idx] > 127)
                        {
                            byteptr[byte_idx] = byteptr[byte_idx] - 256;
                        }
                        byte_idx++;
                    }
                }
                else if (wps.decorr_passes[dpp_idx].term < 0)
                {
                    wps.decorr_passes[dpp_idx].samples_A[0] = WordsUtils.exp2s(temp = WordsUtils.log2s(
                                    wps.decorr_passes[dpp_idx].samples_A[0]));
                    byteptr[byte_idx] = temp & 0xFF;
                    if(byteptr[byte_idx] > 127)
                    {
                        byteptr[byte_idx] = byteptr[byte_idx] - 256;
                    }
                    byte_idx++;
                    byteptr[byte_idx] = (temp >> 8) & 0xFF;
                    if(byteptr[byte_idx] > 127)
                    {
                        byteptr[byte_idx] = byteptr[byte_idx] - 256;
                    }
                    byte_idx++;
                    wps.decorr_passes[dpp_idx].samples_B[0] = WordsUtils.exp2s(temp = WordsUtils.log2s(
                                    wps.decorr_passes[dpp_idx].samples_B[0]));
                    byteptr[byte_idx] = temp & 0xFF;
                    if(byteptr[byte_idx] > 127)
                    {
                        byteptr[byte_idx] = byteptr[byte_idx] - 256;
                    }
                    byte_idx++;
                    byteptr[byte_idx] = (temp >> 8) & 0xFF;
                    if(byteptr[byte_idx] > 127)
                    {
                        byteptr[byte_idx] = byteptr[byte_idx] - 256;
                    }
                    byte_idx++;
                }
                else
                {
                    var m:Int= 0;
                    var cnt:Int= wps.decorr_passes[dpp_idx].term;

                    while (cnt > 0)
                    {
                        wps.decorr_passes[dpp_idx].samples_A[m] = WordsUtils.exp2s(temp = WordsUtils.log2s(
                                        wps.decorr_passes[dpp_idx].samples_A[m]));
                        byteptr[byte_idx] = (temp);
                        byte_idx++;
                        byteptr[byte_idx] = ((temp >> 8));
                        byte_idx++;

                        if(haxe.Int32.compare(zeroCheck, haxe.Int32.and(wps.wphdr.flags, haxe.Int32.ofInt(Defines.MONO_FLAG | Defines.FALSE_STEREO))) == 0 )
                        {
                            wps.decorr_passes[dpp_idx].samples_B[m] = WordsUtils.exp2s(temp = WordsUtils.log2s(
                                            wps.decorr_passes[dpp_idx].samples_B[m]));
                            byteptr[byte_idx] = temp & 0xFF;
                            if(byteptr[byte_idx] > 127)
                            {
                                byteptr[byte_idx] = byteptr[byte_idx] - 256;
                            }
                            byte_idx++;
                            byteptr[byte_idx] = (temp >> 8) & 0xFF;
                            if(byteptr[byte_idx] > 127)
                            {
                                byteptr[byte_idx] = byteptr[byte_idx] - 256;
                            }
                            byte_idx++;
                        }

                        m++;
                        cnt--;
                    }
                }

                wcount--;
            }
            else
            {
                for (internalc in 0...Defines.MAX_TERM)
                {
                    wps.decorr_passes[dpp_idx].samples_A[internalc] = 0;
                    wps.decorr_passes[dpp_idx].samples_B[internalc] = 0;
                }
            }

            dpp_idx++;
            tcount--;
           }

        wpmd.byte_length = byte_idx;
        wpmd.data = byteptr;
    }

    // Allocate room for and copy the noise shaping info into the specified
    // metadata structure. These would normally be written to the
    // "correction" file and are used for lossless reconstruction of
    // hybrid data. The "delta" parameter is not yet used in encoding as it
    // will be part of the "quality" mode.
    static function write_shaping_info(wps:WavpackStream, wpmd:WavpackMetadata):Void {
        var byteptr:Array<Int> = new Array();
        var byte_idx:Int= 0;
        var temp:Int;
        var zeroCheck : haxe.Int32 = haxe.Int32.ofInt(0);

        wpmd.id = Defines.ID_SHAPING_WEIGHTS;

        wps.dc.error[0] = WordsUtils.exp2s(temp = WordsUtils.log2s(wps.dc.error[0]));
        byteptr[byte_idx] =(temp);
        byte_idx++;
        byteptr[byte_idx] = ((temp >> 8));
        byte_idx++;
        wps.dc.shaping_acc[0] = WordsUtils.exp2s(temp = WordsUtils.log2s(wps.dc.shaping_acc[0]));
        byteptr[byte_idx] = (temp);
        byte_idx++;
        byteptr[byte_idx] = ((temp >> 8));
        byte_idx++;

        if(haxe.Int32.compare(zeroCheck, haxe.Int32.and(wps.wphdr.flags, haxe.Int32.ofInt(Defines.MONO_FLAG | Defines.FALSE_STEREO))) == 0 )
        {
            wps.dc.error[1] = WordsUtils.exp2s(temp = WordsUtils.log2s(wps.dc.error[1]));
            byteptr[byte_idx] = (temp);
            byte_idx++;
            byteptr[byte_idx] = ((temp >> 8));
            byte_idx++;
            wps.dc.shaping_acc[1] = WordsUtils.exp2s(temp = WordsUtils.log2s(wps.dc.shaping_acc[1]));
            byteptr[byte_idx] = (temp);
            byte_idx++;
            byteptr[byte_idx] = ((temp >> 8));
            byte_idx++;
        }

        if ((wps.dc.shaping_delta[0] | wps.dc.shaping_delta[1]) != 0)
        {
            wps.dc.shaping_delta[0] = WordsUtils.exp2s(temp = WordsUtils.log2s(
                            wps.dc.shaping_delta[0]));
            byteptr[byte_idx] = (temp);
            byte_idx++;
            byteptr[byte_idx] = ((temp >> 8));
            byte_idx++;

        if(haxe.Int32.compare(zeroCheck, haxe.Int32.and(wps.wphdr.flags, haxe.Int32.ofInt(Defines.MONO_FLAG | Defines.FALSE_STEREO))) == 0 )
            {
                wps.dc.shaping_delta[1] = WordsUtils.exp2s(temp = WordsUtils.log2s(
                                wps.dc.shaping_delta[1]));
                byteptr[byte_idx] = (temp);
                byte_idx++;
                byteptr[byte_idx] = ((temp >> 8));
                byte_idx++;
            }
        }

        wpmd.byte_length = byte_idx;
        wpmd.data = byteptr;
    }

    // Allocate room for and copy the configuration information into the specified
    // metadata structure. Currently, we just store the upper 3 bytes of
    // config.flags and only in the first block of audio data. Note that this is
    // for informational purposes not required for playback or decoding (like
    // whether high or fast mode was specified).
    static function write_config_info(wpc:WavpackContext, wpmd:WavpackMetadata):Void {
        var byteptr:Array<Int> = new Array();
        var byte_idx:Int= 0;

        wpmd.id = Defines.ID_CONFIG_BLOCK;

        byteptr[byte_idx] = ((haxe.Int32.toInt(wpc.config.flags) >> 8));
        byte_idx++;
        byteptr[byte_idx] = ((haxe.Int32.toInt(wpc.config.flags) >> 16));
        byte_idx++;
        byteptr[byte_idx] = ((haxe.Int32.toInt(wpc.config.flags) >> 24));
        byte_idx++;

        wpmd.byte_length = byte_idx;
        wpmd.data = byteptr;
    }

    // Allocate room for and copy the non-standard sampling rateinto the specified
    // metadata structure. We just store the lower 3 bytes of the sampling rate.
    // Note that this would only be used when the sampling rate was not included
    // in the table of 15 "standard" values.
    static function write_sample_rate(wpc:WavpackContext, wpmd:WavpackMetadata):Void {
        var byteptr:Array<Int> = new Array();
        var byte_idx:Int= 0;

        wpmd.id = Defines.ID_SAMPLE_RATE;
        byteptr[byte_idx] = ((wpc.config.sample_rate));
        byte_idx++;
        byteptr[byte_idx] = ((wpc.config.sample_rate >> 8));
        byte_idx++;
        byteptr[byte_idx] = ((wpc.config.sample_rate >> 16));
        byte_idx++;

        wpmd.data = byteptr;
        wpmd.byte_length = byte_idx;
    }

    public static function pack_start_block(wpc:WavpackContext):Int {
        var wps:WavpackStream= wpc.stream;
        var flags:haxe.Int32= wps.wphdr.flags;
        var wpmd:WavpackMetadata= new WavpackMetadata();
        var i:Int= 0;
        var chunkSize:Int;
        var zeroCheck : haxe.Int32 = haxe.Int32.ofInt(0);


        wps.lossy_block = Defines.FALSE;
        wps.wphdr.crc = 0xffffffff;
        wps.wphdr.block_samples = 0;
        wps.wphdr.ckSize = Defines.WAVPACK_HEADER_SIZE - 8;

        wps.blockbuff[0] = (wps.wphdr.ckID[0]);
        wps.blockbuff[1] = (wps.wphdr.ckID[1]);
        wps.blockbuff[2] = (wps.wphdr.ckID[2]);
        wps.blockbuff[3] = (wps.wphdr.ckID[3]);
        wps.blockbuff[4] = ((wps.wphdr.ckSize));
        wps.blockbuff[5] = ((wps.wphdr.ckSize >> 8));
        wps.blockbuff[6] = ((wps.wphdr.ckSize >>> 16));
        wps.blockbuff[7] = ((wps.wphdr.ckSize >>> 24));
        wps.blockbuff[8] = ((wps.wphdr.version));
        wps.blockbuff[9] = ((wps.wphdr.version >>> 8));
        wps.blockbuff[10] = ((wps.wphdr.track_no));
        wps.blockbuff[11] = ((wps.wphdr.index_no));
        wps.blockbuff[12] = ((wps.wphdr.total_samples));
        wps.blockbuff[13] = ((wps.wphdr.total_samples >>> 8));
        wps.blockbuff[14] = ((wps.wphdr.total_samples >>> 16));
        wps.blockbuff[15] = ((wps.wphdr.total_samples >>> 24));
        wps.blockbuff[16] = ((wps.wphdr.block_index));
        wps.blockbuff[17] = ((wps.wphdr.block_index >>> 8));
        wps.blockbuff[18] = ((wps.wphdr.block_index >>> 16));
        wps.blockbuff[19] = ((wps.wphdr.block_index >>> 24));
        wps.blockbuff[20] = ((wps.wphdr.block_samples));
        wps.blockbuff[21] = ((wps.wphdr.block_samples >>> 8));
        wps.blockbuff[22] = ((wps.wphdr.block_samples >>> 16));
        wps.blockbuff[23] = ((wps.wphdr.block_samples >>> 24));
        wps.blockbuff[24] = ((haxe.Int32.toInt(wps.wphdr.flags)));
        wps.blockbuff[25] = ((haxe.Int32.toInt(wps.wphdr.flags) >>> 8));
        wps.blockbuff[26] = ((haxe.Int32.toInt(wps.wphdr.flags) >>> 16));
        wps.blockbuff[27] = ((haxe.Int32.toInt(wps.wphdr.flags) >>> 24));
        wps.blockbuff[28] = ((wps.wphdr.crc));
        wps.blockbuff[29] = ((wps.wphdr.crc >>> 8));
        wps.blockbuff[30] = ((wps.wphdr.crc >>> 16));
        wps.blockbuff[31] = ((wps.wphdr.crc >>> 24));
        
        write_decorr_terms(wps, wpmd);
        copy_metadata(wpmd, wps.blockbuff, wps.blockend);        

        write_decorr_weights(wps, wpmd);
        copy_metadata(wpmd, wps.blockbuff, wps.blockend);

        write_decorr_samples(wps, wpmd);
        copy_metadata(wpmd, wps.blockbuff, wps.blockend);

        WordsUtils.write_entropy_vars(wps, wpmd);
        copy_metadata(wpmd, wps.blockbuff, wps.blockend);

        if (((haxe.Int32.toInt(flags) & Defines.SRATE_MASK) == Defines.SRATE_MASK) &&
                (wpc.config.sample_rate != 44100))
        {
            write_sample_rate(wpc, wpmd);
            copy_metadata(wpmd, wps.blockbuff, wps.blockend);
        }

        if(haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.HYBRID_FLAG))) != 0 )
        {
            WordsUtils.write_hybrid_profile(wps, wpmd);
            copy_metadata(wpmd, wps.blockbuff, wps.blockend);
        }

        if((haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.INITIAL_BLOCK))) != 0 ) && (wps.sample_index == 0))
        {
            write_config_info(wpc, wpmd);
            copy_metadata(wpmd, wps.blockbuff, wps.blockend);
        }

        chunkSize = (wps.blockbuff[4] & 0xff) + ((wps.blockbuff[5] & 0xff) << 8) +
            ((wps.blockbuff[6] & 0xff) << 16) + ((wps.blockbuff[7] & 0xff) << 24);
        BitsUtils.bs_open_write(wps.wvbits, ((chunkSize + 12)), wps.blockend);

        if (wpc.wvc_flag != 0)
        {
            wps.block2buff[0] = (wps.wphdr.ckID[0]);
            wps.block2buff[1] = (wps.wphdr.ckID[1]);
            wps.block2buff[2] = (wps.wphdr.ckID[2]);
            wps.block2buff[3] = (wps.wphdr.ckID[3]);
            wps.block2buff[4] = ((wps.wphdr.ckSize));
            wps.block2buff[5] = ((wps.wphdr.ckSize >>> 8));
            wps.block2buff[6] = ((wps.wphdr.ckSize >>> 16));
            wps.block2buff[7] = ((wps.wphdr.ckSize >>> 24));
            wps.block2buff[8] = ((wps.wphdr.version));
            wps.block2buff[9] = ((wps.wphdr.version >>> 8));
            wps.block2buff[10] = ((wps.wphdr.track_no));
            wps.block2buff[11] = ((wps.wphdr.index_no));
            wps.block2buff[12] = ((wps.wphdr.total_samples));
            wps.block2buff[13] = ((wps.wphdr.total_samples >>> 8));
            wps.block2buff[14] = ((wps.wphdr.total_samples >>> 16));
            wps.block2buff[15] = ((wps.wphdr.total_samples >>> 24));
            wps.block2buff[16] = ((wps.wphdr.block_index));
            wps.block2buff[17] = ((wps.wphdr.block_index >>> 8));
            wps.block2buff[18] = ((wps.wphdr.block_index >>> 16));
            wps.block2buff[19] = ((wps.wphdr.block_index >>> 24));
            wps.block2buff[20] = ((wps.wphdr.block_samples));
            wps.block2buff[21] = ((wps.wphdr.block_samples >>> 8));
            wps.block2buff[22] = ((wps.wphdr.block_samples >>> 16));
            wps.block2buff[23] = ((wps.wphdr.block_samples >>> 24));
            wps.block2buff[24] = ((haxe.Int32.toInt(wps.wphdr.flags)));
            wps.block2buff[25] = ((haxe.Int32.toInt(wps.wphdr.flags) >>> 8));
            wps.block2buff[26] = ((haxe.Int32.toInt(wps.wphdr.flags) >>> 16));
            wps.block2buff[27] = ((haxe.Int32.toInt(wps.wphdr.flags) >>> 24));
            wps.block2buff[28] = ((wps.wphdr.crc));
            wps.block2buff[29] = ((wps.wphdr.crc >>> 8));
            wps.block2buff[30] = ((wps.wphdr.crc >>> 16));
            wps.block2buff[31] = ((wps.wphdr.crc >>> 24));

            if(haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.HYBRID_SHAPE))) != 0 )
            {
                write_shaping_info(wps, wpmd);
                copy_metadata(wpmd, wps.block2buff, wps.block2end);
            }

            chunkSize = (wps.block2buff[4] & 0xff) + ((wps.block2buff[5] & 0xff) << 8) +
                ((wps.block2buff[6] & 0xff) << 16) + ((wps.block2buff[7] & 0xff) << 24);

            BitsUtils.bs_open_write(wps.wvcbits, ((chunkSize + 12)), wps.block2end);
        }

        return Defines.TRUE;
    }

    // Pack the given samples into the block currently being assembled. This function
    // checks the available space each sample so that it can return prematurely to
    // indicate that the blocks must be terminated. The return value is the number
    // of actual samples packed and will be the same as the provided sample_count
    // in no error occurs.
    public static function pack_samples(wpc:WavpackContext, buffer:Array<Int>, sample_count:Int):Int {
        var wps:WavpackStream= wpc.stream;

        var flags:haxe.Int32= wps.wphdr.flags;
        var tcount:Int;
        var lossy:Int= 0;
        var m:Int;
        var byte_idx:Int= 0;
        var dpp_idx:Int= 0;
        var crc : haxe.Int32 = haxe.Int32.ofInt(0);
        var crc2 : haxe.Int32 = haxe.Int32.ofInt(0);
        var i:Int;
        var bptr:Array<Int>;
        var block_samples:Int;
        var zeroCheck : haxe.Int32 = haxe.Int32.ofInt(0);

        if (sample_count == 0)
        {
            return 0;
        }

        byte_idx = wpc.byte_idx; // Get the index position for the buffer holding the input WAV data

        i = 0;

        block_samples = (((wps.blockbuff[23] & 0xFF) << 24));
        block_samples += (((wps.blockbuff[22] & 0xFF) << 16));
        block_samples += (((wps.blockbuff[21] & 0xFF) << 8));
        block_samples += ((wps.blockbuff[20] & 0xFF));
        m = ((block_samples & (Defines.MAX_TERM - 1)));

        crc = haxe.Int32.shl(haxe.Int32.ofInt(wps.blockbuff[31] & 0xFF),24);
        crc = haxe.Int32.add(crc, haxe.Int32.shl(haxe.Int32.ofInt(wps.blockbuff[30] & 0xFF),16));
        crc = haxe.Int32.add(crc, haxe.Int32.shl(haxe.Int32.ofInt(wps.blockbuff[29] & 0xFF),8));
        crc = haxe.Int32.add(crc, haxe.Int32.ofInt(wps.blockbuff[28] & 0xFF));

        crc2 = haxe.Int32.ofInt(0);

        if (wpc.wvc_flag != 0)
        {
            crc2 = haxe.Int32.shl(haxe.Int32.ofInt(wps.block2buff[31] & 0xFF),24);
            crc2 = haxe.Int32.add(crc2, haxe.Int32.shl(haxe.Int32.ofInt(wps.block2buff[30] & 0xFF),16));
            crc2 = haxe.Int32.add(crc2, haxe.Int32.shl(haxe.Int32.ofInt(wps.block2buff[29] & 0xFF),8));
            crc2 = haxe.Int32.add(crc2, haxe.Int32.ofInt(wps.block2buff[28] & 0xFF));
        }

        bptr = new Array();
        
        /////////////////////// handle lossless mono mode /////////////////////////
        if((haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.HYBRID_FLAG))) == 0 ) && 
            (haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.MONO_FLAG | Defines.FALSE_STEREO))) != 0 ) )
        {            
            bptr = buffer;

            
            for (internalCounter in 0...sample_count)
            {
                var code:Int = 0;

                if (BitsUtils.bs_remain_write(wps.wvbits) < 64)
                {
                    break;
                }

                code = bptr[byte_idx];        
                crc = haxe.Int32.add(haxe.Int32.mul(crc, haxe.Int32.ofInt(3)),  haxe.Int32.ofInt(code));    
                
                byte_idx++;

                dpp_idx = 0;

                tcount = wps.num_terms;
                while (tcount > 0)
                {
                    var sam:Int;

                    if (wps.decorr_passes[dpp_idx].term > Defines.MAX_TERM)
                    {
                        if ((wps.decorr_passes[dpp_idx].term & 1) != 0)
                        {
                            sam = (2* wps.decorr_passes[dpp_idx].samples_A[0]) -
                                wps.decorr_passes[dpp_idx].samples_A[1];
                        }
                        else
                        {
                            sam = ((3* wps.decorr_passes[dpp_idx].samples_A[0]) -
                                wps.decorr_passes[dpp_idx].samples_A[1]) >> 1;
                        }

                        wps.decorr_passes[dpp_idx].samples_A[1] = wps.decorr_passes[dpp_idx].samples_A[0];
                        wps.decorr_passes[dpp_idx].samples_A[0] = code;
                    }
                    else
                    {
                        sam = wps.decorr_passes[dpp_idx].samples_A[m];

                        wps.decorr_passes[dpp_idx].samples_A[(m + wps.decorr_passes[dpp_idx].term) &
                        (Defines.MAX_TERM - 1)] = code;
                    }

                    code -= apply_weight(wps.decorr_passes[dpp_idx].weight_A, sam);
                    wps.decorr_passes[dpp_idx].weight_A = update_weight(wps.decorr_passes[dpp_idx].weight_A,
                            wps.decorr_passes[dpp_idx].delta, sam, code);

                    dpp_idx++;
                    tcount--;
                   }

                m = (m + 1) & (Defines.MAX_TERM - 1);
                WordsUtils.send_word_lossless(wps, code, 0);
                i++;
            }
            

            wpc.byte_idx = byte_idx;
        }

        //////////////////// handle the lossless stereo mode //////////////////////
        else if((haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.HYBRID_FLAG))) == 0 ) && 
            (haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.MONO_FLAG | Defines.FALSE_STEREO))) == 0 ) )
        {    

            bptr = buffer;    
    
            for (internalCounter in 0...sample_count)
            {
                var left:Int;
                var right:Int;
                var sam_A:Int;
                var sam_B:Int;

                if (BitsUtils.bs_remain_write(wps.wvbits) < 128)
                {
                    break;
                }

                left = bptr[byte_idx];
                crc = haxe.Int32.add(haxe.Int32.mul(crc, haxe.Int32.ofInt(3)),  haxe.Int32.ofInt(left));
                right = bptr[byte_idx + 1];
                crc = haxe.Int32.add(haxe.Int32.mul(crc, haxe.Int32.ofInt(3)),  haxe.Int32.ofInt(right));   
                
                byte_idx = byte_idx + 2;
                
                if(haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.JOINT_STEREO))) != 0 )
                {
                    right += ((left -= right) >> 1);
                }

                dpp_idx = 0;

                tcount = wps.num_terms;
                while (tcount > 0)
                {
                    if (wps.decorr_passes[dpp_idx].term > 0)
                    {
                        if (wps.decorr_passes[dpp_idx].term > Defines.MAX_TERM)
                        {
                            if ((wps.decorr_passes[dpp_idx].term & 1) != 0)
                            {
                                sam_A = (2* wps.decorr_passes[dpp_idx].samples_A[0]) -
                                    wps.decorr_passes[dpp_idx].samples_A[1];
                                sam_B = (2* wps.decorr_passes[dpp_idx].samples_B[0]) -
                                    wps.decorr_passes[dpp_idx].samples_B[1];
                            }
                            else
                            {
                                sam_A = ((3* wps.decorr_passes[dpp_idx].samples_A[0]) -
                                    wps.decorr_passes[dpp_idx].samples_A[1]) >> 1;
                                sam_B = ((3* wps.decorr_passes[dpp_idx].samples_B[0]) -
                                    wps.decorr_passes[dpp_idx].samples_B[1]) >> 1;
                            }

                            wps.decorr_passes[dpp_idx].samples_A[1] = wps.decorr_passes[dpp_idx].samples_A[0];
                            wps.decorr_passes[dpp_idx].samples_B[1] = wps.decorr_passes[dpp_idx].samples_B[0];
                            wps.decorr_passes[dpp_idx].samples_A[0] = left;
                            wps.decorr_passes[dpp_idx].samples_B[0] = right;
                        }
                        else
                        {
                            var k:Int= (m + wps.decorr_passes[dpp_idx].term) & (Defines.MAX_TERM - 1);

                            sam_A = wps.decorr_passes[dpp_idx].samples_A[m];
                            sam_B = wps.decorr_passes[dpp_idx].samples_B[m];
                            wps.decorr_passes[dpp_idx].samples_A[k] = left;
                            wps.decorr_passes[dpp_idx].samples_B[k] = right;
                        }

                        left -= apply_weight(wps.decorr_passes[dpp_idx].weight_A, sam_A);
                        right -= apply_weight(wps.decorr_passes[dpp_idx].weight_B, sam_B);
                        wps.decorr_passes[dpp_idx].weight_A = update_weight(wps.decorr_passes[dpp_idx].weight_A,
                                wps.decorr_passes[dpp_idx].delta, sam_A, left);
                        wps.decorr_passes[dpp_idx].weight_B = update_weight(wps.decorr_passes[dpp_idx].weight_B,
                                wps.decorr_passes[dpp_idx].delta, sam_B, right);
                    }
                    else
                    {
                        sam_A = (wps.decorr_passes[dpp_idx].term == -2) ? right
                                                                        : wps.decorr_passes[dpp_idx].samples_A[0];
                        sam_B = (wps.decorr_passes[dpp_idx].term == -1) ? left
                                                                        : wps.decorr_passes[dpp_idx].samples_B[0];
                        wps.decorr_passes[dpp_idx].samples_A[0] = right;
                        wps.decorr_passes[dpp_idx].samples_B[0] = left;
                        left -= apply_weight(wps.decorr_passes[dpp_idx].weight_A, sam_A);
                        right -= apply_weight(wps.decorr_passes[dpp_idx].weight_B, sam_B);
                        wps.decorr_passes[dpp_idx].weight_A = update_weight_clip(wps.decorr_passes[dpp_idx].weight_A,
                                wps.decorr_passes[dpp_idx].delta, sam_A, left);
                        wps.decorr_passes[dpp_idx].weight_B = update_weight_clip(wps.decorr_passes[dpp_idx].weight_B,
                                wps.decorr_passes[dpp_idx].delta, sam_B, right);
                    }

                    dpp_idx++;
                    tcount--;
                   }

                m = (m + 1) & (Defines.MAX_TERM - 1);
                WordsUtils.send_word_lossless(wps, left, 0);
                WordsUtils.send_word_lossless(wps, right, 1);
                
                i++;
            }

            
            wpc.byte_idx = byte_idx;
        }

        /////////////////// handle the lossy/hybrid mono mode /////////////////////
        else if((haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.HYBRID_FLAG))) != 0 ) && 
            (haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.MONO_FLAG | Defines.FALSE_STEREO))) != 0 ) )
        {
            bptr = buffer;
            for (internalCounter in 0...sample_count)
            {
                var code:Int;
                var temp:Int;

                if ((BitsUtils.bs_remain_write(wps.wvbits) < 64) ||
                        ((wpc.wvc_flag != 0) && (BitsUtils.bs_remain_write(wps.wvcbits) < 64)))
                {
                    break;
                }

                code = bptr[byte_idx];
                crc2 = haxe.Int32.add(haxe.Int32.mul(crc2, haxe.Int32.ofInt(3)),  haxe.Int32.ofInt(code));
                byte_idx++;

                if(haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.HYBRID_SHAPE))) != 0 )
                {
                    wps.dc.shaping_acc[0] += wps.dc.shaping_delta[0];
                    var shaping_weight:Int= (wps.dc.shaping_acc[0] ) >> 16;
                    temp = -apply_weight(shaping_weight, wps.dc.error[0]);

                    if((haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.NEW_SHAPING))) != 0 ) && (shaping_weight < 0) &&
                            (temp != 0))
                    {
                        if (temp == wps.dc.error[0])
                        {
                            temp = (temp < 0) ? (temp + 1) : (temp - 1);
                        }

                        wps.dc.error[0] = -code;
                        code += temp;
                    }
                    else
                    {
                        wps.dc.error[0] = -(code += temp);
                    }
                }

                dpp_idx = 0;

                tcount = wps.num_terms;
                while (tcount > 0)
                {
                    if (wps.decorr_passes[dpp_idx].term > Defines.MAX_TERM)
                    {
                        if ((wps.decorr_passes[dpp_idx].term & 1) != 0)
                        {
                            wps.decorr_passes[dpp_idx].samples_A[2] = (2* wps.decorr_passes[dpp_idx].samples_A[0]) -
                                wps.decorr_passes[dpp_idx].samples_A[1];
                        }
                        else
                        {
                            wps.decorr_passes[dpp_idx].samples_A[2] = ((3* wps.decorr_passes[dpp_idx].samples_A[0]) -
                                wps.decorr_passes[dpp_idx].samples_A[1]) >> 1;
                        }

                        code -= (wps.decorr_passes[dpp_idx].aweight_A = apply_weight(wps.decorr_passes[dpp_idx].weight_A,
                                wps.decorr_passes[dpp_idx].samples_A[2]));
                    }
                    else
                    {
                        code -= (wps.decorr_passes[dpp_idx].aweight_A = apply_weight(wps.decorr_passes[dpp_idx].weight_A,
                                wps.decorr_passes[dpp_idx].samples_A[m]));
                    }

                    dpp_idx++;
                    tcount--;
                   }

                code = WordsUtils.send_word(wps, code, 0);

                dpp_idx--;

                while (dpp_idx >= 0)
                {
                    if (wps.decorr_passes[dpp_idx].term > Defines.MAX_TERM)
                    {
                        wps.decorr_passes[dpp_idx].weight_A = update_weight(wps.decorr_passes[dpp_idx].weight_A,
                                wps.decorr_passes[dpp_idx].delta,
                                wps.decorr_passes[dpp_idx].samples_A[2], code);
                        wps.decorr_passes[dpp_idx].samples_A[1] = wps.decorr_passes[dpp_idx].samples_A[0];
                        wps.decorr_passes[dpp_idx].samples_A[0] = (code += wps.decorr_passes[dpp_idx].aweight_A);
                    }
                    else
                    {
                        var sam:Int= wps.decorr_passes[dpp_idx].samples_A[m];

                        wps.decorr_passes[dpp_idx].weight_A = update_weight(wps.decorr_passes[dpp_idx].weight_A,
                                wps.decorr_passes[dpp_idx].delta, sam, code);

                        wps.decorr_passes[dpp_idx].samples_A[(m + wps.decorr_passes[dpp_idx].term) &
                        (Defines.MAX_TERM - 1)] = (code += wps.decorr_passes[dpp_idx].aweight_A);
                    }

                    dpp_idx--;
                }

                wps.dc.error[0] += code;
                m = (m + 1) & (Defines.MAX_TERM - 1);

                crc = haxe.Int32.add(haxe.Int32.mul(crc, haxe.Int32.ofInt(3)),  haxe.Int32.ofInt(code));
                if(haxe.Int32.compare(crc, crc2) != 0 )
                {
                    lossy = Defines.TRUE;
                }
                
                i++;
            }

            wpc.byte_idx = byte_idx;
        }

        /////////////////// handle the lossy/hybrid stereo mode ///////////////////
        else if((haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.HYBRID_FLAG))) != 0 ) && 
            (haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.MONO_FLAG | Defines.FALSE_STEREO))) == 0 ) )
        {
            bptr = buffer;
            for (internalCounter in 0...sample_count)
            {
                var left:Int;
                var right:Int;
                var temp:Int;
                var shaping_weight:Int;

                if ((BitsUtils.bs_remain_write(wps.wvbits) < 128) ||
                        ((wpc.wvc_flag != 0) && (BitsUtils.bs_remain_write(wps.wvcbits) < 128)))
                {
                    break;
                }

                left = bptr[byte_idx];
                byte_idx++;
                right = bptr[byte_idx];
                crc2 = haxe.Int32.add(haxe.Int32.mul(haxe.Int32.add(haxe.Int32.mul(crc2, haxe.Int32.ofInt(3)),  haxe.Int32.ofInt(left)),haxe.Int32.ofInt(3)),haxe.Int32.ofInt(right));
                byte_idx++;

                if(haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.HYBRID_SHAPE))) != 0 )
                {
                    wps.dc.shaping_acc[0] += wps.dc.shaping_delta[0];
                    shaping_weight = (wps.dc.shaping_acc[0]) >> 16;
                    temp = -apply_weight(shaping_weight, wps.dc.error[0]);

                    if((haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.NEW_SHAPING))) != 0 ) && (shaping_weight < 0) &&
                            (temp != 0))
                    {
                        if (temp == wps.dc.error[0])
                        {
                            temp = (temp < 0) ? (temp + 1) : (temp - 1);
                        }

                        wps.dc.error[0] = -left;
                        left += temp;
                    }
                    else
                    {
                        wps.dc.error[0] = -(left += temp);
                    }
                    wps.dc.shaping_acc[1] += wps.dc.shaping_delta[1];
                    shaping_weight = (wps.dc.shaping_acc[1]) >> 16;
                    temp = -apply_weight(shaping_weight, wps.dc.error[1]);

                    if((haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.NEW_SHAPING))) != 0 ) && (shaping_weight < 0) &&
                            (temp != 0))
                    {
                        if (temp == wps.dc.error[1])
                        {
                            temp = (temp < 0) ? (temp + 1) : (temp - 1);
                        }

                        wps.dc.error[1] = -right;
                        right += temp;
                    }
                    else
                    {
                        wps.dc.error[1] = -(right += temp);
                    }
                }

                if(haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.JOINT_STEREO))) != 0 )
                {
                    right += ((left -= right) >> 1);
                }

                dpp_idx = 0;

                tcount = wps.num_terms;
                while (tcount > 0)
                {
                    if (wps.decorr_passes[dpp_idx].term > Defines.MAX_TERM)
                    {
                        if ((wps.decorr_passes[dpp_idx].term & 1) != 0)
                        {
                            wps.decorr_passes[dpp_idx].samples_A[2] = (2* wps.decorr_passes[dpp_idx].samples_A[0]) -
                                wps.decorr_passes[dpp_idx].samples_A[1];
                            wps.decorr_passes[dpp_idx].samples_B[2] = (2* wps.decorr_passes[dpp_idx].samples_B[0]) -
                                wps.decorr_passes[dpp_idx].samples_B[1];
                        }
                        else
                        {
                            wps.decorr_passes[dpp_idx].samples_A[2] = ((3* wps.decorr_passes[dpp_idx].samples_A[0]) -
                                wps.decorr_passes[dpp_idx].samples_A[1]) >> 1;
                            wps.decorr_passes[dpp_idx].samples_B[2] = ((3* wps.decorr_passes[dpp_idx].samples_B[0]) -
                                wps.decorr_passes[dpp_idx].samples_B[1]) >> 1;
                        }

                        left -= (wps.decorr_passes[dpp_idx].aweight_A = apply_weight(wps.decorr_passes[dpp_idx].weight_A,
                                wps.decorr_passes[dpp_idx].samples_A[2]));
                        right -= (wps.decorr_passes[dpp_idx].aweight_B = apply_weight(wps.decorr_passes[dpp_idx].weight_B,
                                wps.decorr_passes[dpp_idx].samples_B[2]));
                    }
                    else if (wps.decorr_passes[dpp_idx].term > 0)
                    {
                        left -= (wps.decorr_passes[dpp_idx].aweight_A = apply_weight(wps.decorr_passes[dpp_idx].weight_A,
                                wps.decorr_passes[dpp_idx].samples_A[m]));
                        right -= (wps.decorr_passes[dpp_idx].aweight_B = apply_weight(wps.decorr_passes[dpp_idx].weight_B,
                                wps.decorr_passes[dpp_idx].samples_B[m]));
                    }
                    else
                    {
                        if (wps.decorr_passes[dpp_idx].term == -1)
                        {
                            wps.decorr_passes[dpp_idx].samples_B[0] = left;
                        }
                        else if (wps.decorr_passes[dpp_idx].term == -2)
                        {
                            wps.decorr_passes[dpp_idx].samples_A[0] = right;
                        }

                        left -= (wps.decorr_passes[dpp_idx].aweight_A = apply_weight(wps.decorr_passes[dpp_idx].weight_A,
                                wps.decorr_passes[dpp_idx].samples_A[0]));
                        right -= (wps.decorr_passes[dpp_idx].aweight_B = apply_weight(wps.decorr_passes[dpp_idx].weight_B,
                                wps.decorr_passes[dpp_idx].samples_B[0]));
                    }

                    dpp_idx++;
                    tcount--;
                   }

                left = WordsUtils.send_word(wps, left, 0);
                right = WordsUtils.send_word(wps, right, 1);

                dpp_idx--;

                while (dpp_idx >= 0)
                {
                    if (wps.decorr_passes[dpp_idx].term > Defines.MAX_TERM)
                    {
                        wps.decorr_passes[dpp_idx].weight_A = update_weight(wps.decorr_passes[dpp_idx].weight_A,
                                wps.decorr_passes[dpp_idx].delta,
                                wps.decorr_passes[dpp_idx].samples_A[2], left);
                        wps.decorr_passes[dpp_idx].weight_B = update_weight(wps.decorr_passes[dpp_idx].weight_B,
                                wps.decorr_passes[dpp_idx].delta,
                                wps.decorr_passes[dpp_idx].samples_B[2], right);

                        wps.decorr_passes[dpp_idx].samples_A[1] = wps.decorr_passes[dpp_idx].samples_A[0];
                        wps.decorr_passes[dpp_idx].samples_B[1] = wps.decorr_passes[dpp_idx].samples_B[0];

                        wps.decorr_passes[dpp_idx].samples_A[0] = (left += wps.decorr_passes[dpp_idx].aweight_A);
                        wps.decorr_passes[dpp_idx].samples_B[0] = (right += wps.decorr_passes[dpp_idx].aweight_B);
                    }
                    else if (wps.decorr_passes[dpp_idx].term > 0)
                    {
                        var k:Int= (m + wps.decorr_passes[dpp_idx].term) & (Defines.MAX_TERM - 1);

                        wps.decorr_passes[dpp_idx].weight_A = update_weight(wps.decorr_passes[dpp_idx].weight_A,
                                wps.decorr_passes[dpp_idx].delta,
                                wps.decorr_passes[dpp_idx].samples_A[m], left);
                        wps.decorr_passes[dpp_idx].samples_A[k] = (left += wps.decorr_passes[dpp_idx].aweight_A);

                        wps.decorr_passes[dpp_idx].weight_B = update_weight(wps.decorr_passes[dpp_idx].weight_B,
                                wps.decorr_passes[dpp_idx].delta,
                                wps.decorr_passes[dpp_idx].samples_B[m], right);
                        wps.decorr_passes[dpp_idx].samples_B[k] = (right += wps.decorr_passes[dpp_idx].aweight_B);
                    }
                    else
                    {
                        if (wps.decorr_passes[dpp_idx].term == -1)
                        {
                            wps.decorr_passes[dpp_idx].samples_B[0] = left +
                                wps.decorr_passes[dpp_idx].aweight_A;
                            wps.decorr_passes[dpp_idx].aweight_B = apply_weight(wps.decorr_passes[dpp_idx].weight_B,
                                    wps.decorr_passes[dpp_idx].samples_B[0]);
                        }
                        else if (wps.decorr_passes[dpp_idx].term == -2)
                        {
                            wps.decorr_passes[dpp_idx].samples_A[0] = right +
                                wps.decorr_passes[dpp_idx].aweight_B;
                            wps.decorr_passes[dpp_idx].aweight_A = apply_weight(wps.decorr_passes[dpp_idx].weight_A,
                                    wps.decorr_passes[dpp_idx].samples_A[0]);
                        }

                        wps.decorr_passes[dpp_idx].weight_A = update_weight_clip(wps.decorr_passes[dpp_idx].weight_A,
                                wps.decorr_passes[dpp_idx].delta,
                                wps.decorr_passes[dpp_idx].samples_A[0], left);
                        wps.decorr_passes[dpp_idx].weight_B = update_weight_clip(wps.decorr_passes[dpp_idx].weight_B,
                                wps.decorr_passes[dpp_idx].delta,
                                wps.decorr_passes[dpp_idx].samples_B[0], right);
                        wps.decorr_passes[dpp_idx].samples_B[0] = (left += wps.decorr_passes[dpp_idx].aweight_A);
                        wps.decorr_passes[dpp_idx].samples_A[0] = (right += wps.decorr_passes[dpp_idx].aweight_B);
                    }

                    dpp_idx--;
                }

                if(haxe.Int32.compare(zeroCheck, haxe.Int32.and(flags, haxe.Int32.ofInt(Defines.JOINT_STEREO))) != 0 )
                {
                    left += (right -= (left >> 1));
                }

                wps.dc.error[0] += left;
                wps.dc.error[1] += right;
                m = (m + 1) & (Defines.MAX_TERM - 1);

                crc = haxe.Int32.add(haxe.Int32.mul(haxe.Int32.add(haxe.Int32.mul(crc, haxe.Int32.ofInt(3)),  haxe.Int32.ofInt(left)),haxe.Int32.ofInt(3)),haxe.Int32.ofInt(right));
                if(haxe.Int32.compare(crc, crc2) != 0 )
                {
                    lossy = Defines.TRUE;
                }
                
                i++;
            }

            wpc.byte_idx = byte_idx;
        }

        block_samples = (((wps.blockbuff[23] & 0xFF) << 24));
        block_samples += (((wps.blockbuff[22] & 0xFF) << 16));
        block_samples += (((wps.blockbuff[21] & 0xFF) << 8));
        block_samples += ((wps.blockbuff[20] & 0xFF));

        block_samples = block_samples + i;

        wps.blockbuff[20] = (block_samples);
        wps.blockbuff[21] = ((block_samples >>> 8));
        wps.blockbuff[22] = ((block_samples >>> 16));
        wps.blockbuff[23] = ((block_samples >>> 24));

        wps.blockbuff[28] = haxe.Int32.toInt(haxe.Int32.and(crc,haxe.Int32.ofInt(0xFF)));
        wps.blockbuff[29] = haxe.Int32.toInt(haxe.Int32.and(haxe.Int32.shr(crc,8),haxe.Int32.ofInt(0xFF)));
        wps.blockbuff[30] = haxe.Int32.toInt(haxe.Int32.and(haxe.Int32.shr(crc,16),haxe.Int32.ofInt(0xFF)));
        wps.blockbuff[31] = haxe.Int32.toInt(haxe.Int32.and(haxe.Int32.shr(crc,24),haxe.Int32.ofInt(0xFF)));

        if (wpc.wvc_flag != 0)
        {
            block_samples = (((wps.block2buff[23] & 0xFF) << 24));
            block_samples += (((wps.block2buff[22] & 0xFF) << 16));
            block_samples += (((wps.block2buff[21] & 0xFF) << 8));
            block_samples += ((wps.block2buff[20] & 0xFF));

            block_samples = block_samples + i;

            wps.block2buff[20] = (block_samples);
            wps.block2buff[21] = ((block_samples >>> 8));
            wps.block2buff[22] = ((block_samples >>> 16));
            wps.block2buff[23] = ((block_samples >>> 24));

            wps.block2buff[28] = haxe.Int32.toInt(haxe.Int32.and(crc2,haxe.Int32.ofInt(0xFF)));
            wps.block2buff[29] = haxe.Int32.toInt(haxe.Int32.and(haxe.Int32.shr(crc2,8),haxe.Int32.ofInt(0xFF)));
            wps.block2buff[30] = haxe.Int32.toInt(haxe.Int32.and(haxe.Int32.shr(crc2,16),haxe.Int32.ofInt(0xFF)));
            wps.block2buff[31] = haxe.Int32.toInt(haxe.Int32.and(haxe.Int32.shr(crc2,24),haxe.Int32.ofInt(0xFF)));

        }

        if (lossy != 0)
        {
            wps.lossy_block = Defines.TRUE;
        }

        wps.sample_index += i;

        
        return i;
    }

    static inline function apply_weight(weight:Int, sample:Int):Int 
    {
        //return ((((weight *  sample) + 512) >> 10));
        return(((((sample & 0xffff) * weight) >> 9) + (((sample & ~0xffff) >>9) * weight) + 1) >> 1);

    }

    static inline function update_weight(weight:Int, delta:Int, source:Int, result:Int):Int 
    {
        if ((source != 0) && (result != 0))
        {
            weight += ((((source ^ result) >> 30) | 1) * delta);
        }

        return weight;
    }

    static inline function update_weight_clip(weight:Int, delta:Int, source:Int, result:Int):Int {
        if ((source != 0) && (result != 0) &&
                (((source ^ result) < 0) ? ((weight -= delta) < -1024) : ((weight += delta) > 1024)))
        {
            if (weight < 0)
            {
                weight = -1024;
            }
            else
            {
                weight = 1024;
            }
        }

        return weight;
    }

    // Once all the desired samples have been packed into the WavPack block being
    // built, this function is called to prepare it for writing. Basically, this
    // means just closing the bitstreams because the block_samples and crc fields
    // of the WavpackHeader are updated during packing.
    public static function pack_finish_block(wpc:WavpackContext):Int {
        var wps:WavpackStream= wpc.stream;
        var lossy:Int= wps.lossy_block;
        var tcount:Int;
        var m:Int;
        var data_count:Int;
        var block_samples:Int;
        var chunkSize:Int= 0;
        var dpp_idx:Int= 0;

        block_samples = (((wps.blockbuff[23] & 0xFF) << 24));
        block_samples += (((wps.blockbuff[22] & 0xFF) << 16));
        block_samples += (((wps.blockbuff[21] & 0xFF) << 8));
        block_samples += ((wps.blockbuff[20] & 0xFF));

        m = (block_samples &  (Defines.MAX_TERM - 1));

        if (m != 0)
        {
            tcount = wps.num_terms;
               while (tcount > 0)
            {
                if ((wps.decorr_passes[dpp_idx].term > 0) &&
                        (wps.decorr_passes[dpp_idx].term <= Defines.MAX_TERM))
                {
                    var temp_A:Array<Int>= new Array();
                    var temp_B:Array<Int>= new Array();
                    var k:Int;

                    for ( t in 0 ... wps.decorr_passes[dpp_idx].samples_A.length )
                    {
                        temp_A[t] = wps.decorr_passes[dpp_idx].samples_A[t];
                    }
                    
                    for ( t in 0 ... wps.decorr_passes[dpp_idx].samples_B.length )
                    {
                        temp_B[t] = wps.decorr_passes[dpp_idx].samples_B[t];
                    }

                    for (k in 0...Defines.MAX_TERM)
                    {
                        wps.decorr_passes[dpp_idx].samples_A[k] = temp_A[m];
                        wps.decorr_passes[dpp_idx].samples_B[k] = temp_B[m];
                        m = (m + 1) & (Defines.MAX_TERM - 1);
                    }
                }

                tcount--;
                dpp_idx++;
               }
        }

        WordsUtils.flush_word(wps);
        data_count = BitsUtils.bs_close_write(wps);

        if (data_count != 0)
        {
            if (data_count != -1)
            {
                var cptr_idx:Int= 0;

                chunkSize = (wps.blockbuff[4] & 0xff) + ((wps.blockbuff[5] & 0xff) << 8) +
                    ((wps.blockbuff[6] & 0xff) << 16) + ((wps.blockbuff[7] & 0xff) << 24);

                    
                cptr_idx = chunkSize + 8;

                wps.blockbuff[cptr_idx] = ((Defines.ID_WV_BITSTREAM | Defines.ID_LARGE));
                cptr_idx++;
                wps.blockbuff[cptr_idx] = ((data_count >> 1));
                cptr_idx++;
                wps.blockbuff[cptr_idx] = ((data_count >> 9));
                cptr_idx++;
                wps.blockbuff[cptr_idx] = ((data_count >> 17));

                chunkSize = chunkSize + data_count + 4;

                wps.blockbuff[4] = ((chunkSize));
                wps.blockbuff[5] = ((chunkSize >> 8));
                wps.blockbuff[6] = ((chunkSize >> 16));
                wps.blockbuff[7] = ((chunkSize >> 24));
                
            }
            else
            {
                return Defines.FALSE;
            }
        }

        if (wpc.wvc_flag != 0)
        {
            data_count = BitsUtils.bs_close_correction_write(wps);

            if ((data_count != 0) && (lossy != 0))
            {
                if (data_count != -1)
                {
                    var cptr_idx:Int= 0;
                    chunkSize = (wps.block2buff[4] & 0xff) + ((wps.block2buff[5] & 0xff) << 8) +
                        ((wps.block2buff[6] & 0xff) << 16) + ((wps.block2buff[7] & 0xff) << 24);

                    cptr_idx = chunkSize + 8;

                    wps.block2buff[cptr_idx] = ((Defines.ID_WVC_BITSTREAM | Defines.ID_LARGE));
                    cptr_idx++;
                    wps.block2buff[cptr_idx] = ((data_count >> 1));
                    cptr_idx++;
                    wps.block2buff[cptr_idx] = ((data_count >> 9));
                    cptr_idx++;
                    wps.block2buff[cptr_idx] = ((data_count >> 17));
                    cptr_idx++;

                    chunkSize = chunkSize + data_count + 4;
                    wps.block2buff[4] = ((chunkSize));
                    wps.block2buff[5] = ((chunkSize >> 8));
                    wps.block2buff[6] = ((chunkSize >> 16));
                    wps.block2buff[7] = ((chunkSize >> 24));
                }
                else
                {
                    return Defines.FALSE;
                }
            }
        }
        else if (lossy != 0)
        {
            wpc.lossy_blocks = Defines.TRUE;
        }

        return Defines.TRUE;
    }

    // Copy the specified metadata item to the WavPack block being contructed. This
    // function tests for writing past the end of the available space, however the
    // rest of the code is designed so that can't occur.
    // Prepare a WavPack block for writing. The block will be written at
    // "wps.blockbuff" and "wps.blockend" points to the end of the available
    // space. If a wvc file is being written, then block2buff and block2end are
    // also used. This also sets up the bitstreams so that pack_samples() can be
    // called next with actual sample data. To find out how much data was written
    // the caller must look at the ckSize field of the written WavpackHeader, NOT
    // the one in the WavpackStream. A return value of FALSE indicates an error.
    static function copy_metadata(wpmd:WavpackMetadata, buffer_start:Array<Int>, buffer_end:Int):Int {
        var mdsize:Int= wpmd.byte_length + (wpmd.byte_length & 1);
        var chunkSize:Int;
        var bufIdx:Int= 0;

        if ((wpmd.byte_length & 1) != 0)
        {
            wpmd.data[wpmd.byte_length] = 0;
        }

        mdsize += ((wpmd.byte_length > 510) ? 4: 2);

        chunkSize = (buffer_start[4] & 0xff) + ((buffer_start[5] & 0xff) << 8) +
            ((buffer_start[6] & 0xff) << 16) + ((buffer_start[7] & 0xff) << 24);
            

        bufIdx = (chunkSize + 8);

        if ((bufIdx + mdsize) >= buffer_end)
        {
            return Defines.FALSE;
        }

        buffer_start[bufIdx] = ((wpmd.id |
            (((wpmd.byte_length & 1) != 0) ? Defines.ID_ODD_SIZE : 0)));
        buffer_start[bufIdx + 1] = (((wpmd.byte_length + 1) >> 1));

        if (wpmd.byte_length > 510)
        {
            buffer_start[bufIdx] |= Defines.ID_LARGE;
            buffer_start[bufIdx + 2] = (((wpmd.byte_length + 1) >> 9));
            buffer_start[bufIdx + 3] = (((wpmd.byte_length + 1) >> 17));
        }

        if ((wpmd.data.length != 0) && (wpmd.byte_length != 0))
        {
            if (wpmd.byte_length > 510)
            {
                buffer_start[bufIdx] |= Defines.ID_LARGE;
                buffer_start[bufIdx + 2] = (((wpmd.byte_length + 1) >> 9));
                buffer_start[bufIdx + 3] = (((wpmd.byte_length + 1) >> 17));

                for ( t in 0 ... (mdsize - 4) )
                {
                    buffer_start[t+(bufIdx + 4)] = wpmd.data[t];
                }
            }
            else
            {
                for ( t in 0 ... (mdsize - 2) )
                {
                    buffer_start[t+(bufIdx + 2)] = wpmd.data[t];
                }
            }
        }

        chunkSize += mdsize;

        buffer_start[4] = ((chunkSize));
        buffer_start[5] = ((chunkSize >>> 8));
        buffer_start[6] = ((chunkSize >>> 16));
        buffer_start[7] = ((chunkSize >>> 24));

        return Defines.TRUE;
    }
}
