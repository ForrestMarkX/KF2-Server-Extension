Class Ext_PerkSurvivalist extends Ext_PerkBase;

defaultproperties
{
	PerkName="Survivalist"
	PerkIcon=Texture2D'UI_PerkIcons_TEX.UI_PerkIcon_Survivalist'
	DefTraitList.Add(class'Ext_TraitWPSurv')
	//DefTraitList.Add(class'Ext_TraitHeavyArmor')
	BasePerk=class'KFPerk_Survivalist'

	PrimaryMelee=class'KFWeap_Random'
	PrimaryWeapon=class'KFWeap_Knife_Support'
	PerkGrenade=class'KFProj_HEGrenade'

	PrimaryWeaponDef=class'KFWeapDef_Random'
	KnifeWeaponDef=class'KFweapDef_Knife_Support'
	GrenadeWeaponDef=class'KFWeapDef_Grenade_Commando'

	AutoBuyLoadOutPath=(class'KFWeapDef_DragonsBreath', class'KFWeapDef_M16M203', class'KFWeapDef_MedicRifle')
}