package com.proofhq.proofviewer.model.pm.proof.renderer.swf
{
	import com.proofhq.proofviewer.delegate.PlayerConnector;
	import com.proofhq.proofviewer.event.SwfConnectionEvent;
	import com.proofhq.proofviewer.event.asset.GetSnapshotAssetEvent;
	import com.proofhq.proofviewer.event.asset.GetSwfAssetEvent;
	import com.proofhq.proofviewer.event.asset.GetSwfAssetUrlEvent;
	import com.proofhq.proofviewer.event.asset.UploadSnapshotEvent;
	import com.proofhq.proofviewer.event.proof.swfRenderer.SwfControlsEvent;
	import com.proofhq.proofviewer.event.proof.swfRenderer.SwfPlayerEvent;
	import com.proofhq.proofviewer.model.pm.proof.renderer.ProofRendererPM;
	import com.proofhq.proofviewer.model.vo.local.SwfDetailsVO;
	import com.proofhq.proofviewer.model.vo.remote.CommentVO;
	import com.proofhq.proofviewer.util.SWFBridgeAS3;
	import com.proofhq.proofviewer.util.SwfReader;
	import com.proofhq.proofviewer.util.constant.ProofType;
	import com.proofhq.proofviewer.util.service.LoaderDataInfo;
	
	import flash.display.ActionScriptVersion;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	
	import mx.utils.UIDUtil;
	
	
	public class SwfProofRendererPM extends ProofRendererPM
	{
		/**
		 * Event type which triggers SwfProofRenderer to create
		 * a bitmap stored in swfSnapshot variable.
		 **/
		public static const CREATE_SNAPSHOT_INTERNAL_EVENT:String = "createSnapshotInternalEvent";
		
		[Bindable]
		/**
		 * An object which stores info on loaded SWF file
		 **/
		public var swfDetailsVO:SwfDetailsVO;
				
		[Bindable]
		/**
		 * Stored bitmap of loaded SWF file.
		 * Created in SwfProofRenderer, deleted in PM. 
		 **/
		public var swfSnapshot:Bitmap;
		
		[Bindable]
		public var selectedComment:CommentVO;
		
		/**
		 * Cloned swfSnapshot object. We need to make sure that
		 * between hitting 'Save' in comment box even when user try
		 * to change current state of loaded SWF ('play', 'pause', etc)
		 * which will override the current swfSnapshot object, will still
		 * send a proper bitmap object related to the comment.
		 **/
		private var persistedSwfBitmapData:BitmapData;
		
		/**
		 * Resolve SWF binary data to get info of:
		 * AS version, stage width, height and background color. 
		 **/
		private var swfReader:SwfReader;
		
		/**
		 * Wrapper for LocalConnection
		 **/
		private var swfBridge:SWFBridgeAS3;
		
		/**
		 * A client object for LocalConnection and a facade
		 * to invoke player methods.
		 **/
		private var playerConnector:PlayerConnector;
		
		/**
		 * Indicates when the comment save was attempt and accomplished,
		 * so we can decide when snapshot can be preserved.
		 **/
		private var _commentCallInProgress:Boolean;
			
		/**
		 * PM object UID to refer to from SwfConnectionController 
		 **/
		private var _uid:String;
		
		
		
		public function SwfProofRendererPM()
		{
			_uid = UIDUtil.createUID();
		}
		
		/**
		 * Starts from the SwfProofRenderer
		 **/
		public function getSwfAsset():void
		{
			requestInit();
		}
		
		
		
		//////////////////////////
		//  MANAGES CONNECTION  //
		//////////////////////////
		
		
		/**
		 * Register PM object in SwfConnectionController which checks if in same
		 * app instance and same scope there was any previously registered PM.
		 * - 	If NO, we are OK and we can proceed and handleResultInitialized method
		 * 		will be triggered.
		 * -	If YES, then first we need to do is unload swf, clear LocalConnection and
		 * 		unregister previous PM. Then handleResultInitialized method
		 * 		will be triggered.
		 **/
		private function requestInit():void
		{
			var event:SwfConnectionEvent = new SwfConnectionEvent(SwfConnectionEvent.REQUEST_INIT);
			event.scope = scope;
			event.uid = _uid;
			dispatchMessage(event);
		}
		
		/**
		 * Handler triggered from SwfConnectionController when the PM is registered.
		 * We check the PMs UID so we make sure that we receive a proper event for this PM object.
		 * After that we dispatch message to load a SWF file.
		 **/
		public function handleResultInitialized(event:SwfConnectionEvent):void
		{
			if(event.uid != _uid)
			{
				return;
			}
			
			var e:GetSwfAssetEvent = new GetSwfAssetEvent(GetSwfAssetEvent.TYPE);
			e.sessionId = sessionId;
			e.proofToken = proof.token;
			e.request = "";
			e.proof = proof;
			dispatchMessage(e);
		}
		
		/**
		 * We receive a SWF file so we use SWFReader to gather data
		 * from the SWFs header. Then we store proper info in a SwfDetailsVO object.
		 * Through SwfDetaulsVO.asVersion property, SwfProofRenderer gets notified
		 * which player version should be loaded.
		 **/
		public function handleGetSwfAssetSuccess(event:GetSwfAssetEvent):void
		{
			swfReader = new SwfReader(event.result as ByteArray);
			
			var asType:uint;
			
			//For some reason some AS2 SWF files are not loading correctly in AS2 Player,
			//so in case the proof type is TYPE_SWF_APPLICATION we load them into
			//AS3 Player, it is more accurate. The APPLICATION type does not require
			//to have any control over the SWF file.
			
			if( swfReader.asVersion == ActionScriptVersion.ACTIONSCRIPT2 &&
				proof.type == ProofType.SWF_APPLICATION)
			{
				asType = 3;
			}
			else
			{
				asType = swfReader.asVersion;
			}
			
			swfDetailsVO = new SwfDetailsVO(asType, swfReader.width, swfReader.height, swfReader.backgroundColor, swfReader.frameRate);
			
			swfReader = null;
		}
		
		/**
		 * Proper player is loaded, we can begin connecting with the player
		 * through LocalConnection.
		 **/
		public function playerLoaded():void
		{
			playerConnector = new PlayerConnector;
			configureConnectorListeners(playerConnector);
			
			initBridgeConnection();
		}
		
		/**
		 * Invoked when the player in unloaded.
		 **/
		public function playerUnloaded():void
		{	
		}
		
		/**
		 * Attempt to connect to player via LocalConnection. If the connection
		 * is busy, try next one until succeded.
		 **/
		private function initBridgeConnection(connectionId:uint = 0):void
		{
			try
			{
				if(swfBridge && swfBridge.connected)
				{
					return;
				}
				swfBridge = new SWFBridgeAS3(("a" + connectionId).toString(), playerConnector);
				swfBridge.addEventListener(Event.CONNECT, swfBridgeConnectHandler, false, 0, true);
			}
			catch (err:Error)
			{
				connectionId++;
				initBridgeConnection(connectionId);
			}			
		}
		
		/**
		 * LocalConnection with player was successfully established. We can register connection
		 * in SwfConnectionController so in future we have a reference to unload and clear it.
		 * We gather info of the SWF url so it can be send to the player which will load it. 
		 **/
		private function swfBridgeConnectHandler(event:Event):void
		{
			playerConnector.bridge = swfBridge;
			
			var swfConnectionEvent:SwfConnectionEvent = new SwfConnectionEvent(SwfConnectionEvent.REGISTER_CONNECTION);
			swfConnectionEvent.uid = _uid;
			swfConnectionEvent.playerConnector = playerConnector;
			dispatchMessage(swfConnectionEvent);
			
			var getSwfAssetUrlEvent:GetSwfAssetUrlEvent = new GetSwfAssetUrlEvent(GetSwfAssetUrlEvent.TYPE);
			getSwfAssetUrlEvent.sessionId = sessionId;
			getSwfAssetUrlEvent.proofToken = proof.token;
			getSwfAssetUrlEvent.request = "";
			dispatchMessage(getSwfAssetUrlEvent);
		}
		
		/**
		 * And we receive the SWF url. We send it to the player.
		 **/
		public function handleGetSwfAssetUrlSuccess(event:GetSwfAssetUrlEvent):void
		{
			var swfUrl:String = event.result.toString();
			playerConnector.load(swfUrl);
		}
		
		
		
		////////////////////////
		//  MANAGES SNAPSHOT  //
		////////////////////////
		
		/**
		 * We get an info from the ProofController that snapshot is needed.
		 * We decide if we need to take it from the view or get it from
		 * the server based on comment ID.
		 **/
		public function handleUploadSnapshotTake(event:UploadSnapshotEvent):void
		{
			if(event.comment)
			{
				if(event.comment.id == 0)
				{
					// We create new snapshot only when there is no snapshot
					// this will not create snapshot a second snapshot when pause was click first
					// and then Add Comment was clicked (a little visible jump between frames)
					// But will create snapshot when pause was clicked and frame forward/backward click
					// (which obviously removes previous snapshot) and than Add Comment was clicked -
					// - then we need to create a snapshot.
					if(!swfSnapshot)
					{
						dispatchEvent(new Event(CREATE_SNAPSHOT_INTERNAL_EVENT));
					}
				}
				else
				{
					var getSnapshotAssetEvent:GetSnapshotAssetEvent = new GetSnapshotAssetEvent(GetSnapshotAssetEvent.TYPE);
					getSnapshotAssetEvent.comment = event.comment;
					getSnapshotAssetEvent.sessionId = sessionId;
					getSnapshotAssetEvent.scope = scope;
					dispatchMessage(getSnapshotAssetEvent);
				}
			}
		}
		
		/**
		 * We have a snapshot so we upload it when the comment is Saved.
		 **/
		public function handleUploadSnapshotRequest(event:UploadSnapshotEvent):void
		{			
			var e:UploadSnapshotEvent = new UploadSnapshotEvent(UploadSnapshotEvent.TYPE);
			e.comment = event.comment;
			e.sessionId = sessionId;
			e.bitmapData = persistedSwfBitmapData;
			dispatchMessage(e);
		}
		
		/**
		 * Snapshot was successfully uploaded.
		 **/
		public function handleUploadSnapshotSuccess(event:UploadSnapshotEvent):void
		{
		}
		
		/**
		 * Apply newly obtained snapshot from server. Only if a proper comment is opened.
		 **/
		public function handleGetSnapshotAssetSuccess(event:GetSnapshotAssetEvent):void
		{
			if(event.comment && selectedComment && event.comment.id == selectedComment.id)
			{
				swfSnapshot = event.result;
			}
		}
		
		[Bindable]
		public function get commentCallInProgress():Boolean
		{
			return _commentCallInProgress;
		}
		
		/**
		 * Preserve snapshot when user clicked Save button in comment box.
		 **/
		public function set commentCallInProgress(value:Boolean):void
		{
			_commentCallInProgress = value;
			
			if(_commentCallInProgress)
			{
				persistedSwfBitmapData = swfSnapshot ? swfSnapshot.bitmapData.clone() : null;
			}
		}
		
		
		
		/////////////////////////////////
		//  MANAGES CONTROLS & PLAYER  //
		/////////////////////////////////
		
		/**
		 * Configure listeners for PlayerConnector. Provides responses from player.
		 **/		
		public function configureConnectorListeners(dispatcher:IEventDispatcher):void
		{
			dispatcher.addEventListener(SwfPlayerEvent.SWF_ERROR, swfErrorHandler, false, 0, true);
			dispatcher.addEventListener(SwfPlayerEvent.SWF_LOADED, swfLoadedHandler, false, 0, true);
			dispatcher.addEventListener(SwfPlayerEvent.SWF_UNLOADED, swfUnloadedHandler, false, 0, true);
		}
		
		/**
		 * Error occured in player
		 **/
		private function swfErrorHandler(event:SwfPlayerEvent):void
		{
			// errors from swf
		}
		
		/**
		 * When the SWF file is loaded or reloaded in the player we rewind it when
		 * it is loaded. Only animated SWF files may be rewinded.
		 **/
		private function swfLoadedHandler(event:SwfPlayerEvent):void
		{
			if(proof.type == ProofType.SWF_ANIMATION)
			{
				playerConnector.rewind();
			}
		}
		
		/**
		 * When SWF file is being unloaded from the player.
		 **/
		private function swfUnloadedHandler(event:SwfPlayerEvent):void
		{	
		}
		
		/**
		 * Unloads the SWF file from the player
		 **/
		public function unload():void
		{
			if(!playerConnector)
				return;
			
			playerConnector.unload();
		}
		
		/**
		 * Triggered when pause was invoked - directly from SwfControlsPM.
		 * When the proof type is TYPE_SWF_APPLICATION we don't invoke
		 * pause method on the player because we can't control it this way.
		 * We attempt to pause the animated SWF file in the player.
		 **/
		public function handleSwfControlsPause(event:SwfControlsEvent):void
		{
			if(!playerConnector)
				return;
			
			if(event.comment && event.comment.id > 0)
			{
				if(proof.type == ProofType.SWF_ANIMATION)
				{
					playerConnector.pause();
				}
				
				if(event.scope == scope)
				{
					var getSnapshotAssetEvent:GetSnapshotAssetEvent = new GetSnapshotAssetEvent(GetSnapshotAssetEvent.TYPE);
					getSnapshotAssetEvent.comment = event.comment;
					getSnapshotAssetEvent.sessionId = sessionId;
					dispatchMessage(getSnapshotAssetEvent);
				}
				else
				{
					// In case in compare mode in the other scope we pause,
					// in this one we want to display new snapshot.
					if(swfSnapshot == null)
					{
						dispatchEvent(new Event(CREATE_SNAPSHOT_INTERNAL_EVENT));
					}
				}
			}
			else
			{
				if(proof.type == ProofType.SWF_ANIMATION)
				{
					playerConnector.pause();
				}
				
				dispatchEvent(new Event(CREATE_SNAPSHOT_INTERNAL_EVENT));
			}
			
		}
		
		/**
		 * Triggered when play was invoked - directly from SwfControlsPM.
		 * When the proof type is TYPE_SWF_APPLICATION we don't invoke
		 * play method on the player because we can't control it this way.
		 * We also remove snapshot if exists.
		 * We attempt to play the animated SWF file in the player.
		 **/
		public function handleSwfControlsPlay(event:SwfControlsEvent):void
		{
			if(!playerConnector)
				return;
			
			swfSnapshot = null;
			
			if(proof.type == ProofType.SWF_ANIMATION)
			{
				playerConnector.play();
			}
		}
		
		/**
		 * Triggered when reload was invoked - directly from SwfControlsPM.
		 * We also remove snapshot if exists.
		 * We attempt to reload SWF file in the player.
		 **/
		public function handleSwfControlsReload(event:SwfControlsEvent):void
		{
			if(!playerConnector)
				return;
			
			swfSnapshot = null;
			
			playerConnector.reload();
		}
		
		/**
		 * Triggered when reload was invoked - directly from SwfControlsPM.
		 * We also remove snapshot if exists.
		 * We attempt to reload SWF file in the player.
		 **/
		public function handleSwfControlsRewind(event:SwfControlsEvent):void
		{
			if(!playerConnector)
				return;
			
			swfSnapshot = null;
			
			playerConnector.rewind();
		}
		
		/**
		 * Triggered when step backward was invoked - directly from SwfControlsPM.
		 * We also remove snapshot if exists.
		 * We attempt to go one frame back in SWF file in the player.
		 **/
		public function handleSwfControlsStepBackward(event:SwfControlsEvent):void
		{
			if(!playerConnector)
				return;
			
			swfSnapshot = null;
			
			playerConnector.stepBackward();
		}
		
		/**
		 * Triggered when step forward was invoked - directly from SwfControlsPM.
		 * We also remove snapshot if exists.
		 * We attempt to go one frame forward in SWF file in the player.
		 **/
		public function handleSwfControlsStepForward(event:SwfControlsEvent):void
		{
			if(!playerConnector)
				return;
			
			swfSnapshot = null;
			
			playerConnector.stepForward();
		}
		
		/**
		 * Triggered when step forward was invoked - directly from SwfControlsPM.
		 * We also remove snapshot if exists.
		 * We attempt to go one frame forward in SWF file in the player.
		 **/
		public function handleSwfControlsGoToEnd(event:SwfControlsEvent):void
		{
			if(!playerConnector)
				return;
			
			swfSnapshot = null;
			
			playerConnector.goToEnd();
		}
		
		
	}
}
