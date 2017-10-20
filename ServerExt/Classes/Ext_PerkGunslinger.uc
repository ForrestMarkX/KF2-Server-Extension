Class Ext_PerkGunslinger extends Ext_PerkRhythmPerkBase;

var bool bHasUberAmmo,bHasFanfire;

replication
{
	// Things the server should send to the client.
	if ( true )
		bHasUberAmmo,bHasFanfire;
}

simulated function bool GetIsUberAmmoActive( KFWeapon KFW )
{
	return bHasUberAmmo && IsWeaponOnPerk(KFW) && WorldInfo.TimeDilation < 1.f;
}

simulated function float GetZedTimeModifier( KFWeapon W )
{
	if( bHasFanfire && WorldInfo.TimeDilation<1.f && IsWeaponOnPerk(W) && BasePerk.Default.ZedTimeModifyingStates.Find(W.GetStateName()) != INDEX_NONE )
		return 0.9f;
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