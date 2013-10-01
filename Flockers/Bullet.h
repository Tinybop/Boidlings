//
//  Bullet.h
//  Flockers
//
//  Created by Rob Blackwood on 9/27/13.
//  Copyright (c) 2013 Tinybop. All rights reserved.
//

#import "SpaceManagerCocos2d.h"
#import "Game.h"

@interface Bullet : cpCCSprite

@property (strong) NSArray *gravitationalBodies;

+(id) bulletWithSpaceManager:(SpaceManager*)spaceManager;
-(id) initWithSpaceManager:(SpaceManager*)spaceManager;

@end
