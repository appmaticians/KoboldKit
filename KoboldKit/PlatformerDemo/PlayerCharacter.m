//
//  PlayerCharacter.m
//  KoboldKit
//
//  Created by Steffen Itterheim on 10.07.13.
//  Copyright (c) 2013 Steffen Itterheim. All rights reserved.
//

#import "PlayerCharacter.h"

@implementation PlayerCharacter

-(void) nodeDidSpawnWithObject:(KKTilemapObject*)object
{
	NSLog(@"-(void) nodeDidSpawnWithObject:(KKTilemapObject*)object");
	LOG_EXPR(object);
	
	// tilamep node
	KKTilemapNode* tilemapNode = (KKTilemapNode*)self.parent.parent;
	NSAssert1([tilemapNode isKindOfClass:[KKTilemapNode class]], @"player.parent.parent (%@) is not the tilemap node!", tilemapNode);
	
	[self setupWithPlayerObject:object movementBounds:tilemapNode.bounds];
}

-(void) setupWithPlayerObject:(KKTilemapObject*)playerObject movementBounds:(CGRect)movementBounds
{
	KKTilemapProperties* playerProperties = playerObject.properties;
	NSString* defaultImage = [playerProperties stringForKey:@"defaultImage"];
	CGSize playerSize = playerObject.size;
	
	if (defaultImage.length > 0)
	{
		SKTexture* texture = [SKTexture textureWithImageNamed:defaultImage];
		if (texture)
		{
			_playerSprite = [SKSpriteNode spriteNodeWithImageNamed:defaultImage];
		}
		else
		{
			SKTextureAtlas* atlas = [SKTextureAtlas atlasNamed:@"Jetpack"];
			texture = [atlas textureNamed:defaultImage];
			_playerSprite = [SKSpriteNode spriteNodeWithTexture:texture];
		}

		playerSize = _playerSprite.size;
	}
	else
	{
		_playerSprite = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:playerSize];
	}
	[self addChild:_playerSprite];

	CGSize bboxSize = playerSize;
	NSString* bboxString = [playerProperties stringForKey:@"boundingBox"];
	if (bboxString.length)
	{
		bboxSize = CGSizeFromString(bboxString);
	}
	LOG_EXPR(playerSize);
	LOG_EXPR(bboxSize);
	
	[self physicsBodyWithRectangleOfSize:bboxSize];
	self.physicsBody.contactTestBitMask = 0xFFFFFFFF;
	self.physicsBody.affectedByGravity = NO;
	self.name = @"player";
	self.position = CGPointMake(playerObject.position.x + playerSize.width / 2,
								playerObject.position.y + playerSize.height / 2);
	
	self.physicsBody.allowsRotation = [playerProperties numberForKey:@"allowsRotation"].boolValue;
	self.physicsBody.angularDamping = [playerProperties numberForKey:@"angularDamping"].floatValue;
	self.physicsBody.linearDamping = [playerProperties numberForKey:@"linearDamping"].floatValue;
	self.physicsBody.friction = [playerProperties numberForKey:@"friction"].floatValue;
	self.physicsBody.mass = [playerProperties numberForKey:@"mass"].floatValue;
	self.physicsBody.restitution = [playerProperties numberForKey:@"restitution"].floatValue;
	LOG_EXPR(self.physicsBody.allowsRotation);
	LOG_EXPR(self.physicsBody.angularDamping);
	LOG_EXPR(self.physicsBody.linearDamping);
	LOG_EXPR(self.physicsBody.friction);
	LOG_EXPR(self.physicsBody.mass);
	LOG_EXPR(self.physicsBody.density);
	LOG_EXPR(self.physicsBody.restitution);
	LOG_EXPR(self.physicsBody.area);

	/*
	// apply Tiled properties to ivars
	KKIvarSetter* ivarSetter = [[KKIvarSetter alloc] initWithClass:[self class]];
	[ivarSetter setIvarsWithDictionary:playerProperties.properties target:self];
	 */
	LOG_EXPR(_jumpSpeedInitial);
	LOG_EXPR(_jumpSpeedDeceleration);
	LOG_EXPR(_fallSpeedAcceleration);
	LOG_EXPR(_fallSpeedLimit);
	LOG_EXPR(_runSpeedAcceleration);
	
	// limit maximum speed of the player
	if ([playerProperties numberForKey:@"velocityLimit"])
	{
		CGFloat limit = [playerProperties numberForKey:@"velocityLimit"].doubleValue;
		[self addBehavior:[KKLimitVelocityBehavior limitVelocity:limit]];
	}
	
	// prevent player from leaving the area
	if ([playerProperties numberForKey:@"stayInBounds"].boolValue)
	{
		[self addBehavior:[KKStayInBoundsBehavior stayInBounds:movementBounds]];
	}
	
	// make the camera follow the player
	[self addBehavior:[KKCameraFollowBehavior behavior] withKey:@"camera"];

	// receive updates
	[self observeSceneEvents];
}

-(void) controlPadDidChangeDirection:(NSNotification*)note
{
	KKControlPadBehavior* controlPad = [note.userInfo objectForKey:@"behavior"];
	if (controlPad.direction == KKArcadeJoystickNone)
	{
		_running = NO;
		_currentControlPadDirection = CGPointZero;
	}
	else
	{
		_running = YES;
		CGFloat speed = _runSpeedAcceleration;
		if (speed == 0.0 || speed > _runSpeedLimit)
		{
			speed = _runSpeedLimit;
		}
		_currentControlPadDirection = ccpMult(vectorFromJoystickState(controlPad.direction), speed);
	}
}

-(void) attackButtonPressed:(NSNotification*)note
{
	NSLog(@"attack!");
}

-(void) jumpButtonPressed:(NSNotification*)note
{
	CGPoint velocity = self.physicsBody.velocity;
	if (_jumping == NO && velocity.y > -0.001 && velocity.y < 0.001)
	{
		_jumping = YES;
		velocity.y = _jumpSpeedInitial;
		self.physicsBody.velocity = velocity;
		
		_jumpButton = [note.userInfo objectForKey:@"behavior"];
	}
}

-(void) jumpButtonReleased:(NSNotification *)note
{
	if (_jumping)
	{
		[self endJump];

		CGPoint velocity = self.physicsBody.velocity;
		if (velocity.y > _jumpAbortVelocity)
		{
			velocity.y = _jumpAbortVelocity;
		}
		self.physicsBody.velocity = velocity;
	}
}

-(void) endJump
{
	_jumping = NO;
	
	[_jumpButton endSelect];
	_jumpButton = nil;
}

-(void) update:(NSTimeInterval)currentTime
{
	CGPoint velocity = self.physicsBody.velocity;
	if (_jumping)
	{
		if (velocity.y > 0.0)
		{
			velocity.y -= _jumpSpeedDeceleration;
		}
		else
		{
			[self endJump];
		}
	}
	else
	{
		if (_fallSpeedAcceleration == 0.0 || _fallSpeedAcceleration >= _fallSpeedLimit)
		{
			velocity.y = -_fallSpeedLimit;
		}
		else
		{
			velocity.y -= _fallSpeedAcceleration;
		}
	}
	
	velocity.y = MAX(velocity.y, -_fallSpeedLimit);

	if (_running)
	{
		velocity.x += _currentControlPadDirection.x;
		velocity.x = MIN(velocity.x, _runSpeedLimit);
		velocity.x = MAX(velocity.x, -_runSpeedLimit);
	}
	else if (velocity.x != 0.0)
	{
		if (_runSpeedDeceleration == 0)
		{
			velocity.x = 0.0;
		}
		else if (velocity.x > 0.0)
		{
			velocity.x -= _runSpeedDeceleration;
			if (velocity.x < 0.0)
			{
				velocity.x = 0.0;
			}
		}
		else
		{
			velocity.x += _runSpeedDeceleration;
			if (velocity.x > 0.0)
			{
				velocity.x = 0.0;
			}
		}
	}
	
	self.physicsBody.velocity = velocity;
	
	//NSLog(@"pos: {%.0f, %.0f}", _playerCharacter.position.x, _playerCharacter.position.y);
	//NSLog(@"pos: {%.0f, %.0f}", _tilemapNode.mainTileLayerNode.position.x, _tilemapNode.mainTileLayerNode.position.y);
	
	/*
	NSLog(@"----------------------------");
	LOG_EXPR(_playerSprite.position);
	LOG_EXPR(_playerSprite.parent.position);
	LOG_EXPR(_playerSprite.parent.parent.position);
	LOG_EXPR(_playerSprite.parent.parent.parent.position);
	 */
}

-(void) didBeginContact:(SKPhysicsContact*)contact
{
	SKPhysicsBody* myBody = self.physicsBody;
	if (contact.bodyA == myBody || contact.bodyB == myBody)
	{
		// FIXME: this should actually check for collision with floor
		
		// prevent jitter on floor
		/*
		CGPoint velocity = myBody.velocity;
		velocity.y = 0.0;
		myBody.velocity = velocity;
		 */
	}
}

@end
