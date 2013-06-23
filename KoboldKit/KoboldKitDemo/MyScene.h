//
//  MyScene.h
//  KoboldKitDemo
//

//  Copyright (c) 2013 Steffen Itterheim. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "KoboldKit.h"

@class MyLabelNode;

@interface MyScene : KKScene
{
	SKNode* _testCamera;
	CGPoint _currentControlPadDirection;
	KKTilemapNode* _tilemapNode;
}

@end
