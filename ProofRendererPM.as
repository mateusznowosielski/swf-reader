package com.proofhq.proofviewer.model.pm.proof.renderer
{
	import com.proofhq.proofviewer.model.vo.remote.ProofVO;
	
	import flash.events.EventDispatcher;

	public class ProofRendererPM extends EventDispatcher
	{
		public var dispatchMessage:Function;
		
		[Bindable]
		public var sessionId:String;
		
		private var _proof:ProofVO;
		
		public var previousProof:ProofVO;   
		
		[Bindable]
		public var scope:String;
		
		public function ProofRendererPM()
		{
		}
		
		[Bindable]
		public function get proof():ProofVO
		{
			return _proof;
		}
		
		public function set proof(value:ProofVO):void
		{
			previousProof = _proof;
			_proof = value;
		}  
	}
}