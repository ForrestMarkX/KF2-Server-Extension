Class Ext_TraitWPGuns extends Ext_TraitWeapons;

defaultproperties
{
	TraitName="Gunslinger Weapon Loadout"
	Description="This will grant you gunslinger weapon loadout to spawn with.|Level 1: M1911 Pistol|Level 2: Desert Eagle|Level 3: Magnum Revolver|Level 4: All 3 with dualies"
	
	LevelEffects(0)=(LoadoutClasses=(class'KFWeap_Pistol_Colt1911'))
	LevelEffects(1)=(LoadoutClasses=(class'KFWeap_Pistol_Deagle'))
	LevelEffects(2)=(LoadoutClasses=(class'KFWeap_Revolver_SW500'))
	LevelEffects(3)=(LoadoutClasses=(class'KFWeap_Pistol_DualColt1911',class'KFWeap_Pistol_DualDeagle',class'KFWeap_Revolver_DualSW500'))
}