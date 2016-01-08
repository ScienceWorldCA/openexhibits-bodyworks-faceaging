package com.zarinmedia {
	import com.greensock.motionPaths.MotionPath;
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Zoubin Zarin
	 */
	public class AgeDisplay extends MovieClip {
		private var ageSeqArr:Array;
		internal var sUI:SliderUI;
		private var ageDisplayContainer:MovieClip;
		private var originalAgeClip:MovieClip;
		private var ageSequenceClip:MovieClip;
		private var ageSequenceImagesArray:Array;
		private var splitScreenMask:MovieClip;
		private var splitLeftMargin:Number = 35;
		private var splitRightMargin:Number = 35;
		private var splitlineClip:MovieClip;
		
		private var logoClip:MovieClip;
		private var logoClipRight:MovieClip;
		
		private var yearLabelLeft:MovieClip;
		private var yearLabelRight:MovieClip;
		private var year:Number;
		private var agenow:int;
		private var infoPointsArray:Array;
		private var modalWindowInfoPoint:MovieClip;
		private var whatIndexToStartat:Number = 4;
		public function AgeDisplay(originalPhoto:Bitmap , currentAge:int , ageSequence:Array , ageSequenceFilenamesArray:Array ) {
			super();
			ageSeqArr = ageSequence;
			agenow = currentAge;
			var d:Date = new Date();
			year = d.getFullYear();
			originalPhoto.x = 0;
			originalPhoto.y = 0; // we previously move the xy on this object..
			// this class coordinates the split screen and ui functionality of step 3 where user views the age results
						
			//------------- create the slider
			sUI = new SliderUI(ageSeqArr);
			sUI.name = "ageSlider";
			sUI.x = 285;
			sUI.y = 970;
			addChild(sUI);
			sUI.addEventListener("CHANGE", onChangeAge);
			
			//-------------------- age display clip is the overall clip we will have the split screen in
			ageDisplayContainer = new MovieClip();
			ageDisplayContainer.name = "displayContainor";
			addChild(ageDisplayContainer);
			
			var adcm:MovieClip = new MovieClip(); // just in case we get an image that is bigger, mask this all.. 
			adcm.graphics.beginFill(0xFF0000, .5);
			adcm.graphics.drawRect(0, 0, 575, 905);
			adcm.graphics.endFill();
			addChild(adcm);
			ageDisplayContainer.mask = adcm;
			
			// ------------------- place original image in ageDisplayContainer
			
			ageDisplayContainer.addChild(originalPhoto);
			originalPhoto.visible = true;
			originalPhoto.alpha = 1;
			originalPhoto.name = "snapshotPhoto";
	
			// create logo
			logoClip = new logo(); // in the library
			ageDisplayContainer.addChild(logoClip);
			logoClip.x = 135;
			logoClip.y = 843;
			
			// create year label for left side
			
			yearLabelLeft = new yearLabel(); // in the library
			ageDisplayContainer.addChild(yearLabelLeft);
			yearLabelLeft.x = 100;
			yearLabelLeft.y = 100;
			TextField(yearLabelLeft.getChildByName("ageText")).text = String(currentAge);
			TextField(yearLabelLeft.getChildByName("yearText")).text = String(year);

			// ---------------------- got to load the aged photos..
			ageSequenceClip = new MovieClip(); // this is the containor for the age sequcne photos (the right side of the split screen
			ageDisplayContainer.addChild(ageSequenceClip);
			ageSequenceImagesArray = new Array();
			var tempLoader:Loader;
			for (var i:int = 0; i < ageSequenceFilenamesArray.length; i++) {
				//cycle through the age sequence filenames and load them up into the array, and add them to display list..
				tempLoader = new Loader()
				tempLoader.load(new URLRequest(ageSequenceFilenamesArray[i]));
				ageSequenceImagesArray.push(tempLoader);
				ageSequenceClip.addChild(tempLoader);
			}
			

			
			
	
			
			// create splitline element (thats the thin line and the arrows
			splitlineClip = new splitLine(); // in the library
			ageDisplayContainer.addChild(splitlineClip)

			
			
			// ---------------------------------- lets start setting up the split screen.. 
			splitScreenMask = new MovieClip();
			splitScreenMask.graphics.beginFill(0xFF0000, .5);
			splitScreenMask.graphics.drawRect(0, 0, 575, 905);
			splitScreenMask.graphics.endFill();
			addChild(splitScreenMask);
			splitScreenMask.mouseEnabled = false;
			ageSequenceClip.mask = splitScreenMask;
			
			
			
			// --------------------- this is the alternate logo on the right.. its got to be on top of everything so thats why its down here..
			logoClipRight = new logo(); // in the library
			ageDisplayContainer.addChild(logoClipRight);
			logoClipRight.x = 435;
			logoClipRight.y = 843;
			logoClipRight.visible = false;
			
			// here is the year label on the right (on top of everything)
			yearLabelRight = new yearLabel(); // in the library
			ageSequenceClip.addChild(yearLabelRight);
			yearLabelRight.x = 470;
			yearLabelRight.y = 100;
			
			
			// -------------------------------- setup the events for split screen
			ageDisplayContainer.addEventListener(MouseEvent.MOUSE_DOWN , onMDown);
			FaceAgingMainTimeline.theTimeline.addEventListener(MouseEvent.RELEASE_OUTSIDE , onMUp);
			FaceAgingMainTimeline.theTimeline.addEventListener(MouseEvent.MOUSE_UP , onMUp);
			
			setSplitMask(287)// start the split screen in the middle
			
			setAgePhoto(whatIndexToStartat); // start with which index..  (
			
			// ------------------------------------------ info points
			//FaceAgingMainTimeline.configData.getInfoPointText()
			//FaceAgingMainTimeline.configData.getInfoPointTitles()
			//FaceAgingMainTimeline.configData.getInfoPointLocations()
			
			
	
			infoPointsArray = new Array();
			var tempInfoPoint:MovieClip;
			for (var j:int = 0; j < FaceAgingMainTimeline.configData.getInfoPointLocations().length; j++) {
				// place the info points
				tempInfoPoint = new poiTarget(); // this is the round cicles in the library
				tempInfoPoint.name = "infoPoint" + j;
				infoPointsArray.push(tempInfoPoint);
				ageSequenceClip.addChild(tempInfoPoint);
				tempInfoPoint.x = Point(FaceAgingMainTimeline.configData.getInfoPointLocations()[j]).x;
				tempInfoPoint.y = Point(FaceAgingMainTimeline.configData.getInfoPointLocations()[j]).y;
				tempInfoPoint.gotoAndPlay(j*3);
			}
			
			modalWindowInfoPoint = new infoPointModalWindow();
			addChild(modalWindowInfoPoint);

			

			modalWindowInfoPoint.visible = false;
		}
		internal function showInfoPointWIndow(idx:int):void {
			var cn:TextField = TextField(modalWindowInfoPoint.getChildByName("content"))
			TextField(modalWindowInfoPoint.getChildByName("title")).text = FaceAgingMainTimeline.configData.getInfoPointTitles()[idx];
			cn.htmlText = FaceAgingMainTimeline.configData.getInfoPointText()[idx];
			for (var i:int = 0; i < infoPointsArray.length; i++) {
				MovieClip(infoPointsArray[i].getChildByName("dot")).gotoAndStop(1);
				infoPointsArray[i].visible = false;
			}
			MovieClip(infoPointsArray[idx].getChildByName("dot")).gotoAndStop(2);
			infoPointsArray[idx].visible = true;
			modalWindowInfoPoint.visible = true;
			
		}
		internal function closeInfoPointWindow():void {
			for (var i:int = 0; i < infoPointsArray.length; i++) {
				MovieClip(infoPointsArray[i].getChildByName("dot")).gotoAndStop(1);
				infoPointsArray[i].visible = true;
			}
			modalWindowInfoPoint.visible = false;
		}
		
		private function onMUp(e:MouseEvent):void {
			// stop listening to the movements
			FaceAgingMainTimeline.theTimeline.removeEventListener(MouseEvent.MOUSE_MOVE , onMMove);
		}
		
		private function onMDown(e:MouseEvent):void {
			// on touch mouse down (touch) start listening for the movement
			FaceAgingMainTimeline.theTimeline.addEventListener(MouseEvent.MOUSE_MOVE , onMMove);
		}
		
		private function onMMove(e:MouseEvent):void {
			if ( ageDisplayContainer.mouseX > splitLeftMargin && ageDisplayContainer.mouseX < (575 - splitRightMargin) ) { // make sure we are within margins set above
				trace( "ageDisplayContainer.mouseX : " + ageDisplayContainer.mouseX );
					setSplitMask(ageDisplayContainer.mouseX);
				
				if ( ageDisplayContainer.mouseX < 280) { // we are running into the logo.. switch the position to the right
					logoClip.visible = false;
					logoClipRight.visible = true;
				}else {
					logoClip.visible = true;
					logoClipRight.visible = false;
				}
				
				
			}
			
			
		}
		private function setSplitMask(position:Number):void {
				splitScreenMask.x = position;
				splitScreenMask.width = 575 - position;
				splitlineClip.x = position;
			
		}
		
		
		private function setAgePhoto(idx:int):void {
			
			for (var i:int = 0; i < ageSequenceImagesArray.length; i++) {
				Loader(ageSequenceImagesArray[i]).alpha = 0;
			}
			Loader(ageSequenceImagesArray[idx]).alpha = 1;
			
			TextField(yearLabelRight.getChildByName("ageText")).text = String(ageSeqArr[idx]);	 // set the age and year labels for the aging photos .	
			TextField(yearLabelRight.getChildByName("yearText")).text = String(year+(ageSeqArr[idx] - agenow));
			
		}
		
		private function onChangeAge(e:Event):void {
			// the slider UI just told us the age picture should be changed
			SliderUI(e.currentTarget).currentIndex
			trace( "SliderUI(e.currentTarget).currentIndex :   CHANGE the age photo to index=" + SliderUI(e.currentTarget).currentIndex );
			setAgePhoto(SliderUI(e.currentTarget).currentIndex);
		}
		internal function kill():void {
			// close things down
			sUI.removeEventListener("CHANGE", onChangeAge);
			ageDisplayContainer.removeEventListener(MouseEvent.MOUSE_DOWN , onMDown);
			FaceAgingMainTimeline.theTimeline.removeEventListener(MouseEvent.RELEASE_OUTSIDE , onMUp);
			FaceAgingMainTimeline.theTimeline.removeEventListener(MouseEvent.MOUSE_UP , onMUp);
			FaceAgingMainTimeline.theTimeline.removeEventListener(MouseEvent.MOUSE_MOVE , onMMove);
			sUI.kill();
			// try and remove the movieclips
			for (var i : int = numChildren-1 ; i >= 0 ; i--){
					removeChildAt(i);
			}

		}
		
	}

}