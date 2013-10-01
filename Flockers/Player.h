//
//  Player.h
//  Flockers
//
//  Created by Rob Blackwood on 9/26/13.
//  Copyright (c) 2013 Tinybop. All rights reserved.
//

#import "SpaceManagerCocos2d.h"
#import "Game.h"

@interface Player : cpCCSprite<GravitationalBodiesListing>
{
    CGPoint _realAimVector;
    CGPoint _realVelocityVector;
    
    CCSprite *_cannon;
    CCSprite *_rockets;
}

@property (readwrite, assign, nonatomic) CGPoint aimVector;
@property (readwrite, assign, nonatomic) CGPoint velocityVector;
@property (readwrite, assign, nonatomic) BOOL shooting;

@property (strong) NSArray *gravitationalBodies;

+(id) playerWithSpaceManager:(SpaceManager*)spaceManager;
-(id) initWithSpaceManager:(SpaceManager*)spaceManager;

-(void) update:(ccTime)dt;

@end
