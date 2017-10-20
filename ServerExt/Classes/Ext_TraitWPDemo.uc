Class Ext_TraitWPDemo extends Ext_TraitWeapons;

defaultproperties
{
	TraitName="Demolitionist Weapon Loadout"
	Description="This will grant you demolitionist weapon loadout to spawn with.|Level 1: C4|Level 2: M79 Grenade Launcher|Level 3: RPG Rocket Launcher|Level 4: All 3"
	
	LevelEffects(0)=(LoadoutClasses=(class'KFWeap_Thrown_C4'))
	LevelEffects(1)=(LoadoutClasses=(class'KFWeap_GrenadeLauncher_M79'))
	LevelEffects(2)=(LoadoutClasses=(class'KFWeap_RocketLauncher_RPG7'))
	LevelEffects(3)=(LoadoutClasses=(class'KFWeap_Thrown_C4',class'KFWeap_GrenadeLauncher_M79',class'KFWeap_RocketLauncher_RPG7'))
}