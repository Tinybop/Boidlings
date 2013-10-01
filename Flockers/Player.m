//
//  Player.m
//  Flockers
//
//  Created by Rob Blackwood on 9/26/13.
//  Copyright (c) 2013 Tinybop. All rights reserved.
//

#import "Player.h"
#import "Bullet.h"
#import "contants.h"
#import "SimpleAudioEngine.h"

@interface Player ()
{
    float _shootTimer;
}
@end

@implementation Player

+(id) playerWithSpaceManager:(SpaceManager*)spaceManager
{
    return [[[self alloc] initWithSpaceManager:spaceManager] autorelease];
}

-(id) initWithSpaceManager:(SpaceManager*)spaceManager
{
    if ((self = [super initWithFile:@"player-center.png"]))
    {
        // Setup cannon sprite, position in the center of self, anchor to the left
        _cannon = [CCSprite spriteWithFile:@"player-cannon.png"];
        _cannon.position = self.anchorPointInPoints;
        _cannon.anchorPoint = ccp(-.22, .5);
        [self addChild:_cannon];
        
        // Setup rocket sprite, position in the center of self, anchor slightly to left
        _rockets = [CCSprite spriteWithFile:@"player-rockets.png"];
        _rockets.position = self.anchorPointInPoints;
        _rockets.anchorPoint = ccp(.43, .5);
        [self addChild:_rockets];
        
        // Setup physics piece
        self.shape = [spaceManager addCircleAt:cpvzero mass:30 radius:15];
        self.spaceManager = spaceManager;
        
        // Collision type
        self.shape->collision_type = kPlayerCollisionType;
        
        // We don't want the actual shape to rotate
        cpBodySetMoment(self.body, INFINITY);
        
        // Maximum speed
        cpBodySetVelLimit(self.body, 300);
        
        // Velocity function
        self.body->velocity_func = gravityVelocityFunc;
        
        // Start our update loop
        [self scheduleUpdate];
    }
    
    return self;
}

-(void) update:(ccTime)dt
{
    const float dampenVectorSpeed = 10 * dt;
    const float forceMultiplier = 20;
    
    cpBody *body = self.body;
    
    // Dampen changes in velocity and aiming
    _realVelocityVector = ccpAdd(_realVelocityVector, ccpMult(ccpSub(_velocityVector, _realVelocityVector), dampenVectorSpeed));
    _realAimVector = ccpAdd(_realAimVector, ccpMult(ccpSub(_aimVector, _realAimVector), dampenVectorSpeed));
    
    // Rotate our rockets and our cannon to the right angles
    [self updateAnimation];
    
    // Shoot if necessary
    [self updateShooting:dt];
    
    // Reset forces, then apply a new one
    cpBodyResetForces(body);
    cpBodyApplyForce(body, ccpMult(_realVelocityVector, forceMultiplier), cpvzero);
}

-(void) updateAnimation
{
    // Calculate the angle, plus 180 because we want the opposite side
    _rockets.rotation = -CC_RADIANS_TO_DEGREES(ccpToAngle(_realVelocityVector)) + 180;
    
    // Calculate the angle
    _cannon.rotation = -CC_RADIANS_TO_DEGREES(ccpToAngle(_realAimVector));
}

-(void) updateShooting:(ccTime)dt
{
    // degrade timer
    _shootTimer -= dt;
    
    // when timer crosses the threshold, shoot!
    if (_shooting && _shootTimer < 0)
        [self shoot];
}

-(void) shoot
{
    // We'll put the bullet in the same coord space as us, so make sure
    // there's a parent
    if (self.parent)
    {
        // Calculate where the cannon tip is relative to self.parent
        CGPoint worldPt = [_cannon convertToWorldSpace:ccp(_cannon.contentSize.width, _cannon.contentSize.height*.5)];
        CGPoint localPt = [self.parent convertToNodeSpace:worldPt];
        
        // Create a bullet
        Bullet *bullet = [Bullet bulletWithSpaceManager:self.spaceManager];
        bullet.position = localPt;
        bullet.gravitationalBodies = self.gravitationalBodies;
        [self.parent addChild:bullet];
        
        // Match the velocities
        cpBodySetVel(bullet.body, cpBodyGetVel(self.body));
        
        // Direction from the center of the ship
        CGPoint dir = ccpNormalize(ccpSub(localPt, self.position));
        
        // Apply an impulse (like a gunshot)
        cpBodyApplyImpulse(bullet.body, ccpMult(dir, 600), cpvzero);
        
        // sfx, random pitch value
        [[SimpleAudioEngine sharedEngine] playEffect:@"shoot.wav" pitch:randomFloatRange(.8, 1) pan:0 gain:1.0];
        
        // Reset the timer
        _shootTimer = .75;
    }
}

@end
