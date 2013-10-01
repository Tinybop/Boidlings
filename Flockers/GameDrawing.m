//
//  GameDrawing.m
//  Flockers
//
//

// Import the interfaces
#import "GameDrawing.h"
#import "chipmunk_unsafe.h"

int noDrawFlag;

#define rgbf(x) (x/255.0)

#pragma mark - GameDrawing

void drawShapeWithColor(cpShape *shape, CCDrawNode *renderer, ccColor4F color)
{
    switch(shape->CP_PRIVATE(klass)->type){
		case CP_CIRCLE_SHAPE: {
            cpCircleShape *circle = (cpCircleShape *)shape;
            [renderer drawDot:circle->tc radius:cpfmax(circle->r+.5, 1.0) color:color];
        } break;
		case CP_SEGMENT_SHAPE: {
            cpSegmentShape *seg = (cpSegmentShape *)shape;
            [renderer drawSegmentFrom:seg->ta to:seg->tb radius:cpfmax(seg->r, 0.5) color:color];
        } break;
		case CP_POLY_SHAPE: {
            cpPolyShape *poly = (cpPolyShape *)shape;
            [renderer drawPolyWithVerts:poly->tVerts count:poly->numVerts fillColor:color borderWidth:0.0 borderColor:color];
        }break;
		default:
			cpAssertHard(FALSE, "Bad assertion in drawShapeWithColor()");
	}
    
#if 0
    // Draw center of grav
    [renderer drawDot:cpBodyGetPos(shape->body) radius:2 color:ccc4f(0, 0, 0, 1)];
#endif
}

void drawConstraint(cpConstraint *constraint, Game *game)
{
    if (constraint->data == &noDrawFlag)
        return;
    
	cpBody *body_a = constraint->a;
	cpBody *body_b = constraint->b;
    
    CCDrawNode *renderer = game.batchDynamicDraw;
    ccColor4F color = game.defaultConstraintColor;
    const cpConstraintClass *klass = constraint->CP_PRIVATE(klass);
    
    if (klass == cpSimpleMotorGetClass())
//        klass == cpGearJointGetClass())
    {
    }
    else
    {
        if(klass == cpPinJointGetClass()){
            cpPinJoint *joint = (cpPinJoint *)constraint;
            
            cpVect a = cpBodyLocal2World(body_a, joint->anchr1);
            cpVect b = cpBodyLocal2World(body_b, joint->anchr2);
            
            [renderer drawDot:a radius:3.0 color:color];
            [renderer drawDot:b radius:3.0 color:color];
            [renderer drawSegmentFrom:a to:b radius:1.5 color:color];
        }
        else if (klass == cpSlideJointGetClass()){
            cpSlideJoint *joint = (cpSlideJoint *)constraint;
            
            cpVect a = cpBodyLocal2World(body_a, joint->anchr1);
            cpVect b = cpBodyLocal2World(body_b, joint->anchr2);
            
            [renderer drawDot:a radius:3.0 color:game.defaultRopeColor];
            [renderer drawDot:b radius:3.0 color:game.defaultRopeColor];
            [renderer drawSegmentFrom:a to:b radius:1.0 color:game.defaultRopeColor];
        } else if(klass == cpPivotJointGetClass()){
            cpPivotJoint *joint = (cpPivotJoint *)constraint;
            
            cpVect a = cpBodyLocal2World(body_a, joint->anchr1);
            cpVect b = cpBodyLocal2World(body_b, joint->anchr2);
            cpVect pt = cpvmult(cpvadd(a, b), 0.5);
            
            ccColor4F color2 = ccc4f(color.r*.8, color.g*.8, color.b*.8, color.a);
            static const float len = .5;
            
            cpBody *body = (body_a->m == INFINITY) ? body_b : body_a;
            
            cpVect pt2 = cpvadd(pt, cpvmult(body->rot, 3));
            cpVect perp = cpvperp(body->rot);
            
            [renderer drawSegmentFrom:pt to:pt2 radius:1 color:color];
            [renderer drawSegmentFrom:cpvadd(pt2, cpvmult(perp, len)) to:cpvadd(pt2, cpvmult(perp, -len)) radius:2 color:color2];
            
            //[renderer drawDot:pt radius:3.0 color:color];
            
        } else if(klass == cpGrooveJointGetClass()){
            cpGrooveJoint *joint = (cpGrooveJoint *)constraint;
            
            cpVect a = cpBodyLocal2World(body_a, joint->grv_a);
            cpVect b = cpBodyLocal2World(body_a, joint->grv_b);
            cpVect c = cpBodyLocal2World(body_b, joint->anchr2);
            
            [renderer drawDot:c radius:3.0 color:color];
            [renderer drawSegmentFrom:a to:b radius:1.0 color:ccc4f(1, 1, 1, 1)]; //Always white
        } else if(klass == cpDampedSpringGetClass()){
            
            static const cpFloat totalStemLenFactor = .5;
            static const cpFloat heightFactor = .1;
            
            cpDampedSpring *joint = (cpDampedSpring *)constraint;
            
            cpVect a = cpBodyLocal2World(body_a, joint->anchr1);
            cpVect b = cpBodyLocal2World(body_b, joint->anchr2);
            cpFloat restLen = joint->restLength;
            
            cpVect dxdy = ccpSub(b, a);
            cpFloat len = cpvlength(dxdy);
            cpVect norm = cpvmult(dxdy, 1.0f/len);
            cpVect perp = cpvperp(norm);
            
            //### Force some mins for visibility
            if (restLen <= 15)
                restLen = 15;
            if (len <= 5)
                len = 5;
            
            cpFloat lenFactor = (restLen/len);
            
            // Don't get too large
            if (lenFactor > 3)
                lenFactor = 3;
            // or too small
            else if (lenFactor < .85)
                lenFactor = .85;
            
            cpFloat h = heightFactor*restLen*lenFactor;
            
            cpVect a2 = cpvadd(a, cpvmult(norm, totalStemLenFactor/2*restLen));
            cpVect b2 = cpvsub(b, cpvmult(norm, totalStemLenFactor/2*restLen));
            
            len -= (totalStemLenFactor*restLen);
            
            // Not a "true" calculation but looks right enough
            cpVect p1 = cpvadd(cpvadd(a2, cpvmult(perp, h)), cpvmult(norm, .1*len));
            cpVect p2 = cpvadd(cpvsub(a2, cpvmult(perp, h)), cpvmult(norm, .2*len));
            cpVect p3 = cpvadd(cpvadd(a2, cpvmult(perp, h)), cpvmult(norm, .3*len));
            cpVect p4 = cpvadd(cpvsub(a2, cpvmult(perp, h)), cpvmult(norm, .4*len));
            cpVect p5 = cpvadd(cpvadd(a2, cpvmult(perp, h)), cpvmult(norm, .5*len));
            cpVect p6 = cpvadd(cpvsub(a2, cpvmult(perp, h)), cpvmult(norm, .6*len));
            cpVect p7 = cpvadd(cpvadd(a2, cpvmult(perp, h)), cpvmult(norm, .7*len));
            cpVect p8 = cpvadd(cpvsub(a2, cpvmult(perp, h)), cpvmult(norm, .8*len));
            cpVect p9 = cpvadd(cpvadd(a2, cpvmult(perp, h)), cpvmult(norm, .9*len));
            
            //Stems
            [renderer drawSegmentFrom:a to:a2 radius:1.0 color:color];
            [renderer drawSegmentFrom:b to:b2 radius:1.0 color:color];
            
            //Coils
            [renderer drawSegmentFrom:a2 to:p1 radius:1.0 color:color];
            [renderer drawSegmentFrom:p1 to:p2 radius:1.0 color:color];
            [renderer drawSegmentFrom:p2 to:p3 radius:1.0 color:color];
            [renderer drawSegmentFrom:p3 to:p4 radius:1.0 color:color];
            [renderer drawSegmentFrom:p4 to:p5 radius:1.0 color:color];
            [renderer drawSegmentFrom:p5 to:p6 radius:1.0 color:color];
            [renderer drawSegmentFrom:p6 to:p7 radius:1.0 color:color];
            [renderer drawSegmentFrom:p7 to:p8 radius:1.0 color:color];
            [renderer drawSegmentFrom:p8 to:p9 radius:1.0 color:color];
            [renderer drawSegmentFrom:p9 to:b2 radius:1.0 color:color];
            
            //Anchors
            [renderer drawDot:a radius:3.0 color:color];
            [renderer drawDot:b radius:3.0 color:color];
            
        } else {
            //		printf("Cannot draw constraint\n");
        }
    }
}

void drawStaticShape(cpShape *shape, Game *game)
{
    // Definitely don't draw if we have this (Sprite data)
    CCNode<cpCCNodeProtocol>* node = shape->body->data;
    if (node)
        return;
    
    drawShapeWithColor(shape, game.batchStaticDraw, game.defaultShapeColor);
}

void drawActiveShape(cpShape *shape, Game *game)
{
    // Definitely don't draw if we have this (Sprite data)
    CCNode<cpCCNodeProtocol>* node = shape->body->data;
    if (node)
        return;
    
    drawShapeWithColor(shape, game.batchDynamicDraw, game.defaultShapeColor);
}
