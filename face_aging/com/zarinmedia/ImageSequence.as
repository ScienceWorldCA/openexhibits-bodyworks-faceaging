package com.zarinmedia {
	import com.greensock.events.LoaderEvent;
	import com.greensock.*;
	import com.greensock.easing.*;
	
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;

	import flash.utils.Timer;
	import flash.filters.ColorMatrixFilter;
	import flash.display.LoaderInfo;
	import flash.display.DisplayObject;
	import flash.system.System;

	//
	/**
	 * ...
	 * @author Zoubin Zarin
	 */
	public class ImageSequence extends MovieClip {
		// so this is the display object that will cycle through the different age images and then sepia tone at the end..	
		private var playhead:int;
		private var theTimer:Timer;		
		internal var myWidth:Number;
		internal var myHeight:Number;
		internal var idx:uint;
		private var maskClip:Sprite;
		private var containorClip:MovieClip;
		private var delaytime:Number;
		private var effectMatrix:String;
		private var transitiontime:Number;
		private var imageArray:Array;
		private var playAfter:Boolean
		private var imagedirectory:String;
		internal var loadCount:uint;
		private var filenames:Array;
		private var currentImageVisible:int;
		internal var imageSequenceIndexPlayingNow:int;
		private var lastImageHolder:Loader;
		
		private var l1:Loader = new Loader();
		private var l2:Loader = new Loader();
		private var l3:Loader = new Loader();
		private var l4:Loader = new Loader();
		private var l5:Loader = new Loader();
		private var l6:Loader = new Loader();
		
		
		private var arrListeners:Array = [];
		
		
		public function ImageSequence():void {
			
			

		}
		
		public function initialize(index:uint , wdth:Number , Hght:Number){
			myHeight = Hght;
			myWidth = wdth;
			idx = index;
			
			// make the mask object
			maskClip = new Sprite();
			maskClip.graphics.beginFill(0xff0000);
			maskClip.graphics.drawRect(0, 0, myWidth, myHeight);
			maskClip.graphics.endFill();
			maskClip.name = "theMask";
			addChild(maskClip);
			
			// make the image sequence containor clip
			containorClip = new MovieClip()
			containorClip.name = "containorClip"; // always feel better if I name my clips..
			addChild(containorClip)
			
			// mask out the content clip
			containorClip.mask = maskClip;

			// lets get some config info we need.
			transitiontime = FaceAgingMainTimeline.configData.getIntrotransitionTime();
			delaytime = FaceAgingMainTimeline.configData.getIntroDelay();
			effectMatrix = FaceAgingMainTimeline.configData.getIntroColorMatrix();
			// easy tool to use to get these numbers to plug into the XML is http://www.onebyonedesign.com/flash/matrixGenerator/
			imagedirectory = FaceAgingMainTimeline.configData.getIntroImageDirectory();

			
			imageArray = new Array(); // the array that holds all the images in the sequence
			
		}
		
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			// record what event listeners we added so that we can kill them easily at the end
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
			arrListeners.push({type:type, listener:listener});
		}
		
		private function clearEvents():void {
			// go through all the listeners we have logged and shut them down..
			   for (var i:Number = 0; i < arrListeners.length ; i++) {
				  if (this.hasEventListener(arrListeners[i].type)) {
					  trace("removed an event listener");
					 this.removeEventListener(arrListeners[i].type, arrListeners[i].listener);
				  }
			   }
			   arrListeners = []
		}
		internal function loadSequence( imageSequenceIndexToPlay:int , playAfterLoad:Boolean = true ):void {
			if (imageArray.length != 0 ) {// if this is not the first time that this fucntion is playing we need to clean house a bit..

				if (lastImageHolder) {
					
					// if there is something in the last image holder.. remove it..
					containorClip.removeChild(lastImageHolder);
					lastImageHolder = null;
				}
				
				for (var j:int = 0; j < imageArray.length; j++) {
						
						
						if ( imageArray[j].filters[0] ) { // checking to see if there is a color matrix on the filter, if there is that is the image that has changed color
							// move the reference of the one that has changed color to the holder (for housekeeping the next time we call this)
	
							lastImageHolder = imageArray[j];
						}else {
							// and remove the rest
							containorClip.removeChild(imageArray[j]);
						}
						
	
						

						
				}
				// this is the last picture, dont delete it, put the reference in a variable to delete it later
				
				filenames = new Array();
				imageArray = new Array();
				
			}
			
			
			
			imageSequenceIndexPlayingNow = imageSequenceIndexToPlay;
			// call this function if you want to load the sequence  given the index number (in reference to the image sequence xml file)... 
			// the switch playafterload is to either start with a color treatment photo, or get right into playing the sequence
			playAfter = playAfterLoad;
			loadCount = 0; // this variable determines if we have loaded all of the images yet or not
			playhead = -1; // means we have not started playing yet;
			// start loading the files for this sequnce
			filenames = FaceAgingMainTimeline.imageSequenceData.getSequenceFilenames(imageSequenceIndexPlayingNow);
			
			
			for (var i:int = 0; i < filenames.length ; i++) {
				
				
					
				
					
				
				
					this["l"+(i+1)].unload(); 
					// Remove Listener
					this["l"+(i+1)].contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoadFile);
					// Set to Null
					
					this["l"+(i+1)] = null;
					
					this["l"+(i+1)] = new Loader(); 
				
				
				
				this["l"+(i+1)].load(new URLRequest(imagedirectory+filenames[i]));
				containorClip.addChild(this["l"+(i+1)]); // right away we can add these images to the containor
				imageArray.push(this["l"+(i+1)]); // keep track of them
				this["l"+(i+1)].alpha = 0; // turn the alpha off so that they are not on at the same time
				this["l"+(i+1)].contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadFile); // add event listiners on these so that we know when all the images are loaded, we need this because we can only get dimention of loaded images after they are loaded
			}
			
			
			
		}
		
		private function onLoadFile(e:Event):void {
			
			
			//MH Remove Loader junk
			
			
			//LoaderInfo(e.target).removeEventListener(Event.COMPLETE, onLoadFile);// cleanup after yourself
			e.target.removeEventListener(Event.COMPLETE, onLoadFile)
			loadCount++;

			if (loadCount == filenames.length) {
				// check to see if we have loaded all the files?
				resizeImages(); //
				
				if (playAfter) { // in this mode, we actually start the sequence right after we loaded... 
					startSequence();
				}else {// display the image to feeze on  // currently the first one
					//-------------------------------------------------------------------------------------------------NOTE: if you want it to freeze start on the last picture change the lines below..
					sepiaImage(0, true, true);// start with the sepia color
					showImage(0); // fade the first image in
					imageSequenceIndexPlayingNow = -1; // this tells the previous class controlling these clips that we are just on freezeframe
					//so we sit here and wait until we are told to play the animation..
				}
				// if so then depending on the switch either pause on first image or play	
			}
		}
		
		private function resizeImages():void {
			var tempImage:Loader;
			for (var i:int = 0; i < imageArray.length; i++) {
				tempImage = Loader(imageArray[i]);
				// first set both height and width to the size of the sqaures
				tempImage.height = myHeight;
				tempImage.width = myWidth;
				if (tempImage.scaleX < tempImage.scaleY) {// then adjust the aspect ratio so its not distorted..
					tempImage.scaleX = tempImage.scaleY;
				}else {
					tempImage.scaleY = tempImage.scaleX;
				}
				// now we need to center the image

			
				tempImage.x = tempImage.x -  ((tempImage.width - myWidth) / 2);
				tempImage.y = tempImage.y -  ((tempImage.height - myHeight) / 2);

				
			}
			


		}
		
		
		
		private function showImage (imageNumber:uint, noTransition:Boolean = false):void {
			playhead = imageNumber;
			if (noTransition) {
				Loader(imageArray[playhead]).alpha = 1;
			}else {
				TweenLite.to(imageArray[playhead], transitiontime, { alpha:1 , ease:Quart.easeOut } );
			}
			
	
		}
		
		private function sepiaImage(imageNumber:uint, turnOn:Boolean = true ,noTransition:Boolean = false):void {
			// here we either make the image sepia right away, or transition to sepia
			var m:Array;
			if (turnOn) {
				// means we are turning on the sepia
				m = effectMatrix.split(",");
			}else {
				// means we are going back to normal color
				m = new Array(1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0);
				
			}
			if (noTransition) {
				var cmFilter:ColorMatrixFilter = new ColorMatrixFilter(m);
				imageArray[imageNumber].filters = [cmFilter];
				
			}else {
				TweenMax.to(imageArray[imageNumber], transitiontime, {colorMatrixFilter:{matrix:m}});
			}
			
			
		}
		
		internal function startSequence():void {
			theTimer = new Timer((delaytime+transitiontime)*1000, imageArray.length);
			theTimer.addEventListener(TimerEvent.TIMER, onTimerTick);
			theTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerDone);
			theTimer.start();
			playNext();
		}
		
		private function onTimerDone(e:TimerEvent):void {
			theTimer.removeEventListener(TimerEvent.TIMER, onTimerTick);
			theTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onTimerDone);
			dispatchEvent(new Event("COMPLETE"));
		}
		
		private function onTimerTick(e:TimerEvent):void {

			
			if (Timer(e.target).currentCount == imageArray.length ) { // we are at the last tick.. so start to change color
				sepiaImage(playhead);
				//
			}else {
					playNext();
			}
			
		}
		
		private function playNext():void {
			playhead ++;
			showImage(playhead); // fade in the next image
			
		}
		
		
		internal function killMe():void {
			try {
				theTimer.stop();// just in case its still in the loop
			}catch (error:Error) {
			}
			// remove event listeners
			clearEvents();
			// try and remove the movieclips
			for (var i : int = containorClip.numChildren-1 ; i >= 0 ; i--){
					containorClip.removeChildAt(i);
			}

			removeChild(containorClip);
			removeChild(maskClip);
		}
		
		
	}

}