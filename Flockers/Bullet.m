//
//  Bullet.m
//  Flockers
//
//  Created by Rob Blackwood on 9/27/13.
//  Copyright (c) 2013 Tinybop. All rights reserved.
//

#import "Bullet.h"
#import "contants.h"

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
        
        // Run an action that will explode and kill this sprite off
        id delay = [CCDelayTime actionWithDuration:4];
        id explode = [CCCallFunc actionWithTarget:self selector:@selector(explosion)];
        id kill = [CCCallFunc actionWithTarget:self selector:@selector(removeFromParent)];
        
        [self runAction:[CCSequence actions:delay, explode, kill, nil]];
    }
    
    return self;
}

-(void) explosion
{
    [self.spaceManager applyLinearExplosionAt:self.position radius:100 maxForce:1100];
}

@end
