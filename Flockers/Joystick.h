//
//  Joystick.h
//  Flockers
//
//  Created by Rob Blackwood on 9/27/13.
//  Copyright (c) 2013 Tinybop. All rights reserved.
//

#import "cocos2d.h"

@class Joystick;

@protocol JoystickDelegate <NSObject>
@required
-(void) joystickStarted:(Joystick*)joystick;
-(void) joystickMoved:(Joystick*)joystick vector:(CGPoint)vector;
-(void) joystickStopped:(Joystick*)joystick;
@end

@interface Joystick : NSObject<CCTouchOneByOneDelegate>

@property (readwrite, assign, nonatomic) id<JoystickDelegate> delegate;

+(id) joystick;

-(void) enableWithPriority:(int)priority;
-(void) disable;

@end
