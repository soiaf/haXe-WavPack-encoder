/*
** TestRecorder.hx
**
** Copyright (c) 2012-2017 Peter McQuillan
**
** All Rights Reserved.
**
** Distributed under the BSD Software License (see license.txt)
**
*/

	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.media.Microphone;
	import flash.net.FileReference;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	import MicRecorder;

	import RecordingEvent;
	
	class TestRecorder {
    static var DEFAULT_FILE_NAME : String = "recording.wv";
	static var mc : flash.display.MovieClip;
	static var stage : Dynamic; 
	
    static var playBtn : flash.display.Sprite;
    static var stopBtn : flash.display.Sprite;
    static var te : flash.text.TextField;
	static var _display : flash.text.TextField;
    static var _sizedisplay : flash.text.TextField;
    static var _output_sizedisplay : flash.text.TextField;
	static var _state:Bool;
	static var recorder:MicRecorder;
	static	var _file:FileReference ;	

	public function new() { 
		recorder = new MicRecorder( );
		_file = new FileReference();
	}
		

		
    static function main() {
			var tr = new TestRecorder();
			
            mc = flash.Lib.current; 
			stage = mc.stage; 
			var g : flash.display.Graphics;

			te = new flash.text.TextField();

			te.autoSize = flash.text.TextFieldAutoSize.LEFT;
            te.y=80;
			mc.addChild(te);

			te.text = "Press Button to start recording, press stop button to stop and save\n\n";

 
            playBtn = new flash.display.Sprite(); 

            g = playBtn.graphics;
            g.lineStyle(1,0xe5e5e5);
            
            var w : Int = 60;
            var h : Int = 40;
            var colors : Array <UInt> = [0xF5F5F5, 0xA0A0A0];
            var alphas : Array <Int>  = [1, 1];
            var ratios : Array <Int> = [0, 255];
            var matrix : flash.geom.Matrix = new flash.geom.Matrix();
            
            matrix.createGradientBox(w-2, h-2, Math.PI/2, 0, 0);
            g.beginGradientFill(flash.display.GradientType.LINEAR, 
                                colors,
                                alphas,
                                ratios, 
                                matrix, 
                                flash.display.SpreadMethod.PAD, 
                                flash.display.InterpolationMethod.LINEAR_RGB, 
                                0);
            g.drawRoundRect(0,0,w,h,16,16);
            g.endFill();
    
            // draw a triangle
            g.lineStyle(1,0x808080);
            g.beginFill(0x0);
            g.moveTo((w-20)/2,5);
            g.lineTo((w-20)/2+20,h/2);
            g.lineTo((w-20)/2,h-5);
            g.lineTo((w-20)/2,5);
            g.endFill();
    
            // add the drop-shadow filter
            var shadow : flash.filters.DropShadowFilter = new flash.filters.DropShadowFilter(
            4,45,0x000000,0.8,
            4,4,
            0.65, flash.filters.BitmapFilterQuality.HIGH, false, false
            );
    
            var af : Array < flash.filters.BitmapFilter > = new Array();
            af.push(shadow);
            playBtn.filters = af;
            playBtn.alpha = 0.5;
            playBtn.x = 10;
            playBtn.y = 10;


            // add the event listener 
            playBtn.addEventListener(flash.events.MouseEvent.MOUSE_OUT, outEntry); 
            playBtn.addEventListener(flash.events.MouseEvent.MOUSE_OVER, overEntry); 
            playBtn.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, downEntry); 

            mc.addChild(playBtn); 
			
			   stopBtn = new flash.display.Sprite(); 

            g = stopBtn.graphics;
            g.lineStyle(1,0xe5e5e5);
            
            matrix = new flash.geom.Matrix();
            
            matrix.createGradientBox(w-2, h-2, Math.PI/2, 0, 0);
            g.beginGradientFill(flash.display.GradientType.LINEAR, 
                                colors,
                                alphas,
                                ratios, 
                                matrix, 
                                flash.display.SpreadMethod.PAD, 
                                flash.display.InterpolationMethod.LINEAR_RGB, 
                                0);
            g.drawRoundRect(0,0,w,h,16,16);
            g.endFill();
    
            // draw a smaller square
            g.lineStyle(1,0x808080);
            g.beginFill(0x0);
            g.drawRect( (w-25)/2 ,9,25,22);
            g.endFill();
    
            // add the drop-shadow filter
            var shadow : flash.filters.DropShadowFilter = new flash.filters.DropShadowFilter(
            4,45,0x000000,0.8,
            4,4,
            0.65, flash.filters.BitmapFilterQuality.HIGH, false, false
            );
    
            var af : Array < flash.filters.BitmapFilter > = new Array();
            af.push(shadow);
            stopBtn.filters = af;
            stopBtn.alpha = 0.5;
            stopBtn.x = 10;
            stopBtn.y = 10;


            // add the event listener 
            stopBtn.addEventListener(flash.events.MouseEvent.MOUSE_OUT, outStopEntry); 
            stopBtn.addEventListener(flash.events.MouseEvent.MOUSE_OVER, overStopEntry); 
            stopBtn.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, downStopEntry); 

            mc.addChild(stopBtn); 

            stopBtn.visible = false;
			
			_display = new flash.text.TextField();

			_display.autoSize = flash.text.TextFieldAutoSize.LEFT;
            _display.y=120;
			mc.addChild(_display);
			
			_sizedisplay = new flash.text.TextField();

			_sizedisplay.autoSize = flash.text.TextFieldAutoSize.LEFT;
            _sizedisplay.y=150;
			mc.addChild(_sizedisplay);

			_output_sizedisplay = new flash.text.TextField();

			_output_sizedisplay.autoSize = flash.text.TextFieldAutoSize.LEFT;
            _output_sizedisplay.y=180;
			mc.addChild(_output_sizedisplay);

			
			recorder.addEventListener(RecordingEvent.RECORDING, onRecording);
			recorder.addEventListener(Event.COMPLETE, onRecordComplete);
		}

		static function onRecording(event:RecordingEvent):Void
		{
			_display.text = "Recording since : " + event.time + " ms.";
			_sizedisplay.text = "Bytes read: " + event.bytesize + " bytes";
		}

	static function onRecordComplete(event:Event):Void
	{
		_file.save( recorder.output, "recorded.wv" );
    }
		
    static function overStopEntry(event : flash.events.MouseEvent)
    {
        stopBtn.alpha=0.9;
    }
  
    static function outStopEntry(event:flash.events.MouseEvent)
    {
        stopBtn.alpha=0.7;
    }
    
    // triggered when stop button is clicked
  
    static function downStopEntry(event:flash.events.MouseEvent)
    {
        stopBtn.visible = false;
        playBtn.visible = true;

        recorder.stop();
			
		_state = !_state;
		
		try
		{
		    _output_sizedisplay.text = "Encoded size is: " + recorder.output.length + " bytes";
		}
		catch (err: Dynamic)
        {
            _output_sizedisplay.text = "Error getting output length: " +Std.string(err);
        }
		
		_file.save( recorder.output, "recorded.wv" );
    }
	
    static function overEntry(event : flash.events.MouseEvent)
    {
        playBtn.alpha=0.9;
    }
  
    static function outEntry(event:flash.events.MouseEvent)
    {
        playBtn.alpha=0.7;
    }
    
    // triggered when play button is clicked
  
    static function downEntry(event:flash.events.MouseEvent)
    {
        playBtn.visible = false;
        _output_sizedisplay.text = "";
		if ( !_state ) {
            recorder = new MicRecorder( );
			recorder.addEventListener(RecordingEvent.RECORDING, onRecording);
			recorder.addEventListener(Event.COMPLETE, onRecordComplete);
			recorder.record();
			stopBtn.visible = true;

            _state = !_state;
        }
    }

    function onClick(event:MouseEvent):Void
		{
			if ( !_state ) {
                recorder = new MicRecorder();
                recorder.addEventListener(RecordingEvent.RECORDING, onRecording);
                recorder.addEventListener(Event.COMPLETE, onRecordComplete);
				recorder.record();
            }
			else {
                recorder.stop();
            }
			
			_state = !_state;
		}
	}
