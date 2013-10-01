//
//  Joystick.m
//  Flockers
//
//  Created by Rob Blackwood on 9/27/13.
//  Copyright (c) 2013 Tinybop. All rights reserved.
//

#import "Joystick.h"

@interface Joystick()
{
    BOOL    _touching;
    CGPoint _startPt;
}

@end

@implementation Joystick

+(id) joystick
{
    return [[[self alloc] init] autorelease];
}

-(void) enableWithPriority:(int)priority
{
    [[CCDirector sharedDirector].touchDispatcher addTargetedDelegate:self priority:priority swallowsTouches:YES];
}

-(void) disable
{
    [[CCDirector sharedDirector].touchDispatcher removeDelegate:self];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (!_touching)
    {
        _startPt = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
        _touching = YES;
        
        [_delegate joystickStarted:self];
        
        return YES;
    }
    else
        return NO;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint pt = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
    [_delegate joystickMoved:self vector:ccpSub(pt, _startPt)];
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    _touching = NO;
    [_delegate joystickStopped:self];
}

- (void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self ccTouchEnded:touch withEvent:event];
}

@end
