/*
** Defines.hx
**
** Copyright (c) 2011-2017 Peter McQuillan
**
** All Rights Reserved.
**
** Distributed under the BSD Software License (see license.txt)
**
*/
class Defines
{
    public static inline var BIT_BUFFER_SIZE:Int= 65536; // This should be carefully chosen for the
                                        // application and platform. Larger buffers are
                                        // somewhat more efficient, but the code will
                                        // allow smaller buffers and simply terminate
                                        // blocks early. If the hybrid lossless mode
                                        // (2 file) is not needed then the wvc_buffer
                                        // can be made very small.
                                        // or-values for "flags"
    public static inline var INPUT_SAMPLES:Int= 65536;
    public static inline var BYTES_STORED:Int= 3; // 1-4 bytes/sample
    public static inline var CONFIG_AUTO_SHAPING:Float= 0x4000; // automatic noise shaping
    public static inline var CONFIG_BITRATE_KBPS:Float= 0x2000; // bitrate is kbps, not bits / sample
    public static inline var CONFIG_BYTES_STORED:Float= 3; // 1-4 bytes/sample
    public static inline var CONFIG_CALC_NOISE:Float= 0x800000; // calc noise in hybrid mode
    public static inline var CONFIG_CREATE_EXE:Float= 0x40000; // create executable
    public static inline var CONFIG_CREATE_WVC:Int= 0x80000; // create correction file
    public static inline var CONFIG_CROSS_DECORR:Float= 0x20; // no-delay cross decorrelation
    public static inline var CONFIG_EXTRA_MODE:Float= 0x2000000; // extra processing mode
    public static inline var CONFIG_FAST_FLAG:Int= 0x200; // fast mode
    public static inline var CONFIG_FLOAT_DATA:Float= 0x80; // ieee 32-bit floating point data
    public static inline var CONFIG_HIGH_FLAG:Int= 0x800; // high quality mode
    public static inline var CONFIG_HYBRID_FLAG:Int= 8; // hybrid mode
    public static inline var CONFIG_HYBRID_SHAPE:Int = 0x40; // noise shape (hybrid mode only)
    public static inline var CONFIG_JOINT_OVERRIDE:Int= 0x10000; // joint-stereo mode specified
    public static inline var CONFIG_JOINT_STEREO:Int= 0x10; // joint stereo
    public static inline var CONFIG_LOSSY_MODE:Float= 0x1000000; // obsolete (for information)
    public static inline var CONFIG_MD5_CHECKSUM:Float= 0x8000000; // compute & store MD5 signature
    public static inline var CONFIG_MONO_FLAG:Float= 4; // not stereo
//    public static inline var CONFIG_OPTIMIZE_MONO:Float= 0x80000000; // optimize for mono streams posing as stereo
    public static inline var CONFIG_OPTIMIZE_WVC:Int = 0x100000; // maximize bybrid compression
    public static inline var CONFIG_SHAPE_OVERRIDE:Int = 0x8000; // shaping mode specified
    public static inline var CONFIG_SKIP_WVX:Float= 0x4000000; // no wvx stream w/ floats & big ints
    public static inline var CONFIG_VERY_HIGH_FLAG:Int= 0x1000; // very high
    public static inline var CROSS_DECORR:Int= 0x20; // no-delay cross decorrelation
    public static inline var CUR_STREAM_VERS:Int= 0x405; // stream version we are writing now

    // encountered
    public static inline var FALSE:Int= 0;
    public static inline var FALSE_STEREO:Int= 0x40000000; // block is stereo, but data is mono
    public static inline var FINAL_BLOCK:Int= 0x1000; // final block of multichannel segment
    public static inline var FLOAT_DATA:Int= 0x80; // ieee 32-bit floating point data
    public static inline var FLOAT_EXCEPTIONS:Int= 0x20; // contains exceptions (inf, nan, etc.)
    public static inline var FLOAT_NEG_ZEROS:Int= 0x10; // contains negative zeros
    public static inline var FLOAT_SHIFT_ONES:Int= 1; // bits left-shifted into float = '1'
    public static inline var FLOAT_SHIFT_SAME:Int= 2; // bits left-shifted into float are the same
    public static inline var FLOAT_SHIFT_SENT:Int= 4; // bits shifted into float are sent literally
    public static inline var FLOAT_ZEROS_SENT:Int= 8; // "zeros" are not all real zeros
    public static inline var HARD_ERROR:Int= 2;
    public static inline var HYBRID_BALANCE:Int= 0x400; // balance noise (hybrid stereo mode only)
    public static inline var HYBRID_BITRATE:Int= 0x200; // bitrate noise (hybrid mode only)
    public static inline var HYBRID_FLAG:Int= 8; // hybrid mode
    public static inline var HYBRID_SHAPE:Int= 0x40; // noise shape (hybrid mode only)
    public static inline var ID_CHANNEL_INFO:Float= 0xd;
    public static inline var ID_CONFIG_BLOCK:Int= 0x25;
    public static inline var ID_CUESHEET:Float= 0x24;
    public static inline var ID_DECORR_SAMPLES:Int= 0x4;
    public static inline var ID_DECORR_TERMS:Int= 0x2;
    public static inline var ID_DECORR_WEIGHTS:Int= 0x3;
    public static inline var ID_DUMMY:Float= 0x0;
    public static inline var ID_ENCODER_INFO:Float= 0x1;
    public static inline var ID_ENTROPY_VARS:Int= 0x5;
    public static inline var ID_FLOAT_INFO:Float= 0x8;
    public static inline var ID_HYBRID_PROFILE:Int= 0x6;
    public static inline var ID_INT32_INFO:Float= 0x9;
    public static inline var ID_LARGE:Int= 0x80;
    public static inline var ID_MD5_CHECKSUM:Float= 0x26;
    public static inline var ID_ODD_SIZE:Int= 0x40;
    public static inline var ID_OPTIONAL_DATA:Float= 0x20;
    public static inline var ID_REPLAY_GAIN:Float= 0x23;
    public static inline var ID_RIFF_HEADER:Float= 0x21;
    public static inline var ID_RIFF_TRAILER:Float= 0x22;
    public static inline var ID_SAMPLE_RATE:Int= 0x27;
    public static inline var ID_SHAPING_WEIGHTS:Int= 0x7;
    public static inline var ID_WVC_BITSTREAM:Int= 0xb;
    public static inline var ID_WVX_BITSTREAM:Float= 0xc;
    public static inline var ID_WV_BITSTREAM:Int= 0xa;
    public static inline var IGNORED_FLAGS:Int= 0x18000000; // reserved, but ignore if encountered
    public static inline var INITIAL_BLOCK:Int= 0x800; // initial block of multichannel segment
    public static inline var INT32_DATA:Int= 0x100; // special extended int handling
    public static inline var JOINT_STEREO:Int= 0x10; // joint stereo
    public static inline var MAG_LSB:Int= 18;
    public static inline var MAX_NTERMS:Int= 16;
    public static inline var MAX_STREAM_VERS:Int= 0x410; // highest stream version we'll decode
    public static inline var MAX_TERM:Int= 8;
    public static inline var MIN_STREAM_VERS:Int= 0x402; // lowest stream version we'll decode
    public static inline var MODE_FAST:Int= 0x40;
    public static inline var MODE_FLOAT:Int= 0x8;
    public static inline var MODE_HIGH:Int= 0x20;
    public static inline var MODE_HYBRID:Int= 0x4;
    public static inline var MODE_LOSSLESS:Int= 0x2;
    public static inline var MODE_VALID_TAG:Int= 0x10;
    public static inline var MODE_WVC:Int= 0x1;
    public static inline var MONO_FLAG:Int= 4; // not stereo
    public static inline var NEW_SHAPING:Int= 0x20000000; // use IIR filter for negative shaping
    public static inline var NO_ERROR:Int= 0;

    // Change the following value to an even number to reflect the maximum number of samples to be processed
    // per call to WavPackUtils.WavpackUnpackSamples
    public static inline var SAMPLE_BUFFER_SIZE:Int= 256;
    public static inline var SHIFT_LSB:Int= 13;
    public static inline var SOFT_ERROR:Int= 1;
    public static inline var SRATE_LSB:Int= 23;
    public static inline var TRUE:Int= 1;
//    public static inline var UNKNOWN_FLAGS:Int= 0x80000000; // also reserved, but refuse decode if
    public static inline var WAVPACK_HEADER_SIZE:Int= 32;
    public static inline var SRATE_MASK:Int= (0xf << SRATE_LSB);
    public static inline var SHIFT_MASK:Int= (0x1f << SHIFT_LSB);
    public static inline var MAG_MASK:Int= (0x1f << MAG_LSB);

    public static inline var FALSE_STEREO_OR_MONO_FLAG: Int = (MONO_FLAG | FALSE_STEREO);
}
