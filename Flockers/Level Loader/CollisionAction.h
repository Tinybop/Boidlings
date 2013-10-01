#import "cocos2d.h"
#import "chipmunk.h"

@interface CCBlockingAction :  CCAction
{
    CCAction    *m_pInnerAction;
    bool         m_unblocked;
}

-(id) initWithAction:(CCAction*)pAction;
+(CCBlockingAction*) actionWithAction:(CCAction*)pAction;

-(void) setInnerAction:(CCAction*)pAction;
-(CCAction*) innerAction;

-(void) unblock;

@end

@interface CollisionAction : CCBlockingAction
{
    cpSpace* _space;
    cpCollisionType _type1;
    cpCollisionType _type2;
    int _uid1;
    int _uid2;
};

-(id) initWithAction:(CCAction*)pAction
               space:(cpSpace*)space
               type1:(cpCollisionType)type1
               type2:(cpCollisionType)type2
                uid1:(int)uid1 uid2:(int)uid2;

+(CollisionAction*) actionWithAction:(CCAction*)pAction
                               space:(cpSpace*)space
                               type1:(cpCollisionType)type1
                               type2:(cpCollisionType)type2
                                uid1:(int)uid1 uid2:(int)uid2;

@property(readonly) cpCollisionType type1;
@property(readonly) cpCollisionType type2;


@end

