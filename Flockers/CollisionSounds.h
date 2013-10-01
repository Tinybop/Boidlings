//
//  CollisionSounds.h
//  HumanBody
//
//  Created by Rob Blackwood on 3/6/13.
//
//

#import "cocos2d.h"
#import "chipmunk.h"

// Call this to play the sound
void collisionSound(cpArbiter *arb, cpSpace *space, void *data);

@interface CollisionSounds : NSObject

+(CollisionSounds*) sharedSounds;

-(void) addCollisionSoundForFirstType:(int)type1 secondType:(int)type2 soundFile:(NSString*)soundFile;
-(NSArray*) collisionSoundsForFirstType:(int)type1 secondType:(int)type2;

@end
