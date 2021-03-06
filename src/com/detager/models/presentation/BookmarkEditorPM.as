package com.detager.models.presentation
{
	import com.detager.events.BookmarkEvent;
	import com.detager.events.MessageEvent;
	import com.detager.events.SwitchViewEvent;
	import com.detager.models.ApplicationModel;
	import com.detager.models.domain.Bookmark;
	import com.detager.models.domain.Tag;
	import com.detager.models.domain.User;
	
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	import mx.utils.ObjectProxy;
	import mx.utils.ObjectUtil;
	import mx.validators.Validator;

	public class BookmarkEditorPM
	{
		[Dispatcher]
		public var dispatcher:IEventDispatcher;

		[Bindable]
		public var currentBookmark:Bookmark;
		
		protected var originalBookmark:Bookmark;

		[Bindable]
		public var currentTagGroups:ArrayCollection;

		[Inject(source="applicationModel.tagGroups")]
		public var tagGroups:ArrayCollection;
		
		[Bindable]
		[Inject(source="applicationModel.statusBarText", twoWay="true", bind="true")]
		public var statusBarText:String;
		
		[Inject(source="applicationModel.currentUser")]
		public var currentUser:User;
		
		[Bindable]
		public var enabledTitle:Boolean = true;
		
		[PostConstruct]
		public function postConstruct():void
		{
			createNewBookmark();
		}
		
		[PreDestroy]
		public function preDestroy():void
		{
			trace("AddLinkPM::preDestroy");
		}
		
		[EventHandler(event="BookmarkEvent.OPEN", properties="bookmark")]
		public function openBookmark(bookmark:Bookmark):void
		{
			// Checking if bookmark was updated
			if (ObjectUtil.compare(originalBookmark, currentBookmark) != 0)
			{
				Alert.show("Discard current changes?", "Question", Alert.YES | Alert.NO, null, 
					function(event:CloseEvent):void
					{
						if (event.detail == Alert.YES)
							setCurrentBookmark(bookmark);
					}
				);
			}
			else
				setCurrentBookmark(bookmark);
		}
		
		[EventHandler(event="BookmarkEvent.UPDATED", properties="bookmark")]
		public function bookmark_updatedHandler(bookmark:Bookmark):void
		{
			dispatcher.dispatchEvent(new SwitchViewEvent(SwitchViewEvent.SWITCH_VIEW, ApplicationModel.HOME_VIEW_STATE));
			dispatcher.dispatchEvent(new MessageEvent(MessageEvent.INFO_MESSAGE, "Bookmark updated successfully!", 3));
			createNewBookmark(true);
		}

		[EventHandler(event="BookmarkEvent.CREATED", properties="bookmark")]
		public function bookmark_createdHandler(bookmark:Bookmark):void
		{
			dispatcher.dispatchEvent(new SwitchViewEvent(SwitchViewEvent.SWITCH_VIEW, ApplicationModel.HOME_VIEW_STATE));
			dispatcher.dispatchEvent(new MessageEvent(MessageEvent.INFO_MESSAGE, "Bookmark created successfully!", 3));
			createNewBookmark(true);
		}

		[EventHandler(event="BookmarkEvent.DELETED", properties="bookmark")]
		public function bookmark_deletedHandler(bookmark:Bookmark):void
		{
			dispatcher.dispatchEvent(new SwitchViewEvent(SwitchViewEvent.SWITCH_VIEW, ApplicationModel.HOME_VIEW_STATE));
			dispatcher.dispatchEvent(new MessageEvent(MessageEvent.INFO_MESSAGE, "Bookmark deleted successfully!", 3));
			createNewBookmark(true);
		}

		public function btnNewLink_clickHandler():void
		{
			createNewBookmark();
		}

		public function btnDelete_clickHandler():void
		{
			Alert.show("Do you want to delete this bookmark?", "Question", Alert.YES | Alert.NO, null, 
				function(event:CloseEvent):void
				{
					if (event.detail == Alert.YES)
						dispatcher.dispatchEvent(new BookmarkEvent(BookmarkEvent.DELETE, currentBookmark));
				}
			);
		}

		public function btnSaveLink_clickHandler(validators:Array):void
		{
			if (Validator.validateAll(validators).length == 0)
			{
				if (!currentBookmark.isOwner)
				{
					currentBookmark.id = NaN;
					currentBookmark.entryDate = null;
					currentBookmark.ownerUsername = currentUser.username;
				}
				
				var selectedTags:ArrayCollection = new ArrayCollection();
				for each(var tgp:ObjectProxy in currentTagGroups)
					for each(var tp:ObjectProxy in tgp.tags)
						if (tp.selected)
							selectedTags.addItem(tp.tag);
						
				currentBookmark.tags = selectedTags;
				
				if (currentBookmark.id)
					dispatcher.dispatchEvent(new BookmarkEvent(BookmarkEvent.UPDATE, currentBookmark));
				else
					dispatcher.dispatchEvent(new BookmarkEvent(BookmarkEvent.CREATE, currentBookmark));
			}
		}

		public function txtUrl_changeHandler():void
		{
			if (currentBookmark.url && currentBookmark.url != "http://")
				loadTitle();
		}
		
		protected function createNewBookmark(clear:Boolean = false):void
		{
			// var clipboardUrl:String = Clipboard.generalClipboard.getData(ClipboardFormats.URL_FORMAT) as String;
			if (clear)
			{
				currentBookmark = null;
				originalBookmark = null;
			}
			openBookmark(new Bookmark("http://"));
		}
		
		protected function setCurrentBookmark(newBookmark:Bookmark):void
		{
			originalBookmark = newBookmark;
			currentBookmark = ObjectUtil.copy(newBookmark) as Bookmark;
		
			currentTagGroups = ObjectUtil.copy(tagGroups) as ArrayCollection;

			// In case this is existing link loaded
			var tagIds:Vector.<Number> = new Vector.<Number>();
			for each(var tag:Tag in currentBookmark.tags)
				tagIds.push(tag.id);
			
			if (tagIds.length > 0)
				for each(var tgp:ObjectProxy in currentTagGroups)
					for each(var tp:ObjectProxy in tgp.tags)
						if (tagIds.indexOf(tp.tag.id) > -1)
							tp.selected = true;
			
			if (currentBookmark.url && currentBookmark.url != "http://" && !currentBookmark.title)
				loadTitle();
		}
		
		protected function loadTitle():void
		{
			statusBarText = "Loading link title...";
			enabledTitle = false;
			
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, 
				function(event:Event):void
				{
					var arr:Array = String(URLLoader(event.currentTarget).data).match(/<title>.*<\/title>/);
					if (arr && arr.length > 0)
					{
						var titleElement:String = String(arr[0]);
						currentBookmark.title = titleElement.substr(7).substr(0,titleElement.length - 15);
						
						statusBarText = "";
						enabledTitle = true;
					}
				});
			loader.addEventListener(IOErrorEvent.IO_ERROR,
				function(event:IOErrorEvent):void
				{
					statusBarText = "";
					enabledTitle = true;
					trace("Failed to load title:", event.text);					
				});
			loader.load(new URLRequest(currentBookmark.url));
		}
	}
}