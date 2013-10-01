/* Copyright (c) 2011 Robert Blackwood
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

//V8.0

#import "cocos2d.h"

@class CCPanZoomController;

@protocol CCPanZoomControllerDelegate <NSObject>
@optional
-(BOOL) canBeginPanningWithController:(CCPanZoomController*)controller touch:(UITouch*)touch;
-(BOOL) canBeginZoomingWithController:(CCPanZoomController*)controller touches:(NSArray*)touches;

-(void) beganPanningWithController:(CCPanZoomController*)controller touch:(UITouch*)touch;
-(void) panningWithController:(CCPanZoomController*)controller touch:(UITouch*)touch;
-(void) endedPanningWithController:(CCPanZoomController*)controller touch:(UITouch*)touch;

-(void) beganZoomingWithController:(CCPanZoomController*)controller touches:(NSArray*)touches;
-(void) zoomingWithController:(CCPanZoomController*)controller touches:(NSArray*)touches;
-(void) endedZoomingWithController:(CCPanZoomController*)controller touches:(NSArray*)touches;
@end

@interface CCPanZoomController : NSObject<CCTouchOneByOneDelegate>
{	
    //properties
    CCNode  *_node;

    //bounding rect
    CGPoint _tr;
    CGPoint _bl;
    
    //window rect
    CGPoint _winTr;
    CGPoint _winBl;
    
    BOOL    _centerOnPinch;
    BOOL    _zoomOnDoubleTap;
    float   _zoomRate;
    float   _zoomInLimit;
    float   _zoomOutLimit;
    float   _swipeVelocityMultiplier;
    float   _scrollDuration;
    float   _scrollRate;
    float   _scrollDamping;
    float   _pinchDamping;
    float   _pinchDistanceThreshold;
    float   _doubleTapZoomDuration;
    	
	//touches
	CGPoint _firstTouch;
	float   _firstLength;
	float   _oldScale;
	
    //keep track of touches in order
	NSMutableArray *_touches;
    
    //momentum
    CGPoint _momentum;
}

@property (readwrite, assign, nonatomic) CGRect    boundingRect;   /*!< The max bounds you want to scroll */
@property (readwrite, assign, nonatomic) CGRect    windowRect;     /*!< The boundary of your window, by default uses winSize of CCDirector */
@property (readwrite, assign, nonatomic) BOOL      centerOnPinch;  /*!< Should zoom center on pinch pts, default is YES */
@property (readwrite, assign, nonatomic) BOOL      zoomOnDoubleTap;/*!< Should we zoom in/out on double-tap */
@property (readwrite, assign, nonatomic) float     zoomRate;       /*!< How much to zoom based on movement of pinch */
@property (readwrite, assign, nonatomic) float     zoomInLimit;    /*!< The smallest zoom level */
@property (readwrite, assign, nonatomic) float     zoomOutLimit;   /*!< The hightest zoom level */
@property (readwrite, assign, nonatomic) float     scrollRate;     /*!< Rate of the easing part of the scroll action after a swipe */
@property (readwrite, assign, nonatomic) float     scrollDamping;  /*!< When scrolling around, this will dampen the movement */
@property (readwrite, assign, nonatomic) float     zoomCenteringDamping;   /*!< Dampen the centering motion of the zoom */
@property (readwrite, assign, nonatomic) float     pinchDamping;   /*!< When zooming, this will dampen the zoom */
@property (readwrite, assign, nonatomic) float     pinchDistanceThreshold; /*!< The distance moved before a pinch is recognized */
@property (readonly, nonatomic) float              optimalXZoomOutLimit; /*!< Get the optimal x-axis zoomOutLimit for the current state */
@property (readonly, nonatomic) float              optimalYZoomOutLimit; /*!< Get the optimal y-axis zoomOutLimit for the current state */
@property (readonly, nonatomic) float              optimalZoomOutLimit; /*!< Get the optimal zoomOutLimit for the current state */
@property (readwrite, assign, nonatomic) float     doubleTapZoomDuration;  /*!< Duration of zoom after double-tap */
@property (readwrite, assign, nonatomic) id<CCPanZoomControllerDelegate> delegate; /*!< Delegate */
@property (readonly, nonatomic) CCNode* node; /*! The node we're panning/zooming */

@property (readwrite, assign, nonatomic) CGPoint    offsetZoomPosition; /*! Special property for offsetting the pinch zooming center pt */

@property (readonly, nonatomic) BOOL isPanning;
@property (readonly, nonatomic) BOOL isZooming;

/*! Create a new control with the node you want to scroll/zoom */
+ (id) controllerWithNode:(CCNode*)node;

/*! Initialize a new control with the node you want to scroll/zoom */
- (id) initWithNode:(CCNode*)node;

/*! Scroll to position */
- (void) updatePosition:(CGPoint)pos;

/*! Scroll to position, with damping */
- (void) updatePosition:(CGPoint)pos damping:(float)damping;

/*! Center point in window view */
- (void) centerOnPoint:(CGPoint)pt;

/*! Center point in window view with damping (call this in your main loop to follow a character smoothly) */
- (void) centerOnPoint:(CGPoint)pt damping:(float)damping;

/*! Center point in window view with a given duration */
- (void) centerOnPoint:(CGPoint)pt duration:(float)duration rate:(float)rate;

/*! Zoom in on point with duration */
- (void) zoomInOnPoint:(CGPoint)pt duration:(float)duration;

/*! Zoom out on point with duration */
- (void) zoomOutOnPoint:(CGPoint)pt duration:(float)duration;

/*! Zoom to a scale on a point with a given duration */
- (void) zoomOnPoint:(CGPoint)pt duration:(float)duration scale:(float)scale;

/*! Enable touches, convenience method really */
- (void) enableWithTouchPriority:(int)priority swallowsTouches:(BOOL)swallowsTouches;

/*! Disable touches */
- (void) disable;

@end
