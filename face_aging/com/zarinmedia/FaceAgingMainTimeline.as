package com.zarinmedia {
	import com.adobe.air.filesystem.events.FileMonitorEvent;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.geom.Point;
	import flash.media.*;
	import flash.text.TextField;
	import com.adobe.images.*;
	import flash.filesystem.FileMode;
	import flash.net.*;
	import flash.events.HTTPStatusEvent;
	import com.greensock.*;
	import com.greensock.easing.*;
	import flash.events.OutputProgressEvent;
	import flash.geom.Matrix;
	import flash.ui.Mouse;
	import com.ngxinteractive.dts.DTS;
	import flash.desktop.NativeApplication;
	import flash.utils.setTimeout;
	import flash.display.StageDisplayState;
	//import com.adobe.serialization.json.JSON;

	//JL Feb.5.2016 Added
	import flash.events.IOErrorEvent;
	import flash.utils.getTimer;
	import flash.system.System;
	import flash.errors.IOError;

	//

	/**
	 * ...
	 * Copyright 2015
	 * @author Zoubin Zarin flash@zarinmedia.com
	 */
	public class FaceAgingMainTimeline extends MovieClip {
		// the object oriented gods will not be happy, but it makes sense for me to have my data objects sitting in my main movieclip, and I need to access these from a few other classes
		internal static var imageSequenceData: ImageSequeceData; // remember to reload the image sequence data when the kiosk starts over because the constructor to this class wont get called again..
		internal static var configData: ConfigData; // this data should not change after the software starts, so we dont really need to reload it at any point durring the kiosk's uptime
		internal static var theTimeline: MovieClip;
		private var introImageSequenceLocation: Array;
		private var introImageSequenceSize: Array;
		private var imageSequenceClipArray: Array;
		private var currentISXMLindex: int;
		private var cam: Camera;
		private var vid: Video;
		private var ageText: TextField;
		private var aprilParameters: Object;

		private var snapshotData: BitmapData;
		private var snapshotBitmap: Bitmap;


		private var arrListeners: Array = [];

		private var currentStep: int = 0;
		private var imgBytes: ByteArray;

		internal var photoCaptureFilePath: File;

		private var AprilDocumentID: String;
		private var AprilJobID: String;
		private var apidirectory: String;
		private var checkToSeeIfAprilisDoneTimer: Timer;
		private var ageSequence: Array;

		internal var agedImagesURLArray: Array;
		private var loaderFactJPGArray: Array;
		private var loaderFactTimer: Timer;
		private var loaderFactShowingNow: int;

		private var aDisp: AgeDisplay;
		private var ovalGuideClip: MovieClip;

		private var disableStep1: MovieClip;
		private var emailWindow: emailModalWindow;
		private var screenTimoutTimer: Timer;
		private var checkingTimeout: Boolean = true;
		private var dtsconfig: Object;
		private var ageButtonTimer: Timer;
		private var ageUpButton: MovieClip;
		private var ageDownButton: MovieClip;
		private var selectedAgeButton: MovieClip;
		private var imageSequenceHolder: MovieClip;

		//JL Feb.5.2016 Added
		private var aprilNotDoneCounter: int;
		private var maxAprilAttempts: int;
		//
		
		//MH 
		private var saveBmpData; 
		private var errorCount = 0; 

		private var sq1:ImageSequence;
		private var sq2:ImageSequence;
		private var sq3:ImageSequence;
		private var sq4:ImageSequence;
		private var sq5:ImageSequence;
		private var sq6:ImageSequence;
		


		public function FaceAgingMainTimeline() {
			theTimeline = this;
			
			trace(File.applicationStorageDirectory.nativePath);
			// these are the coordinates to place the image sequence objects in the intro
			introImageSequenceLocation = new Array(new Point(828 + 240, 15), new Point(1105 + 240, 15), new Point(1301 + 240, 15), new Point(828 + 240, 497), new Point(1244 + 240, 675), new Point(1462 + 240, 675));
			introImageSequenceSize = new Array(new Point(262, 464), new Point(182, 322), new Point(365, 646), new Point(304, 538), new Point(204, 360), new Point(204, 360));

			checkToSeeIfAprilisDoneTimer = new Timer(1000);
			
			
			checkToSeeIfAprilisDoneTimer.addEventListener(TimerEvent.TIMER, checkToSeeIfAprilisDoneTimerTick);
			

			var cfdld: URLLoader = new URLLoader(); // lets loadup the config xml.. only need to load once 
			cfdld.load(new URLRequest("xml/SCW-FaceAging-config.xml"));
			cfdld.addEventListener(Event.COMPLETE, onConfigDataLoaded);
			//var now:Date = new Date();
			//trace( "Date(new Date() ).valueOf() : " + now.valueOf() ); // use this value as timestamp in my imagesequncedata xml when its time to re-write it.

			emailWindow = new emailModalWindow(); // this is a library item..

			ageButtonTimer = new Timer(200);
			ageButtonTimer.addEventListener(TimerEvent.TIMER, onAgeButtonTimerTick);

			imageSequenceHolder = MovieClip(getChildByName("isHolder"));
			
		}

		override public function addEventListener(type: String, listener: Function, useCapture: Boolean = false, priority: int = 0, useWeakReference: Boolean = false): void {
			// record what event listeners we added so that we can kill them easily at the end
			trace("override the addeventlistener function in the main class");
			trace("arrListeners : " + arrListeners);
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
			arrListeners.push({
				type: type,
				listener: listener
			});
		}
		
		
		

		private function clearEvents(): void {
			// go through all the listeners we have logged and shut them down..
			for (var i: Number = 0; i < arrListeners.length; i++) {
				if (this.hasEventListener(arrListeners[i].type)) {
					trace("removed an event listener in the main class");
					this.removeEventListener(arrListeners[i].type, arrListeners[i].listener);
				}
			}
			arrListeners = null
			arrListeners = new Array();
		}

		private function onConfigDataLoaded(e: Event): void {
			URLLoader(e.target).removeEventListener(Event.COMPLETE, onConfigDataLoaded); // make a habbit of removing all my listeners so that it doesn't leak memory over time as the kiosk is on for days...
			FaceAgingMainTimeline.configData = new ConfigData(new XML(e.target.data));
			apidirectory = "http://" + FaceAgingMainTimeline.configData.getAPILocation() + "/api/";

			// might as well loadup the loaderslide images here, by the time we get there they should be loaded
			loaderFactJPGArray = new Array();
			var tempLoader: Loader;
			for (var i: int = 0; i < FaceAgingMainTimeline.configData.getLoaderImageSlideFilenames().length; i++) {
				tempLoader = new Loader();
				tempLoader.load(new URLRequest(FaceAgingMainTimeline.configData.getLoaderImageSlideFilenames()[i]));
				loaderFactJPGArray.push(tempLoader);
			}

			loaderFactTimer = new Timer(FaceAgingMainTimeline.configData.getLoaderImageSlideTiming() * 1000); // setup the timer.. we can just turn it on and off as we need to..
			loaderFactTimer.addEventListener(TimerEvent.TIMER, onLoadFactTimerTick);

			if (FaceAgingMainTimeline.configData.getMouseHide() == "true") {
				Mouse.hide();
			}

			if (FaceAgingMainTimeline.configData.isAppFullScreen() == "true") {
				stage.displayState = StageDisplayState.FULL_SCREEN;
			}

			screenTimoutTimer = new Timer(FaceAgingMainTimeline.configData.getScreenTimeout() * 1000);
			screenTimoutTimer.addEventListener(TimerEvent.TIMER, onScreenTimeoutTick);
			
			//JL Feb.5.2016 Added
			maxAprilAttempts = FaceAgingMainTimeline.configData.getmaxAprilAttempts();
			//

			// loadup dts config..
			var dtsloader: URLLoader = new URLLoader();
			var dtsrequest: URLRequest = new URLRequest();
			dtsrequest.url = FaceAgingMainTimeline.configData.getDTSconfigLocation();
			dtsloader.addEventListener(Event.COMPLETE, onDTSConfigLoaded);
			dtsloader.load(dtsrequest);
		}

		private function onDTSConfigLoaded(e: Event): void {
			URLLoader(e.target).removeEventListener(Event.COMPLETE, onDTSConfigLoaded);
			stage.nativeWindow.addEventListener(Event.CLOSING, onCloseApplication);

			var urlloader: URLLoader = URLLoader(e.target);
			dtsconfig = JSON.parse(urlloader.data);
			DTS.setupTracking(dtsconfig);
			DTS.sendLoaded();
			loadUpTheIntro();
		}

		private function onCloseApplication(e) {
			if (e) {
				e.preventDefault();
			}

			DTS.sendQuit();
			setTimeout(exit, 0.2);
		}

		private function exit(): void {
			NativeApplication.nativeApplication.exit();
		}

		private function onScreenTimeoutTick(e: TimerEvent): void {
			// we have not reset this timer in a long time, so we should probably reset the app...
			removeEventListener(MouseEvent.CLICK, onClick); // cleanup the click event for steps 1 2 and 3
			killStep(currentStep); // this should close down the current step so we can go back to the intro
			clearEvents();
			gotoAndPlay("intro");
			currentStep = 0;
			screenTimoutTimer.stop();
		}

		internal function resetTimeout(): void {
			screenTimoutTimer.reset();
			if (checkingTimeout) {
				screenTimoutTimer.start();
			}
		}

		internal function freezeTimeout(ft: Boolean = true): void {
			if (ft) {
				checkingTimeout = false;
			} else {
				checkingTimeout = true;
			}
			resetTimeout();
		}

		private function loadUpTheIntro(): void {
			currentStep = 0;

			// now that we have the config xml, we know the location of the image sequnce xml file and can load it in
			var ISXLoader: URLLoader = new URLLoader();
			ISXLoader.load(new URLRequest(FaceAgingMainTimeline.configData.getIntroXMLfilePath()));
			ISXLoader.addEventListener(Event.COMPLETE, onISXLoaded);
			FaceAgingMainTimeline.imageSequenceData = null; // make sure this is empty
			imageSequenceClipArray = null;
		}

		private function onISXLoaded(e: Event): void {
			URLLoader(e.target).removeEventListener(Event.COMPLETE, onISXLoaded); // clean up after the listener
			FaceAgingMainTimeline.imageSequenceData = new ImageSequeceData(new XML(e.target.data));
			// ok so now we have the xml in the imageSequenceData object and can use it
			// we just sit there until in the timeline we call the startImageSequence..
		}

		
		private function performMemTest():void {
		trace("!!!!!! MEMORY : " + System.totalMemory);
		}
		
		
		internal function startImageSequence(): void {
			
			
			performMemTest();
			
			DTS.sendAttractStart(); // tracking wants to know when we start the attract screen..
			if (snapshotData) {
				// clean up the bitmap data
				snapshotData.dispose(); 
			}

			
			if (imageSequenceData.numberOfImageSequences() > 5) { // leave things blank if we dont have at least 6 image sequences to show
				imageSequenceClipArray = new Array();
				var tempISObj: ImageSequence;
				for (var i: int = 0; i < 6; i++) {
					// create the image sequence objects and place them 
					
					if(!this["sq"+(i+1)]){
							trace("!!!!!REDRAWN");
					}
					this["sq"+(i+1)] = (this["sq"+(i+1)]) ? this["sq"+(i+1)] : this["sq"+(i+1)] = new ImageSequence(); 
					
					
					
					this["sq"+(i+1)].initialize(i, Point(introImageSequenceSize[i]).x, Point(introImageSequenceSize[i]).y); 
					// tempISObj = new ImageSequence(i, Point(introImageSequenceSize[i]).x, Point(introImageSequenceSize[i]).y)
					imageSequenceHolder.addChild(this["sq"+(i+1)])
					imageSequenceClipArray.push(this["sq"+(i+1)]);
					this["sq"+(i+1)].x = Point(introImageSequenceLocation[i]).x;
					this["sq"+(i+1)].y = Point(introImageSequenceLocation[i]).y;
					this["sq"+(i+1)].name = "imageSequenceMovieclip" + i; // like to name the clips..	

					if (i == 0) {
						this["sq"+(i+1)].loadSequence(i); // play the first one
					} else {
						this["sq"+(i+1)].loadSequence(i, false); // pause on first frame for all the others
					}

					this["sq"+(i+1)].addEventListener("COMPLETE", onImageSquenceComplete);
				}
				// by this point we have created the image sequcne
			
				currentISXMLindex = 0; // this means the real animated image sequence remains to be #0 even tho we have placed all the others on the stage (and frozen their frame).
			} else {
				trace("WARNING: There are less than 6 photo sequences to display in the intro, please be sure there is at least 6 sequences in the xml");
			}
		}

		private function onImageSquenceComplete(e: Event): void {
			var nextISObject: ImageSequence
			if (ImageSequence(e.target).idx > 4) {
				// this conditional loops through the IS objects, once we get to #5, start at 0 again..
				nextISObject = imageSequenceClipArray[0]
			} else {
				nextISObject = imageSequenceClipArray[ImageSequence(e.target).idx + 1]
			}
			if (ImageSequence(e.target).imageSequenceIndexPlayingNow > -1) { // only advance if we are not on a freeze frame scenario
				if (currentISXMLindex > FaceAgingMainTimeline.imageSequenceData.numberOfImageSequences() - 2) {
					// this conditional loops through the xml index for the image sequences..
					currentISXMLindex = 0;
				} else {
					currentISXMLindex++
				}
			}

			nextISObject.loadSequence(currentISXMLindex);
			// we hand off the loading and playing to the next object...
		}

		private function killIntro(): void {
			clearEvents(); // remove any listiners we have been keeping track of..
			try {
				for (var i: int = 0; i < imageSequenceClipArray.length; i++) {
					trace("REMOVE ******************imageSequenceClipArray : " + i);
					ImageSequence(imageSequenceClipArray[i]).killMe(); // go through all the image sequnce objects and kills them..
					this.removeChild(imageSequenceClipArray[i]);
				}
			} catch (error: Error) {
				trace("***********************TRY error : " + error);
			}
			imageSequenceClipArray = null;
		}

		private function killStep(i: int): void {
			if (i == 1) {
				// for step 1.. do the following
				removeChild(ovalGuideClip);
				removeChild(vid); // remove the video
			}

			if (i == 2) {
				// step 2
				removeChild(snapshotBitmap); // take the snapshot off the screen
			}

			if (i == 3) {
				
				
				
				
				try{
				aDisp.kill();
				} catch (e){
					
				}
				
				try{
					removeChild(aDisp);
				} catch(e){}
				// remove the slider and splitscreen element
				try {
					removeChild(emailWindow)
				} catch (e: Error) {
					trace("TRY error caught : " + e);
				}
			}
		}

		internal function enableIntroTouch(): void {
			addEventListener(MouseEvent.CLICK, onIntroTouchStage);
			imageSequenceHolder.visible = true;
		}

		private function onIntroTouchStage(e: MouseEvent): void {
			currentStep = 1;
			
			
			
			DTS.sendScreen('step1', 'Moving to step 1');
			e.currentTarget.removeEventListener(MouseEvent.CLICK, onIntroTouchStage); // cleanup
			killIntro();
			this.play();

			// here is some code that I dont want called if we hit the back button
			aprilParameters = new Object();
			DTS.sendAttractBreak(); // tell the tracking that we have clicked out of the attract screen..
		}

		internal function loadupStep1(): void {
			
			
			if(aprilParameters){
				if(aprilParameters.age){
					if(aprilParameters.age < 9){
						
					trace(String(aprilParameters.age) + " IS AGE")
						tens_text.text = "0"; 
						ones_text.text = String(aprilParameters.age);
						
					} else {
						tens_text.text = String(aprilParameters.age).substr(0,1); 
						ones_text.text = String(aprilParameters.age).substr(1,1);
					}
				}
			}
			
			
			errorCount = 0;
			imageSequenceHolder.visible = false;
			screenTimoutTimer.start(); // from now on.. reset the program if its inactive for the amount of time specified in the xml..
			if (Camera.names.length > 0) {
				trace("User has at least one camera installed.");
				cam = Camera.getCamera();
				cam.setMode(575, 1020, 24);
				vid = new Video(575, 1020);
				vid.x = 15;
				vid.y = 15;
				if (FaceAgingMainTimeline.configData.getMirrorWebcam() == "true") {
					vid.scaleX = -1;
					vid.x = 15 + 575
				}

				vid.attachCamera(cam);
				addChild(vid);
				ovalGuideClip = new oval();

				if (FaceAgingMainTimeline.configData.useFaceGuides() != "true") {
					MovieClip(ovalGuideClip.getChildByName("faceGuides")).visible = false;
				}

				if (FaceAgingMainTimeline.configData.dimCameraBackground() != "true") {
					MovieClip(ovalGuideClip.getChildByName("dim")).visible = false;
				}

				addChild(ovalGuideClip)
				ovalGuideClip.x = 302;
				ovalGuideClip.y = 463;
			} else {
				trace("User has no cameras installed.");
			}

			ageText = TextField(getChildByName("ageLabel"));

			if (aprilParameters.age != undefined) { // if the age is in the parameters object, use that as the default
				ageText.text = aprilParameters.age
			} else {
				//aprilParameters.age = makeSureAgeIsLegal(FaceAgingMainTimeline.configData.getDefaultAge())
				aprilParameters.age = 0;
				//otherwise default comes from the xml
				ageText.text = String(aprilParameters.age); //sets the default age we are starting off with
			}

			//polulate skin color if it is defined in the parameters
			if (aprilParameters.ethnicity != undefined) {
				if (aprilParameters.ethnicity == 3) {
					MovieClip(getChildByName("skin1")).gotoAndStop(2);
				}
				if (aprilParameters.ethnicity == 0) {
					MovieClip(getChildByName("skin2")).gotoAndStop(2);
				}
				if (aprilParameters.ethnicity == 2) {
					MovieClip(getChildByName("skin3")).gotoAndStop(2);
				}
			}

			// populate sex if defined in april parameters
			if (aprilParameters.gender != undefined) {
				if (aprilParameters.gender == 1) {
					MovieClip(getChildByName("sex1")).gotoAndStop(2);
				} else {
					MovieClip(getChildByName("sex2")).gotoAndStop(2);
				}
			}

			addEventListener(MouseEvent.CLICK, onClick); // now lets register a listener to catch all clicks on the stage.. (and then firgure out which button by the name..
			disableStep1 = MovieClip(getChildByName("disablebutton"));
			checkStep1ButtonEnable();

			ones.up.addEventListener(MouseEvent.CLICK, onesUp);
			ones.down.addEventListener(MouseEvent.CLICK, onesDown);
			tens.up.addEventListener(MouseEvent.CLICK, tensUp);
			tens.down.addEventListener(MouseEvent.CLICK, tensDown);

			/*
			ageUpButton = MovieClip(getChildByName("ageUp"));
			ageDownButton = MovieClip(getChildByName("ageDown"))
			
			ageUpButton.addEventListener(MouseEvent.MOUSE_DOWN , onAgeButtonMouseDown );
			ageDownButton.addEventListener(MouseEvent.MOUSE_DOWN , onAgeButtonMouseDown );
			ageUpButton.addEventListener(MouseEvent.MOUSE_UP , onAgeButtonMouseUp );
			ageDownButton.addEventListener(MouseEvent.MOUSE_UP , onAgeButtonMouseUp );
			ageUpButton.addEventListener(MouseEvent.RELEASE_OUTSIDE , onAgeButtonMouseUp );
			ageDownButton.addEventListener(MouseEvent.RELEASE_OUTSIDE , onAgeButtonMouseUp );
			*/
		}

		private function onesUp(e) {
			var n = ones_text.text;
			n++;
			if (n > 9) {
				ones_text.text = "0";
			} else {
				ones_text.text = n;
			}
			aprilParameters.age = makeSureAgeIsLegal(int(tens_text.text + ones_text.text));
			checkStep1ButtonEnable();
		}

		private function tensUp(e) {
			var n = tens_text.text;
			n++;
			if (n > 7) {
				tens_text.text = "0";
			} else {
				tens_text.text = n;
			}
			aprilParameters.age = makeSureAgeIsLegal(int(tens_text.text + ones_text.text));
			checkStep1ButtonEnable();
		}

		private function onesDown(e) {
			var n = ones_text.text;
			n--;
			if (n < 0) {
				ones_text.text = "9";
			} else {
				ones_text.text = n;
			}
			aprilParameters.age = makeSureAgeIsLegal(int(tens_text.text + ones_text.text));
			checkStep1ButtonEnable();
		}

		private function tensDown(e) {
			var n = tens_text.text;
			n--;
			if (n < 0) {
				tens_text.text = "7";
			} else {
				tens_text.text = n;
			}
			aprilParameters.age = makeSureAgeIsLegal(int(tens_text.text + ones_text.text));
			checkStep1ButtonEnable();
		}

		private function onAgeButtonTimerTick(e: TimerEvent): void {
			if (selectedAgeButton.name == "ageUp") {
				increaseAge();
			} else {
				decreaseAge();
			}
		}

		private function increaseAge(): void {
			//ageUp.play();
			if (aprilParameters.age < 64) {
				aprilParameters.age++
			}
			aprilParameters.age = makeSureAgeIsLegal(aprilParameters.age);
			ageText.text = String(aprilParameters.age);
			checkStep1ButtonEnable();
		}

		private function decreaseAge(): void {
			//ageDown.play();
			if (aprilParameters.age > 6) {
				aprilParameters.age--
			}
			aprilParameters.age = makeSureAgeIsLegal(aprilParameters.age);
			ageText.text = String(aprilParameters.age);
			checkStep1ButtonEnable();
		}

		private function onAgeButtonMouseUp(e: MouseEvent): void {
			ageButtonTimer.reset();
			ageButtonTimer.stop();
			selectedAgeButton.gotoAndStop(1);
		}

		private function onAgeButtonMouseDown(e: MouseEvent): void {
			// one of the age buttons is pressed, so start it increasing values
			selectedAgeButton = MovieClip(e.target);
			selectedAgeButton.gotoAndStop(2);
			ageButtonTimer.start();
		}

		private function checkStep1ButtonEnable(): void {
			if (aprilParameters.ethnicity == undefined || aprilParameters.gender == undefined || aprilParameters.age < 6 || aprilParameters.age > 65) {
				disableStep1.visible = true;
			} else {
				disableStep1.visible = false;
			}
		}

		private function makeSureAgeIsLegal(agein: int): int {
			trace(agein);
			return agein;
		}

		private function onClick(e: MouseEvent): void {
			// we catch all the buttons here
			resetTimeout();

			var buttonPressed: String = e.target.name;
			if (buttonPressed == "ageDown") {

				decreaseAge();
			}
			if (buttonPressed == "ageUp") {
				increaseAge();
			}
			if (buttonPressed.substr(0, 4) == "skin") {
				setSkin(int(buttonPressed.substr(4, 1)));
				checkStep1ButtonEnable();
			}

			if (buttonPressed.substr(0, 3) == "sex") {
				setSex(int(buttonPressed.substr(3, 1)));
				checkStep1ButtonEnable();
			}

			if (buttonPressed == "takePhotoButton") {
				// do the countdown..
				/*
				ageUpButton.removeEventListener(MouseEvent.MOUSE_DOWN , onAgeButtonMouseDown );
				ageDownButton.removeEventListener(MouseEvent.MOUSE_DOWN , onAgeButtonMouseDown );
				ageUpButton.removeEventListener(MouseEvent.MOUSE_UP , onAgeButtonMouseUp );
				ageDownButton.removeEventListener(MouseEvent.MOUSE_UP , onAgeButtonMouseUp );
				ageUpButton.removeEventListener(MouseEvent.RELEASE_OUTSIDE , onAgeButtonMouseUp );
				ageDownButton.removeEventListener(MouseEvent.RELEASE_OUTSIDE , onAgeButtonMouseUp );
				*/
				play();
			}

			if (buttonPressed == "agePhotoButton") {
				killStep(2);
				currentStep = 3;
				DTS.sendScreen('step3', 'Moving to step 3');
				play();
				// savePhoto(snapshotData);  is being called from the timeline so that it doesn't freeze the loader..  look for it there... :-)
				// start putting up the loader facts

				nextLoaderFactImage();
				loaderFactTimer.start();
			}

			if (buttonPressed == "testbutton") {
				aprilParameters.age = 26;
				aprilParameters.sex = 1;
				aprilParameters.ethnicity = 0;
				ageSequence = calculateAgeSequence();
				var tbmd: BitmapData = new testJpg();
				snapshotData = new BitmapData(575, 1020, false);

				var matrix: Matrix = new Matrix();
				matrix.scale((575 / tbmd.width), (575 / tbmd.width));
				snapshotData.draw(tbmd, matrix);

				killStep(2);
				currentStep = 3;

				DTS.sendScreen('step3', 'Test button 1 step 3');
				play();
				nextLoaderFactImage();
				loaderFactTimer.start();
				trace("snapshotBitmap : " + snapshotData);
				snapshotBitmap = new Bitmap(snapshotData);
			}

			if (buttonPressed == "testbutton2") {
				aprilParameters.age = 28;
				aprilParameters.sex = 0;
				aprilParameters.ethnicity = 0;
				ageSequence = calculateAgeSequence();
				var tbmd2: BitmapData = new testJpg2();
				snapshotData = new BitmapData(575, 1020, false);

				var matrix2: Matrix = new Matrix();
				matrix2.scale((575 / tbmd2.width), (575 / tbmd2.width));
				snapshotData.draw(tbmd2, matrix2);

				killStep(2);
				currentStep = 3;
				DTS.sendScreen('step3', 'Test button 2 step 3');
				play();
				nextLoaderFactImage();
				loaderFactTimer.start();
				trace("snapshotBitmap : " + snapshotData);
				snapshotBitmap = new Bitmap(snapshotData);
			}

			if (buttonPressed == "startOver" || buttonPressed == "finish") {
				
				TweenLite.killDelayedCallsTo(restart);
				
				removeEventListener(MouseEvent.CLICK, onClick); // cleanup the click event for steps 1 2 and 3
				killStep(currentStep); // this should close down the current step so we can go back to the intro
				clearEvents();
				gotoAndPlay("intro");
				currentStep = 0;
			}

			if (buttonPressed.substr(0, 9) == "infoPoint") {
				var tp: Number = int(buttonPressed.substr(9, 1))
				aDisp.showInfoPointWIndow(tp);
				DTS.sendScreen('step3/infopoint' + tp, 'clicked on infopoint #' + tp);
			}

			if (buttonPressed == "infopointwindowclose" || buttonPressed == "clickoutsideinfopointmodal") {
				aDisp.closeInfoPointWindow();
			}

			if (buttonPressed == "backButton" || buttonPressed == "retake") {
				
				TweenLite.killDelayedCallsTo(restart);
				// the only place this can be pressed is when we are in step2 
				killStep(currentStep);
				currentStep = 1;
				gotoAndPlay("step1");

				DTS.sendScreen('step1', 'went back to step1');
			}

			if (buttonPressed == "emailBtn") {
				var showingImagenumber: int = aDisp.sUI.currentIndex;

				if (showingImagenumber < 0) { // in case the user hasnt interacted with the slider yet.. then just use the first value..
					showingImagenumber = 4;
				}

				emailWindow.setEmailPhoto(photoCaptureFilePath.nativePath, aprilParameters.age, agedImagesURLArray[showingImagenumber], ageSequence[showingImagenumber]); // send along info we need to put together the image to send in the email..
				addChild(emailWindow);
				DTS.sendScreen('step3/email_window', 'User launched the email window');
			}
			if (buttonPressed == "emailwindowclose" || buttonPressed == "clickoutsideemailmodal") {
				emailWindow.exitWindow();
				removeChild(emailWindow);
			}

		}

		internal function takeThePicture(): void {
			trace("***********************FaceAgingMainTimeline.takeThePicture");
			killStep(1); // cleanup the last step
			currentStep = 2; // we are now entering the new step
			DTS.sendScreen('step2', 'age:' + aprilParameters.age + " gender:" + aprilParameters.gender + " ethnicity:" + aprilParameters.ethnicity);
			//e.currentTarget.removeEventListener(MouseEvent.CLICK , onIntroTouchStage );// cleanup
			// take the picture
			snapshotData = new BitmapData(vid.width, vid.height);
			snapshotData.draw(vid);
			snapshotBitmap = new Bitmap(snapshotData);

			// put together ageSequence
			ageSequence = calculateAgeSequence();

			//replace it with the bitmap
			addChild(snapshotBitmap);
			snapshotBitmap.x = 15;
			snapshotBitmap.y = 15;
			gotoAndPlay("step2");
		}

		private function nextLoaderFactImage(): void {
			var holder: MovieClip;
			var lastimagenumber: int = loaderFactShowingNow;
			if (getChildByName("loaderFactImageClip") == null) {
				lastimagenumber = -1;
				// this is the first run, so create the clip

				var tc: MovieClip = new MovieClip();
				addChild(tc);
				tc.x = 15;
				tc.y = 15; // put it in position..
				tc.name = "loaderFactImageClip";
				for (var i: int = 0; i < loaderFactJPGArray.length; i++) {
					tc.addChild(loaderFactJPGArray[i]);
					loaderFactJPGArray[i].alpha = 0; // turn them all off to start
				}
				loaderFactShowingNow = 0;

			} else {
				// we have a movieclip by this name..
				if (loaderFactShowingNow > (loaderFactJPGArray.length - 2)) {
					// if its the end start at zero again
					loaderFactShowingNow = 0;
				} else {
					// we have not reached the end yet
					loaderFactShowingNow++;
				}
			}

			holder = MovieClip(getChildByName("loaderFactImageClip"));
			loaderFactJPGArray[loaderFactShowingNow].alpha = 0;
			holder.setChildIndex(loaderFactJPGArray[loaderFactShowingNow], holder.numChildren - 1); // bring the one we are interested in to the top so that we can fade over the last one..
			if (lastimagenumber < 0) { // if its the first time.. just play it..
				TweenLite.to(loaderFactJPGArray[loaderFactShowingNow], FaceAgingMainTimeline.configData.getLoaderImageSliderFadeTiming(), {
					alpha: 1,
					ease: Quart.easeOut
				});
			} else {
				// if its cycling.. remove the last slide before bringing in the next one..
				TweenLite.to(loaderFactJPGArray[loaderFactShowingNow], FaceAgingMainTimeline.configData.getLoaderImageSliderFadeTiming(), {
					alpha: 1,
					ease: Quart.easeOut,
					delay: FaceAgingMainTimeline.configData.getLoaderImageSliderFadeTiming()
				});
				TweenLite.to(loaderFactJPGArray[lastimagenumber], FaceAgingMainTimeline.configData.getLoaderImageSliderFadeTiming(), {
					alpha: 0,
					ease: Quart.easeOut
				});
			}
		}

		internal function removeEmailPopup(): void {
			removeChild(emailWindow);
		}

		private function calculateAgeSequence(): Array {
			var retArray: Array = new Array()
			var increaseageby: int = Math.round(((70 - aprilParameters.age) / 5));

			
		
 

			// MH
			var ageStep = (70 - aprilParameters.age)/5; 

			for(var index = 0; index<4; index++) 
			{
				var age = Math.round(aprilParameters.age + (ageStep * (index + 1)));
				retArray.push(age)
			}
			
			retArray.push(70);
			
			

			/*
			for (var i: int = int(aprilParameters.age) + increaseageby; i < 70; i = i + increaseageby) {
				
				trace("AGE IS " + i);
				retArray.push(i);
			}
			retArray.push(70);

			if (retArray.length > 5) {
				trace("ERROR: for some reason we have too many age elements in the ageSequence array");
				// so if for some reason we have more than 5 elements, make sure there are 5 and set the last to 70..
				retArray.pop();
				retArray[4] = 70;
				 
			}

			*/
			
			
			return retArray.sort();;
		}

		private function onLoadFactTimerTick(e: TimerEvent): void {
			trace("FaceAgingMainTimeline.onLoadFactTimerTick > e : ");
			// show the next loader fact...
			nextLoaderFactImage();
		}

		private function removeLoaderFactImage(): void {
			// remove the loader face image clip... and stop the timer, we are moving on
			if (getChildByName("loaderFactImageClip") != null) {
				var tc: MovieClip = MovieClip(getChildByName("loaderFactImageClip"));
				for (var i: int = tc.numChildren - 1; i >= 0; i--) {
					tc.removeChildAt(i);
				} // first get rid of the all the children
				removeChild(getChildByName("loaderFactImageClip")); // then the parent..

				// stop and reset the timer
				loaderFactTimer.reset();
				loaderFactTimer.stop();
			}
		}

		
		function sleep(ms:int):void {
			var init:int = getTimer();
			while(true) {
				if(getTimer() - init >= ms) {
					break;
				}
			}
		}
		
		
		private function savePhoto(bmpData: BitmapData): void { /// NOTE: this gets called from the Flash timeline.. (dont get confused) had to do it that way as it freezes the system.. so I wanted to give time to the loader elements
			
			trace("ERROR COUNT " + errorCount)
			saveBmpData = bmpData;
			
			var jEncoder: JPGEncoder = new JPGEncoder(99);
			imgBytes = jEncoder.encode(saveBmpData)
			
			//var filePath:File = File.documentsDirectory.resolvePath("april_capture.jpg");
			photoCaptureFilePath = File.documentsDirectory.resolvePath("April Age\\april_capture"+errorCount+".jpg");
			var s: FileStream = new FileStream();
			
			s.addEventListener(Event.CLOSE, onFinishedSavingPhoto); // this doesnt seem to work , but after the close we seem to have written the file..
			s.addEventListener(IOErrorEvent.IO_ERROR, saveIO);
			s.openAsync(photoCaptureFilePath, FileMode.WRITE);
			s.writeBytes(imgBytes);
			s.close();
			
			//freezeTimeout(true);
			
		}
		
		
		
		private function saveIO(e){
			
			
			errorCount ++;
			if(errorCount < 20){
				savePhoto(saveBmpData); 
			} else {
			onFinishedSavingPhoto(false)	
			}
		}

		private function onFinishedSavingPhoto(e): void { // not working see whats up with this.. it should be firing when the photo is saved..
			e.target.removeEventListener(Event.CLOSE, onFinishedSavingPhoto);
			// ok.. so our file is now saved..
			//e.target.close();
			//var apidirectory:String = "http://" + FaceAgingMainTimeline.configData.getAPILocation() + "/api/";
			// first we make document object

			//start passing the data to April
			// make document
			var sendParams: String
			//if (testText.text == "true") {
			// this is to test with an image we know works
			//	sendParams = '{"Name":"SCWAGE KIOSK","Age":' + int(aprilParameters.age) + ',"Gender":' + int(aprilParameters.gender) + ',"Ethnicity":' + int(aprilParameters.ethnicity) + ',"OriginalImagePath":"C:\\\\Users\\\\zz\\\\Documents\\\\April Age\\\\test.jpg"}';
			//}else {
			// this is the normal image from the camera..
			sendParams = '{"Name":"SCWAGE KIOSK","Age":' + int(aprilParameters.age) + ',"Gender":' + int(aprilParameters.gender) + ',"Ethnicity":' + int(aprilParameters.ethnicity) + ',"OriginalImagePath":"' + doubleDashify(String(photoCaptureFilePath.nativePath)) + '"}';
			//	}

			//JL Feb.5.2016 Added
			aprilNotDoneCounter = 0;
			//

			trace("sendParams  to setup document: " + sendParams);
			callAprilAPI("documents", sendParams, onAprilDocumentCreated); // make the document 
		}

		private function doubleDashify(stringIn: String): String {
			var pattern: RegExp = /\\/g;
			return stringIn.replace(pattern, "\\\\");
		}

		private function onAprilDocumentCreated(e: Event): void {
			trace("FaceAgingMainTimeline.onAprilDocumentCreated > e : ");
			var loader: URLLoader = URLLoader(e.target);
			var data: Object = JSON.parse(loader.data);
			AprilDocumentID = data.Id
			// so now make a job object...
			var sendParams: String;
			sendParams = '{"DocumentId":"' + AprilDocumentID + '","Smoking":' + FaceAgingMainTimeline.configData.getAprilSmoking() + ',"SunExposure":' + FaceAgingMainTimeline.configData.getAprilSun() + ',"ObesityIntensity":' + FaceAgingMainTimeline.configData.getAprilObesity() + ',"AgeSequence":"' + ageSequence + '"}';

			callAprilAPI("document/age", sendParams, onApriljobCreated); // create a job object
		}

		private function onApriljobCreated(e: Event): void {
			trace("FaceAgingMainTimeline.onApriljobCreated > e : ");
			var loader: URLLoader = URLLoader(e.target);
			var data: Object = JSON.parse(loader.data);
			AprilJobID = data.Id
			trace("APRIL JOB CREATED (" + AprilJobID + ") ----- April Job Status : " + data.Status);
			
			checkToSeeIfAprilisDoneTimer.start();
			
			//	callAprilAPI("jobs/", AprilJobID, checkOnTheJobID, false); // we call this command to check the status of the job... 1 means its working on it, 2 means its good, 3 means there was a problem..
		}

		private function checkOnTheJobID(e: Event): void {
			trace("FaceAgingMainTimeline.checkOnTheJobID > e : ");
			var loader: URLLoader = URLLoader(e.target);
			var data: Object = JSON.parse(loader.data);
			trace("check job status (" + AprilJobID + ") ----- April Job Status : " + data.Status);

			if (int(data.Status) == 2) {

				// the aging seemed to work
				trace("----:  + the aging seemed to work ");
				checkToSeeIfAprilisDoneTimer.stop();
				//JL Feb.5.2016 Added:
				checkToSeeIfAprilisDoneTimer.reset(); //We might need it again ;)
				//
				callAprilAPI("results/", AprilDocumentID, getAprilAgeResults, false);
			} else if (int(data.Status) == 1) {
				// still processing
				//checkToSeeIfAprilisDoneTimer.start();
			} else if (int(data.Status) == 3) {
				//JL Feb.5.2016 Commented, Added
				//// the aging failed****************************************************************************ERROR 3
				////addChild(new errorMessage() );
				//checkToSeeIfAprilisDoneTimer.stop();
				//currentStep = 2;
				//removeLoaderFactImage();
				//addChild(snapshotBitmap);
				//gotoAndPlay("error3");
				//trace("********************************gotoAndPlay(\"error3\") :  current step " + currentStep);
				aprilFailed();
				//
			}
		}
		
		
		//MH Feb.09.2016 Added
		public function logError(error){
			
			var fs:FileStream = new FileStream();
			trace(File.applicationStorageDirectory.nativePath)
			
			var update; 
			
			
			try{
				// try open
				fs.open(new File(File.applicationStorageDirectory.nativePath).resolvePath("error.txt"),FileMode.READ);
				fs.close()
				
				// append
				fs.open(new File(File.applicationStorageDirectory.nativePath).resolvePath("error.txt"),FileMode.APPEND);
				update = error + "\n";
				fs.writeUTFBytes(update);
				fs.close()
				
				
			} catch(e){
				
				
				
				trace(File.applicationStorageDirectory.nativePath)
				fs.open(new File(File.applicationStorageDirectory.nativePath).resolvePath("error.txt"),FileMode.WRITE);
				
				
				update = error + "\n";
				fs.writeUTFBytes(update);
				fs.close()
			
			}
			
			
			
		}
		
		//MH Feb.09.2016 Added
		private function restart(){
			
				killStep(currentStep); // this should close down the current step so we can go back to the intro
				clearEvents();
				gotoAndPlay("intro");
				currentStep = 0;
			
		}
		

		//JL Feb.5.2016 Added - MH Feb.09.2016 Edited
		private function aprilFailed(e: IOErrorEvent = null): void {
			// the aging failed****************************************************************************ERROR 3
			// addChild(new errorMessage() );
			
			// Log Error
			
				//
			
			//
			if(e){
				DTS.sendScreen('error', e.text);
				logError(e.text);
			}
			checkToSeeIfAprilisDoneTimer.stop();			
			checkToSeeIfAprilisDoneTimer.reset(); //We might need it again ;)
			currentStep = 2;
			removeLoaderFactImage();
			addChild(snapshotBitmap);
			gotoAndPlay("error3");
			
			TweenLite.delayedCall(5,restart);
			trace("********************************gotoAndPlay(\"error3\") :  current step " + currentStep);
		}
		//

		private function getAprilAgeResults(e: Event): void {
			//trace( "FaceAgingMainTimeline.getAprilAgeResults > e : " );
			var loader: URLLoader = URLLoader(e.target);
			var data: Object = JSON.parse(loader.data);
			//var jsonArray:Array = JSON.decode(loader.data);
			//var jsonArray:Array = com.adobe.serialization.json.JSON.decode(loader.data);

			for (var id: String in data) {
				var value: Object = data[id];
				trace("data[id].Id : " + data[id].Images);
				trace(id + " = " + value);
			}

			agedImagesURLArray = new Array();
			//trace( "data[\"0\"].Images[0].ImagePath : " + data["0"].Images[0].ImagePath );
			// put together the URLS to the aged images
			for (var i: int = 0; i < data[id].Images.length; i++) {
				agedImagesURLArray.push(data["0"].Images[i].ImagePath);
			}
			// this function re-writes the xml file with the latest set of images.
			FaceAgingMainTimeline.imageSequenceData.saveNewSequence(photoCaptureFilePath, aprilParameters.age, agedImagesURLArray, ageSequence, FaceAgingMainTimeline.configData.getIntroImageDirectory(), FaceAgingMainTimeline.configData.getIntroMaximum(), FaceAgingMainTimeline.configData.getIntroXMLfilePath());
			FaceAgingMainTimeline.imageSequenceData.addEventListener("COPIED", onSeqCopied); // wait for all the files copied.. we have to change the filename reference to new names
		}

		private function onSeqCopied(e: Event): void {
			FaceAgingMainTimeline.imageSequenceData.removeEventListener("COPIED", onSeqCopied)
			agedImagesURLArray = FaceAgingMainTimeline.imageSequenceData.newSequenceLocationArray; // we have new file locations..
			loadUpTheIntro(); // this makes sure that the image sequence xml is reloaded and ready if we hit the start button
			currentStep = 3;
			play(); // now that we made the switch we can move on to section 3 in the timeline..
		}

		internal function startStep3(): void { // call this from the timeline in the flash...
			freezeTimeout(false);
			removeLoaderFactImage(); // close down the laoder facts as we've moved onto step 3
			aDisp = new AgeDisplay(snapshotBitmap, aprilParameters.age, ageSequence, agedImagesURLArray); // create the age display movieclip.. this is the slipt screen display and the slider that controls it..
			aDisp.name = "ageDisplay";
			aDisp.x = 15;
			aDisp.y = 15;
			addChild(aDisp);
		}

		private function checkToSeeIfAprilisDoneTimerTick(e: TimerEvent): void {
			trace("FaceAgingMainTimeline.checkToSeeIfAprilisDoneTimerTick > e : ");
			// its been a second since we last checked, is April done with aging?
			callAprilAPI("jobs/", AprilJobID, checkOnTheJobID, false);
			//JL Feb.5.2016 Added
			
			trace(String(aprilNotDoneCounter) + " - COUNTER"); 
			
			if (++aprilNotDoneCounter > maxAprilAttempts) {
				
				trace(aprilNotDoneCounter + " of " +maxAprilAttempts); 
				aprilFailed();
			}
			//
		}

		private function callAprilAPI(cmd: String, sendParams: String, lstnr: Function, sendPOST: Boolean = true): void {

			var uLoader: URLLoader = new URLLoader();
			//JL Feb.5.2016 Added			
			uLoader.addEventListener(IOErrorEvent.IO_ERROR, aprilFailed);
			//
			var uRequest: URLRequest;

			if (sendPOST) {
				uRequest = new URLRequest(apidirectory + cmd);
			} else {
				uRequest = new URLRequest(apidirectory + cmd + sendParams);
			}

			var header: URLRequestHeader = new URLRequestHeader("Content-Type", "application/json");
			uRequest.requestHeaders.push(header);
			if (sendPOST) {
				uRequest.data = sendParams;
				uRequest.method = URLRequestMethod.POST;
			} else {
				uRequest.method = URLRequestMethod.GET;
			}
			uLoader.addEventListener(Event.COMPLETE, lstnr);
			uLoader.load(uRequest);
		}

		private function setSex(i: int): void {
			MovieClip(getChildByName("sex1")).gotoAndStop(1);
			MovieClip(getChildByName("sex2")).gotoAndStop(1);
			MovieClip(getChildByName("sex" + i)).gotoAndStop(2);
			if (i == 1) {
				aprilParameters.gender = int(1); //female code 1
			} else {
				aprilParameters.gender = int(0); //male code 0
			}
		}

		private function setSkin(i: int): void {
			for (var j: int = 1; j < 4; j++) {
				MovieClip(getChildByName("skin" + j)).gotoAndStop(1);
			}

			MovieClip(getChildByName("skin" + i)).gotoAndStop(2);

			if (i == 1) {
				aprilParameters.ethnicity = int(3); //asian code 3
			} else if (i == 2) {
				aprilParameters.ethnicity = int(0); // caucasian code 0 
			} else if (i == 3) {
				aprilParameters.ethnicity = int(2); // african code 1
			}
		}

		internal function loadupStep2(): void {}

	}
}