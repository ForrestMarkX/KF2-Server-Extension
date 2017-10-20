class Ext_AICommandBasePet extends AICommand_Base_Zed;

var transient Pawn OwnerPawn;
var transient float NextSightCheckTime;

final function vector PickPointNearOwner()
{
	local byte i;
	local vector V,HL,HN,Start;
	
	Start = OwnerPawn.Location;
	if( OwnerPawn.Physics==PHYS_Falling )
	{
		if( Pawn.Trace(HL,HN,OwnerPawn.Location-vect(0,0,5000),OwnerPawn.Location,false,vect(20,20,60))!=None )
			Start = HL;
	}
	while( true )
	{
		++i;
		V.X = FRand()-0.5;
		V.Y = FRand()-0.5;
		V = Start + Normal2D(V) * (100.f+FRand()*500.f);
		
		if( i<20 && !FastTrace(V,Start) ) // Destination is inside a wall.
			continue;
		
		if( i<20 && FastTrace(V-vect(0,0,100),V) ) // Destination is above a pit.
			continue;
		break;
	}
	OwnerPawn = None;
	return V;
}
final function bool CanSeeOwner()
{
	local Pawn P;
	
	NextSightCheckTime = WorldInfo.TimeSeconds+1.f + FRand();
	P = Ext_T_MonsterPRI(PlayerReplicationInfo)!=None ? Ext_T_MonsterPRI(PlayerReplicationInfo).OwnerController.Pawn : None;
	if( P!=None && !LineOfSightTo(P) )
		return false;
	return true;
}

state ZedBaseCommand
{
Begin:
	if( Pawn.Physics == PHYS_Falling )
	{
		DisableMeleeRangeEventProbing();
		WaitForLanding();
	}
	EnableMeleeRangeEventProbing();
	// Check for any interrupt transitions
	CheckInterruptCombatTransitions();

	// Select nearest enemy if current enemy is invalid
	if( Enemy == none || Enemy.Health <= 0 || !IsValidAttackTarget(KFPawn(Enemy)) )
		SelectEnemy();

	// Handle special case if I'm supposed to be attacking a door
	if( DoorEnemy != none && DoorEnemy.Health > 0 && VSizeSq( DoorEnemy.Location - Pawn.Location ) < (DoorMeleeDistance * DoorMeleeDistance) ) //200UU
	{
		`AILog( self$" DoorEnemy: "$DoorEnemy$" starting melee attack", 'Command_Base' );
		UpdateHistoryString( "[Attacking : "$DoorEnemy$" at "$WorldInfo.TimeSeconds$"]" );
		class'AICommand_Attack_Melee'.static.Melee( Outer, DoorEnemy );
	}
	
	// See if we are close to our owner
RecheckOwner:
	OwnerPawn = Ext_T_MonsterPRI(PlayerReplicationInfo)!=None ? Ext_T_MonsterPRI(PlayerReplicationInfo).OwnerController.Pawn : None;
	if( OwnerPawn!=None )
	{
		if( Enemy!=None && LineOfSightTo(OwnerPawn) && LineOfSightTo(Enemy) ) // We have sight to our owner and can see enemy, go for it!
		{
			OwnerPawn = None;
			
			bWaitingOnMovementPlugIn = true;
			SetEnemyMoveGoal(self, true,,, ShouldAttackWhileMoving() );
			NextSightCheckTime = WorldInfo.TimeSeconds+2.f;
			while( bWaitingOnMovementPlugIn && bUsePluginsForMovement )
			{
				if( NextSightCheckTime<WorldInfo.TimeSeconds && !CanSeeOwner() )
				{
					ClearMovementInfo();
					GoTo'RecheckOwner';
				}
				Sleep(0.03);
			}
		}
		else if( VSizeSq(OwnerPawn.Location-Pawn.Location)>640000.f || !LineOfSightTo(OwnerPawn) ) // 800.f - Need to move closer to our owner.
		{
			bWaitingOnMovementPlugIn = true;
			SetMovePoint(PickPointNearOwner(),OwnerPawn,,300.f);

			while( bWaitingOnMovementPlugIn && bUsePluginsForMovement )
			{
				Sleep(0.03);
			}
		}
		else // Standing next to our owner.
		{
			OwnerPawn = None;
			Sleep(0.2+FRand()*0.5);
		}
	}
	else if( IsValidAttackTarget(KFPawn(Enemy)) )
	{
		`AILog( "Calling SetEnemyMoveGoal [Dist:"$VSize(Enemy.Location - Pawn.Location)$"] using offset of "$AttackRange$", because IsWithinBasicMeleeRange() returned false ", 'Command_Base' );
		bWaitingOnMovementPlugIn = true;
		SetEnemyMoveGoal(self, true,,, ShouldAttackWhileMoving() );

		while( bWaitingOnMovementPlugIn && bUsePluginsForMovement )
		{
			Sleep(0.03);
		}
		`AiLog("Back from waiting for the movement plug in!!!");

		if( Enemy == none )
		{
			Sleep( FRand() + 0.1f );
			Goto( 'Begin' );
		}
	}
	else
	{
		`AILog("Enemy is invalid melee target" @ Enemy, 'Command_Base');
		bFailedToMoveToEnemy = true;
	}

	// Check combat transitions
	CheckCombatTransition();
	if( bFailedToMoveToEnemy )
	{
		if( bFailedPathfind )
		{
			bFailedPathfind = false;
			Sleep( 0.f );
		}
		else
		{
			Sleep( 0.f );
		}
		SetEnemy( GetClosestEnemy( Enemy ) );
	}
	else
	{
		Sleep(0.f);
	}
	Goto('Begin');
}

DefaultProperties
{
}