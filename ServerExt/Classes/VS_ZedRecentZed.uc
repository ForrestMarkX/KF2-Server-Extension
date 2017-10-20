class VS_ZedRecentZed extends VS_ZedClotBase;

var repnotify bool bWasWoken;
var transient float WakeUpAnimTime;

replication
{
	if( true )
		bWasWoken;
}

simulated function float StartAttackAnim( byte Num ) // Return animation duration.
{
	if( FPHandModel!=None )
		FPHandModel.PlayHandsAnim('Atk_Combo1_V3',1.5f);
	return PlayBodyAnim('Atk_Combo1_V3',EAS_UpperBody,1.5f);
}

simulated event ReplicatedEvent(name VarName)
{
	switch( VarName )
	{
	case 'bWasWoken':
		if( bWasWoken )
			WakeUp();
		break;
	default:
		Super.ReplicatedEvent(VarName);
	}
}
simulated function WakeUp() // Just spawned from transformed into a zombie.
{
	bWasWoken = true;
	bNoWeaponFiring = true;
	WakeUpAnimTime = BodyStanceNodes[EAS_FullBody].PlayCustomAnim('Getup_Fast_F_V1',1.f);
	SetTimer(WakeUpAnimTime,false,'GotUp');
	GoToState('WakingUp');
}
simulated function GotUp()
{
	if( Health<=0 )
		return;
	ClearTimer('GotUp');
	bWasWoken = false;
	bNoWeaponFiring = false;
	if( WorldInfo.NetMode!=NM_Client )
	{
		if( ExtPlayerController(Controller)!=None )
			ExtPlayerController(Controller).EnterRagdollMode(false);
		else if( Controller!=None )
			Controller.ReplicatedEvent('EndRagdollMove');
	}
	GoToState('Auto');
}

state WakingUp
{
Ignores TakeDamage, FaceRotation;

	function UnPossessed()
	{
		Super.UnPossessed();
		
		ClearTimer('GotUp');
		KilledBy(None);
		LifeSpan = 2.f;
	}
}

simulated function NotifyTeamChanged()
{
	// Applies Character Info for < ROLE_Authority
	if( PlayerReplicationInfo != None )
		SetCharacterArch(GetCharacterInfo());
}

simulated function SetCharacterAnimationInfo()
{
	local KFCharacterInfo_Monster M;

	Super.SetCharacterAnimationInfo();

	// Keep monster animations.
	M = KFCharacterInfo_Monster'ZED_ARCH.ZED_Clot_UnDev_Archetype';
    Mesh.AnimSets = M.AnimSets;
	if ( Mesh.AnimTreeTemplate != M.AnimTreeTemplate )
		Mesh.SetAnimTreeTemplate(M.AnimTreeTemplate);
	if ( M.AnimArchetype != None )
		PawnAnimInfo = M.AnimArchetype;
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
	if (Info != CharacterArch)
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
		if( CharacterArch != none )
		{
			if( CharacterArch.VoiceGroupArchName != "" )
				VoiceGroupArch = class<KFPawnVoiceGroup>(class'ExtCharacterInfo'.Static.SafeLoadObject(CharacterArch.VoiceGroupArchName, class'Class'));
		}
	}
}

// Dont gore and gib because human chars don't support it.
simulated function HandlePartialGoreAndGibs(class<KFDamageType> DmgType,vector HitLocation,vector HitDirection,name HitBoneName,bool ObliterateGibs);
simulated function PlayHeadAsplode();
simulated function bool PlayDismemberment(int InHitZoneIndex, class<KFDamageType> InDmgType, optional vector HitDirection)
{
	return false;
}
event OnRigidBodyLinearConstraintViolated(name StretchedBoneName);
simulated function ApplyHeadChunkGore(class<KFDamageType> DmgType, vector HitLocation, vector HitDirection);

defaultproperties
{
	Health=300
	HealthMax=300
	ZombieName="Recently Infected"
	FPHandOffset=(X=-35,Z=-60)
	HitsPerAttack=1
	HPScaler=0.4

	MonsterArchPath="ZED_ARCH.ZED_Clot_UnDev_Archetype"
	CharacterMonsterArch=KFCharacterInfo_Monster'ZED_ARCH.ZED_Clot_UnDev_Archetype'
	GroundSpeed=700
	MeleeDamage=35
	
	// Stats
	XPValues(0)=11
	XPValues(1)=11
	XPValues(2)=11
	XPValues(3)=11
}