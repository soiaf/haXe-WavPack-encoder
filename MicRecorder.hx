/*
** RecordingEvent.hx
**
** Copyright (c) 2012-2017 Peter McQuillan
**
** All Rights Reserved.
**
** Distributed under the BSD Software License (see license.txt)
**
** This file based on code from Thibault Imbert - bytearray.org
**
*/

	class MicRecorder extends flash.events.EventDispatcher {
		
		public var gain(get_gain, set_gain) : UInt;
		public var microphone(get_microphone, set_microphone) : flash.media.Microphone;
		public var output(get_output, null) : flash.utils.ByteArray;
		public var rate(get_rate, set_rate) : UInt;
		public var silenceLevel(get_silenceLevel, set_silenceLevel) : UInt;
		var _gain:UInt;
		var _rate:UInt;
		var _silenceLevel:UInt;
		var _timeOut:UInt;
		var _difference:UInt;
		var _microphone:flash.media.Microphone;
		var _buffer:flash.utils.ByteArray ;
		var _output:flash.utils.ByteArray;
		
		var _completeEvent:flash.events.Event ;
		var _recordingEvent:RecordingEvent ;
		
		var config:WavpackConfig;
		var wpc:WavpackContext;
		
		var first: Int;

		/**
		 * 
		 * @param encoder The audio encoder to use
		 * @param microphone The microphone device to use
		 * @param gain The gain
		 * @param rate Audio rate
		 * @param silenceLevel The silence level
		 * @param timeOut The timeout
		 * 
		 */		
		public function new(?microphone:flash.media.Microphone=null, ?gain:UInt=50, ?rate:UInt=8, ?silenceLevel:UInt=0, ?timeOut:UInt=4000)
		{
			/*
			** Supported rates for microphone
			44 	44,100 Hz 
			22 	22,050 Hz 
			11 	11,025 Hz 
			8 	8,000 Hz 
			5 	5,512 Hz 
			*/

			super();
			_buffer = new flash.utils.ByteArray();
			_completeEvent = new flash.events.Event ( flash.events.Event.COMPLETE );
			_recordingEvent = new RecordingEvent( RecordingEvent.RECORDING, 0, 0 );

			_microphone = microphone;
			
			
			_gain = gain;
			
			_rate = rate;
			_silenceLevel = silenceLevel;
			_timeOut = timeOut;
			
			wpc = new WavpackContext();
			
			config = new WavpackConfig();
			//config.flags = haxe.Int32.or(config.flags, haxe.Int32.ofInt(Defines.CONFIG_FAST_FLAG));
			
			config.bytes_per_sample = 2;
			config.bits_per_sample = 16;
			config.num_channels = 1;    // Flash records in mono from microphone
			config.sample_rate = 8000;  // make sure to change the default value for rate above also
			if (rate==44){
				config.sample_rate = 44100;
			}else if (rate==22){
				config.sample_rate = 22050;
			}else if (rate==11){
				config.sample_rate = 11025;
			}else if (rate==8){
				config.sample_rate = 8000;
			}else if (rate==5){
				config.sample_rate = 5512;
			}
			
			/* these set the bitrate for lossy encoding */
			config.flags = (config.flags | Defines.CONFIG_HYBRID_FLAG);
			config.bitrate = 1536;

			
			wpc.outfile = new flash.utils.ByteArray();
			
			WavPackUtils.WavpackSetConfiguration(wpc, config, -1);
			
			WavPackUtils.WavpackPackInit(wpc);

		}
		
		/**
		 * Starts recording from the default or specified microphone.
		 * The first time the record() method is called the settings manager may pop-up to request access to the Microphone.
		 */		
		public function record():Void
		{
			first = 0;
			if ( _microphone == null )
				_microphone = flash.media.Microphone.getMicrophone();
			 
			_difference = flash.Lib.getTimer();

			_microphone.setSilenceLevel(_silenceLevel, _timeOut);
			_microphone.gain = _gain;
			_microphone.rate = _rate;
			_buffer.length = 0;
			
			_buffer.endian = flash.utils.Endian.LITTLE_ENDIAN;
			
			
			_microphone.addEventListener(flash.events.SampleDataEvent.SAMPLE_DATA, onSampleData);
			_microphone.addEventListener(flash.events.StatusEvent.STATUS, onStatus);
		}
		
		function onStatus(event:flash.events.StatusEvent):Void
		{
			_difference = flash.Lib.getTimer();
		}
		
		/**
		 * Dispatched during the recording.
		 * @param event
		 */		
		function onSampleData(event:flash.events.SampleDataEvent):Void
		{
			_recordingEvent.time = flash.Lib.getTimer() - _difference;

			
			var sample_count : Int = 0;
			var sample_buffer:Array < Int > = new Array();
			var counter : Int = 0;

			sample_buffer[event.data.bytesAvailable-1] = 0;
			while(event.data.bytesAvailable > 0)
			{
                // 32767 as we're recording 16 bit information
				sample_buffer[counter] = Std.int(event.data.readFloat() * 32767.0);
				counter++;
				sample_count++;
			}
			
			_recordingEvent.bytesize += (sample_count * 2); // times 2 as each sample is 2 bytes
			dispatchEvent( _recordingEvent );
			
			wpc.byte_idx = 0;
			WavPackUtils.WavpackPackSamples(wpc, sample_buffer, sample_count);
		}
		
		/**
		 * Stop recording the audio stream
		 */		
		public function stop():Void
		{
		
			_microphone.removeEventListener(flash.events.SampleDataEvent.SAMPLE_DATA, onSampleData);
		
			WavPackUtils.WavpackFlushSamples(wpc);
			
			_buffer.position = 0;
			_output = wpc.outfile;	
				
			dispatchEvent( _completeEvent );
		}
			
		public function get_gain():UInt{
			return _gain;
		}

		public function set_gain(value:UInt):UInt{
			_gain = value;
			return value;
		}

		public function get_rate():UInt{
			return _rate;
		}
	
		public function set_rate(value:UInt):UInt{
			_rate = value;
			return value;
		}
			
		public function get_silenceLevel():UInt{
			return _silenceLevel;
		}

		public function set_silenceLevel(value:UInt):UInt{
			_silenceLevel = value;
			return value;
		}
	
		public function get_microphone():flash.media.Microphone{
			return _microphone;
		}

		public function set_microphone(value:flash.media.Microphone):flash.media.Microphone{
			_microphone = value;
			return value;
		}

		public function get_output():flash.utils.ByteArray
		{
			return _output;
		}
			
		public override function toString():String
		{
			return "[MicRecorder gain=" + _gain + " rate=" + _rate + " silenceLevel=" + _silenceLevel + " timeOut=" + _timeOut + " microphone:" + _microphone + "]";
		}
	}
