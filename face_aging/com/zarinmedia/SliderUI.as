package com.zarinmedia
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.geom.Rectangle;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Zoubin Zarin
	 */
	public class SliderUI extends MovieClip
	{
		private var sliderClip:MovieClip;
		private var wRail:MovieClip;
		private var bRail:MovieClip;
		private var handleCircle:MovieClip;
		private var ageLabels:Array;
		private var sliderRange:Array
		private var sliderConstraint:Rectangle;
		private var maskBlueRail:MovieClip;
		private var indentValue:int = 10
		internal var currentIndex:int = -1;
		private var whatIndexToStartat:Number = 4;
		
		public function SliderUI(ageRange:Array)
		{
			sliderRange = ageRange;
			
			// this class is the slider UI in step 3 where the user can drive the aging photo sequences in the split screen
			// take an age range array, and calls events when the user drags past an age..
			sliderClip = new sliderElements(); // this is an element in the library that has the graphics for this UI
			addChild(sliderClip); // so here are the UI elements placed in here..
			
			wRail = MovieClip(sliderClip.getChildByName("whiteRail")); // references in variables for easy access..
			bRail = MovieClip(sliderClip.getChildByName("blueRail"));
			handleCircle = MovieClip(sliderClip.getChildByName("roundHandle"));
			
			ageLabels = new Array();
			var tf:TextField;
			for (var i:int = 0; i < ageRange.length; i++)
			{ // put the textfields into an array for easy access
				
				tf = TextField(sliderClip.getChildByName("a" + i))
				ageLabels.push(tf);
				tf.text = ageRange[i];
			}
			handleCircle.addEventListener(MouseEvent.MOUSE_DOWN, onMDown);
			FaceAgingMainTimeline.theTimeline.addEventListener(MouseEvent.RELEASE_OUTSIDE, onMUp);
			FaceAgingMainTimeline.theTimeline.addEventListener(MouseEvent.MOUSE_UP, onMUp);
			
			sliderConstraint = new Rectangle(wRail.x + indentValue, wRail.y + (wRail.height / 2), wRail.width - (indentValue * 2), 0);
			
			maskBlueRail = new MovieClip();
			maskBlueRail.graphics.beginFill(0xFF0000, .5);
			maskBlueRail.graphics.drawRect(0, 0, wRail.width, wRail.height);
			maskBlueRail.graphics.endFill();
			addChild(maskBlueRail);
			maskBlueRail.x = wRail.x;
			maskBlueRail.y = wRail.y;
			bRail.mask = maskBlueRail;
			setHandlePosition(whatIndexToStartat);
			refreshBlueSlider();
			
			addEventListener(MouseEvent.CLICK, onClickJumpto);
		
		}
		
		private function onClickJumpto(e:MouseEvent):void {

				
				var jmpto:int = int(String(e.target.name).substr(2, 1))

				
				if (e.target.name != "roundHandle") {
						setHandlePosition( jmpto);
						refreshBlueSlider();
						currentIndex = checkIndexPosition();
						dispatchEvent(new Event("CHANGE"));
				}

	

		}
		
		private function onMMove(e:MouseEvent):void
		{
			if (checkIndexPosition() != currentIndex)
			{
				// the index has changed so call the dispatcher so that the main timeline knows to update the age images..
				currentIndex = checkIndexPosition();
				dispatchEvent(new Event("CHANGE"));
			}
			refreshBlueSlider();
		
		}
		
		private function refreshBlueSlider():void
		{
			maskBlueRail.width = handleCircle.x + (wRail.width / 2);
		}
		
		private function onMUp(e:MouseEvent):void
		{
			setHandlePosition(checkIndexPosition()); // check to see what is the age we are closest to, return the index, and then set the handle's position at the nearest location
			refreshBlueSlider();
			FaceAgingMainTimeline.theTimeline.removeEventListener(MouseEvent.MOUSE_MOVE, onMMove);
			handleCircle.stopDrag();
		
		}
		
		private function checkIndexPosition():int
		{
			// check to see where we are..
			var xpos:Number = handleCircle.x + (sliderConstraint.width / 2);
			var currenIndex:int = Math.round(xpos / (sliderConstraint.width / 4));
			
			return int(currenIndex);
		}
		
		private function setHandlePosition(i:int):void
		{
			handleCircle.x = ((sliderConstraint.width / 4) * i) - (sliderConstraint.width / 2);
		}
		
		private function onMDown(e:MouseEvent):void
		{

			FaceAgingMainTimeline.theTimeline.addEventListener(MouseEvent.MOUSE_MOVE, onMMove);
			handleCircle.startDrag(true, sliderConstraint);
			
		
		}
		
		internal function kill():void
		{
			// cleanup before removing this object..
			removeEventListener(MouseEvent.CLICK, onClickJumpto);
			FaceAgingMainTimeline.theTimeline.removeEventListener(MouseEvent.MOUSE_MOVE, onMMove);
			handleCircle.removeEventListener(MouseEvent.MOUSE_DOWN, onMDown);
			FaceAgingMainTimeline.theTimeline.removeEventListener(MouseEvent.RELEASE_OUTSIDE, onMUp);
			FaceAgingMainTimeline.theTimeline.removeEventListener(MouseEvent.MOUSE_UP, onMUp);
			removeChild(maskBlueRail);
			removeChild(sliderClip)
		}
	
	}

}