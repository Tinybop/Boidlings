//
//  Enemy.m
//  Flockers
//
//  Created by Rob Blackwood on 9/26/13.
//  Copyright (c) 2013 Tinybop. All rights reserved.
//

#import "Enemy.h"
#import "contants.h"

@implementation Enemy

+(id) enemyWithSpaceManager:(SpaceManager*)spaceManager
{
    return [[[self alloc] initWithSpaceManager:spaceManager] autorelease];
}

-(id) initWithSpaceManager:(SpaceManager*)spaceManager
{
    if ((self = [super initWithFile:@"enemy.png"]))
    {
        // Our sprite has it's circle piece to the right, so we offset our circle shape a bit
        self.shape = [spaceManager addCircleAt:cpvzero mass:20 radius:10 offset:cpvzero];
        self.spaceManager = spaceManager;
        self.autoFreeShapeAndBody = YES;
        
        // Collision type
        self.shape->collision_type = kEnemyCollisionType;
        
        // We don't want the actual shape to rotate
        cpBodySetMoment(self.body, INFINITY);
        
        // Velocity function
        self.body->velocity_func = gravityVelocityFunc;
        
        // Propeller thing
        _propeller = [CCSprite spriteWithFile:@"enemy-propeller.png"];
        _propeller.position = self.anchorPointInPoints;
        [self addChild:_propeller z:-1];
        
        // Start our update loop
        [self scheduleUpdate];
    }
    
    return self;
}

-(void) update:(ccTime)dt
{
    // Do nothing if we're not visible
    if (self.visible)
    {
        // Figure out forces to apply
        [self updateForces:dt];
        
        // Update the propeller
        [self updatePropeller:dt];
    }
}


-(void) updateForces:(ccTime)dt
{
    // Simple logic, get vector pointing at  target node
    CGPoint vect = ccpSub(_targetNode.position, self.position);
    CGPoint norm = ccpNormalize(vect);
    
    // Reset forces and apply
    cpBodyResetForces(self.body);
    cpBodyApplyForce(self.body, ccpMult(norm, 800), cpvzero);
}

-(void) updatePropeller:(ccTime)dt
{
    const float speedFactor = 5;
    
    // Make rotation speed just a simple equation based on velocity of ourselves
    _propeller.rotation += speedFactor * dt * ccpLength(cpBodyGetVel(self.body));
}

@end
