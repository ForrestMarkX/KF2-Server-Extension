Class Ext_TraitWPFire extends Ext_TraitWeapons;

defaultproperties
{
	TraitName="Firebug Weapon Loadout"
	Description="This will grant you firebug weapon loadout to spawn with.|Level 1: Dragons Breath|Level 2: Flamethrower|Level 3: Microwave Gun|Level 4: All 3"
	
	LevelEffects(0)=(LoadoutClasses=(class'KFWeap_Shotgun_DragonsBreath'))
	LevelEffects(1)=(LoadoutClasses=(class'KFWeap_Flame_Flamethrower'))
	LevelEffects(2)=(LoadoutClasses=(class'KFWeap_Beam_Microwave'))
	LevelEffects(3)=(LoadoutClasses=(class'KFWeap_Shotgun_DragonsBreath',class'KFWeap_Flame_Flamethrower',class'KFWeap_Beam_Microwave'))
}