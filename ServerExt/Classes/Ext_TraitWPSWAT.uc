Class Ext_TraitWPSWAT extends Ext_TraitWeapons;

defaultproperties
{
	TraitName="SWAT Weapon Loadout"
	Description="This will grant you SWAT weapon loadout to spawn with.|Level 1: MP5 RAS|Level 2: P90|Level 3: Kriss|Level 4: All 3"
	
	LevelEffects(0)=(LoadoutClasses=(class'KFWeap_SMG_MP5RAS'))
	LevelEffects(1)=(LoadoutClasses=(class'KFWeap_SMG_P90'))
	LevelEffects(2)=(LoadoutClasses=(class'KFWeap_SMG_Kriss'))
	LevelEffects(3)=(LoadoutClasses=(class'KFWeap_SMG_MP5RAS',class'KFWeap_SMG_P90',class'KFWeap_SMG_Kriss'))
}