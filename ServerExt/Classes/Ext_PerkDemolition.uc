Class Ext_PerkDemolition extends Ext_PerkBase;

defaultproperties
{
	PerkName="Demolitionist"
	PerkIcon=Texture2D'UI_PerkIcons_TEX.UI_PerkIcon_Demolition'
	DefTraitList.Add(class'Ext_TraitWPDemo')
	DefTraitList.Add(class'Ext_TraitBoomWeld')
	DefTraitList.Add(class'Ext_TraitContactNade')
	DefTraitList.Add(class'Ext_TraitSupplyGren')
	BasePerk=class'KFPerk_Demolitionist'

	PrimaryMelee=class'KFWeap_Knife_Demolitionist'
	PrimaryWeapon=class'KFWeap_GrenadeLauncher_HX25'
	PerkGrenade=class'KFProj_DynamiteGrenade'
	
	PrimaryWeaponDef=class'KFWeapDef_HX25'
	KnifeWeaponDef=class'KFWeapDef_Knife_Demo'
	GrenadeWeaponDef=class'KFWeapDef_Grenade_Demo'
	
	AutoBuyLoadOutPath=(class'KFWeapDef_HX25', class'KFWeapDef_M79', class'KFWeapDef_M16M203', class'KFWeapDef_RPG7')
	
	DefPerkStats(10)=(bHiddenConfig=true) // No support for mag size on demo.
	DefPerkStats(13)=(bHiddenConfig=false) // Self damage.
}