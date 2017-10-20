Class Ext_PerkSupport extends Ext_PerkBase;

defaultproperties
{
	PerkName="Support"
	PerkIcon=Texture2D'UI_PerkIcons_TEX.UI_PerkIcon_Support'
	DefTraitList.Add(class'Ext_TraitWPSupp')
	DefTraitList.Add(class'Ext_TraitSupply')
	DefTraitList(0)=class'Ext_TraitGrenadeSUpg'
	BasePerk=class'KFPerk_Support'
	WeldExpUpNum=80

	DefPerkStats(0)=(MaxValue=20,CostPerValue=2)
	DefPerkStats(8)=(bHiddenConfig=false)

	PrimaryMelee=class'KFWeap_Knife_Support'
	PrimaryWeapon=class'KFWeap_Shotgun_MB500'
	
	PrimaryWeaponDef=class'KFWeapDef_MB500'
	KnifeWeaponDef=class'KFWeapDef_Knife_Support'
	GrenadeWeaponDef=class'KFWeapDef_Grenade_Support'
	
	AutoBuyLoadOutPath=(class'KFWeapDef_MB500', class'KFWeapDef_DoubleBarrel', class'KFWeapDef_M4', class'KFWeapDef_AA12')
}