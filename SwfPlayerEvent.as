package com.proofhq.proofviewer.event.proof.swfRenderer
{
	import flash.events.Event;
	
	public class SwfPlayerEvent extends Event
	{		
		static public const SWF_LOADING:String = "swfLoading";
		static public const SWF_LOADED:String = "swfLoaded";
		static public const SWF_ERROR:String = "swfError";
		static public const SWF_UNLOADING:String = "swfUnloading";
		static public const SWF_UNLOADED:String = "swfUnloaded";
		static public const SWF_RELOADED:String = "swfReloaded";
		
		static public const SWF_PLAYING:String = "swfPlaying";
		static public const SWF_PAUSED:String = "swfPaused";
		static public const SWF_REWINDED:String = "swfRewinded";
		static public const SWF_STEP_FORWARDED:String = "swfStepForwarded";
		static public const SWF_STEP_BACKWARDED:String = "swfStepBackwarded";
		static public const SWF_GONE_TO_END:String = "swfGoneToEnd";
		
		public var error:String;
		
		public function SwfPlayerEvent(type:String, error:String=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this.error = error;
		}
		
		override public function clone():Event
		{
			var e:SwfPlayerEvent = new SwfPlayerEvent(type, error);
			e.error = error;
			
			return e; 
		}
	}
}