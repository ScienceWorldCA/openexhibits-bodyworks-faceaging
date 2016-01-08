package  com.zarinmedia {
	
	import com.greensock.TimelineLite;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import flash.geom.Matrix;
	import flash.net.URLVariables;
	import flash.net.URLRequestMethod;
	import com.adobe.images.JPGEncoder;
	import flash.utils.ByteArray;
	import flash.net.URLLoaderDataFormat ;
	import com.ngxinteractive.dts.DTS;
	import flash.events.IOErrorEvent;
	import flash.utils.Timer;
	import flash.net.URLRequestHeader;

	public class emailModalWindow extends MovieClip {
		
		private var nowImage:Loader;
		private var agedImage:Loader;
		private var sendImageClip:MovieClip;
		private var comparisonImage:Boolean = false;
		private var compToggle:MovieClip;
		private var maskclip:MovieClip;
		private var sendButton:MovieClip;
		internal var sendBitmap:Bitmap;
		private var characters:Array;
		private var numKeyboard:MovieClip;
		private var uppercaseKeyboard:MovieClip;
		
		
		private var nameClip:MovieClip;
		private var emailClip:MovieClip;
		private var selectedTextClip:MovieClip;
		private var addToList:Boolean = false;
		private var bd:BitmapData;
		private var disableEverythingClip:MovieClip;
		private var theCursor:MovieClip;
		public function emailModalWindow() {
			// constructor code
			compToggle = MovieClip(getChildByName("comparisonToggle"));
			addEventListener(MouseEvent.CLICK , onClickedDown );
			characters = new Array("q","u","e","r","t","y","u","i","o","p","a","s","d","f","g","h","j","k","l","@","z","x","c","v","b","n","m",".","Q","W","E","R","T","Y","U","I","O","P","A","S","D","F","G","H","J","K","L","Z","X","C","V","B","N","M","0","1","2","3","4","5","6","7","8","9","!","#","$","%","&","'","*","+","-","/","=","?","^","_","`","{","|","}","~",".com"," ");
			numKeyboard = MovieClip(getChildByName("numberToggle"));
			uppercaseKeyboard = MovieClip(getChildByName("shiftToggle"));
			nameClip = MovieClip(getChildByName("nameclip"));
			emailClip = MovieClip(getChildByName("emailclip"));
			theCursor = new cursorClip();
			
			disableEverythingClip = new MovieClip()
			disableEverythingClip.graphics.beginFill(0x000000, .75)
			disableEverythingClip.graphics.drawRect(0, 0, this.width, this.height);
			disableEverythingClip.graphics.endFill();
			var ldcir:MovieClip = new loadeCircle();// this is a library item
			disableEverythingClip.addChild(ldcir);
			ldcir.x = 960;
			ldcir.y = 525;
			ldcir.scaleX = .5;
			ldcir.scaleY = .5;
			
		}
		
		private function onClickedDown(e:MouseEvent):void {

			var clickedName:String = e.target.name;
			
			if (clickedName == "send") {
				// check to validate data...
				var emailText:String = String(TextField(emailClip.getChildByName("txt")).text)  ;
				var uname:String = String(TextField(nameClip.getChildByName("txt")).text);
				if ( isValidUserEmail( emailText)) {
					addChild(disableEverythingClip);
					DTS.sendScreen('step3/email_validated', 'Sending email');
					emailClip.gotoAndStop(1);
					TextField(emailClip.getChildByName("txt")).textColor = 0x666666
				
					// the code to encode jpg freezes system. so in this frame disable everything and make stage darker..
					// then after a delay, process the image and send the email..
					var delayProcessing:Timer = new Timer(1000, 1);
					delayProcessing.addEventListener(TimerEvent.TIMER, onDelayFinished);
					delayProcessing.start();
					

		
					
				}else {
					emailClip.gotoAndStop(2);
					TextField(emailClip.getChildByName("txt")).textColor = 0xffffff

					
					
				}
			
			// if things check out, then send it..
			
			

				
			}
			if ( clickedName == "comparisonToggle") {
				
				if (comparisonImage) {
					
					compToggle.gotoAndStop(1); // turn on comparason toggle,
						maskclip.graphics.clear();
					maskclip.graphics.beginFill(0xff0000 , .5);
					maskclip.graphics.drawRect(288, 0, 287, 905);
					maskclip.graphics.endFill();
					comparisonImage = false;
					
					
				}else {

					compToggle.gotoAndStop(2); // turn off comparason toggle..
					
					maskclip.graphics.clear();
					maskclip.graphics.beginFill(0xff0000 , .5);
					maskclip.graphics.drawRect(0, 0, 575, 905);
					maskclip.graphics.endFill();
					comparisonImage = true;
				}
				
			}
			if (clickedName.substr(0, 1) == "k") {
				// if it starts with a k that means its a button..
				var buttonNumber:int = int(clickedName.substr(1, clickedName.length -1));
				trace( "buttonNumber : " + buttonNumber + " ----- character: " + characters[buttonNumber]);
				
				sendCharToSelectedTextClip( characters[buttonNumber] );
				refreshCursor()
			}
			
			if (clickedName == "del") {
				// the delete btn  was pressed...
				var theTextfield:TextField = TextField(selectedTextClip.getChildByName("txt"));
				if ( theTextfield.text == "Full Name" || theTextfield.text == "Email Address") {
					theTextfield.text = "";
				}else {
					var tstr:String = theTextfield.text
					theTextfield.text = tstr.substr(0, tstr.length - 1);
				}
				refreshredbox();
				refreshCursor();
			}
			
			if (clickedName == "numberToggle") {
				if (numKeyboard.currentFrame == 1) {
					// the number keyboard is off, turn it on..
					numKeyboard.gotoAndStop(2);
					uppercaseKeyboard.gotoAndStop(1);
				}else {
					numKeyboard.gotoAndStop(1);
					uppercaseKeyboard.gotoAndStop(1);
				}
				
				
			}
			if (clickedName == "shiftToggle") {
				if (uppercaseKeyboard.currentFrame == 1) {
					// the shift keyboard is off, turn it on..
					uppercaseKeyboard.gotoAndStop(2);
					numKeyboard.gotoAndStop(1);
				}else {
					uppercaseKeyboard.gotoAndStop(1);
					numKeyboard.gotoAndStop(1);
				}
				
				
			}
			
			if (clickedName == "checkToggle") {
				//addToList
				var cktg:MovieClip = MovieClip(getChildByName("checkToggle"));
				if (addToList) {
					addToList = false;
					cktg.gotoAndStop(1);
				}else {
					addToList = true;
					cktg.gotoAndStop(2);
				}
				
				
			}
			if (clickedName == "nameclip" ) {
				nameClip.getChildByName("selectKeyline").visible = true;
				emailClip.getChildByName("selectKeyline").visible = false;
				selectedTextClip = nameClip;
				//nameClip.stage.focus = nameClip;  this makes a yellow square instead..
				refreshCursor();
			}
			if (clickedName == "emailclip" ) {
				emailClip.getChildByName("selectKeyline").visible = true;
				nameClip.getChildByName("selectKeyline").visible = false;
				selectedTextClip = emailClip;
				refreshCursor();
			}
			
		}
		private function refreshCursor():void {

			var textfieldInFocus:TextField = TextField( selectedTextClip.getChildByName("txt"));
			trace( "textfieldInFocus : " + textfieldInFocus.text );
			var caretRect:Rectangle = textfieldInFocus.getCharBoundaries(textfieldInFocus.caretIndex - 1 );
			trace( "caretRect : " + caretRect );
			

			if (caretRect != null) {
				
				theCursor.x = selectedTextClip.x + caretRect.x + caretRect.width;
				theCursor.y = selectedTextClip.y + caretRect.y
			}else {
				if (textfieldInFocus.text == "Full Name") {
					theCursor.x = selectedTextClip.x + 100 
				}else {
					theCursor.x = selectedTextClip.x + 140; 
				}
				
				theCursor.y = selectedTextClip.y 
			}

			
		}
		internal function exitWindow():void {
			removeChild(theCursor);
		}
		
		private function onDelayFinished(e:TimerEvent):void {
					e.target.removeEventListener(TimerEvent.TIMER, onDelayFinished);
					
					var emailText:String = String(TextField(emailClip.getChildByName("txt")).text)  ;
					var uname:String = String(TextField(nameClip.getChildByName("txt")).text);
					// take a snapshot of the sendclip..
					bd  = new BitmapData(575, 905, false, 0xffffff);
					bd.draw(sendImageClip);
					//sendBitmap = new Bitmap(bd);
					
					var jEncoder:JPGEncoder = new JPGEncoder(99);
					var imgBytes:ByteArray; 
					imgBytes = jEncoder.encode(bd); // image should be ready to send now..
					
					var theEmailScriptURL:String = FaceAgingMainTimeline.configData.getEmailScriptURL();
					// send some variables in the URL.. and then post the binary data
					theEmailScriptURL += "?name=" + escape(uname) 
					theEmailScriptURL += "&email=" + escape(emailText) ;
					theEmailScriptURL += "&addtolist=" + escape(String(addToList)) ;
					trace( "theEmailScriptURL : " + theEmailScriptURL );
								
					var request:URLRequest = new URLRequest(theEmailScriptURL);

					//var requestVars:URLVariables = new URLVariables();
					//requestVars.username = 
					//request.data = requestVars;
					
					var header:URLRequestHeader = new URLRequestHeader("Content-type", "application/octet-stream");
					request.requestHeaders.push(header);
					request.data = imgBytes;
					request.method = URLRequestMethod.POST;
					
					var uloader:URLLoader = new URLLoader();
					uloader.addEventListener(IOErrorEvent.IO_ERROR, onError);
					uloader.dataFormat = URLLoaderDataFormat.BINARY;
					uloader.load(request);
					bd.dispose();
							
					FaceAgingMainTimeline.theTimeline.removeEmailPopup();
		}
		
		private function onError(e:IOErrorEvent):void {
			trace( ">>>>> IO ERROR EVENT HERE : " + e );
			
		}
		private function isValidEmail(email:String):Boolean {
			var emailExpression:RegExp = /([a-z0-9._-]+?)@([a-z0-9.-]+)\.([a-z]{2,4})/;
			return emailExpression.test(email);
		}
		
		function isValidUserEmail(email:String):Boolean {
				var myRegExp:RegExp = /^[a-z][\w.-]+@\w[\w.-]+\.[\w.-]*[a-z][a-z]$/i;
				var myResult:Object = myRegExp.exec(email);
				if (myResult == null) {
					return false;
				}
				return true;
		}
				
				
		private function sendCharToSelectedTextClip(chara:String):void {
			var theTextfield:TextField = TextField(selectedTextClip.getChildByName("txt"));
				if ( theTextfield.text == "Full Name" || theTextfield.text == "Email Address") {
					theTextfield.text = "";
				}
				theTextfield.appendText( chara);
				
				refreshredbox()
			
		}

		private function refreshredbox():void {
				if ( isValidUserEmail( String(TextField(emailClip.getChildByName("txt")).text) )) {
					// validate with every character that is added
					emailClip.gotoAndStop(1);
					TextField(emailClip.getChildByName("txt")).textColor = 0x666666
				}else {
				
					emailClip.gotoAndStop(2);
					TextField(emailClip.getChildByName("txt")).textColor = 0xffffff
					
				
				}
		}
		
		internal function setEmailPhoto(origphotofilename:String, currentAge:int ,  agedphotofilename:String , ageTo:int):void {
			comparisonImage = false;// rest the comp toggle...
			compToggle.gotoAndStop(1);
			
			if (contains(disableEverythingClip)) {
				removeChild(disableEverythingClip);
			}
			
			
			// initialize things..
			nameClip.getChildByName("selectKeyline").visible = true;
			emailClip.getChildByName("selectKeyline").visible = false;
			selectedTextClip = nameClip;
			TextField(emailClip.getChildByName("txt")).text = "Email Address";
			TextField(nameClip.getChildByName("txt")).text = "Full Name";
			
			emailClip.gotoAndStop(1);
			TextField(emailClip.getChildByName("txt")).textColor = 0x666666 ;
			
			addChild(theCursor);
			refreshCursor();
			
			
			// load up the two photos..
			
			nowImage = new Loader();
			agedImage = new Loader();
			nowImage.load(new URLRequest(origphotofilename));
			agedImage.load(new URLRequest(agedphotofilename));
			
			
			var d:Date = new Date();
			var year:int = d.getFullYear();
			
			var ageText1:MovieClip = new yearLabel();
			var ageText2:MovieClip = new yearLabel();
			
			TextField(ageText1.getChildByName("ageText")).text = String(currentAge);
			TextField(ageText1.getChildByName("yearText")).text = String(year);
			TextField(ageText2.getChildByName("ageText")).text = String(ageTo);
			TextField(ageText2.getChildByName("yearText")).text = String(year + (ageTo - currentAge));

			
			sendImageClip = new MovieClip;
			sendImageClip.addChild(nowImage);
			sendImageClip.addChild(ageText1);
			sendImageClip.addChild(agedImage);
			
			var branding:MovieClip = new logo();
			sendImageClip.addChild(branding);
			branding.x = 144;
			branding.y = 830;
			

			
			
			sendImageClip.addChild(ageText2);
			
			ageText1.y = 100 ;
			ageText2.y = 100;
			
			ageText1.x = 100;
			ageText2.x = 470;
			
			maskclip = new MovieClip();
			var masknowImage:MovieClip = new MovieClip();
			maskclip.graphics.beginFill(0xff0000 , .5);
			maskclip.graphics.drawRect(288, 0, 287, 905);
			maskclip.graphics.endFill();
			masknowImage.graphics.beginFill(0xff0000 , .5);
			masknowImage.graphics.drawRect(0, 0, 575, 905);
			masknowImage.graphics.endFill();
			sendImageClip.addChild(masknowImage);
			sendImageClip.addChild(maskclip);
			nowImage.mask = masknowImage;
			agedImage.mask = maskclip;
			
			addChild(sendImageClip);
			sendImageClip.x = 557;
			sendImageClip.y = 307;
			sendImageClip.width = 170;
			sendImageClip.scaleY = sendImageClip.scaleX;
			
			
			
			
			var cktg:MovieClip = MovieClip(getChildByName("checkToggle"));
			addToList = false;
			cktg.gotoAndStop(1);
			
		}
	}
	
}
