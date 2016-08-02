package com.zarinmedia {
	import com.adobe.air.filesystem.events.FileMonitorEvent;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import flash.utils.getTimer;

	/**
	 * ...
	 * @author Zoubin Zarin
	 */
	public class ImageSequeceData extends EventDispatcher {
		// this class reads the xml that has the file name references for the image sequnces that we are going to cycle through at the start of the kiosk (the intro)
		public var x:XML;
		private var numberOfAgeSequenceImages:int;
		private var loadCount:int = 0;
		internal var newSequenceLocationArray:Array;
		public function ImageSequeceData( theXML:XML ) {
			
			x = theXML;
			
		}
			
		internal function numberOfImageSequences():uint {
			return uint (x.*.length());
		}
		
		


		internal function getSequenceFilenames(idx:uint):Array {
			var returnArray:Array = new Array();
			for (var i:int = 0; i < x.*[idx].*.length() ; i++) {
				returnArray.push(  x.*[idx].*[i])
			}
			return returnArray;
		}
		
		internal function saveNewSequence(origPhotoFile:File, origAge:int, seqLocation:Array, seqAgearray:Array , saveDirectory:String , maximumNumber:int ,xmlFileLocation:String):void {
			// in this function we move the images that we created, and rewrite the xml file
			var now = new Date();
			var timestamp:String = String( now.valueOf() );  // lets use this as part of the filenames
			
			var securityBypass:File; // air wont let us save to the application directory.. but I'd like to build ontop of our assets directory structure
			securityBypass = File.applicationDirectory;
			securityBypass = securityBypass.resolvePath(saveDirectory + timestamp + "-" + origAge+".jpg");
			
			
			
			var newOrigPhotoFile:File = new File(securityBypass.nativePath);
			trace( "newOrigPhotoFile : " + newOrigPhotoFile.nativePath );
			
			
			
			origPhotoFile.copyToAsync(newOrigPhotoFile, true); // copy the current image
			
			//var delOrig:File = new File(origPhotoFile.nativePath) // have to do this funky thing because it wont let me call delete on a file object that I have executed stuff on already
			//delOrig.deleteFileAsync();// then delete it from old location
			FaceAgingMainTimeline.theTimeline.photoCaptureFilePath = newOrigPhotoFile;
			
			
			var tempFrom:File;
			var tempTo:File;
			newSequenceLocationArray = new Array();  // since we deleted the results files, we need to pass back the reference to them..
			var deleteReference:File; // something as3 makes me do.. I can't call delete on the same object I copied..
			loadCount = 0;
			numberOfAgeSequenceImages = seqLocation.length;
			for (var i:int = 0; i < seqLocation.length; i++) {
				// cycle through aged photos 
				tempFrom = new File(seqLocation[i]);
				
				securityBypass = File.applicationDirectory;
				securityBypass = securityBypass.resolvePath(saveDirectory + timestamp + "-" + seqAgearray[i] + ".jpg" );
				tempTo = new File(securityBypass.nativePath);
				trace( "tempTo : " + tempTo.nativePath );
				newSequenceLocationArray.push(securityBypass.nativePath);
				tempFrom.copyToAsync(tempTo, true);
				
				tempFrom.addEventListener(Event.COMPLETE , onCopiedFile); 
				
				deleteReference = new File(tempFrom.nativePath);
				deleteReference.deleteFileAsync();
				
			}
			
			// now put together the new xml
			var buildXML:String;
			buildXML = "<introimagesequnces>";
			var count:int = 0
			var sqarr:Array;
			
			var justFilenames:Array = new Array;
			var ff:File;
			for (var k:int = 0; k < newSequenceLocationArray.length+1; k++) {
				if (k == 0 ) {
					//push the current picture
					ff = new File(newOrigPhotoFile.nativePath);
				}else {
					ff =new File(newSequenceLocationArray[k-1]);  
				}
				
				justFilenames.push(ff.name);
			}
			
			do {
				if (count == 0) {
					// the first element should be the current sequence
					sqarr = justFilenames;
				}else {
					// then we can put the rest
					if ( count > numberOfImageSequences() ) {
						// ok we ran out of image sequence elements in the previous xml.. so just break out of this
						break;
					}else {
						sqarr = getSequenceFilenames(count - 1);
					}
					
				}
				buildXML += "<sequence>";
				for (var j:int = 0; j < sqarr.length; j++) {
					buildXML += "<image>" + sqarr[j]+"</image>";
				}
				buildXML += "</sequence>";
				count++;
			}while (count < maximumNumber ); // make sure we only have as many elements as specified in the config xml file
			
			buildXML += "</introimagesequnces>";
			var xx:XML = new XML(buildXML);

		
			// save the xml
			
			securityBypass = File.applicationDirectory;
			securityBypass = securityBypass.resolvePath(xmlFileLocation);
			var imsXMLfile:File = new File(securityBypass.nativePath);       
			var fileStream:FileStream = new FileStream();  
			//fileStream.addEventListener(Event.CLOSE, fileClosed);     // dont really need to wait for this to write.. its not time sensitive.. 
			fileStream.openAsync(imsXMLfile, FileMode.WRITE);  
			fileStream.writeUTFBytes(xx.toXMLString()); 
			fileStream.close();  
			
			// delete files that we did not include..
			if (numberOfImageSequences() == maximumNumber) {
				// to keep things clean we should delete the files we did not include in the xml
				var delFilesarr:Array = getSequenceFilenames(numberOfImageSequences() - 1); 
				trace( "============================delFilesarr : " + delFilesarr );
				var delmePath:File;
				var delme:File;
				for (var l:int = 0; l < delFilesarr.length; l++) {
					delmePath = File.applicationDirectory;
					delmePath = delmePath.resolvePath(saveDirectory + delFilesarr[l]);
					delme = new File(delmePath.nativePath);
					trace( "delme : " + delme.nativePath );
					
					delme.deleteFileAsync();
				}
				
				
			}

			
		}
		
		private function onCopiedFile(e:Event):void {

			loadCount++
			if (loadCount == numberOfAgeSequenceImages) {
				//everything copied over now.. dispatch event..
				dispatchEvent(new Event("COPIED"));
				trace( "---------------------dispatchEvent : COPIED all the sequence files... " );
				
	
			}
			
		}
		

	}

}