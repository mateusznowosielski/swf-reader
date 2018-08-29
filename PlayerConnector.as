package com.proofhq.proofviewer.delegate
{
	
	import com.proofhq.proofviewer.event.proof.swfRenderer.SwfPlayerEvent;
	import com.proofhq.proofviewer.util.SWFBridgeAS3;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class PlayerConnector extends EventDispatcher
	{
		public var bridge:SWFBridgeAS3;
		
		public function PlayerConnector()
		{
		}
		
		///////////////
		//  METHODS  //
		///////////////
		
		/**
		 * Begin loading SWF file by given SWF url
		 **/
		public function load(swfUrl:String):void
		{
			if(!bridge)
				return;
			
			bridge.send("load", swfUrl);
			
			dispatchEvent(new SwfPlayerEvent(SwfPlayerEvent.SWF_LOADING));
		}
		
		/**
		 * Unload the SWF file
		 **/
		public function unload():void
		{
			if(!bridge)
				return;
			
			bridge.send("unload");
			
			dispatchEvent(new SwfPlayerEvent(SwfPlayerEvent.SWF_UNLOADING));
		}
		
		/**
		 * Closes connection between PV and player
		 **/
		public function close():void
		{
			if(!bridge)
				return;
			
			bridge.send("close");
		}
		
		/**
		 * Play loaded SWF file
		 **/
		public function play():void
		{
			if(!bridge)
				return;
			
			bridge.send("play");
		}
		
		/**
		 * stop playing an SWF file
		 **/
		public function pause():void
		{
			if(!bridge)
				return;
			
			bridge.send("pause");
		}
		
		/**
		 * 1 step forward [in frames]
		 **/
		public function stepForward():void
		{
			if(!bridge)
				return;
			
			bridge.send("stepForward");
		}
		
		/**
		 * 1 step backward [in frames]
		 **/
		public function stepBackward():void
		{
			if(!bridge)
				return;
			
			bridge.send("stepBackward");
		}
		
		/**
		 * Rewind SWF to the beginning
		 **/
		public function rewind():void
		{
			if(!bridge)
				return;
			
			bridge.send("rewind");
		}
		
		/**
		 * Go to end in SWF file
		 **/
		public function goToEnd():void
		{
			if(!bridge)
				return;
			
			bridge.send("goToEnd");
		}
		
		/**
		 * Reload SWF
		 **/
		public function reload():void
		{
			if(!bridge)
				return;
			
			bridge.send("reload");
		}
		
		////////////////
		//  HANDLERS  //
		////////////////
		
		/**
		 * Dispatched when swf is loaded and displayed
		 **/
		public function isLoaded():void
		{
			dispatchEvent(new SwfPlayerEvent(SwfPlayerEvent.SWF_LOADED));
		}
		
		/**
		 * Dispatched when swf is unloaded
		 **/
		public function isUnloaded():void
		{
			dispatchEvent(new SwfPlayerEvent(SwfPlayerEvent.SWF_UNLOADED));
		}
		
		/**
		 * Dispatched when swf is playing
		 **/
		public function isPlaying():void
		{
			dispatchEvent(new SwfPlayerEvent(SwfPlayerEvent.SWF_PLAYING));
		}
		
		/**
		 * Dispatched when swf is stopped
		 **/
		public function isPaused():void
		{
			dispatchEvent(new SwfPlayerEvent(SwfPlayerEvent.SWF_PAUSED));
		}
		
		/**
		 * Dispatched when swf is rewinded
		 **/
		public function isRewinded():void
		{
			dispatchEvent(new SwfPlayerEvent(SwfPlayerEvent.SWF_REWINDED));
		}
		
		/**
		 * Dispatched when swf was forwarded by 1 frame
		 **/
		public function isStepForwarded():void
		{
			dispatchEvent(new SwfPlayerEvent(SwfPlayerEvent.SWF_STEP_FORWARDED));
		}
		
		/**
		 * Dispatched when swf was backwarded by 1 frame
		 **/
		public function isStepBackwarded():void
		{
			dispatchEvent(new SwfPlayerEvent(SwfPlayerEvent.SWF_STEP_BACKWARDED));
		}
		
		/**
		 * Dispatched when swf was forwarded to the end
		 **/
		public function isGoneToEnd():void
		{
			dispatchEvent(new SwfPlayerEvent(SwfPlayerEvent.SWF_GONE_TO_END));
		}
		
		/**
		 * Dispatched when an error occurred in SWF file
		 **/
		public function throwError(value:String):void
		{
			dispatchEvent(new SwfPlayerEvent(SwfPlayerEvent.SWF_ERROR, value));
		}
		
		
	}
}