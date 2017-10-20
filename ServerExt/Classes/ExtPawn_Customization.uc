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

defaultproperties
{
	bCollideActors=false
	bBlockActors=false
}