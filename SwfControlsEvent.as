package com.proofhq.proofviewer.event.proof.swfRenderer
{
	import com.proofhq.proofviewer.event.proof.viewport.navigation.ProofNavigationBaseEvent;
	import com.proofhq.proofviewer.model.vo.remote.CommentVO;
	import com.proofhq.proofviewer.model.vo.remote.ProofVO;
	
	public class SwfControlsEvent extends ProofNavigationBaseEvent
	{
		public static const REQUEST_REWIND:String = 		"swfcontrols_event_request_rewind";
		public static const REQUEST_GO_TO_END:String = 		"swfcontrols_event_request_gotoend";
		public static const REQUEST_STEP_BACKWARD:String = 	"swfcontrols_event_request_stepbackward";
		public static const REQUEST_STEP_FORWARD:String = 	"swfcontrols_event_request_stepforward";
		public static const REQUEST_PLAY:String = 			"swfcontrols_event_request_play";
		public static const REQUEST_PAUSE:String =			"swfcontrols_event_request_pause";
		public static const REQUEST_RELOAD:String =			"swfcontrols_event_request_reload";
		
		public static const REWIND:String = 		"swfcontrols_event_rewind";
		public static const GO_TO_END:String = 		"swfcontrols_event_gotoend";
		public static const STEP_BACKWARD:String = 	"swfcontrols_event_stepbackward";
		public static const STEP_FORWARD:String = 	"swfcontrols_event_stepforward";
		public static const PLAY:String = 			"swfcontrols_event_play";
		public static const PAUSE:String =			"swfcontrols_event_pause";
		public static const RELOAD:String =			"swfcontrols_event_reload";
		
		public var proof:ProofVO;
		
		public var comment:CommentVO;
		
		public var sessionId:String;
		
		public var scope:String;
		
		public function SwfControlsEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}