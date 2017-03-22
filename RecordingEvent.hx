/*
** RecordingEvent.hx
**
** Copyright (c) 2012-2017 Peter McQuillan
**
** All Rights Reserved.
**
** Distributed under the BSD Software License (see license.txt)
**
*/

	import flash.events.Event;
	
	class RecordingEvent extends flash.events.Event {
		
		public var time(get_time, set_time) : Float;
		public var bytesize(get_bytesize, set_bytesize) : Int;
		public static var RECORDING:String = "recording";
		
		var _time:Float;
		var _size:Int;
			
		public function new(type:String, time:Float, bytesize:Int)
		{
			super(type, false, false);
			_time = time;
			_size = bytesize;
		}

		public function get_bytesize():Int {
			return _size;
		}

		public function set_bytesize(value:Int):Int {
			_size = value;
			return value;
		}
				
		public function get_time():Float{
			return _time;
		}
	
		public function set_time(value:Float):Float{
			_time = value;
			return value;
		}
	
		public override function clone(): Event
		{
			return new RecordingEvent(type, _time, _size);
		}
	}
