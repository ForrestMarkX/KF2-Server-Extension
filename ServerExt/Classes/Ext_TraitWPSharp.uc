Class Ext_TraitWPSharp extends Ext_TraitWeapons;

defaultproperties
{
	TraitName="Sharpshooter Weapon Loadout"
	Description="This will grant you sharpshooter weapon loadout to spawn with.|Level 1: Crossbow|Level 2: M14 EBR|Level 3: Railgun|Level 4: All 3"
	
	LevelEffects(0)=(LoadoutClasses=(class'KFWeap_Bow_Crossbow'))
	LevelEffects(1)=(LoadoutClasses=(class'KFWeap_Rifle_M14EBR'))
	LevelEffects(2)=(LoadoutClasses=(class'KFWeap_Rifle_RailGun'))
	LevelEffects(3)=(LoadoutClasses=(class'KFWeap_Bow_Crossbow',class'KFWeap_Rifle_M14EBR',class'KFWeap_Rifle_RailGun'))
}