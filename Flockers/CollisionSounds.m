//
//  CollisionSounds.m
//  HumanBody
//
//  Created by Rob Blackwood on 3/6/13.
//
//

#import "CollisionSounds.h"
#import "SimpleAudioEngine.h"

// Generic collision sound player function, calculates appropriate values based on impact force
static float doCollisionSound(cpArbiter *arb, CollisionSounds *sounds)
{
    float gain = 0;
    
    //Sound
    if (cpArbiterIsFirstContact(arb))
    {
        cpVect total = cpArbiterTotalImpulse(arb);
        float lenSq = cpvlengthsq(total);
        
        static const float min = 900.0f;
        
        //NSLog(@"Coll Force Squared: %.2f", lenSq);

        //Theshold
        if (lenSq > (min * min))
        {
            CP_ARBITER_GET_SHAPES(arb, shapeA, shapeB);
            
            NSArray *soundFiles = [sounds collisionSoundsForFirstType:shapeA->collision_type secondType:shapeB->collision_type];
            
            if (soundFiles)
            {
                static const float max = 2400.0f;
                float len = cpfsqrt(lenSq);
                
                //NSLog(@"Coll Force: %.2f", len);
                
                //Volume based on impact force
                gain = cpfmin((len-min)/(max-min), 1.0f);
                
                //NSLog(@"Gain: %.2f", gain);
                
                //Random pitch (based upon volume too), but not too low or high (0.7 - 1.2)
                float pitch = 0.7f + ((rand()%51) * gain)/100.0f;

                //Play a random sound from the array
                NSString *file = [soundFiles objectAtIndex:rand()%[soundFiles count]];
                [[SimpleAudioEngine sharedEngine] playEffect:file pitch:pitch pan:0.0f gain:gain];
                
                //NSLog(@"Play FX: %@ for type:%li and type:%li", file, shapeA->collision_type, shapeB->collision_type);
            }
        }
    }
    
    return gain;
}

void collisionSound(cpArbiter *arb, cpSpace *space, void *data)
{
//    CP_ARBITER_GET_SHAPES(arb, shapeA, shapeB);
//    NSLog(@"Play FX for type:%li and type:%li", shapeA->collision_type, shapeB->collision_type);  
    doCollisionSound(arb, [CollisionSounds sharedSounds]);
}

@interface CollisionSounds ()
{
    NSMutableDictionary *_library;
}

@end

@implementation CollisionSounds

//
// singleton stuff
//
static CollisionSounds *_sharedCollisionSounds = nil;

+(CollisionSounds*) sharedSounds
{
	if (!_sharedCollisionSounds) {
        _sharedCollisionSounds = [[self alloc] init];
	}
    
	return _sharedCollisionSounds;
}

+(void) destroy
{
    [_sharedCollisionSounds release];
}

+(id) alloc
{
	NSAssert(_sharedCollisionSounds == nil, @"Attempted to allocate a second instance of a singleton.");
    
    if (_sharedCollisionSounds)
        return nil;
    else
        return [super alloc];
}

-(id) init
{
    if ((self = [super init]))
    {
        _library = [[NSMutableDictionary dictionaryWithCapacity:20] retain];
    }
    
    return self;
}

-(void) dealloc
{
    [_library release];
    [super dealloc];
}

-(void) addCollisionSoundForFirstType:(int)type1 secondType:(int)type2 soundFile:(NSString*)soundFile;
{
    NSMutableDictionary *secondary = [_library objectForKey:[NSNumber numberWithInt:type1]];
    NSMutableArray *soundFiles = nil;
    
    if (!secondary)
    {
        secondary = [NSMutableDictionary dictionaryWithCapacity:10];
        [_library setObject:secondary forKey:[NSNumber numberWithInt:type1]];
        
        soundFiles = [NSMutableArray arrayWithCapacity:5];
        [secondary setObject:soundFiles forKey:[NSNumber numberWithInt:type2]];
    }
    else
    {
        soundFiles = [secondary objectForKey:[NSNumber numberWithInt:type2]];
        
        if (!soundFiles)
        {
            soundFiles = [NSMutableArray arrayWithCapacity:5];
            [secondary setObject:soundFiles forKey:[NSNumber numberWithInt:type2]];
        }
    }
    
    [soundFiles addObject:soundFile];
}

-(NSArray*) collisionSoundsForFirstType:(int)type1 secondType:(int)type2
{
    NSDictionary *first = [_library objectForKey:[NSNumber numberWithInt:type1]];
    NSArray *sounds = [first objectForKey:[NSNumber numberWithInt:type2]];
    return sounds;
}

@end
