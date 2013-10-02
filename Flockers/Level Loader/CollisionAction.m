#include "CollisionAction.h"

//This is kind of bad...
#define CP_HASH_COEF (3344921057ul)
#define CP_HASH_PAIR(A, B) ((cpHashValue)(A)*CP_HASH_COEF ^ (cpHashValue)(B)*CP_HASH_COEF)

extern void *cpHashSetFind(cpHashSet *set, cpHashValue hash, void *ptr);


static cpBool collisionActionBegin(cpArbiter *arb, cpSpace *space, void *data)
{
    return YES;
}

static cpBool collisionActionPreSolve(cpArbiter *arb, cpSpace *space, void *data)
{
    return YES;
}

static void collisionPostSolve(cpArbiter *arb, cpSpace *space, void *data)
{
    NSMutableArray* array;

    array = (NSMutableArray*)data;

    if (array)
    {
        for (int i = 0; i <[array count]; i++)
        {
            CollisionAction* action = [array objectAtIndex:i];

            //###
            [action unblock];
        }
    }
}

static void collisionActionSeparate(cpArbiter *arb, cpSpace *space, void *data)
{
}

static cpCollisionHandler *getCollisionHandler(cpSpace* space, cpCollisionType type1, cpCollisionType type2)
{
    struct { cpCollisionType a, b; } ids = {type1, type2};
    cpCollisionHandler *handler = (cpCollisionHandler *) cpHashSetFind(space->CP_PRIVATE(collisionHandlers), CP_HASH_PAIR(type1, type2), &ids);

    return handler;
}

static void addCollisionActionToHandler(CollisionAction* action, cpSpace* space)
{
    cpCollisionHandler *handler = getCollisionHandler(space, action.type1, action.type2);

    NSMutableArray* array;

    if (handler && handler->data)
        array = (NSMutableArray*)(handler->data);
    else
        array = [[NSMutableArray array] retain];

    [array addObject:action];
    cpSpaceAddCollisionHandler(space, action.type1, action.type2, NULL, NULL, collisionPostSolve, NULL, (void*)array);
}

static void removeCollisionActionFromHandler(CollisionAction* action, cpSpace* space)
{
    cpCollisionHandler *handler = getCollisionHandler(space, action.type1, action.type2);

    NSMutableArray* array;

    if (handler && handler->data)
    {
        array = (NSMutableArray*)(handler->data);
        
        int index = [array indexOfObject:action];
        
        if (index != NSNotFound)
        {
            [array removeObjectAtIndex:index];
            
            if ([array count] != 0)
            {
                cpSpaceAddCollisionHandler(space, action.type1, action.type2, NULL, NULL, collisionPostSolve, NULL, (void*)array);
            }
            else 
            {
                cpSpaceRemoveCollisionHandler(space, action.type1, action.type2);
            }
        }
    }
}

void removeCollisionActionCallback(cpSpace *space, void *obj, void *data)
{
    removeCollisionActionFromHandler((CollisionAction*)(obj), space);
}

///
/// CCBlockingAction
///

@implementation CCBlockingAction

-(void) dealloc
{
    [m_pInnerAction release];
    
    [super dealloc];
}

-(id) initWithAction:(CCAction*) pAction
{
    [super init];
    
    m_pInnerAction = pAction;
    m_unblocked = NO;
    
    return self;
}

+(CCBlockingAction*) actionWithAction:(CCAction*)pAction
{
    return [[(CCBlockingAction*)[self alloc] initWithAction:pAction] autorelease];
}

-(void) startWithTarget:(CCNode*) pTarget
{
    [super startWithTarget:pTarget];
    
    m_unblocked = NO;
    [m_pInnerAction startWithTarget:pTarget];
}

-(void) unblock
{
    m_unblocked = YES;
}

-(void) stop
{
    [m_pInnerAction stop];
    [super stop];
}

-(void) step:(ccTime) dt
{
    if (m_unblocked)
        [m_pInnerAction step:dt];
}

-(BOOL) isDone
{
    return m_unblocked && [m_pInnerAction isDone];
}

-(void) setInnerAction:(CCAction*) pAction
{
    if (m_pInnerAction != pAction)
        m_pInnerAction = pAction;
}

-(CCAction*) innerAction
{
    return m_pInnerAction;
}

@end



///
/// CollisionAction
///

@implementation CollisionAction
@synthesize type1 = _type1;
@synthesize type2 = _type2;

-(void) dealloc
{
    removeCollisionActionFromHandler(self, _space);
    
    [super dealloc];
}

-(id) initWithAction:(CCAction*)pAction
               space:(cpSpace*)space
               type1:(cpCollisionType)type1
               type2:(cpCollisionType)type2
                uid1:(int)uid1 uid2:(int)uid2
{
    [super initWithAction:pAction];

    _space = space;
    _type1 = type1;
    _type2 =type2;
    _uid1 = uid1;
    _uid2 = uid2;

    return self;
}

+(CollisionAction*) actionWithAction:(CCAction*)pAction
                               space:(cpSpace*)space
                               type1:(cpCollisionType)type1
                               type2:(cpCollisionType)type2
                                uid1:(int)uid1 uid2:(int)uid2
{
    return [[[self alloc] initWithAction:pAction 
                                   space:space
                                   type1:type1 
                                   type2:type2 
                                    uid1:uid1 
                                    uid2:uid2] autorelease];
}


-(void) startWithTarget:(CCNode*) pTarget
{
    addCollisionActionToHandler(self, _space);
    [super startWithTarget:pTarget];
}

-(void) unblock
{
    cpSpaceAddPostStepCallback(_space, removeCollisionActionCallback, self, NULL);

    [super unblock];
}

@end
