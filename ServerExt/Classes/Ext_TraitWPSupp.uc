Class Ext_TraitWPSupp extends Ext_TraitWeapons;

defaultproperties
{
	TraitName="Support Weapon Loadout"
	Description="This will grant you support weapon loadout to spawn with.|Level 1: M4 Shotgun|Level 2: Boomstick|Level 3: AA12|Level 4: All 3"
	
	LevelEffects(0)=(LoadoutClasses=(class'KFWeap_Shotgun_M4'))
	LevelEffects(1)=(LoadoutClasses=(class'KFWeap_Shotgun_DoubleBarrel'))
	LevelEffects(2)=(LoadoutClasses=(class'KFWeap_Shotgun_AA12'))
	LevelEffects(3)=(LoadoutClasses=(class'KFWeap_Shotgun_M4',class'KFWeap_Shotgun_DoubleBarrel',class'KFWeap_Shotgun_AA12'))
}