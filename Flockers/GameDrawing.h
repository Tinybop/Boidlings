//
//  GameDrawing.h
//  Flockers
//
//

#import "cocos2d.h"
#import "SpaceManagerCocos2d.h"
#import "Game.h"

extern int noDrawFlag;

void drawShapeWithColor(cpShape *shape, CCDrawNode *renderer, ccColor4F color);
void drawConstraint(cpConstraint *constraint, Game *game);
void drawStaticShape(cpShape *shape, Game *game);
void drawActiveShape(cpShape *shape, Game *game);
