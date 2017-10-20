Class Ext_PerkGunslinger extends Ext_PerkRhythmPerkBase;

var bool bHasUberAmmo,bHasFanfire;

replication
{
	// Things the server should send to the client.
	if ( true )
		bHasUberAmmo,bHasFanfire;
}

simulated function bool GetUsingTactialReload( KFWeapon KFW )
{
	return (IsWeaponOnPerk(KFW) ? Modifiers[5]<0.8 : false);
}

simulated function bool GetIsUberAmmoActive( KFWeapon KFW )
{
	return bHasUberAmmo && IsWeaponOnPerk(KFW) && WorldInfo.TimeDilation < 1.f;
}

simulated function float GetZedTimeModifier( KFWeapon W )
{
	local name StateName;
	
	if( bHasFanfire && IsWeaponOnPerk( W ) )
	{
		StateName = W.GetStateName();
		if( BasePerk.Default.ZedTimeModifyingStates.Find( StateName ) != INDEX_NONE || StateName == 'Reloading' )
			return 1.f;
	}

	return 0.f;
}

defaultproperties
{
	PerkName="Gunslinger"
	DefTraitList.Add(class'Ext_TraitWPGuns')
	DefTraitList.Add(class'Ext_TraitUberAmmo')
	DefTraitList.Add(class'Ext_TraitFanfire')
	DefTraitList.Add(class'Ext_TraitRackEmUp')
	PerkIcon=Texture2D'UI_PerkIcons_TEX.UI_PerkIcon_Gunslinger'
	BasePerk=class'KFPerk_Gunslinger'

	PrimaryMelee=class'KFWeap_Knife_Gunslinger'
	PrimaryWeapon=class'KFWeap_Revolver_DualRem1858'
	PerkGrenade=class'KFProj_NailBombGrenade'
	
	PrimaryWeaponDef=class'KFWeapDef_Remington1858Dual'
	KnifeWeaponDef=class'KFWeapDef_Knife_Gunslinger'
	GrenadeWeaponDef=class'KFWeapDef_Grenade_Gunslinger'
	
	AutoBuyLoadOutPath=(class'KFWeapDef_Remington1858', class'KFWeapDef_Remington1858Dual', class'KFWeapDef_Colt1911', class'KFWeapDef_Colt1911Dual',class'KFWeapDef_Deagle', class'KFWeapDef_DeagleDual', class'KFWeapDef_SW500', class'KFWeapDef_SW500Dual')
}