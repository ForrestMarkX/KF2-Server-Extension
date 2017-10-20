Class VSZombie extends KFPawn_Monster
	abstract;

var() class<DamageType> MeleeHitDT;
var() string ZombieName;
var transient VSFPZedHands FPHandModel;
var() int MeleeDamage,HitsPerAttack;
var() float PropDamageScale;
var byte IsFiringMode[3];
var repnotify byte ServerAttackMode;
var() vector FPHandOffset;
var() name FPHandsIdle;
var() float HPScaler;
var bool bAttacking,bShowFPHands,bFPShowBody,bLockMovement;
var() bool bBoss;

replication
{
	if( true )
		ServerAttackMode;
}

// Bot AI.
function bool BotFire(bool bFinished)
{
	StartFire(0);
	return true;
}
function bool CanAttack(Actor Other)
{
	return VSizeSq(Other.Location-Location)<62500.f; // 250.f
}
function bool IsFiring()
{
	local byte i;
	
	for( i=0; i<ArrayCount(IsFiringMode); ++i )
		if( IsFiringMode[i]!=0 )
			return true;
	return false;
}
function bool StopFiring()
{
	local byte i;
	
	for( i=0; i<ArrayCount(IsFiringMode); ++i )
		IsFiringMode[i] = 0;
	return true;
}
function bool HasRangedAttack()
{
	return false;
}

simulated function ModifyPlayerInput( PlayerController PC, float DeltaTime )
{
	if( bLockMovement )
	{
		PC.PlayerInput.aForward = 0;
		PC.PlayerInput.aStrafe = 0;
		PC.bPressedJump = false;
	}
}

function SetSprinting(bool bNewSprintStatus);

// Handle animation input.
function PlayAttackAnim( byte Num )
{
	if( !bAttacking )
		ServerAttackAnim(Num);
}
simulated function float StartAttackAnim( byte Num ) // Return animation duration.
{
	return 0.2f;
}
simulated function AttackFinished()
{
	local byte i;

	bAttacking = false;
	bLockMovement = false; // Usually at this point enable movement.
	if( WorldInfo.NetMode!=NM_Client )
	{
		// Attack again.
		for( i=0; i<ArrayCount(IsFiringMode); ++i )
		{
			if( IsFiringMode[i]!=0 )
			{
				PlayAttackAnim(i);
				break;
			}
		}
	}
}

// Handle fire input.
reliable server function ServerModeFire( bool bStart, byte Mode )
{
	if( (bStart && bNoWeaponFiring) || Mode>=ArrayCount(IsFiringMode) || WorldInfo.NetMode==NM_Client )
		return;
	IsFiringMode[Mode] = byte(bStart);
	if( bStart )
		PlayAttackAnim(Mode);
}
simulated function StartFire(byte FireModeNum)
{
	if( bNoWeaponFiring )
		return;
	ServerModeFire(true,FireModeNum);
}
simulated function StopFire(byte FireModeNum)
{
	ServerModeFire(false,FireModeNum);
}

function DropProp();

// Handle animation replication.
function ServerAttackAnim( byte Num )
{
	local float F;
	bAttacking = true;
	F = StartAttackAnim(Num);
	SetTimer(F,false,'AttackFinished');
	if( WorldInfo.NetMode!=NM_StandAlone )
	{
		Num+=1;
		if( Num==ServerAttackMode )
			ServerAttackMode = ServerAttackMode | 128;
		else ServerAttackMode = Num;
		SetTimer(F+0.5,false,'ResetAttackTimer');
	}
}
function ResetAttackTimer()
{
	ServerAttackMode = 0;
}
simulated event ReplicatedEvent(name VarName)
{
	switch( VarName )
	{
	case 'ServerAttackMode':
		if( ServerAttackMode!=0 )
		{
			ServerAttackMode = (ServerAttackMode & 127)-1;
			bAttacking = true;
			SetTimer(StartAttackAnim(ServerAttackMode),false,'AttackFinished');
		}
		break;
	default:
		Super.ReplicatedEvent(VarName);
	}
}

// Handle melee damage.
simulated function MeleeImpactNotify(KFAnimNotify_MeleeImpact Notify)
{
	if( WorldInfo.NetMode!=NM_Client )
		MeleeDamageTarget(vector(Rotation)*MeleeDamage*500.f);
}

function bool MeleeDamageTarget( vector pushdir )
{
	local Actor A;
	local vector Dir,HL,HN,Start;
	local byte T;
	local bool bResult,bHitActors;

	if( WorldInfo.NetMode==NM_Client || Controller==None )
		Return False; // Never should be done on client.

	Start = GetPawnViewLocation();
	Dir = vector(GetAdjustedAimFor(None,Start));
	T = GetTeamNum();
	
	// First try if can hit with a small extent trace.
	foreach TraceActors(Class'Actor',A,HL,HN,Start+Dir*120.f,Start,vect(8,8,8))
	{
		if( A.bWorldGeometry || A==WorldInfo )
		{
			if( KFDoorActor(A)!=None )
			{
				DamageDoor(KFDoorActor(A),HL,pushdir);
				bHitActors = true;
			}
			bResult = true;
			break;
		}
		else if( Pawn(A)!=None )
		{
			if( Pawn(A).Health>0 && (Pawn(A).GetTeamNum()!=T || WorldInfo.Game.bGameEnded) )
			{
				DealMeleeDamage(A,HL,pushdir);
				bResult = true;
				bHitActors = true;
			}
		}
	}

	if( !bHitActors )
	{
		// Then try with large extent.
		HN.X = GetCollisionRadius()*0.75;
		HN.Y = HN.X;
		HN.Z = GetCollisionHeight()*0.5;
		foreach TraceActors(Class'Actor',A,HL,HN,Location+Dir*120.f,Location,HN)
		{
			if( A.bWorldGeometry || A==WorldInfo )
			{
				if( KFDoorActor(A)!=None )
					DamageDoor(KFDoorActor(A),HL,pushdir);
				else DealMeleeDamage(A,HL,pushdir);
				bResult = true;
				break;
			}
			else if( Pawn(A)!=None )
			{
				if( Pawn(A).Health>0 && (Pawn(A).GetTeamNum()!=T || WorldInfo.Game.bGameEnded) )
				{
					DealMeleeDamage(A,HL,pushdir);
					bResult = true;
				}
			}
			else DealMeleeDamage(A,HL,pushdir);
		}
	}
	return bResult;
}
function DealMeleeDamage( Actor Other, vector HL, vector pushdir )
{
	if( KFPawn_Monster(Other)!=None && KFPawn_Monster(Other).GetTeamNum()==0 )
		Other.TakeDamage(MeleeDamage*5, Controller, HL, pushdir, MeleeHitDT,,Self); // Almost insta-kill pet zeds.
	else Other.TakeDamage(MeleeDamage, Controller, HL, pushdir, MeleeHitDT,,Self);
}
function DamageDoor( KFDoorActor D, vector HL, vector pushdir )
{
	local bool bIsP;

	// Hack method, fake player being a NPC while damage is dealt to allow destroy the door.
	bIsP = Controller.bIsPlayer;
	Controller.bIsPlayer = false;
	D.TakeDamage(MeleeDamage, Controller, HL, pushdir, MeleeHitDT,,Self);
	Controller.bIsPlayer = bIsP;
}

/** Apply damage to a specific zone (useful for gore effects) */
function TakeHitZoneDamage(float Damage, class<DamageType> DamageType, int HitZoneIdx, vector InstigatorLocation)
{
	local float HeadHealthPercentage;

	Super(KFPawn).TakeHitZoneDamage(Damage, DamageType, HitZoneIdx, InstigatorLocation);

	if ( HitZoneIdx == HZI_Head && Health>0 ) // Don't remove head until zombie actually dies.
		HitZones[HZI_Head].GoreHealth = Max(HitZones[HZI_Head].GoreHealth,1);

	// When GoreHealth <= 0, check to see if this weapon can dismember limbs
	if ( HitZones[HitZoneIdx].GoreHealth <= 0 && CanInjureHitZone(DamageType, HitZoneIdx) )
		HitZoneInjured(HitZoneIdx);

	// Handle head injuries
	if ( HitZoneIdx == HZI_Head )
	{
		// Based on head health, calculate number of head chunks we're allowed to remove
		if( !bPlayedDeath && !bIsHeadless && !bTearOff )
		{
			HeadHealthPercentage = GetHeadHealthPercent();
			if( HeadHealthPercentage > 0.5 )
			{
				MaxHeadChunkGoreWhileAlive = 1;
			}
			else if ( HeadHealthPercentage > 0.25 )
			{
				MaxHeadChunkGoreWhileAlive = 2;
			}
			else if ( HeadHealthPercentage > 0.0 )
			{
				MaxHeadChunkGoreWhileAlive = 3;
			}
		}
	}
}

simulated function SetMeshVisibility(bool bVisible)
{
	Super.SetMeshVisibility(bVisible);
	bShowFPHands = !bVisible;
}

// First person hands.
simulated function DrawHUD( HUD H )
{
	Super.DrawHUD(H);
	if( Health<=0 )
		return;
	if( !bShowFPHands )
	{
		if( FPHandModel!=None && !FPHandModel.bHidden )
			FPHandModel.SetHidden(true);
	}
	else
	{
		if( FPHandModel==None )
		{
			FPHandModel = Spawn(class'VSFPZedHands',Self);
			FPHandModel.InitHands(Mesh);
			FPHandModel.Mesh.SetLightingChannels(PawnLightingChannel);
			InitFPHands();
		}
		if( FPHandModel.bHidden )
			FPHandModel.SetHidden(false);
		FPHandModel.SetRotation(GetViewRotation());
		FPHandModel.SetLocation(GetPawnViewLocation()+(FPHandOffset >> FPHandModel.Rotation));
	}
}
simulated function InitFPHands()
{
	FPHandModel.Mesh.HideBoneByName('RightUpLeg',PBO_Term);
	FPHandModel.Mesh.HideBoneByName('LeftUpLeg',PBO_Term);
	FPHandModel.Mesh.HideBoneByName('Neck',PBO_Term);
	FPHandModel.SetIdleAnim(FPHandsIdle);
}
simulated function Destroyed()
{
	DisableNightVision();
	if( FPHandModel!=None )
		FPHandModel.Destroy();
	Super.Destroyed();
}
simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	DisableNightVision();
	if( FPHandModel!=None )
		FPHandModel.Destroy();
	Super.PlayDying(DamageType,HitLoc);
}
exec function TestFPOffset( vector V )
{
	FPHandOffset = V;
}

simulated final function DisableNightVision()
{
	local KFPlayerController KFPC;

	if( IsLocallyControlled() )
	{
		KFPC = KFPlayerController(Controller);
		if( KFPC!=None && KFPC.bNightVisionActive )
			KFPC.SetNightVision(false);
	}
}

function PossessedBy( Controller C, bool bVehicleTransition )
{
	Super(KFPawn).PossessedBy( C, bVehicleTransition );

	bReducedZedOnZedPinchPointCollisionStateActive = false;
	bIgnoreTeamCollision = true;
}

// Removed insane damage multiplier for headshot.
function AdjustDamage(out int InDamage, out vector Momentum, Controller InstigatedBy, vector HitLocation, class<DamageType> DamageType, TraceHitInfo HitInfo, Actor DamageCauser)
{
	local float TempDamage,DamageMod;
	local int HitZoneIdx;

	Super(KFPawn).AdjustDamage(InDamage, Momentum, InstigatedBy, HitLocation, DamageType, HitInfo, DamageCauser);

	TempDamage = InDamage; // Multiply by float value all the way for more precise result.

	// is vulnerable?
	DamageMod = 1.f;
	if( IsVulnerableTo(DamageType,DamageMod) )
	{
		TempDamage *= DamageMod;
	}
	else if( IsResistantTo(DamageType,DamageMod) )
	{
		TempDamage *= DamageMod;
	}

	// Cached hit params
	if( HitInfo.BoneName!='' && class<KFDT_Bludgeon>(DamageType)==None && class<KFDT_Slashing>(DamageType)==None )
	{
		HitZoneIdx = HitZones.Find('ZoneName', HitInfo.BoneName);
		if( HitZoneIdx>=0 )
			TempDamage *= HitZones[HitZoneIdx].DmgScale;
	}

	InDamage = FCeil( TempDamage );
	
	if( InstigatedBy!=None && InstigatedBy!=Controller && InstigatedBy.GetTeamNum()==0 )
	{
		// Give credits to pets owner.
		if( Ext_T_MonsterPRI(InstigatedBy.PlayerReplicationInfo)!=None )
			InstigatedBy = Ext_T_MonsterPRI(InstigatedBy.PlayerReplicationInfo).OwnerController;
		if( InstigatedBy!=None )
			AddTakenDamage( InstigatedBy, FMin(Health, InDamage), DamageCauser, class<KFDamageType>(DamageType) );
	}
}

event Landed(vector HitNormal, actor FloorActor)
{
	Super.Landed(HitNormal, FloorActor);
	if ( Velocity.Z < -200 )
	{
		// Slow down after a jump.
		Velocity.X *= 0.02;
		Velocity.Y *= 0.02;
	}
}

function bool DoJump( bool bUpdating )
{
	if( bJumpCapable && (Physics == PHYS_Walking || Physics == PHYS_Ladder || Physics == PHYS_Spider) )
	{
		if ( Physics == PHYS_Spider )
			Velocity = Velocity + (JumpZ * Floor);
		else if ( Physics == PHYS_Ladder )
			Velocity.Z = 0;
		else Velocity.Z = JumpZ;
		if (Base != None && !Base.bWorldGeometry && Base.Velocity.Z > 0.f)
			Velocity.Z += Base.Velocity.Z;
		SetPhysics(PHYS_Falling);
		return true;
	}
	return false;
}

// Nope.
function bool CanBeGrabbed(KFPawn GrabbingPawn, optional bool bIgnoreFalling, optional bool bAllowSameTeamGrab)
{
    return false;
}

// UI stuff.
simulated function String GetHumanReadableName()
{
	if ( PlayerReplicationInfo != None )
		return PlayerReplicationInfo.PlayerName;
	return ZombieName;
}

defaultproperties
{
	bIgnoreBaseRotation=true
	MeleeDamage=22
	HitsPerAttack=1
	bCanCrouch=true
	FPHandOffset=(X=-40,Z=-70)
	FPHandsIdle="Walk_B_taunt_V2"
	MeleeHitDT=class'KFDT_ZombieHit'
	AccelRate=800
	HPScaler=1
	InventoryManagerClass=None // No weapons for bots!

	ZombieName="Zombie"
	PropDamageScale=0.65
	
	HitZones(0)=(ZoneName="head",BoneName="head",GoreHealth=20,Limb=BP_Head,DmgScale=2)
	HitZones(1)=(ZoneName="neck",BoneName="neck",GoreHealth=20,Limb=BP_Head,DmgScale=2)
	HitZones(2)=(ZoneName="chest",BoneName="Spine2",GoreHealth=150,Limb=BP_Torso)
	HitZones(3)=(ZoneName="heart",BoneName="Spine2",GoreHealth=150,Limb=BP_Special)
	HitZones(4)=(ZoneName="lupperarm",BoneName="LeftArm",Limb=BP_LeftArm,DmgScale=0.4)
	HitZones(5)=(ZoneName="lforearm",BoneName="LeftForearm",GoreHealth=15,Limb=BP_LeftArm,DmgScale=0.4)
	HitZones(6)=(ZoneName="lhand",BoneName="LeftHand",GoreHealth=20,Limb=BP_LeftArm,DmgScale=0.4)
	HitZones(7)=(ZoneName="rupperarm",BoneName="RightArm",Limb=BP_RightArm,DmgScale=0.4)
	HitZones(8)=(ZoneName="rforearm",BoneName="RightForearm",GoreHealth=15,Limb=BP_RightArm,DmgScale=0.4)
	HitZones(9)=(ZoneName="rhand",BoneName="RightHand",GoreHealth=20,Limb=BP_RightArm,DmgScale=0.4)
	HitZones(10)=(ZoneName="stomach",BoneName="Spine1",GoreHealth=150,Limb=BP_Torso)
	HitZones(11)=(ZoneName="abdomen",BoneName="Hips",GoreHealth=150,Limb=BP_Torso)
	HitZones(12)=(ZoneName="lthigh",BoneName="LeftUpLeg",GoreHealth=75,Limb=BP_LeftLeg,DmgScale=0.75)
	HitZones(13)=(ZoneName="lcalf",BoneName="LeftLeg",GoreHealth=25,Limb=BP_LeftLeg,DmgScale=0.7)
	HitZones(14)=(ZoneName="lfoot",BoneName="LeftFoot",GoreHealth=15,Limb=BP_LeftLeg,DmgScale=0.7)
	HitZones(15)=(ZoneName="rthigh",BoneName="RightUpLeg",GoreHealth=75,Limb=BP_RightLeg,DmgScale=0.75)
	HitZones(16)=(ZoneName="rcalf",BoneName="RightLeg",GoreHealth=25,Limb=BP_RightLeg,DmgScale=0.7)
	HitZones(17)=(ZoneName="rfoot",BoneName="RightFoot",GoreHealth=15,Limb=BP_RightLeg,DmgScale=0.7)
	
	Begin Object Name=KFPawnSkeletalMeshComponent
		RBChannel=RBCC_Untitled3
	End Object
}