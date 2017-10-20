Class ExtHumanPawn extends KFPawn_Human;

// Forrests backpack weapon and first person legs.
var SkeletalMeshComponent AttachedBackItem;
var SkeletalMeshComponent FPBodyMesh;
var repnotify class<KFWeapon> BackpackWeaponClass;
var KFWeapon PlayerOldWeapon;

var transient float NextRedeemTimer,BHopSpeedMod;
var float KnockbackResist,NoRagdollChance;
var AnimSet WakeUpAnimSet;
var name FeignRecoverAnim;
var byte UnfeignFailedCount,RepRegenHP,BHopAccelSpeed;
var repnotify bool bFeigningDeath;
var bool bPlayingFeignDeathRecovery,bRagdollFromFalling,bRagdollFromBackhit,bRagdollFromMomentum,bCanBecomeRagdoll,bRedeadMode,bPendingRedead,bHasBunnyHop,bOnFirstPerson,bFPLegsAttached,bFPLegsInit;

var byte HealingShieldMod,HealingSpeedBoostMod,HealingDamageBoostMod;

replication
{
	if( true )
		bFeigningDeath,RepRegenHP,BackpackWeaponClass;
	if( bNetOwner )
		bHasBunnyHop;
	if( bNetDirty )
		HealingSpeedBoostMod, HealingDamageBoostMod, HealingShieldMod;
}

function TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	if( KnockbackResist<1 )
		Momentum *= KnockbackResist;
	Super.TakeDamage(Damage,InstigatedBy,HitLocation,Momentum,DamageType,HitInfo,DamageCauser);
}

simulated function bool Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	local ExtPlayerController C;
	local class<Pawn> KillerPawn;
	local PlayerReplicationInfo KillerPRI;
	local SeqAct_Latent Action;

	if( WorldInfo.NetMode!=NM_Client && PlayerReplicationInfo!=None )
	{
		if( Killer==None || Killer==Controller )
		{
			KillerPRI = PlayerReplicationInfo;
			KillerPawn = None;
		}
		else
		{
			KillerPRI = Killer.PlayerReplicationInfo;
			if( KillerPRI==None || KillerPRI.Team!=PlayerReplicationInfo.Team )
			{
				KillerPawn = Killer.Pawn!=None ? Killer.Pawn.Class : None;
				if( PlayerController(Killer)==None ) // If was killed by a monster, don't broadcast PRI along with it.
					KillerPRI = None;
			}
			else KillerPawn = None;
		}
		foreach WorldInfo.AllControllers(class'ExtPlayerController',C)
			C.ClientKillMessage(damageType,PlayerReplicationInfo,KillerPRI,KillerPawn);
	}
	// If got killed by a zombie, turn player into a ragdoll and let em take control of a newly spawned ZED over the ragdoll.
	if( bRedeadMode && WorldInfo.NetMode!=NM_Client && damageType!=None && Killer!=None && Killer!=Controller && Killer.GetTeamNum()!=0 )
	{
		if ( bDeleteMe || WorldInfo.Game == None || WorldInfo.Game.bLevelChange )
			return FALSE;
		bPendingRedead = true;
		if ( WorldInfo.Game.PreventDeath(self, Killer, damageType, HitLocation) )
		{
			bPendingRedead = false;
			Health = max(Health, 1);
			return false;
		}
		Health = 0;
		foreach LatentActions(Action)
			Action.AbortFor(self);
		if ( Controller != None )
			WorldInfo.Game.Killed(Killer, Controller, self, damageType);
		else WorldInfo.Game.Killed(Killer, Controller(Owner), self, damageType);
		
		if ( InvManager != None )
			InvManager.OwnerDied();
		
		Health = 1;
		if( !bFeigningDeath )
			PlayFeignDeath(true,,true);
		Health = 0;
		ClearTimer('UnsetFeignDeath');
		GoToState('TransformZed');
		return true;
	}
	return Super.Died(Killer, DamageType, HitLocation);
}
simulated function BroadcastDeathMessage( Controller Killer );

function SetBatteryRate( float Rate )
{
	BatteryDrainRate = Default.BatteryDrainRate*Rate;
	NVGBatteryDrainRate = Default.NVGBatteryDrainRate*Rate;
	ClientSetBatteryRate(Rate);
}
simulated reliable client function ClientSetBatteryRate( float Rate )
{
	BatteryDrainRate = Default.BatteryDrainRate*Rate;
	NVGBatteryDrainRate = Default.NVGBatteryDrainRate*Rate;
}

event bool HealDamage(int Amount, Controller Healer, class<DamageType> DamageType, optional bool bCanRepairArmor=true, optional bool bMessageHealer=true)
{
	local int DoshEarned,UsedHealAmount;
	local float ScAmount;
	local KFPlayerReplicationInfo InstigatorPRI;
	local ExtPlayerController InstigatorPC, KFPC;
	local KFPerk InstigatorPerk;
	local class<KFDamageType> KFDT;
    local int i;
    local bool bRepairedArmor;
	local ExtPlayerReplicationInfo EPRI;
	local Ext_PerkBase InstigatorExtPerk;

	InstigatorPC = ExtPlayerController(Healer);
	InstigatorPerk = InstigatorPC.GetPerk();
	
	if( InstigatorPerk != None && bCanRepairArmor )
		bRepairedArmor = InstigatorPC.GetPerk().RepairArmor( self );
	
	EPRI = ExtPlayerReplicationInfo(InstigatorPC.PlayerReplicationInfo);
	if( EPRI != none )
	{
		InstigatorExtPerk = ExtPlayerController(Controller).ActivePerkManager.CurrentPerk;
		if( InstigatorExtPerk != none && Ext_PerkFieldMedic(InstigatorExtPerk) != none )
		{
			if( Ext_PerkFieldMedic(InstigatorExtPerk).bHealingBoost )
				UpdateHealingSpeedBoostMod(InstigatorPC);

			if( Ext_PerkFieldMedic(InstigatorExtPerk).bHealingDamageBoost )
				UpdateHealingDamageBoostMod(InstigatorPC);

			if( Ext_PerkFieldMedic(InstigatorExtPerk).bHealingShield )
				UpdateHealingShieldMod(InstigatorPC);
		}
	}

    if( Amount > 0 && IsAliveAndWell() && Health < HealthMax )
    {
		// Play any healing effects attached to this damage type
		KFDT = class<KFDamageType>(DamageType);
		if( KFDT != none && KFDT.default.bNoPain )
			PlayHeal( KFDT );

    	if( Role == ROLE_Authority )
		{
			if( Healer==None || Healer.PlayerReplicationInfo == None )
				return false;

			InstigatorPRI = KFPlayerReplicationInfo(Healer.PlayerReplicationInfo);
			ScAmount = Amount;
			if( InstigatorPerk != none )
				InstigatorPerk.ModifyHealAmount( ScAmount );
			UsedHealAmount = ScAmount;

			// You can never have a HealthToRegen value that's greater than HealthMax
			if( Health + HealthToRegen + UsedHealAmount > HealthMax )
				UsedHealAmount = Min(HealthMax - (Health + HealthToRegen),255-HealthToRegen);
			else UsedHealAmount = Min(UsedHealAmount,255-HealthToRegen);

	    	HealthToRegen += UsedHealAmount;
			RepRegenHP = HealthToRegen;
			if( !IsTimerActive('GiveHealthOverTime') )
				SetTimer(HealthRegenRate, true, 'GiveHealthOverTime');

			// Give the healer money/XP for helping a teammate
		    if( Healer.Pawn != none && Healer.Pawn != self )
		    {
			    DoshEarned = ( UsedHealAmount / float(HealthMax) ) * HealerRewardScaler;
				if( InstigatorPRI!=None )
					InstigatorPRI.AddDosh(Max(DoshEarned, 0), true);
				if( InstigatorPC!=None )
					InstigatorPC.AddHealPoints( UsedHealAmount );
			}

			if( Healer.bIsPlayer )
			{
				if( Healer != Controller )
		    	{
					if( InstigatorPC!=None )
					{
						if( !InstigatorPC.bClientHideNumbers )
							InstigatorPC.ClientNumberMsg(UsedHealAmount,Location,DMG_Heal);
						InstigatorPC.ReceiveLocalizedMessage( class'KFLocalMessage_Game', GMT_HealedPlayer, PlayerReplicationInfo );
					}
					KFPC = ExtPlayerController(Controller);
					if( KFPC!=None )
						KFPC.ReceiveLocalizedMessage( class'KFLocalMessage_Game', GMT_HealedBy, Healer.PlayerReplicationInfo );
				}
				else if( bMessageHealer && InstigatorPC!=None )
					InstigatorPC.ReceiveLocalizedMessage( class'KFLocalMessage_Game', GMT_HealedSelf, PlayerReplicationInfo );
			}

			// don't play dialog for healing done through perk skills (e.g. berserker vampire skill)
			if( bMessageHealer )
			{
				`DialogManager.PlayHealingDialog( KFPawn(Healer.Pawn), self, float(Health + HealthToRegen) / float(HealthMax) );
			}

            // Reduce burn duration and damage in half if you heal while burning
            for( i = 0; i < DamageOverTimeArray.Length; ++i )
        	{
                if( DamageOverTimeArray[i].DoT_Type == DOT_Fire )
                {
                    DamageOverTimeArray[i].Duration *= 0.5;
                    DamageOverTimeArray[i].Damage *= 0.5;
                    break;
                }
        	}

		    return true;
		}
    }

	return bRepairedArmor;
}

function GiveHealthOverTime()
{
	Super.GiveHealthOverTime();
	RepRegenHP = HealthToRegen;
}

simulated event ReplicatedEvent(name VarName)
{
	switch( VarName )
	{
	case 'bFeigningDeath':
		PlayFeignDeath(bFeigningDeath);
		break;
	case 'BackpackWeaponClass':
		SetBackpackWeapon(BackpackWeaponClass);
		break;
	default:
		Super.ReplicatedEvent(VarName);
	}
}

// ==================================================================
// Feign death triggers:
function PlayHit(float Damage, Controller InstigatedBy, vector HitLocation, class<DamageType> damageType, vector Momentum, TraceHitInfo HitInfo)
{
	if( damageType!=class'DmgType_Fell' ) // Not from falling!
	{
		if( bRagdollFromMomentum && Damage>2 && VSizeSq(Momentum)>1000000.f && Rand(3)==0 ) // Square(1000)
			SetFeignDeath(3.f+FRand()*2.5f); // Randomly knockout a player if hit by a huge force.
		else if( bRagdollFromBackhit && Damage>20 && VSizeSq(Momentum)>40000.f && (vector(Rotation) Dot Momentum)>0.f && Rand(4)==0 )
			SetFeignDeath(2.f+FRand()*3.f); // Randomly knockout a player if hit from behind.
	}
	Super.PlayHit(Damage,InstigatedBy,HitLocation,damageType,Momentum,HitInfo);
}
event Landed(vector HitNormal, actor FloorActor)
{
	local float ExcessSpeed;

	Super.Landed(HitNormal, FloorActor);
	if( bRagdollFromFalling )
	{
		ExcessSpeed = Velocity.Z / (-MaxFallSpeed);
		if( ExcessSpeed>1.25 ) // Knockout a player after landed from too high.
		{
			Velocity.Z = 0; // Dont go clip through floor now...
			Velocity.X*=0.5;
			Velocity.Y*=0.5;
			SetFeignDeath((3.f+FRand())*ExcessSpeed);
		}
	}
	else if( BHopAccelSpeed>0 )
		SetTimer((IsLocallyControlled() ? 0.17 : 1.f),false,'ResetBHopAccel'); // Replicating from client to server here because Server Tickrate may screw clients over from executing bunny hopping.
}

// ==================================================================
// Bunny hopping:
function bool DoJump( bool bUpdating )
{
	local float V;

	if ( Super.DoJump(bUpdating) )
	{
		// Accelerate if bunnyhopping.
		if( bHasBunnyHop && VSizeSq2D(Velocity)>Square(GroundSpeed*0.75) )
		{
			if( BHopAccelSpeed<20 )
			{
				if( BHopAccelSpeed==0 )
					BHopSpeedMod = 1.f;

				if( BHopAccelSpeed<5 )
					V = 1.15;
				else
				{
					V = 1.05;
					AirControl = 0.8;
				}
				BHopSpeedMod *= V;
				GroundSpeed *= V;
				SprintSpeed *= V;
				Velocity.X *= V;
				Velocity.Y *= V;
				++BHopAccelSpeed;
			}
			ClearTimer('ResetBHopAccel');
		}
		return true;
	}
	return false;
}
simulated function ResetBHopAccel( optional bool bSkipRep ) // Set on Landed, or Tick if falling 2D speed is too low.
{
	if( BHopAccelSpeed>0 )
	{
		BHopAccelSpeed = 0;
		AirControl = Default.AirControl;
		GroundSpeed /= BHopSpeedMod;
		UpdateGroundSpeed();
		if( WorldInfo.NetMode==NM_Client && !bSkipRep )
			NotifyHasStopped();
	}
}
function UpdateGroundSpeed()
{
	local KFInventoryManager InvM;
	local float HealthMod;

	if ( Role < ROLE_Authority )
		return;

	InvM = KFInventoryManager(InvManager);
	HealthMod = (InvM != None) ? InvM.GetEncumbranceSpeedMod() : 1.f * (1.f - LowHealthSpeedPenalty);
	if( BHopAccelSpeed>0 )
		HealthMod *= BHopSpeedMod;

	// First reset to default so multipliers do not stack
	GroundSpeed = default.GroundSpeed * HealthMod;
	// reset sprint too, because perk may want to scale it
	SprintSpeed = default.SprintSpeed * HealthMod;

	// Ask our perk to set the new ground speed based on weapon type
	if( GetPerk() != none )
	{
		GetPerk().ModifySpeed(GroundSpeed);
		GetPerk().ModifySpeed(SprintSpeed);
	}
}

reliable server function NotifyHasStopped()
{
	ResetBHopAccel(true);
}

// ==================================================================
// Feign death (UT3):
simulated function Tick( float Delta )
{
	Super.Tick(Delta);
	if( bPlayingFeignDeathRecovery )
	{
		// interpolate Controller yaw to our yaw so that we don't get our rotation snapped around when we get out of feign death
		Mesh.PhysicsWeight = FMax(Mesh.PhysicsWeight-(Delta*2.f),0.f);
		if( Mesh.PhysicsWeight<=0 )
			StartFeignDeathRecoveryAnim();
	}
	if( BHopAccelSpeed>0 )
	{
		if( Physics==PHYS_Falling && VSizeSq2D(Velocity)<Square(GroundSpeed*0.7) )
			ResetBHopAccel(true);
	}
	if( WorldInfo.NetMode!=NM_Client && BackpackWeaponClass!=none && (PlayerOldWeapon==None || PlayerOldWeapon.Instigator==None) )
	{
		PlayerOldWeapon = None;
		SetBackpackWeapon(None);
	}
}

function DelayedRagdoll()
{
	SetFeignDeath(2.f+FRand()*3.f);
}
exec function FeignDeath( float Time )
{
	SetFeignDeath(Time);
}
function SetFeignDeath( float Time )
{
	if( WorldInfo.NetMode!=NM_Client && !bFeigningDeath && Health>0 && bCanBecomeRagdoll && NoRagdollChance<1.f && (NoRagdollChance==0.f || FRand()>NoRagdollChance) )
	{
		Time = FMax(1.f,Time);
		PlayFeignDeath(true);
		SetTimer(Time,false,'UnsetFeignDeath');
	}
}
function UnsetFeignDeath()
{
	if( bFeigningDeath )
		PlayFeignDeath(false);
}

simulated function PlayFeignDeath( bool bEnable, optional bool bForce, optional bool bTransformMode )
{
	local vector FeignLocation, HitLocation, HitNormal, TraceEnd, Impulse;
	local rotator NewRotation;
	local float UnFeignZAdjust;

	if( Health<=0 && WorldInfo.NetMode!=NM_Client )
		return; // If dead, don't do it.

	NotifyOutOfBattery(); // Stop nightvision on client.

	bFeigningDeath = bEnable;
	if ( bEnable )
	{
		if( bFPLegsAttached )
		{
			bFPLegsAttached = false;
			DetachComponent(FPBodyMesh);
		}
		WeaponAttachmentTemplate = None;
		WeaponAttachmentChanged();
		
		bPlayingFeignDeathRecovery = false;
		ClearTimer('OnWakeUpFinished');
		if( !bTransformMode )
			GotoState('FeigningDeath');

		// if we had some other rigid body thing going on, cancel it
		if (Physics == PHYS_RigidBody)
		{
			//@note: Falling instead of None so Velocity/Acceleration don't get cleared
			setPhysics(PHYS_Falling);
		}

		PrepareRagdoll();

		SetPawnRBChannels(TRUE);
		Mesh.ForceSkelUpdate();

		// Move into post so that we are hitting physics from last frame, rather than animated from this
		SetTickGroup(TG_PostAsyncWork);
		
		// Turn collision on for skelmeshcomp and off for cylinder
		CylinderComponent.SetActorCollision(false, false);
		Mesh.SetActorCollision(true, true);
		Mesh.SetTraceBlocking(true, true);

		Mesh.SetHasPhysicsAssetInstance(false);
		
		if( !InitRagdoll() ) // Ragdoll error!
		{
			if( PlayerController(Controller)!=None )
				PlayerController(Controller).ClientMessage("Error: InitRagdoll() failed!");
			return;
		}
		
		// Ensure we are always updating kinematic
		Mesh.MinDistFactorForKinematicUpdate = 0.0;

		Mesh.bUpdateKinematicBonesFromAnimation=FALSE;

		// Set all kinematic bodies to the current root velocity, since they may not have been updated during normal animation
		// and therefore have zero derived velocity (this happens in 1st person camera mode).
		UnFeignZAdjust = VSize(Velocity);
		if( UnFeignZAdjust>700.f ) // Limit by a maximum velocity force to prevent from going through walls.
			Mesh.SetRBLinearVelocity((Velocity/UnFeignZAdjust)*700.f, false);
		else Mesh.SetRBLinearVelocity(Velocity, false);

		// reset mesh translation since adjustment code isn't executed on the server
		// but the ragdoll code uses the translation so we need them to match up for the
		// most accurate simulation
		Mesh.SetTranslation(vect(0,0,1) * BaseTranslationOffset);
		// we'll use the rigid body collision to check for falling damage
		Mesh.ScriptRigidBodyCollisionThreshold = MaxFallSpeed;
		Mesh.SetNotifyRigidBodyCollision(true);
	}
	else
	{
		// fit cylinder collision into location, crouching if necessary
		FeignLocation = Location;
		CollisionComponent = CylinderComponent;
		TraceEnd = Location + vect(0,0,1) * GetCollisionHeight();
		if (Trace(HitLocation, HitNormal, TraceEnd, Location, true, GetCollisionExtent()) == None )
		{
			HitLocation = TraceEnd;
		}
		if ( !SetFeignEndLocation(HitLocation, FeignLocation) && WorldInfo.NetMode!=NM_Client )
		{
			UnfeignFailedCount++;
			if ( UnFeignfailedCount > 4 || bForce )
			{
				SetLocation(PickNearestNode()); // Just teleport to nearest pathnode.
			}
			else
			{
				CollisionComponent = Mesh;
				SetLocation(FeignLocation);
				bFeigningDeath = true;
				Impulse = VRand();
				Impulse.Z = 0.5;
				Mesh.AddImpulse(800.0*Impulse, Location);
				SetTimer(1.f,false,'UnsetFeignDeath');
				return;
			}
		}
		
		PreRagdollCollisionComponent = None;

		// Calculate how far we just moved the actor up.
		UnFeignZAdjust = Location.Z - FeignLocation.Z;
		// If its positive, move back down by that amount until it hits the floor
		if(UnFeignZAdjust > 0.0)
		{
			moveSmooth(vect(0,0,-1) * UnFeignZAdjust);
		}

		UnfeignFailedCount = 0;

		bPlayingFeignDeathRecovery = true;
		
		// Reset collision.
		Mesh.SetActorCollision(true, false);
		Mesh.SetTraceBlocking(true, false);

		SetTickGroup(TG_PreAsyncWork);

		// don't need collision events anymore
		Mesh.SetNotifyRigidBodyCollision(false);

		// don't allow player to move while animation is in progress
		SetPhysics(PHYS_None);

		// physics weight interpolated to 0 in C++, then StartFeignDeathRecoveryAnim() is called
		Mesh.PhysicsWeight = 1.0;
		
		// force rotation to match the body's direction so the blend to the getup animation looks more natural
		NewRotation = Rotation;
		NewRotation.Yaw = rotator(Mesh.GetBoneAxis(HeadBoneName, AXIS_X)).Yaw;
		// flip it around if the head is facing upwards, since the animation for that makes the character
		// end up facing in the opposite direction that its body is pointing on the ground
		// FIXME: generalize this somehow (stick it in the AnimNode, I guess...)
		if (Mesh.GetBoneAxis(HeadBoneName, AXIS_Y).Z < 0.0)
		{
			NewRotation.Yaw += 32768;
			FeignRecoverAnim = 'Getup_B_V1';
		}
		else FeignRecoverAnim = 'Getup_F_V1';
		
		// Init wakeup anim.
		if( Mesh.AnimSets.Find(WakeUpAnimSet)==-1 )
			Mesh.AnimSets.AddItem(WakeUpAnimSet);
		BodyStanceNodes[EAS_FullBody].bNoNotifies = true;
		BodyStanceNodes[EAS_FullBody].PlayCustomAnim(FeignRecoverAnim,0.025f,,,,true);
		
		SetRotation(NewRotation);
	}
}
final function vector PickNearestNode()
{
	local NavigationPoint N,Best;
	local float Dist,BestDist;
	
	foreach WorldInfo.AllNavigationPoints(class'NavigationPoint',N)
	{
		Dist = VSizeSq(N.Location-Location);
		if( Best==None || Dist<BestDist )
		{
			Best = N;
			BestDist = Dist;
		}
	}
	return (Best!=None ? Best.Location : Location);
}
simulated function bool SetFeignEndLocation(vector HitLocation, vector FeignLocation)
{
	local vector NewDest;

	if ( SetLocation(HitLocation) && CheckValidLocation(FeignLocation) )
	{
		return true;
	}

	// try crouching
	ForceCrouch();
	if ( SetLocation(HitLocation) && CheckValidLocation(FeignLocation) )
	{
		return true;
	}

	newdest = HitLocation + GetCollisionRadius() * vect(1,1,0);
	if ( SetLocation(newdest) && CheckValidLocation(FeignLocation) )
		return true;
	newdest = HitLocation + GetCollisionRadius() * vect(1,-1,0);
	if ( SetLocation(newdest) && CheckValidLocation(FeignLocation) )
		return true;
	newdest = HitLocation + GetCollisionRadius() * vect(-1,1,0);
	if ( SetLocation(newdest) && CheckValidLocation(FeignLocation) )
		return true;
	newdest = HitLocation + GetCollisionRadius() * vect(-1,-1,0);
	if ( SetLocation(newdest) && CheckValidLocation(FeignLocation) )
		return true;

	return false;
}
simulated function bool CheckValidLocation(vector FeignLocation)
{
	local vector HitLocation, HitNormal, DestFinalZ;

	// try trace down to dest
	if (Trace(HitLocation, HitNormal, Location, FeignLocation, false, vect(10,10,10),, TRACEFLAG_Bullet) == None)
	{
		return true;
	}

	// try trace straight up, then sideways to final location
	DestFinalZ = FeignLocation;
	FeignLocation.Z = Location.Z;
	if ( Trace(HitLocation, HitNormal, DestFinalZ, FeignLocation, false, vect(10,10,10)) == None &&
		Trace(HitLocation, HitNormal, Location, DestFinalZ, false, vect(10,10,10),, TRACEFLAG_Bullet) == None )
	{
		return true;
	}
	return false;
}
simulated function SetPawnRBChannels(bool bRagdollMode)
{
	if(bRagdollMode)
	{
		Mesh.SetRBChannel(RBCC_DeadPawn);
		Mesh.SetRBCollidesWithChannel(RBCC_Default,TRUE);
		Mesh.SetRBCollidesWithChannel(RBCC_Pawn,FALSE);
		Mesh.SetRBCollidesWithChannel(RBCC_Vehicle,TRUE);
		Mesh.SetRBCollidesWithChannel(RBCC_Untitled3,FALSE);
		Mesh.SetRBCollidesWithChannel(RBCC_BlockingVolume,TRUE);
		Mesh.SetRBCollidesWithChannel(RBCC_DeadPawn, false);
	}
	else
	{
		Mesh.SetRBChannel(RBCC_Pawn);
		Mesh.SetRBCollidesWithChannel(RBCC_Default,FALSE);
		Mesh.SetRBCollidesWithChannel(RBCC_Pawn,FALSE);
		Mesh.SetRBCollidesWithChannel(RBCC_Vehicle,FALSE);
		Mesh.SetRBCollidesWithChannel(RBCC_Untitled3,TRUE);
		Mesh.SetRBCollidesWithChannel(RBCC_BlockingVolume,FALSE);
	}
}
simulated function PlayRagdollDeath(class<DamageType> DamageType, vector HitLoc)
{
	local TraceHitInfo HitInfo;
	local vector HitDirection;

	Mesh.SetHasPhysicsAssetInstance(false);
	Mesh.SetHasPhysicsAssetInstance(true);
	if( bFPLegsAttached )
	{
		bFPLegsAttached = false;
		DetachComponent(FPBodyMesh);
	}
	
	// Ensure we are always updating kinematic
	Mesh.MinDistFactorForKinematicUpdate = 0.0;

	PrepareRagdoll();

	if ( InitRagdoll() )
	{
		// Switch to a good RigidBody TickGroup to fix projectiles passing through the mesh
		// https://udn.unrealengine.com/questions/190581/projectile-touch-not-called.html
		//Mesh.SetTickGroup(TG_PostAsyncWork);
		SetTickGroup(TG_PostAsyncWork);

		// Allow all ragdoll bodies to collide with all physics objects (ie allow collision with things marked RigidBodyIgnorePawns)
		SetPawnRBChannels(true);

		// Call CheckHitInfo to give us a valid BoneName
		HitDirection = Normal(TearOffMomentum);
    	CheckHitInfo(HitInfo, Mesh, HitDirection, HitLoc);

		// Play ragdoll death animation (bSkipReplication=TRUE)
		if( CanDoSpecialMove(SM_DeathAnim) && ClassIsChildOf(DamageType, class'KFDamageType') )
		{
			DoSpecialMove(SM_DeathAnim, TRUE,,,TRUE);
			KFSM_DeathAnim(SpecialMoves[SM_DeathAnim]).PlayDeathAnimation(DamageType, HitDirection, HitInfo.BoneName);
		}
		else
		{
			StopAllAnimations(); // stops non-RBbones from animating (fingers)
		}
	}
}
simulated function StartFeignDeathRecoveryAnim()
{
	if( FPBodyMesh!=None && !bFPLegsAttached && bOnFirstPerson && Class'ExtPlayerController'.Default.bShowFPLegs )
	{
		bFPLegsAttached = true;
		AttachComponent(FPBodyMesh);
	}

	bPlayingFeignDeathRecovery = false;

	// we're done with the ragdoll, so get rid of it
	Mesh.PhysicsWeight = 0.f;
	Mesh.PhysicsAssetInstance.SetAllBodiesFixed(TRUE);
	Mesh.PhysicsAssetInstance.SetFullAnimWeightBonesFixed(FALSE, Mesh);
	SetPawnRBChannels(FALSE);
	Mesh.bUpdateKinematicBonesFromAnimation=TRUE;

	// Turn collision on for cylinder and off for skelmeshcomp
	CylinderComponent.SetActorCollision(true, true);

	BodyStanceNodes[EAS_FullBody].PlayCustomAnim(FeignRecoverAnim,1.2f,,,,true);
	SetTimer(1.7f,false,'OnWakeUpFinished');
}

function bool CanBeRedeemed()
{
	return true;
}

simulated function OnWakeUpFinished();

function AddDefaultInventory()
{
    local KFPerk MyPerk;

    MyPerk = GetPerk();
	if( MyPerk != none )
        MyPerk.AddDefaultInventory(self);

	Super(KFPawn).AddDefaultInventory();
}

simulated event FellOutOfWorld(class<DamageType> dmgType)
{
	if ( Role==ROLE_Authority && NextRedeemTimer<WorldInfo.TimeSeconds ) // Make sure to not to spam deathmessages while ghosting.
		Super.FellOutOfWorld(dmgType);
}
simulated event OutsideWorldBounds()
{
	if ( Role==ROLE_Authority && NextRedeemTimer<WorldInfo.TimeSeconds )
		Super.OutsideWorldBounds();
}

simulated function KFCharacterInfoBase GetCharacterInfo()
{
	if( ExtPlayerReplicationInfo(PlayerReplicationInfo)!=None )
		return ExtPlayerReplicationInfo(PlayerReplicationInfo).GetSelectedArch();
	return Super.GetCharacterInfo();
}

simulated function SetCharacterArch(KFCharacterInfoBase Info, optional bool bForce )
{
	local KFPlayerReplicationInfo KFPRI;

    KFPRI = KFPlayerReplicationInfo( PlayerReplicationInfo );
	if (Info != CharacterArch || bForce)
	{
		// Set Family Info
		CharacterArch = Info;
		CharacterArch.SetCharacterFromArch( self, KFPRI );
		class'ExtCharacterInfo'.Static.SetCharacterMeshFromArch( KFCharacterInfo_Human(CharacterArch), self, KFPRI );
		class'ExtCharacterInfo'.Static.SetFirstPersonArmsFromArch( KFCharacterInfo_Human(CharacterArch), self, KFPRI );

		SetCharacterAnimationInfo();

		// Sounds
		SoundGroupArch = Info.SoundGroupArch;

		if (WorldInfo.NetMode != NM_DedicatedServer)
		{
			// refresh weapon attachment (attachment bone may have changed)
			if (WeaponAttachmentTemplate != None)
			{
				WeaponAttachmentChanged(true);
			}
		}
		if( WorldInfo.NetMode != NM_DedicatedServer )
		{
			// Attach/Reattach flashlight components when mesh is set
			if ( Flashlight == None && FlashLightTemplate != None )
			{
				Flashlight = new(self) Class'KFFlashlightAttachment' (FlashLightTemplate);
			}
			if ( FlashLight != None )
			{
				Flashlight.AttachFlashlight(Mesh);
			}
		}
		if( CharacterArch != none )
		{
			if( CharacterArch.VoiceGroupArchName != "" )
				VoiceGroupArch = class<KFPawnVoiceGroup>(class'ExtCharacterInfo'.Static.SafeLoadObject(CharacterArch.VoiceGroupArchName, class'Class'));
		}
	}
}

simulated state FeigningDeath
{
ignores FaceRotation, SetMovementPhysics;

	function SetSprinting(bool bNewSprintStatus)
	{
		bIsSprinting = false;
	}
	simulated event RigidBodyCollision( PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent, const out CollisionImpactData RigidCollisionData, int ContactIndex )
	{
		// only check fall damage for Z axis collisions
		if (Abs(RigidCollisionData.ContactInfos[0].ContactNormal.Z) > 0.5)
		{
			Velocity = Mesh.GetRootBodyInstance().PreviousVelocity;
			TakeFallingDamage();
			// zero out the z velocity on the body now so that we don't get stacked collisions
			Velocity.Z = 0.0;
			Mesh.SetRBLinearVelocity(Velocity, false);
			Mesh.GetRootBodyInstance().PreviousVelocity = Velocity;
			Mesh.GetRootBodyInstance().Velocity = Velocity;
		}
	}
	simulated event bool CanDoSpecialMove(ESpecialMove AMove, optional bool bForceCheck)
	{
		return (bForceCheck ? Global.CanDoSpecialMove(AMove,bForceCheck) : false);
	}
	function bool CanBeGrabbed(KFPawn GrabbingPawn, optional bool bIgnoreFalling, optional bool bAllowSameTeamGrab)
	{
		return false;
	}
	simulated function OnWakeUpFinished()
	{
		if (Physics == PHYS_RigidBody)
			setPhysics(PHYS_Falling);
		Mesh.MinDistFactorForKinematicUpdate = default.Mesh.MinDistFactorForKinematicUpdate;
		GotoState('Auto');
	}

	event bool EncroachingOn(Actor Other)
	{
		// don't abort moves in ragdoll
		return false;
	}

	simulated function bool CanThrowWeapon()
	{
		return false;
	}

	simulated function Tick(float DeltaTime)
	{
		local rotator NewRotation;

		if( bPlayingFeignDeathRecovery )
		{
			if( PlayerController(Controller) != None )
			{
				// interpolate Controller yaw to our yaw so that we don't get our rotation snapped around when we get out of feign death
				NewRotation = Controller.Rotation;
				NewRotation.Yaw = RInterpTo(NewRotation, Rotation, DeltaTime, 2.0).Yaw;
				Controller.SetRotation(NewRotation);
			}
			Mesh.PhysicsWeight = FMax(Mesh.PhysicsWeight-(DeltaTime*2.f),0.f);
			if( Mesh.PhysicsWeight<=0 )
				StartFeignDeathRecoveryAnim();
		}
	}

	simulated event BeginState(name PreviousStateName)
	{
		local KFWeapon UTWeap;

		// Abort current special move
		if( IsDoingSpecialMove() )
			SpecialMoveHandler.EndSpecialMove();

		bCanPickupInventory = false;
		StopFiring();
		bNoWeaponFiring = true;

		UTWeap = KFWeapon(Weapon);
		if (UTWeap != None)
		{
			UTWeap.SetIronSights(false);
			UTWeap.PlayWeaponPutDown(0.5f);
		}
		if( WorldInfo.NetMode!=NM_Client )
		{
			if( ExtPlayerController(Controller)!=None )
				ExtPlayerController(Controller).EnterRagdollMode(true);
			else if( Controller!=None )
				Controller.ReplicatedEvent('RagdollMove');
		}
	}
	simulated function WeaponAttachmentChanged(optional bool bForceReattach)
	{
		// Keep weapon hidden!
		if (WeaponAttachment != None)
		{
			WeaponAttachment.DetachFrom(self);
			WeaponAttachment.Destroy();
			WeaponAttachment = None;
		}
	}
	function bool CanBeRedeemed()
	{
		if( bFeigningDeath )
			PlayFeignDeath(false,true);
		NextRedeemTimer = WorldInfo.TimeSeconds+0.25;
		return false;
	}
	simulated function EndState(name NextStateName)
	{
		local KFWeapon UTWeap;

		Mesh.AnimSets.RemoveItem(WakeUpAnimSet);
		BodyStanceNodes[EAS_FullBody].bNoNotifies = false;
		if (NextStateName != 'Dying' )
		{
			bNoWeaponFiring = default.bNoWeaponFiring;
			bCanPickupInventory = default.bCanPickupInventory;
			
			UTWeap = KFWeapon(Weapon);
			if ( UTWeap != None )
			{
				WeaponAttachmentTemplate = UTWeap.AttachmentArchetype;
				UTWeap.PlayWeaponEquip(0.5f);
			}

			Global.SetMovementPhysics();
			bPlayingFeignDeathRecovery = false;
			if( WorldInfo.NetMode!=NM_Client )
			{
				if( ExtPlayerController(Controller)!=None )
					ExtPlayerController(Controller).EnterRagdollMode(false);
				else if( Controller!=None )
					Controller.ReplicatedEvent('EndRagdollMove');
			}
			
			Global.WeaponAttachmentChanged();
		}
	}
}

// VS mode.
state TransformZed extends FeigningDeath
{
Ignores FaceRotation, SetMovementPhysics, UnsetFeignDeath, Tick, TakeDamage, Died;

	simulated event BeginState(name PreviousStateName)
	{
		bCanPickupInventory = false;
		bNoWeaponFiring = true;
		if( ExtPlayerController(Controller)!=None )
			ExtPlayerController(Controller).EnterRagdollMode(true);
		else if( Controller!=None )
			Controller.ReplicatedEvent('RagdollMove');

		SetTimer(2,false,'TransformToZed');
	}
	simulated function EndState(name NextStateName)
	{
	}
	function bool CanBeRedeemed()
	{
		return false;
	}
	function TransformToZed()
	{
		local VS_ZedRecentZed Z;

		if( Controller==None )
		{
			Destroy();
			return;
		}
		PlayFeignDeath(false);
		SetCollision(false,false);
		Z = Spawn(class'VS_ZedRecentZed',,,Location,Rotation,,true);
		if( Z==None )
		{
			Super.Died(None,Class'DamageType',Location);
			return;
		}
		else
		{
			Z.SetPhysics(PHYS_Falling);
			Z.LastStartTime = WorldInfo.TimeSeconds;
			Controller.Pawn = None;
			Controller.Possess(Z,false);
			WorldInfo.Game.ChangeTeam(Controller,255,true);
			WorldInfo.Game.SetPlayerDefaults(Z);
			if( ExtPlayerController(Controller)!=None )
				Controller.GoToState('RagdollMove');
			else if( Controller!=None )
				Controller.ReplicatedEvent('RagdollMove');
			Z.WakeUp();
			if( ExtPlayerReplicationInfo(Controller.PlayerReplicationInfo)!=None )
			{
				ExtPlayerReplicationInfo(Controller.PlayerReplicationInfo).PlayerHealth = Min(Z.Health,255);
				ExtPlayerReplicationInfo(Controller.PlayerReplicationInfo).PlayerHealthPercent = FloatToByte( float(Z.Health) / float(Z.HealthMax) );
			}
		}
		Controller = None;
		Destroy();
	}
}

simulated final function InitFPLegs()
{
	local int i;

	bFPLegsInit = true;
	
	FPBodyMesh.AnimSets = CharacterArch.AnimSets;
	FPBodyMesh.SetAnimTreeTemplate(CharacterArch.AnimTreeTemplate);
	FPBodyMesh.SetSkeletalMesh(Mesh.SkeletalMesh);
	
    FPBodyMesh.SetActorCollision(false, false);
	FPBodyMesh.SetNotifyRigidBodyCollision(false);
	FPBodyMesh.SetTraceBlocking(false, false);

	for( i=0; i<Mesh.Materials.length; i++ )
		FPBodyMesh.SetMaterial(i, Mesh.Materials[i]);

	FPBodyMesh.HideBoneByName('neck', PBO_None);
    FPBodyMesh.HideBoneByName('Spine2', PBO_None);
    FPBodyMesh.HideBoneByName('RightShoulder', PBO_None);
    FPBodyMesh.HideBoneByName('LeftShoulder', PBO_None);
}

// ForrestMarkX's third person backpack weapon and first person legs:
simulated function SetMeshVisibility(bool bVisible)
{
	Super.SetMeshVisibility(bVisible);

	if( Health>0 )
	{
		bOnFirstPerson = !bVisible;
		if( AttachedBackItem!=None )
			AttachedBackItem.SetHidden(bOnFirstPerson);
		UpdateFPLegs();
	}
}

simulated final function UpdateFPLegs()
{
	if( FPBodyMesh!=None )
	{
		if( !bFPLegsAttached && Physics!=PHYS_RigidBody && bOnFirstPerson && Class'ExtPlayerController'.Default.bShowFPLegs )
		{
			bFPLegsAttached = true;
			AttachComponent(FPBodyMesh);
			
			if( !bFPLegsInit && CharacterArch!=None )
				InitFPLegs();
		}
		FPBodyMesh.SetHidden(!bOnFirstPerson || !Class'ExtPlayerController'.Default.bShowFPLegs);
	}
}

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	if( SkelComp==Mesh ) // Do not allow first person legs eat up animation slots.
		Super.PostInitAnimTree(SkelComp);
}

simulated final function SetBackpackWeapon( class<KFWeapon> WC )
{
	local KFCharacterInfo_Human MyCharacter;
	local Rotator MyRot;
	local Vector MyPos;
	local name WM,B;
	local int i;

	BackpackWeaponClass = WC;
	if( WorldInfo.NetMode==NM_DedicatedServer )
		return;

	if( WC!=None )
	{
		if( AttachedBackItem==None )
		{
			AttachedBackItem = new(Self) class'SkeletalMeshComponent';
			AttachedBackItem.SetHidden(false);
			AttachedBackItem.SetLightingChannels(PawnLightingChannel);
		}
		AttachedBackItem.SetSkeletalMesh(WC.Default.AttachmentArchetype.SkelMesh);
		for( i=0; i<WC.Default.AttachmentArchetype.SkelMesh.Materials.length; i++ )
		{
			AttachedBackItem.SetMaterial(i, WC.Default.AttachmentArchetype.SkelMesh.Materials[i]);
		}
		
		Mesh.DetachComponent(AttachedBackItem);
		
		MyCharacter = KFPlayerReplicationInfo(PlayerReplicationInfo).CharacterArchetypes[KFPlayerReplicationInfo(PlayerReplicationInfo).RepCustomizationInfo.CharacterIndex];
		WM = WC.Default.AttachmentArchetype.SkelMesh.Name;
		
		if( ClassIsChildOf(WC, class'KFWeap_Edged_Knife') )
		{
			MyPos = vect(0,0,10);
			MyRot = rot(-16384,-8192,0);
			B = 'LeftUpLeg';
		}
		else if( class<KFWeap_Welder>(WC) != none || class<KFWeap_Healer_Syringe>(WC) != none || class<KFWeap_Pistol_Medic>(WC) != none || class<KFWeap_SMG_Medic>(WC) != none || ClassIsChildOf(WC, class'KFWeap_PistolBase') || ClassIsChildOf(WC, class'KFWeap_SMGBase') || ClassIsChildOf(WC, class'KFWeap_ThrownBase') )
		{
			MyPos = vect(0,0,10);
			MyRot = rot(0,0,16384);

			B = 'LeftUpLeg';
		}
		else if( ClassIsChildOf(WC, class'KFWeap_MeleeBase') )
		{
			MyPos = vect(-5,15,0);
			MyRot = rot(0,0,0);
			
			if( class<KFWeap_Edged_Katana>(WC) != none || class<KFWeap_Edged_Zweihander>(WC) != none )
				MyPos.Z = -20;
				
			B = 'Spine';
		}
		else
		{
			MyPos = vect(-18.5,16.5,-18);
			MyRot = rot(0,0,0);

			if( MyCharacter == KFCharacterInfo_Human'CHR_Playable_ARCH.chr_DJSkully_archetype' )
				MyRot.Roll = 8192;
				
			switch( WM )
			{
			case 'Wep_3rdP_MB500_Rig':
				MyPos.X = -45;
				break;
			case 'Wep_3rdP_M4Shotgun_Rig':
				MyPos.X = -25;
				break;
			case 'Wep_3rdP_SawBlade_Rig':
				MyPos.X = -75;
				MyRot.Roll = 16384;
				break;
			case 'Wep_3rdP_RPG7_Rig':
				MyPos.X = 10;
				break;
			}
			
			B = 'Spine2';
		}

		AttachedBackItem.SetTranslation(MyPos);
		AttachedBackItem.SetRotation(MyRot);
		Mesh.AttachComponent(AttachedBackItem, B);
		AttachedBackItem.SetHidden(bOnFirstPerson);
	}
	else if( AttachedBackItem!=None )
		AttachedBackItem.SetHidden(true);
}

simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	FPBodyMesh.SetHidden(true);
	if( AttachedBackItem!=None )
		AttachedBackItem.SetHidden(true);
	Super.PlayDying(DamageType,HitLoc);
}

simulated function SetCharacterAnimationInfo()
{
	Super.SetCharacterAnimationInfo();

	if( !bFPLegsInit && bFPLegsAttached )
		InitFPLegs();
}

simulated function SetMeshLightingChannels(LightingChannelContainer NewLightingChannels)
{
    Super.SetMeshLightingChannels(NewLightingChannels);

	if (AttachedBackItem != none)
        AttachedBackItem.SetLightingChannels(NewLightingChannels);
	FPBodyMesh.SetLightingChannels(NewLightingChannels);
}

simulated function PlayWeaponSwitch(Weapon OldWeapon, Weapon NewWeapon)
{
    Super.PlayWeaponSwitch(OldWeapon, NewWeapon);

	if( WorldInfo.NetMode!=NM_Client )
	{
		PlayerOldWeapon = KFWeapon(OldWeapon);
		SetBackpackWeapon(PlayerOldWeapon!=None ? PlayerOldWeapon.Class : None);
	}
}

simulated function UpdateHealingSpeedBoostMod(ExtPlayerController Healer)
{
	local Ext_PerkFieldMedic MedPerk;
	
	MedPerk = GetMedicPerk(Healer);
	if( MedPerk == None )
		return;
	
	HealingSpeedBoostMod = Min( HealingSpeedBoostMod + MedPerk.GetHealingSpeedBoost(), MedPerk.GetMaxHealingSpeedBoost() );
	SetTimer( MedPerk.GetHealingSpeedBoostDuration(),, nameOf(ResetHealingSpeedBoost) );
	
	UpdateGroundSpeed();
}

simulated function float GetHealingSpeedModifier()
{
	return 1 + (float(HealingSpeedBoostMod) / 100);
}

simulated function ResetHealingSpeedBoost()
{
	HealingSpeedBoostMod = 0;
	UpdateGroundSpeed();

	if( IsTimerActive( nameOf( ResetHealingSpeedBoost ) ) )
		ClearTimer( nameOf( ResetHealingSpeedBoost ) );
}

simulated function UpdateHealingDamageBoostMod(ExtPlayerController Healer)
{
	local Ext_PerkFieldMedic MedPerk;
	
	MedPerk = GetMedicPerk(Healer);
	if( MedPerk == None )
		return;
		
	HealingDamageBoostMod = Min( HealingDamageBoostMod + MedPerk.GetHealingDamageBoost(), MedPerk.GetMaxHealingDamageBoost() );
	SetTimer( MedPerk.GetHealingDamageBoostDuration(),, nameOf(ResetHealingDamageBoost) );
}

simulated function float GetHealingDamageBoostModifier()
{
	return 1 + (float(HealingDamageBoostMod) / 100);
}

simulated function ResetHealingDamageBoost()
{
	HealingDamageBoostMod = 0;
	if( IsTimerActive( nameOf( ResetHealingDamageBoost ) ) )
		ClearTimer( nameOf( ResetHealingDamageBoost ) );
}

simulated function UpdateHealingShieldMod(ExtPlayerController Healer)
{
	local Ext_PerkFieldMedic MedPerk;
	
	MedPerk = GetMedicPerk(Healer);
	if( MedPerk == None )
		return;
		
	HealingShieldMod = Min( HealingShieldMod + MedPerk.GetHealingShield(), MedPerk.GetMaxHealingShield() );
	SetTimer( MedPerk.GetHealingShieldDuration(),, nameOf(ResetHealingShield) );
}

simulated function float GetHealingShieldModifier()
{
	return 1 - (float(HealingShieldMod) / 100);
}

simulated function ResetHealingShield()
{
	HealingShieldMod = 0;
	if( IsTimerActive( nameOf( ResetHealingShield ) ) )
		ClearTimer( nameOf( ResetHealingShield ) );
}

function SacrificeExplode()
{
	local Ext_PerkDemolition DemoPerk;
	
	Super.SacrificeExplode();
	
	DemoPerk = Ext_PerkDemolition(ExtPlayerController(Controller).ActivePerkManager.CurrentPerk);
	if( DemoPerk != none )
		DemoPerk.bUsedSacrifice = true;
}

simulated function Ext_PerkFieldMedic GetMedicPerk(ExtPlayerController Healer)
{
	local Ext_PerkFieldMedic MedPerk;
	
	MedPerk = Ext_PerkFieldMedic(ExtPlayerController(Controller).ActivePerkManager.CurrentPerk);
	if( MedPerk != None ) 
		return MedPerk;
		
	return None;
}

defaultproperties
{
	KnockbackResist=1

	// Ragdoll mode:
	bReplicateRigidBodyLocation=true
	bCanBecomeRagdoll=true
	InventoryManagerClass=class'ExtInventoryManager'
	WakeUpAnimSet=AnimSet'ZED_Clot_Anim.Alpha_Clot_Master'
	
	Begin Object Name=SpecialMoveHandler_0
		SpecialMoveClasses(SM_Emote)=class'ServerExt.ExtSM_Player_Emote'
	End Object
	
	DefaultInventory.Empty()
	DefaultInventory.Add(class'ExtWeap_Pistol_9mm')
	DefaultInventory.Add(class'KFWeap_Healer_Syringe')
	DefaultInventory.Add(class'KFWeap_Welder')
	DefaultInventory.Add(class'KFInventory_Money')

	Begin Object Class=SkeletalMeshComponent Name=FP_BodyComp
		MinDistFactorForKinematicUpdate=0.0
		bSkipAllUpdateWhenPhysicsAsleep=True
		bIgnoreControllersWhenNotRendered=True
		bHasPhysicsAssetInstance=False
		bUpdateKinematicBonesFromAnimation=False
		bPerBoneMotionBlur=True
		bOverrideAttachmentOwnerVisibility=True
		bChartDistanceFactor=True
		DepthPriorityGroup=SDPG_Foreground
		RBChannel=RBCC_Pawn
		RBDominanceGroup=20
		HiddenGame=True
		bOnlyOwnerSee=True
		bAcceptsDynamicDecals=True
		bUseOnePassLightingOnTranslucency=True
		Translation=(X=-65.876999,Y=0.900000,Z=-95.500000)
		Scale=1.210000
		ScriptRigidBodyCollisionThreshold=200.000000
		PerObjectShadowCullDistance=4000.000000
		bAllowPerObjectShadows=True
		bAllowPerObjectShadowBatching=True
	End Object
	FPBodyMesh=FP_BodyComp
}