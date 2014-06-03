//
//  Bullet.m
//  Flockers
//
//  Created by Rob Blackwood on 9/27/13.
//  Copyright (c) 2013 Tinybop. All rights reserved.
//

#import "Bullet.h"
#import "contants.h"
#import "Enemy.h"

@interface Bullet()
{
}
@end

@implementation Bullet

+(id) bulletWithSpaceManager:(SpaceManager*)spaceManager
{
    return [[[self alloc] initWithSpaceManager:spaceManager] autorelease];
}

-(id) initWithSpaceManager:(SpaceManager*)spaceManager
{
    if ((self = [super initWithFile:@"bullet.png"]))
    {
        // Setup physics piece
        self.shape = [spaceManager addCircleAt:cpvzero mass:5 radius:3];
        self.spaceManager = spaceManager;
        
        // Set our collision type
        self.shape->collision_type = kBulletCollisionType;
        
        // Automatically cleanup physics when this sprite goes away
        self.autoFreeShapeAndBody = YES;
        
        // Velocity function
        self.body->velocity_func = gravityVelocityFunc;
        
        // Limit the speed
        cpBodySetVelLimit(self.body, 700);
        
        //Cameron wrote this
        // Start our update loop
        [self scheduleUpdate];
        
     
        // Run an action that will explode and kill this sprite off
        
        //Cameron edited this bit
        //basically the homing is on during the first delay
        //and off during the second delay.
        //I experienced an assertion error if you attempt to unschedule immediately before
        //you explode/kill, so the second delay is necessary for now. I think it has something to
        //do with removing the bullet but the scheduler thinking the bullet still exists
        id first_delay = [CCDelayTime actionWithDuration:2.5];
        id second_delay = [CCDelayTime actionWithDuration:1.5];
        id unschedule = [CCCallFunc actionWithTarget:self selector:@selector(unscheduleUpdate)];
        id explode = [CCCallFunc actionWithTarget:self selector:@selector(explosion)];
        id kill = [CCCallFunc actionWithTarget:self selector:@selector(removeFromParent)];
        
        [self runAction:[CCSequence actions: first_delay, unschedule, second_delay, explode, kill, nil]];
    }
    
    return self;
}

-(void) explosion
{
    [self.spaceManager applyLinearExplosionAt:self.position radius:100 maxForce:1100];
}

-(void) update:(ccTime)dt
{
    [self applyHeatSeekingForce:dt];
}

//adds a slight heatseeking force that pushes bullets towards the closest
//enemy within a specified range
-(void) applyHeatSeekingForce:(ccTime)dt
{
    //Cameron added this
    //Rob modified this

    // Do an efficient point query for shapes with a radius
    CGPoint vector = CGPointZero;
    for (NSValue *val in [self.spaceManager getShapesAt:self.position radius:80])
    {
        // shapes are c objects stuffed in an NSValue at this point
        cpShape *shape = [val pointerValue];
        
        // Check type is an enemy
        if (shape->collision_type == kEnemyCollisionType)
        {
            //
            CGPoint enemyPos = cpBodyGetPos(cpShapeGetBody(shape));
            CGPoint dir = ccpSub(enemyPos, self.position);
            
            // Add up the vectors, inverse because we want the closest enemy to have more pull
            vector = ccpAdd(vector, ccp(1/dir.x, 1/dir.y));
        }
    }
    
    // Current velocity
    CGPoint oldVelocity = cpBodyGetVel(self.body);
    float magnitude = ccpLength(oldVelocity);

    // Avoid doing a calculation for zero length vectors
    float vectorLen = ccpLength(vector);
    if (vectorLen && magnitude)
    {
        // Normalize
        vector = ccpMult(vector, 1.0f/vectorLen);
        
        // Speed at which to dampen towards new angle
        const float correctFactor = 4;
        
        // Speed it up slightly when chasing an enemy
        const float addMagnitude = 3 * dt;

        /// Calc new velocity vector
       
        // normalize
        CGPoint oldVector = ccpMult(oldVelocity, 1.0f/magnitude);
        
        // Figure out the difference between the current vector and the vector it wants to go in and
        // dampen towards the new vector
        CGPoint newVector = ccpAdd(oldVector, ccpMult(ccpSub(vector, oldVector), dt * correctFactor));
        
        // Keep old velocity magnitude with new direction
        cpBodySetVel(self.body, ccpMult(ccpNormalize(newVector), magnitude + addMagnitude));
    }
}

@end
