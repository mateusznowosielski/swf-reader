package com.proofhq.proofviewer.model.vo.local
{
	import com.proofhq.proofviewer.delegate.PlayerConnector;
	
	import mx.controls.SWFLoader;

	public class SwfConnectionVO
	{
		public var swfUid:String;
		
		public var scope:String;
		
		public var playerConnector:PlayerConnector;
		
		
		public function SwfConnectionVO()
		{
		}
	}
}