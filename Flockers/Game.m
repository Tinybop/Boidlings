//
//  Game.m
//  Flockers
//
//  Created by Rob Blackwood on 9/24/13.
//  Copyright Tinybop 2013. All rights reserved.
//

#import "AppDelegate.h"

// Import the interfaces
#import "Game.h"
#import "GameDrawing.h"
#import "XMLLevelLoader.h"
#import "Enemy.h"
#import "Player.h"
#import "Bullet.h"
#import "contants.h"
#import "SimpleAudioEngine.h"
#import "CollisionSounds.h"

#pragma mark - Game

@interface Game ()
{
    Joystick *_velocityStick;
    Joystick *_aimingStick;
    
    NSMutableArray *_enemyPool;
    float _enemySpawnTimer;
    
    NSMutableArray *_explosionPool;
}
@end

@implementation Game

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	Game *layer = [Game node];
	
	// add layer as a child to scene
	[scene addChild:layer];
	
	// return the scene
	return scene;
}

-(id) init
{
	if ((self=[super init]))
    {
        // ###Shady but we just want a white background
        glClearColor(1, .4, 0, 1);
        
        // initiate
        _gravitationalBodies = [[NSMutableArray array] retain];
        _enemySpawnPoints = [[NSMutableArray array] retain];
        _enemyPool = [[NSMutableArray array] retain];
        _explosionPool = [[NSMutableArray array] retain];
        
        // Colors
        _defaultConstraintColor = ccc4f(0, 1, 0, 1);
        _defaultShapeColor = ccc4f(0, 0, 0, 1);
        _defaultRopeColor = ccc4f(1, 0, 0, 1);
        
        // Joysticks
        _velocityStick = [[Joystick joystick] retain];
        _velocityStick.delegate = self;
        _aimingStick = [[Joystick joystick] retain];
        _aimingStick.delegate = self;
        
        // Setup space manager (chipmunk)
        _spaceManager = [[SpaceManagerCocos2d spaceManager] retain];
        _spaceManager.space->sleepTimeThreshold = INFINITY; // turn off sleeping of bodies
        
        // Setup panning and zooming controller
        _panZoomController = [[CCPanZoomController controllerWithNode:self] retain];
        _panZoomController.zoomRate = 1/5000.0f;
		
        // This node is for drawing anything (shapes) that does not move
        _batchStaticDraw = [CCDrawNode node];
        [self addChild:_batchStaticDraw z:10];

        // This node is for drawing everything (shapes) that do move
        _batchDynamicDraw = [CCDrawNode node];
        [self addChild:_batchDynamicDraw z:20];
        
        // Load level
        [self loadLevel:1];
        
        // Start at 75% scale
        self.scale = .75;
        
        // Create Player
        _player = [Player playerWithSpaceManager:_spaceManager];
        _player.position = ccp(300, 300);
        _player.gravitationalBodies = _gravitationalBodies;
        [self addChild:_player];
        
        // Create pool of enemies
        for (int i = 0; i < 15; ++i)
            [self createEnemyForPool];
        
        // Create pool of explosions
        for (int i = 0; i < 5; ++i)
            [self createExplosionForPool];
        
        // Collision Handlers
        cpSpaceAddCollisionHandler(_spaceManager.space, kBulletCollisionType, kEnemyCollisionType, bullet2Enemy, nil, nil, nil, self);
        cpSpaceAddCollisionHandler(_spaceManager.space, kEnemyCollisionType, kPlayerCollisionType, enemy2Player, nil, nil, nil, self);
        cpSpaceAddCollisionHandler(_spaceManager.space, kEnemyCollisionType, kEnemyCollisionType, nil, nil, enemy2Enemy, nil, self);
                
        // Schedule our update
        [self scheduleUpdate];
                
        // Debug physics
        //[self addChild:[_spaceManager createDebugLayer] z:1000];
	}
	
	return self;
}


-(void) dealloc
{
    // Cleanup
    [_gravitationalBodies release];
    [_enemySpawnPoints release];
    [_enemyPool release];
    [_explosionPool release];
    [_velocityStick release];
    [_aimingStick release];
    [_spaceManager release];
    [_panZoomController release];
    
	[super dealloc];
}

-(void) onEnter
{
    [super onEnter];
    
    [_velocityStick enableWithPriority:10];
    [_aimingStick enableWithPriority:20];
}

-(void) onExit
{
    [super onExit];
    
    [_velocityStick disable];
    [_aimingStick disable];
}

#pragma mark - Methods

-(void) update:(ccTime) dt
{
    // stop delta from getting too big
    dt = MIN(dt, 0.03f);

    // update physics
    [_spaceManager step:dt];
    
    // update spawning of enemies
    [self updateEnemySpawning:dt];

    // update camera
    [self updateCamera:dt];

    // redraw dynamic drawing things
    [self updateDynamicDrawing];
}

-(void) updateDynamicDrawing
{
    // clear our dynamic drawing for below
    [_batchDynamicDraw clear];
    
    // calculate verts to draw dynamic physical shapes and contraints ### bad to access private here of course
    cpSpatialIndexEach(_spaceManager.space->CP_PRIVATE(activeShapes), (cpSpatialIndexIteratorFunc)drawActiveShape, self);
    cpSpaceEachConstraint(_spaceManager.space, (cpSpaceConstraintIteratorFunc)drawConstraint, self);
}

-(void) updateStaticDrawing
{
    // Don't clear this, we draw things here during load that
    // we want to keep
    //[_batchStaticDraw clear];
    
    // calculate verts to draw static physical shapes
    cpSpatialIndexEach(_spaceManager.space->CP_PRIVATE(staticShapes), (cpSpatialIndexIteratorFunc)drawStaticShape, self);
}

-(void) updateCamera:(ccTime)dt
{
    if (_player)
    {
        const float cameraSpeed = 5.0f * dt;
        CGPoint playerPoint = cpBodyGetPos(_player.body);
        
        // update the camera
        [_panZoomController centerOnPoint:playerPoint damping:cameraSpeed];
    }
}

-(void) updateEnemySpawning:(ccTime)dt
{
    _enemySpawnTimer -= dt;
    
    // When our timer hits zero and we have enemies, then spawn one
    if (_enemySpawnTimer < 0 && [_enemyPool count] > 0)
    {
        Enemy *enemy = [_enemyPool lastObject];
        [_enemyPool removeLastObject];

        // Grab a random spawn position
        enemy.position = [[_enemySpawnPoints objectAtIndex:rand()%[_enemySpawnPoints count]] CGPointValue];
        enemy.visible = YES;
        
        // Start small and grow
        enemy.scale = .1;
        [enemy runAction:[CCScaleTo actionWithDuration:.3 scale:1.0]];
        
        // Reset timer
        _enemySpawnTimer = 1;
    }
}

-(void) loadLevel:(int)levNum
{
    // Load our level
    [[XMLLevelLoader loaderWithGame:self] load:[NSString stringWithFormat:@"XML/level%d", levNum]];
    
    // Only should have to call this once here
    [self updateStaticDrawing];
}

-(void) setBoundingRect:(CGRect)rect
{
    const float bottomGradientHeight = 600;
    const float topGradientHeight = 700;
    
    // Set the panning/zooming limits
    _panZoomController.boundingRect = rect;
    
    // Create the bottom gradient, fading from yellow to the orange background color
    CCLayerGradient *bottom = [CCLayerGradient layerWithColor:ccc4(255, 102, 0, 255) fadingTo:ccc4(255, 180, 0, 255) alongVector:ccp(0,-1)];
    bottom.contentSize = CGSizeMake(rect.size.width, bottomGradientHeight);
    [self addChild:bottom];
    
    // Create the top gradient, fading from goldish to the orange background color
    CCLayerGradient *top = [CCLayerGradient layerWithColor:ccc4(255, 102, 0, 255) fadingTo:ccc4(225, 140, 0, 255) alongVector:ccp(0, 1)];
    top.contentSize = CGSizeMake(rect.size.width, topGradientHeight);
    top.position = ccp(0, rect.size.height-topGradientHeight);
    [self addChild:top];
}

-(void) createEnemyForPool
{
    Enemy *enemy = [Enemy enemyWithSpaceManager:_spaceManager];
    enemy.targetNode = _player;
    enemy.gravitationalBodies = self.gravitationalBodies;
    [self addChild:enemy];
    
    [self recycleEnemyForPool:enemy];
}

-(void) recycleEnemyForPool:(Enemy*)enemy
{
    // Place it out of the way
    enemy.position = ccp(-200, -200);
    enemy.visible = NO;
    
    // zero things
    cpBodySetVel(enemy.body, cpvzero);
    cpBodyResetForces(enemy.body);
    
    [_enemyPool addObject:enemy];
}

-(void) zoomOut
{
    CCAction *scaleOut = [CCScaleTo actionWithDuration:3 scale:0.75];
    scaleOut.tag = 1234;
    [self stopActionByTag:scaleOut.tag];
    [self runAction:scaleOut];
}

-(void) zoomIn
{
    CCAction *scaleOut = [CCScaleTo actionWithDuration:3 scale:1.0];
    scaleOut.tag = 1234;
    [self stopActionByTag:scaleOut.tag];
    [self runAction:scaleOut];
}

-(void) addExplosionAt:(CGPoint)pt
{
    // Pop off last explosion
    CCParticleSystem *ps = [_explosionPool lastObject];
    [_explosionPool removeLastObject];
    
    // Position and explode!
    ps.position = pt;
    [ps resetSystem];
    
    // Physics explosion
    [self.spaceManager applyLinearExplosionAt:pt radius:100 maxForce:7100];
    
    // sfx, give it a random pitch value
    [[SimpleAudioEngine sharedEngine] playEffect:@"explosion.wav" pitch:randomFloatRange(.85, 1.2) pan:0 gain:1.0];
    
    // Re-insert at the front of the array
    [_explosionPool insertObject:ps atIndex:0];
}

-(void) createExplosionForPool
{
    // Create a particle system from our definition file
    CCParticleSystem *ps = [CCParticleSystemQuad particleWithFile:@"explode-enemy.plist"];

    // They start automatically, so kill it for now
    [ps stopSystem];

    // Add it
    [self addChild:ps];
    [_explosionPool addObject:ps];
}

#pragma mark - Joystick

-(void) joystickStarted:(Joystick *)joystick
{
    if (joystick == _aimingStick)
    {
        _player.shooting = YES;
        
        // Scale to 1 when shooting
        [self zoomIn];
    }
}

-(void) joystickMoved:(Joystick *)joystick vector:(CGPoint)vector
{
    if (joystick == _velocityStick)
    {
        _player.velocityVector = vector;
    }
    else if (joystick == _aimingStick)
    {
        _player.aimVector = vector;
    }
}

-(void) joystickStopped:(Joystick *)joystick
{
    if (joystick == _velocityStick)
    {
        _player.velocityVector = cpvzero;
    }
    else if (joystick == _aimingStick)
    {
        _player.aimVector = cpvzero;
        _player.shooting = NO;
        
        // Scale to .75 when not shooting
        [self zoomOut];
    }
}

@end

void gravityVelocityFunc(cpBody *body, cpVect gravity, cpFloat damping, cpFloat dt)
{
	// Gravitational acceleration is proportional to the inverse square of
	// distance, and directed toward the origin.
	cpVect p = body->p;
    
    NSArray *bodies = [(id<GravitationalBodiesListing>)(body->data) gravitationalBodies];
    
	for (NSValue *val in bodies)
	{
        cpBody *body = [val pointerValue];
		CGPoint point = cpBodyGetPos(body);
		CGPoint diff = cpvsub(p,point);
		
		cpFloat sqdist = cpvlengthsq(diff);
        
        if (sqdist < 600*600)
        {
            // Make sure it's not too strong
            sqdist = cpfmax(sqdist, 170*170);
            
            // do the calc
            gravity = cpvadd(gravity, cpvmult(diff, -1200000 / (sqdist * cpfsqrt(sqdist))));
        }
	}
    
    // We've modified gravity now pass it along to the original func
	cpBodyUpdateVelocity(body, gravity, damping, dt);
}

cpBool bullet2Enemy(cpArbiter *arb, cpSpace *space, void *data)
{
    CP_ARBITER_GET_BODIES(arb, bulletBody, enemyBody);
    
    Game *game = data;
    Bullet *bullet = bulletBody->data;
    Enemy *enemy = enemyBody->data;
    
    // Explosion
    [game addExplosionAt:enemy.position];

    // kill the bullet
    [bullet removeFromParent];
    
    // recycle enemy
    [game recycleEnemyForPool:enemy];
    
    return cpFalse;
}

cpBool enemy2Player(cpArbiter *arb, cpSpace *space, void *data)
{
    CP_ARBITER_GET_BODIES(arb, enemyBody, playerBody);
    
    Game *game = data;
    Enemy *enemy = enemyBody->data;
//    Player *player = playerBody->data;
    
    // Explosion
    [game addExplosionAt:enemy.position];
    
    // recycle enemy
    [game recycleEnemyForPool:enemy];
    
    return cpFalse;
}

void enemy2Enemy(cpArbiter *arb, cpSpace *space, void *data)
{
    CP_ARBITER_GET_BODIES(arb, enemyBody, whatever);
    
    Enemy *enemy = enemyBody->data;

    // Only play a sound if close to the targetNode
    float lenSq = ccpLengthSQ(ccpSub(enemy.position, enemy.targetNode.position));
    if (lenSq < 250*250)
        collisionSound(arb, space, data);
}