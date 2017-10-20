Class Ext_PerkCommando extends Ext_PerkBase;

simulated function bool GetUsingTactialReload( KFWeapon KFW )
{
	return (IsWeaponOnPerk(KFW) ? Modifiers[5]<0.65 : false);
}

defaultproperties
{
	PerkName="Commando"
	PerkIcon=Texture2D'UI_PerkIcons_TEX.UI_PerkIcon_Commando'
	DefTraitList.Add(class'Ext_TraitWPComm')
	DefTraitList.Add(class'Ext_TraitUnCloak')
	DefTraitList.Add(class'Ext_TraitEnemyHP')
	DefTraitList.Add(class'Ext_TraitEliteReload')
	BasePerk=class'KFPerk_Commando'

	PrimaryMelee=class'KFWeap_Knife_Commando'
	PrimaryWeapon=class'KFWeap_AssaultRifle_AR15'
	PerkGrenade=class'KFProj_HEGrenade'

	PrimaryWeaponDef=class'KFWeapDef_AR15'
	KnifeWeaponDef=class'KFweapDef_Knife_Commando'
	GrenadeWeaponDef=class'KFWeapDef_Grenade_Commando'
	
	AutoBuyLoadOutPath=(class'KFWeapDef_AR15', class'KFWeapDef_Bullpup', class'KFWeapDef_AK12', class'KFWeapDef_SCAR')
}