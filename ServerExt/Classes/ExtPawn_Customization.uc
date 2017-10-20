class ExtPawn_Customization extends KFPawn_Customization;

simulated function KFCharacterInfoBase GetCharacterInfo()
{
	if( ExtPlayerReplicationInfo(PlayerReplicationInfo)!=None )
		return ExtPlayerReplicationInfo(PlayerReplicationInfo).GetSelectedArch();
	return Super.GetCharacterInfo();
}

simulated function SetCharacterArch( KFCharacterInfoBase Info, optional bool bForce )
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
	}

	if( CharacterArch != none )
	{
		if( CharacterArch.VoiceGroupArchName != "" )
			VoiceGroupArch = class<KFPawnVoiceGroup>(class'ExtCharacterInfo'.Static.SafeLoadObject(CharacterArch.VoiceGroupArchName, class'Class'));
	}
}

function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	// Destroy this pawn if player leaves.
	Destroy();
	return true;
}

simulated function PlayEmoteAnimation(optional bool bNewCharacter)
{
	local name AnimName;
	local float BlendInTime;

	AnimName = class'ExtEmoteList'.static.GetUnlockedEmote( class'ExtEmoteList'.static.GetEquippedEmoteId(ExtPlayerController(Controller)), ExtPlayerController(Controller) );	

	BlendInTime = (bNewCharacter) ? 0.f : 0.4;

	// Briefly turn off notify so that PlayCustomAnim won't call OnAnimEnd (e.g. character swap)
	BodyStanceNodes[EAS_FullBody].SetActorAnimEndNotification( FALSE );

	BodyStanceNodes[EAS_FullBody].PlayCustomAnim(AnimName, 1.f, BlendInTime, 0.4, false, true);
	BodyStanceNodes[EAS_FullBody].SetActorAnimEndNotification( TRUE );
}

function AttachWeaponByItemDefinition( int ItemDefinition )
{
	local class<KFWeaponDefinition> WeaponDef;
	local int ItemINdex;
	local KFWeaponAttachment WeaponPreview;

	//find weapon def
	ItemIndex = class'ExtWeaponSkinList'.default.Skins.Find('Id', ItemDefinition);

	if(ItemIndex ==  INDEX_NONE)
	{
		`log("Could not find item" @ItemDefinition);
		return;
	}

	WeaponDef = class'ExtWeaponSkinList'.default.Skins[ItemIndex].WeaponDef;

	if(WeaponDef == none)
	{
		`log("Weapon def NONE for : " @ItemDefinition);
		return;
	}

	//load in and add object .  
	WeaponPreview = KFWeaponAttachment ( DynamicLoadObject( WeaponDef.default.AttachmentArchtypePath, class'KFWeaponAttachment' ) );

	//attatch it to player
	WeaponAttachmentTemplate = WeaponPreview;

	WeaponAttachmentChanged();		

	//setweapon skin
	WeaponAttachment.SetWeaponSkin(ItemDefinition);
	
}

defaultproperties
{
	bCollideActors=false
	bBlockActors=false
}