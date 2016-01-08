package com.zarinmedia {
	import flash.geom.Point;
	/**
	 * ...
	 * @author Zoubin Zarin
	 */
	public class ConfigData {
		// this class gets us the configuration data we need from the xml
		public var x:XML;
		public function ConfigData( theXML:XML) {
			x = theXML;
			
		}
		
		internal function getIntroXMLfilePath():String {

			return x.intro.@xmlpath;
		}
		
		internal function getMouseHide():String {
			return String(x.@mousehide);
		}
		
	internal function getMirrorWebcam():String {
		return String(x.@mirrorwebcam);
	}
		internal function getScreenTimeout():Number {
			return Number(x.@Screentimeout);
		}
		internal function useFaceGuides():String {
			return String(x.@faceguides);
		}
		internal function dimCameraBackground():String {
			return String(x.@dimcamerabackground);
		}
		internal function isAppFullScreen():String {
			return String(x.@fullscreen);
		}
		internal function getIntroMaximum():int {
			return x.intro.@maximumsequences;
		}
		internal function getIntroImageDirectory():String {
			return x.intro.@imagedirectory;
		}
		internal function getIntrotransitionTime():Number {
			return Number(x.intro.@imagesequencetransitiontiming);
		}
		internal function getIntroDelay():Number {
			
			return Number(x.intro.@imagesequencedelay  );
		}
		internal function getIntroColorMatrix():String {
			return x.intro.@endcolormatrix;
		}
		internal function getDefaultAge():int {
			return x.demographics.@defaultage;
		}
		internal function getAPILocation():String {
			return  x.aprilagefixedparams.@apilocation;
		}
		internal function getAprilSmoking():Number {
			return x.aprilagefixedparams.@smoking;
		}
		internal function getAprilSun():Number {
			return x.aprilagefixedparams.@sun;
		}
		internal function getAprilObesity():int {
			return x.aprilagefixedparams.@obesity;
		}
		internal function getLoaderImageSlideFilenames():Array {
			var returnArray:Array = new Array();
			for (var i:int = 0; i < x.loadingslides.*.length() ; i++) {
				returnArray.push( String(x.loadingslides.@imagedirectory) +  String(x.loadingslides.*[i]));
			}
			return returnArray;
		}
		internal function getLoaderImageSlideTiming():int {
				return int( x.loadingslides.@timing );
		}
		
		internal function getLoaderImageSliderFadeTiming():int {
			return int( x.loadingslides.@fadetiming );
		}
		internal function getNumberofInfoPoints():int {
			return x.infopoints.*.length()
		}
		internal function getInfoPointLocations():Array {
			var rtnArr:Array = new Array();
			var pt:Point;
			for (var i:int = 0; i < getNumberofInfoPoints() ; i++) {
				pt = new Point(Number(x.infopoints.*[i].@x ), Number(x.infopoints.*[i].@y));
				rtnArr.push(pt);
				
			}
			return rtnArr;
		}
		
		internal function getInfoPointTitles():Array {
			var rtnArr:Array = new Array();
			for (var i:int = 0; i < getNumberofInfoPoints() ; i++) {
				rtnArr.push(String(x.infopoints.*[i].@title ));
				
			}
			return rtnArr;
		}
		internal function getInfoPointText():Array {
			var rtnArr:Array = new Array();
			for (var i:int = 0; i < getNumberofInfoPoints() ; i++) {
				rtnArr.push(String(x.infopoints.*[i] ));
				
			}
			return rtnArr;
		}
		internal function getEmailScriptURL():String {
			return String(x.social.@emailscript);
		}
		
		internal function getDTSconfigLocation():String {
			return String( x.dts.@jsonconfiglocation )
		}

	}

}