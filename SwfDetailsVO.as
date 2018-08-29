package com.proofhq.proofviewer.model.vo.local
{
	import flash.geom.Rectangle;

	public class SwfDetailsVO
	{
		
		[Bindable]
		/**
		 * version of the ActionScript in SWF (either 2 or 3)
		 **/
		public var asVersion:uint;
		
		[Bindable]
		/**
		 * width of the swf stage
		 **/
		public var width:uint;
		
		[Bindable]
		/**
		 * height of the swf stage
		 **/
		public var height:uint;
		
		[Bindable]
		/**
		 * background color used in swf
		 **/
		public var backgroundColor:uint;
		
		[Bindable]
		/**
		 * framerate in swf
		 **/
		public var frameRate:uint;
		
		public function SwfDetailsVO(asVersion:uint, width:Number, height:Number, backgroundColor:uint, frameRate:Number)
		{
			this.asVersion = asVersion;
			this.width = width;
			this.height = height;
			this.backgroundColor = backgroundColor;
			this.frameRate = frameRate;
		}
	}
}