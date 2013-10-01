//
//  contants.h
//  Flockers
//
//  Created by Rob Blackwood on 9/27/13.
//  Copyright (c) 2013 Tinybop. All rights reserved.
//

#pragma once

#define     kPlayerCollisionType        1
#define     kEnemyCollisionType         2
#define     kBulletCollisionType        3
#define     kTerrainCollisionType       4
#define     kPlanetCollisionType        5

static inline float randomFloatRange(float min, float max)
{
    return min + CCRANDOM_0_1() * (max-min);
}