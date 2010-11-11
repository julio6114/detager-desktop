package com.detager.commands
{
	import com.detager.events.BookmarkEvent;
	import com.detager.events.MessageEvent;
	import com.detager.models.domain.Bookmark;
	import com.detager.services.IBookmarkService;
	
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import org.swizframework.utils.commands.IEventAwareCommand;
	import org.swizframework.utils.services.IServiceHelper;
	
	public class DeleteBookmarkCmd implements IEventAwareCommand
	{
		
		[Dispatcher]
		public var dispatcher:IEventDispatcher;
		
		[Inject]
		public var bookmarkService:IBookmarkService;
		
		[Inject]
		public var serviceHelper:IServiceHelper;
		
		private var bookmark:Bookmark; 
		
		public function set event(value:Event):void
		{
			bookmark = BookmarkEvent(value).bookmark;
		}
		
		public function execute():void
		{
			serviceHelper.executeServiceCall(bookmarkService.remove(bookmark.id), result, fault);
		}
		
		private function result(event:ResultEvent):void
		{
			dispatcher.dispatchEvent(new BookmarkEvent(BookmarkEvent.DELETED, bookmark));
			dispatcher.dispatchEvent(new MessageEvent(MessageEvent.INFO_MESSAGE, "Bookmark deleted successfully!"));
		}
		
		private function fault(event:FaultEvent):void
		{
			dispatcher.dispatchEvent(new MessageEvent(MessageEvent.ERROR_MESSAGE, "Error deleting bookmark: " + event.fault.faultString));
		}
	}
}