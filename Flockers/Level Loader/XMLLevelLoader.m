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

#import "XMLLevelLoader.h"
#import "CollisionAction.h"
#import "SimpleAudioEngine.h"
#import "contants.h"

// Bad coupling here
#import "Game.h"
#import "GameDrawing.h"

@interface XMLLevelLoader(Private)
-(void) addAction:(id)action;
@end

@implementation XMLLevelLoader

+ (id) loaderWithGame:(Game*)game
{
    return [[[self alloc] initWithGame:game] autorelease];
}

- (id) initWithGame:(Game*)game
{
	[super init];
	
	_game = game;
    
    _nodeStack = [[NSMutableArray alloc] init];
    _actionStackList = [[NSMutableArray alloc] init];
    _valueStack = [[NSMutableArray alloc] init];
	
	return self;
}

-(void) dealloc
{
    [_nodeStack release];
    [_actionStackList release];
    [_valueStack release];
    
    [super dealloc];
}

-(NSString*) filenameFromPath:(NSString*)path;
{
    NSRange range = [path rangeOfString:@"/" options:NSBackwardsSearch];
    
    //Find the last slash
    if (range.location != NSNotFound)
        path = [path substringFromIndex:range.location+1];
    
    return path;
}

- (void)load:(NSString*)file
{	
    //Load the physics first
    NSString *phyName = [NSString stringWithFormat:@"%@.mbml", file];
    NSString *phyFile = [[NSBundle mainBundle] pathForResource:phyName ofType:@"phyxml"];
    [_game.spaceManager loadSpaceFromPath:phyFile delegate:self];
    
    //default object is just the game
    [_nodeStack addObject:_game];

    NSXMLParser *parser = [[[NSXMLParser alloc] initWithContentsOfURL:
                           [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:file ofType:@"mbml"]]] autorelease];
  
    // Set self as the delegate of the parser so that it will receive the parser delegate methods callbacks.
  
    [parser setDelegate:self];

    [parser setShouldProcessNamespaces:NO];
    [parser setShouldReportNamespacePrefixes:NO];
    [parser setShouldResolveExternalEntities:NO];
  
    [parser parse];
  
//Getting errors...
  /*NSError *parseError = [parser parserError];
  if (parseError && error) {
    *error = parseError;
  }*/  
}

- (void)    parser:(NSXMLParser *)parser 
     didEndElement:(NSString *)elementName 
      namespaceURI:(NSString *)namespaceURI 
     qualifiedName:(NSString *)qName
{
    //Not sure why this is here...
	if (qName) 
		elementName = qName;
    
    //Might be creating an action
    id action = nil;
    
    //Just pop the last guy
    if ([elementName isEqualToString:@"item"] ||
        [elementName isEqualToString:@"spritesheet"])
    {
        [_nodeStack removeLastObject];
    }
    else if ([elementName isEqualToString:@"repeat_forever"])
    {
        //Get the last list's [only] action
        action = [CCRepeatForever actionWithAction:[[_actionStackList lastObject] firstObject]];
    }
    else if ([elementName isEqualToString:@"on_collision"])
    {
        cpCollisionType t1 = [[_valueStack lastObject] intValue];
        [_valueStack removeLastObject];
        
        cpCollisionType t2 = [[_valueStack lastObject] intValue];
        [_valueStack removeLastObject];
        
        int u1 = [[_valueStack lastObject] intValue];
        [_valueStack removeLastObject];
        
        int u2 = [[_valueStack lastObject] intValue];
        [_valueStack removeLastObject];
        
        //Get the last list's [only] action
        action = [CollisionAction actionWithAction:[[_actionStackList lastObject] firstObject]
                                             space:_game.spaceManager.space
                                             type1:t1
                                             type2:t2
                                              uid1:u1
                                              uid2:u2];
    }
    else if ([elementName isEqualToString:@"sequence"])
    {
        //Use the last list to construct the sequence
        action = [CCSequence actionWithArray:[_actionStackList lastObject]];
        
    }
    else if ([elementName isEqualToString:@"spawn"])
    {
        //Use the last list to construct the spawn
        action = [CCSpawn actionWithArray:[_actionStackList lastObject]];       
    }
    else if ([elementName isEqualToString:@"ease_in_out"])
    {
        float rate = [[_valueStack lastObject] floatValue];
        [_valueStack removeLastObject];
        
        action = [CCEaseInOut actionWithAction:[[_actionStackList lastObject] firstObject] rate:rate];
    }
    else if ([elementName isEqualToString:@"ease_in"])
    {
        float rate = [[_valueStack lastObject] floatValue];
        [_valueStack removeLastObject];
        
        action = [CCEaseIn actionWithAction:[[_actionStackList lastObject] firstObject] rate:rate];
    }
    else if ([elementName isEqualToString:@"ease_out"])
    {
        float rate = [[_valueStack lastObject] floatValue];
        [_valueStack removeLastObject];
        
        action = [CCEaseOut actionWithAction:[[_actionStackList lastObject] firstObject] rate:rate];        
    }
   
    //We need to do something with the action
    if (action)
    {
        //Get rid of the last list
        [_actionStackList removeLastObject];
        
        [self addAction:action];
    }
}

- (void)    parser:(NSXMLParser *)parser 
   didStartElement:(NSString *)elementName 
      namespaceURI:(NSString *)namespaceURI 
     qualifiedName:(NSString *)qName 
        attributes:(NSDictionary *)attributeDict 
{
    CCNode *parent = [_nodeStack lastObject];
    
	//Not sure why this is here...
	if (qName) 
		elementName = qName;
    
    //NSLog(@"%@", elementName);
    
    if ([elementName isEqualToString:@"view"])
    {
        float b = [[attributeDict valueForKey:@"bottom"] floatValue];
		float l = [[attributeDict valueForKey:@"left"] floatValue];
        float t = [[attributeDict valueForKey:@"top"] floatValue];
		float r = [[attributeDict valueForKey:@"right"] floatValue];
        
        if (r-l != 0 && t-b != 0)
        {
            CGRect rect = CGRectMake(l, b, r-l, t-b);
            
            _game.boundingRect = rect;
        }
    }
	else if ([elementName isEqualToString:@"repeat_forever"] ||
             [elementName isEqualToString:@"sequence"] ||
             [elementName isEqualToString:@"spawn"] ||
             [elementName isEqualToString:@"ease_in_out"] ||
             [elementName isEqualToString:@"ease_in"] ||
             [elementName isEqualToString:@"ease_out"] ||
             [elementName isEqualToString:@"on_collision"])
    {
        //Add a new list to the stack
        [_actionStackList addObject:[NSMutableArray array]];
        
        if ([elementName characterAtIndex:0] == 'e')
        {
            [_valueStack addObject:[attributeDict valueForKey:@"rate"]];
        }
        else if ([elementName characterAtIndex:0] == 'o')
        {
            [_valueStack addObject:[attributeDict valueForKey:@"uid2"]];
            [_valueStack addObject:[attributeDict valueForKey:@"uid1"]];
            [_valueStack addObject:[attributeDict valueForKey:@"type2"]];
            [_valueStack addObject:[attributeDict valueForKey:@"type1"]];
        }
    }
    else if ([elementName isEqualToString:@"move_to"])
    {
        float d = [[attributeDict valueForKey:@"duration"] floatValue];
		float x = [[attributeDict valueForKey:@"x"] floatValue];
		float y = [[attributeDict valueForKey:@"y"] floatValue];
        
        id action = [CCMoveTo actionWithDuration:d position:ccp(x,y)];
        
        [self addAction:action];
    }
    else if ([elementName isEqualToString:@"move_by"])
    {
        float d = [[attributeDict valueForKey:@"duration"] floatValue];
		float x = [[attributeDict valueForKey:@"x"] floatValue];
		float y = [[attributeDict valueForKey:@"y"] floatValue];
        
        id action = [CCMoveBy actionWithDuration:d position:ccp(x,y)];
        
        [self addAction:action];
    }
    else if ([elementName isEqualToString:@"rotate_to"])
    {
        float d = [[attributeDict valueForKey:@"duration"] floatValue];
		float r = [[attributeDict valueForKey:@"rotation"] floatValue];
        
        id action = [CCRotateTo actionWithDuration:d angle:r];
        
        [self addAction:action];
    }
    else if ([elementName isEqualToString:@"rotate_by"])
    {
        float d = [[attributeDict valueForKey:@"duration"] floatValue];
		float r = [[attributeDict valueForKey:@"rotation"] floatValue];
        
        id action = [CCRotateBy actionWithDuration:d angle:r];
        
        [self addAction:action];
    }
    else if ([elementName isEqualToString:@"scale_to"])
    {
        float d = [[attributeDict valueForKey:@"duration"] floatValue];
		float r = [[attributeDict valueForKey:@"scale"] floatValue];
        
        id action = [CCScaleTo actionWithDuration:d scale:r];
        
        [self addAction:action];
    }
    else if ([elementName isEqualToString:@"scale_by"])
    {
        float d = [[attributeDict valueForKey:@"duration"] floatValue];
		float r = [[attributeDict valueForKey:@"scale"] floatValue];
        
        id action = [CCScaleBy actionWithDuration:d scale:r];
        
        [self addAction:action];
    }
	else if ([elementName isEqualToString:@"line"])
	{
		//int tag1 = [[attributeDict valueForKey:@"toTag"] intValue];
		//int tag2 = [[attributeDict valueForKey:@"fromTag"] intValue];
		
		float x1 = [[attributeDict valueForKey:@"x1"] floatValue];
		float y1 = [[attributeDict valueForKey:@"y1"] floatValue];
		
		float x2 = [[attributeDict valueForKey:@"x2"] floatValue];
		float y2 = [[attributeDict valueForKey:@"y2"] floatValue];
		
		float w = [[attributeDict valueForKey:@"width"] floatValue];
		
		if (!w)
			w = 1;
        
        [_game.batchStaticDraw drawSegmentFrom:cpv(x1, y1) to:cpv(x2,y2) radius:w color:ccc4f(0, 0, 0, 1)];
	}
//    else if ([elementName isEqualToString:@"text"])
//	{
//        NSString *text = [[attributeDict valueForKey:@"text"] stringByReplacingOccurrencesOfString:@"\\n" 
//                                                                                        withString:@"\n"];
//        
//		float x = [[attributeDict valueForKey:@"x"] floatValue];
//		float y = [[attributeDict valueForKey:@"y"] floatValue];
//		
//		float a = [[attributeDict valueForKey:@"angle"] floatValue];
//	}
    else if ([elementName isEqualToString:@"fill"])
    {
        NSString *ptsStr = [attributeDict objectForKey:@"pts"];
        NSArray *pts = [ptsStr componentsSeparatedByString:@","];
        int count = [pts count]/2;
        
        float r = [[attributeDict valueForKey:@"r"] floatValue]/255.0;
        float g = [[attributeDict valueForKey:@"g"] floatValue]/255.0;
        float b = [[attributeDict valueForKey:@"b"] floatValue]/255.0;

        CGPoint verts[count];
        
        int index = count;
        for (int i = 0; i < count*2; i += 2)
        {
            float x = [[pts objectAtIndex:i] floatValue];
            float y = [[pts objectAtIndex:i+1] floatValue];
            
            verts[--index] = ccp(x, y);
            
            //CCLOG(@"%.2f,%.2f", x, y);
        }
        
        [_game.batchStaticDraw drawPolyWithVerts:verts count:count fillColor:ccc4f(r, g, b, 1) borderWidth:0 borderColor:ccc4f(r, g, b, .5)];
    }
	else if ([elementName isEqualToString:@"item"])
	{
        NSString *name = [attributeDict objectForKey:@"name"];
        float x = [[attributeDict valueForKey:@"x"] floatValue];
        float y = [[attributeDict valueForKey:@"y"] floatValue];
        
        if ([name isEqualToString:@"enemy-spawn"])
        {
            [_game.enemySpawnPoints addObject:[NSValue valueWithCGPoint:ccp(x, y)]];
            
            // Expects something to be put on the stack
            [_nodeStack addObject:[_nodeStack lastObject]];
        }
        else
        {
            float rot = -[[attributeDict valueForKey:@"angle"] floatValue];
            float scale = [[attributeDict valueForKey:@"scale"] floatValue];
            NSString *file = [self filenameFromPath:[attributeDict objectForKey:@"file"]];
            int z = [[attributeDict valueForKey:@"z"] intValue];
            int t = [[attributeDict valueForKey:@"tag"] intValue];
            BOOL hidden = [[attributeDict valueForKey:@"hidden"] boolValue];
            
            CCSprite *sprite = nil;
            
            if ([attributeDict objectForKey:@"shape_id"] != NULL)
            {
                UInt64 shape_id = [[attributeDict valueForKey:@"shape_id"] longLongValue];
                cpShape *shape = [_game.spaceManager loadedShapeForId:shape_id];
                
                if (shape)
                {
                    cpCCSprite* cpSprite = [cpCCSprite spriteWithFile:file];
                    cpSprite.body = shape->body;
                    sprite = cpSprite;
                }
            }	
            else
            {
                sprite = [CCSprite spriteWithFile:file];
                sprite.position = ccp(x,y);
                sprite.rotation = rot;
            }
            
            sprite.visible = !hidden;
            
            if (scale)
                sprite.scale = scale;
            
            [parent addChild:sprite z:z tag:t];
            
            [_nodeStack addObject:sprite];
        }
	}
	else if ([elementName isEqualToString:@"music"])
	{
		NSString *file = [attributeDict valueForKey:@"file"];
		
		[[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
		[[SimpleAudioEngine sharedEngine] playBackgroundMusic:file];
	}	
}
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"Error on XML Parse: %@", [parseError localizedDescription] );
}

-(void) addAction:(id)action
{
    //If the stack is empty we should being running it now
    if ([_actionStackList count] == 0)
        [[_nodeStack lastObject] runAction:action];
    
    //Otherwise pop it on the stack's last list
    else
        [[_actionStackList lastObject] addObject:action];
}

-(BOOL) aboutToReadConstraint:(cpConstraint*)constraint constraintId:(UInt64)id
{
    return YES;
}

-(BOOL) aboutToReadBody:(cpBody*)body bodyId:(UInt64)id
{
    return YES;
}

-(BOOL) aboutToReadShape:(cpShape *)shape shapeId:(UInt64)id
{
    // Save planet's body
    if (shape->collision_type == kPlanetCollisionType)
        [_game.gravitationalBodies addObject:[NSValue valueWithPointer:shape->body]];
    
    return YES;
}


@end
