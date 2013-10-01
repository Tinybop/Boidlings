//
//  Game.h
//  Flockers
//
//  Created by Rob Blackwood on 9/24/13.
//  Copyright Tinybop 2013. All rights reserved.
//

#import "SpaceManagerCocos2d.h"
#import "CCPanZoomController.h"
#import "Joystick.h"

@class Player;

@protocol GravitationalBodiesListing <NSObject>
-(NSArray*) gravitationalBodies;
@end

@interface Game : CCLayer<JoystickDelegate>
{
    Player *_player;
}

// returns a CCScene that contains the Game as the only child
+(CCScene *) scene;

@property(nonatomic, readonly) CCDrawNode *batchStaticDraw;
@property(nonatomic, readonly) CCDrawNode *batchDynamicDraw;

@property(nonatomic, readonly) SpaceManagerCocos2d *spaceManager;
@property(nonatomic, readonly) CCPanZoomController *panZoomController;

@property(nonatomic, readonly) NSMutableArray *gravitationalBodies;
@property(nonatomic, readonly) NSMutableArray *enemySpawnPoints;

//Colors
@property(nonatomic, readwrite, assign) ccColor4F defaultConstraintColor;
@property(nonatomic, readwrite, assign) ccColor4F defaultShapeColor;
@property(nonatomic, readwrite, assign) ccColor4F defaultRopeColor;

-(void) setBoundingRect:(CGRect)rect;

@end

// Velocity function for objects affected by gravity
void gravityVelocityFunc(cpBody *body, cpVect gravity, cpFloat damping, cpFloat dt);

// Collision funcs
cpBool bullet2Enemy(cpArbiter *arb, cpSpace *space, void *data);
cpBool enemy2Player(cpArbiter *arb, cpSpace *space, void *data);
void enemy2Enemy(cpArbiter *arb, cpSpace *space, void *data);
