/*********************************************************************
 *	
 *	cpCCNode.m
 *
 *	http://www.mobile-bros.com
 *
 *	Created by Robert Blackwood on 02/22/2009.
 *	Copyright 2009 Mobile Bros. All rights reserved.
 *
 **********************************************************************/

#import "cpCCNode.h"

#if (COCOS2D_VERSION >= 0x00020100)
#define position_               _position
#define anchorPointInPoints_    _anchorPointInPoints
#define skewX_                  _skewX
#define skewY_                  _skewY
#define scaleX_                 _scaleX
#define scaleY_                 _scaleY
#define transform_              _transform
#endif


@implementation cpCCNode

+ (id) nodeWithShape:(cpShape*)shape
{
	return [[[self alloc] initWithShape:shape] autorelease];
}

+ (id) nodeWithBody:(cpBody*)body
{
	return [[[self alloc] initWithBody:body] autorelease];
}

- (id) initWithShape:(cpShape*)shape
{
    [self init];
        
    _implementation.shape = shape;
    [_implementation syncNode:self];
    	
	return self;
}

- (id) initWithBody:(cpBody*)body
{
	[self init];
    
    _implementation.body = body;
    [_implementation syncNode:self];
    
	return self;
}

- (id) init
{
    [super init];
    
    _implementation = [[cpCCNodeImpl alloc] initWithNode:self];
    
    return self;
}

- (void) dealloc
{
	[_implementation release];
	[super dealloc];
}

#if (COCOS2D_VERSION >= 0x00020000)
-(CGAffineTransform) nodeToParentTransform
{
	cpBody *body = _implementation.body;
    
    // Get out quick
    if (!body)
        return [super nodeToParentTransform];
    
	cpVect rot = (_implementation.ignoreRotation ? cpvforangle(-CC_DEGREES_TO_RADIANS(self.rotation)) : body->rot);
    cpVect pos = cpBodyGetPos(body);
    
    // Translate values
    float x = pos.x*cpCCNodeImpl.xScaleRatio;
    float y = pos.y*cpCCNodeImpl.yScaleRatio;
    
    //Sync node
    position_ = ccp(x,y);
    self.rotation = -CC_RADIANS_TO_DEGREES(cpvtoangle(rot));
    
    if (self.ignoreAnchorPointForPosition) {
        x += anchorPointInPoints_.x;
        y += anchorPointInPoints_.y;
    }
    
    BOOL needsSkewMatrix = ( skewX_ || skewY_ );
    
    // optimization:
    // inline anchor point calculation if skew is not needed
    if( !needsSkewMatrix && !CGPointEqualToPoint(anchorPointInPoints_, CGPointZero) ) {
        x += rot.x * -anchorPointInPoints_.x * scaleX_ + -rot.y * -anchorPointInPoints_.y * scaleY_;
        y += rot.y * -anchorPointInPoints_.x * scaleX_ +  rot.x * -anchorPointInPoints_.y * scaleY_;
    }
    
    
    // Build Transform Matrix
    transform_ = CGAffineTransformMake( rot.x * scaleX_,  rot.y * scaleX_,
                                       -rot.y * scaleY_, rot.x * scaleY_,
                                       x, y );
    
    // XXX: Try to inline skew
    // If skew is needed, apply skew and then anchor point
    if( needsSkewMatrix ) {
        CGAffineTransform skewMatrix = CGAffineTransformMake(1.0f, tanf(CC_DEGREES_TO_RADIANS(skewY_)),
                                                             tanf(CC_DEGREES_TO_RADIANS(skewX_)), 1.0f,
                                                             0.0f, 0.0f );
        transform_ = CGAffineTransformConcat(skewMatrix, transform_);
        
        // adjust anchor point
        if( ! CGPointEqualToPoint(anchorPointInPoints_, CGPointZero) )
            transform_ = CGAffineTransformTranslate(transform_, -anchorPointInPoints_.x, -anchorPointInPoints_.y);
    }
    
    return transform_;
}
#endif

-(void)setRotationX:(float)rot
{
    [self setRotation:rot];
}

-(void)setRotationY:(float)rot
{
    [self setRotation:rot];
}

-(void)setRotation:(float)rot
{
	if([_implementation setRotation:rot])
		[super setRotation:rot];
}

-(void)setPosition:(cpVect)pos
{
	[_implementation setPosition:pos];
	[super setPosition:pos];
}

-(void) applyImpulse:(cpVect)impulse
{
	[_implementation applyImpulse:impulse offset:cpvzero];
}

-(void) applyForce:(cpVect)force
{
	[_implementation applyForce:force offset:cpvzero];
}

-(void) applyImpulse:(cpVect)impulse offset:(cpVect)offset
{
	[_implementation applyImpulse:impulse offset:offset];
}

-(void) applyForce:(cpVect)force offset:(cpVect)offset
{
	[_implementation applyForce:force offset:offset];
}

-(void) resetForces
{
	[_implementation resetForces];
}

-(void) setIgnoreRotation:(BOOL)ignore
{
	_implementation.ignoreRotation = ignore;
}

-(BOOL) ignoreRotation
{
	return _implementation.ignoreRotation;
}

-(void) setIntegrationDt:(cpFloat)dt
{
	_implementation.integrationDt = dt;
}

-(cpFloat) integrationDt
{
	return _implementation.integrationDt;
}

-(void) setShape:(cpShape*)shape
{
    if (shape)
        [self setBody:shape->body];
    else
        [self setBody:NULL];
}

-(cpShape*) shape
{
    return _implementation.shape;
}

-(NSArray*) shapes
{
    return _implementation.shapes;
}

-(void) setBody:(cpBody*)body
{
    if (body)
        body->data = self;
    _implementation.body = body;
}

-(cpBody*) body
{
    return _implementation.body;
}

-(void) setSpaceManager:(SpaceManager*)spaceManager
{
	_implementation.spaceManager = spaceManager;
}

-(SpaceManager*) spaceManager
{
	return _implementation.spaceManager;
}

-(void) setAutoFreeShapeAndBody:(BOOL)autoFree
{
	_implementation.autoFreeShapeAndBody = autoFree;
}

-(BOOL) autoFreeShapeAndBody
{
	return _implementation.autoFreeShapeAndBody;
}

@end

