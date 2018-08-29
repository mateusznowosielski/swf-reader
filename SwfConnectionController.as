package com.proofhq.proofviewer.controller
{
	import com.proofhq.proofviewer.event.SwfConnectionEvent;
	import com.proofhq.proofviewer.model.SwfConnectionModel;
	import com.proofhq.proofviewer.model.vo.local.SwfConnectionVO;
	
	
	/**
	 * IMPORTANT!
	 * Registering PM and registering connection in PM is not the same.
	 * First is registering PM, then registering connection for the PM.
	 * Registering PM is done by preserving a UID of PM. 
	 **/
	
	public class SwfConnectionController extends Controller
	{
		/**
		 * Controllers model
		 **/
		public var swfConnectionModel:SwfConnectionModel;
		
		
		public function SwfConnectionController()
		{
		}
		
		/**
		 * Invoked when a new PM wants to be registered.
		 * We check if previously there was any registered and active
		 * PM in the same scope. If so lets remove it first.
		 **/
		public function handleRequestInit(event:SwfConnectionEvent):void
		{			
			var lastSwfUid:String = checkIfExistsInTheScope(event.scope);
			
			if(lastSwfUid)
			{
				exchangeSwfConnection(lastSwfUid, event.uid, event.scope);
			}
			else
			{
				createNewConnection(event.uid, event.scope);
			}
		}
		
		/**
		 * We register connection if LocalConnection was succesfully established
		 * for registered PM.
		 **/
		public function handleRegisterConnection(event:SwfConnectionEvent):void
		{
			var swfConnectionVO:SwfConnectionVO = swfConnectionModel.swfConnections[event.uid];
			
			if(swfConnectionVO)
			{
				swfConnectionVO.playerConnector = event.playerConnector;
			}
		}
		
		/**
		 * Registers a new PM and informs about it.
		 **/
		private function createNewConnection(uid:String, scope:String):void
		{
			var swfConnectionVO:SwfConnectionVO = new SwfConnectionVO();
			swfConnectionVO.swfUid = uid;
			swfConnectionVO.scope = scope;
			swfConnectionModel.swfConnections[uid] = swfConnectionVO;
			
			var event:SwfConnectionEvent = new SwfConnectionEvent(SwfConnectionEvent.RESULT_INITIALIZED);
			event.scope = scope;
			event.uid = uid;
			dispatchMessage(event);
		}
		
		/**
		 * Check if under the same scope we already have a registered PM
		 **/
		private function checkIfExistsInTheScope(scope:String):String
		{
			for each(var s:SwfConnectionVO in swfConnectionModel.swfConnections)
			{
				if(s.scope == scope)
				{
					return s.swfUid;
				}
			}
			
			return null;
		}
		
		/**
		 * Respectively: unloads SWF file from the player,
		 * closes connection in the previous PM,
		 * unregisters previous PM,
		 * registers newly added PM.
		 **/
		private function exchangeSwfConnection(lastUid:String, newUid:String, scope:String):void
		{
			var swfConnectionVO:SwfConnectionVO = swfConnectionModel.swfConnections[lastUid];
			
			if(	swfConnectionVO &&
				swfConnectionVO.playerConnector &&
				swfConnectionVO.playerConnector.bridge)
			{				
				swfConnectionVO.playerConnector.unload();
				
				// Unfortunately we need to close connection on
				// both ends in PV and player. If we don't do this
				// we cannot establish next connection on the same id
				
				swfConnectionVO.playerConnector.close();
				swfConnectionVO.playerConnector.bridge.close();
				delete swfConnectionModel.swfConnections[lastUid];
				createNewConnection(newUid, scope);
			}
			else if(swfConnectionVO && !swfConnectionVO.playerConnector)
			{
				delete swfConnectionModel.swfConnections[lastUid];
				createNewConnection(newUid, scope);
			}
		}
	}
}