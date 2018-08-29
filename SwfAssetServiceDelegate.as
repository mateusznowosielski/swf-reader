package com.proofhq.proofviewer.delegate.asset
{
	import com.proofhq.proofviewer.model.vo.local.ConfigVO;
	import com.proofhq.proofviewer.util.service.AssetLoader;
	import com.proofhq.proofviewer.util.service.BinaryHTTPService;
	import com.proofhq.proofviewer.util.service.LoaderDataInfo;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.setTimeout;
	
	import mx.core.mx_internal;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	public class SwfAssetServiceDelegate implements ISwfAssetServiceDelegate
	{
		protected var service:AssetLoader;
		protected var urlPattern:String;
		
		private var tokens:Dictionary;
		private var services:Dictionary;
		
		[Bindable]
		public var config:ConfigVO;
		
		public function SwfAssetServiceDelegate(service:AssetLoader, urlPattern:String)
		{
			this.service = service;
			this.urlPattern = urlPattern;
			
			tokens = new Dictionary();
			services = new Dictionary();
		}
		
		public function getSwf(sessionId:String, proofToken:String, request:String):AsyncToken
		{	
			var token:AsyncToken = new AsyncToken();
			
			var url:String = urlPattern;
			url = url.replace(/\[\[host\]\]/g, config.host)
			url = url.replace(/\[\[sessionId\]\]/g, sessionId);
			url = url.replace(/\[\[file\]\]/g, proofToken);
						
			service = new AssetLoader();
			services[token] = service;
			tokens[service] = token;
			service.url = url;
			service.loaderDataInfo.addEventListener(Event.COMPLETE, completeHandler, false, 0, true);
			service.loaderDataInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler, false, 0, true);
			service.loaderDataInfo.addEventListener(IOErrorEvent.IO_ERROR, errorHandler, false, 0, true);
			
			sendInit(service.loaderDataInfo, token);
			
			service.load();
			
			return token;
		}
		
		private function completeHandler(event:Event):void
		{
			var loader:AssetLoader = (event.target as LoaderDataInfo).assetLoader;
			var token:AsyncToken = tokens[loader];
			
			sendResult(loader.data, token);
			
			delete tokens[loader];
			delete services[token];
		}
		
		private function errorHandler(event:*):void
		{
			var loader:AssetLoader = (event.target as LoaderDataInfo).assetLoader;
			var token:AsyncToken = tokens[loader];
			
			sendFault(event, token);
			
			delete tokens[loader];
			delete services[token];
		}
		
		private function sendInit(loaderDataInfo:LoaderDataInfo, token:AsyncToken):void
		{
			// we need to delay this to guarantee that the result will be handled properly
			setTimeout(function():void
			{
				token.mx_internal::applyResult(ResultEvent.createEvent(loaderDataInfo, token));
			}, 1);
		}
		
		private function sendResult(data:Object, token:AsyncToken):void
		{
			token.mx_internal::applyResult(ResultEvent.createEvent(data, token));
		}
		
		private function sendFault(data:Object, token:AsyncToken):void 
		{
			var fault:Fault = new Fault("404", "Error! " + data.toString());
			token.mx_internal::applyFault(FaultEvent.createEvent(fault, token));
		}
		
	}
}
