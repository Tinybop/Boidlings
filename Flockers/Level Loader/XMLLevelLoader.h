/*********************************************************************
 *	
 *	XML Level Loader
 *
 *	XMLLevelLoader.m
 *
 *	Load game level in from XML file
 *
 *	http://www.mobile-bros.com
 *
 *	Created by Robert Blackwood on 02/22/2009.
 *	Copyright 2009 Mobile Bros. All rights reserved.
 *
 **********************************************************************/

#import <UIKit/UIKit.h>
#import "SpaceManagerCocos2d.h"

@class Game;

@interface XMLLevelLoader : NSObject<NSXMLParserDelegate, SpaceManagerSerializeDelegate>
{
	Game            *_game;
    NSMutableArray  *_nodeStack;
    NSMutableArray  *_actionStackList;
    NSMutableArray  *_valueStack;
}
+ (id) loaderWithGame:(Game*)game;
- (id) initWithGame:(Game*)game;
- (void) load:(NSString*)file;
@end
