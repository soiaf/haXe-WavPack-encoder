/*
** RecordingEvent.hx
**
** Copyright (c) 2012 Peter McQuillan
**
** All Rights Reserved.
**
** Distributed under the BSD Software License (see license.txt)
**
*/

	import flash.events.Event;
	
	class RecordingEvent extends flash.events.Event {
		
		public var time(getTime, setTime) : Float;
		public var bytesize(getSize, setSize) : Int;
		public static var RECORDING:String = "recording";
		
		var _time:Float;
		var _size:Int;
			
		public function new(type:String, time:Float, bytesize:Int)
		{
			super(type, false, false);
			_time = time;
			_size = bytesize;
		}

		public function getSize():Int {
			return _size;
		}

		public function setSize(value:Int):Int {
			_size = value;
			return value;
		}
				
		public function getTime():Float{
			return _time;
		}
	
		public function setTime(value:Float):Float{
			_time = value;
			return value;
		}
	
		public override function clone(): Event
		{
			return new RecordingEvent(type, _time, _size);
		}
	}
