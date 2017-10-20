Class Ext_TraitWPSurv extends Ext_TraitWeapons;

defaultproperties
{
	TraitName="Survivalist Weapon Loadout"
	Description="This will grant you Survivalist weapon loadout to spawn with.|Level 1: Dragons Breath|Level 2: M16M203 Assault Rifle|Level 3: Medic Assault Rifle|Level 4: All 3"
	
	LevelEffects(0)=(LoadoutClasses=(class'KFWeap_Shotgun_DragonsBreath'))
	LevelEffects(1)=(LoadoutClasses=(class'KFWeap_AssaultRifle_M16M203'))
	LevelEffects(2)=(LoadoutClasses=(class'KFWeap_AssaultRifle_Medic'))
	LevelEffects(3)=(LoadoutClasses=(class'KFWeap_Shotgun_DragonsBreath',class'KFWeap_AssaultRifle_M16M203',class'KFWeap_AssaultRifle_Medic'))
}