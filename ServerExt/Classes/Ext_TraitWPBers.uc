Class Ext_TraitWPBers extends Ext_TraitWeapons;

defaultproperties
{
	TraitName="Berserker Weapon Loadout"
	Description="This will grant you berserker weapon loadout to spawn with.|Level 1: Pulverizer|Level 2: Nailgun|Level 3: Sawblade Gun|Level 4: All 3"
	
	LevelEffects(0)=(LoadoutClasses=(class'KFWeap_Blunt_Pulverizer'))
	LevelEffects(1)=(LoadoutClasses=(class'KFWeap_Shotgun_Nailgun'))
	LevelEffects(2)=(LoadoutClasses=(class'KFWeap_Eviscerator'))
	LevelEffects(3)=(LoadoutClasses=(class'KFWeap_Blunt_Pulverizer',class'KFWeap_Shotgun_Nailgun',class'KFWeap_Eviscerator'))
}