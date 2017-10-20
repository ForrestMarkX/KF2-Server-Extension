Class Ext_TraitWPMedic extends Ext_TraitWeapons;

defaultproperties
{
	TraitName="Medic Weapon Loadout"
	Description="This will grant you Field Medic weapon loadout to spawn with.|Level 1: SMG|Level 2: Shotgun|Level 3: Assault Rifle|Level 4: All 3"
	
	LevelEffects(0)=(LoadoutClasses=(class'KFWeap_SMG_Medic'))
	LevelEffects(1)=(LoadoutClasses=(class'KFWeap_Shotgun_Medic'))
	LevelEffects(2)=(LoadoutClasses=(class'KFWeap_AssaultRifle_Medic'))
	LevelEffects(3)=(LoadoutClasses=(class'KFWeap_SMG_Medic',class'KFWeap_Shotgun_Medic',class'KFWeap_AssaultRifle_Medic'))
}