Class Ext_TraitMedicPistol extends Ext_TraitBase;

static function AddDefaultInventory( KFPawn Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Player.DefaultInventory.RemoveItem(class'KFWeap_Pistol_9mm');
	Player.DefaultInventory.AddItem(class'KFWeap_Pistol_Medic');
}

defaultproperties
{
	TraitName="Medic Pistol"
	DefLevelCosts(0)=20
	Description="Spawn with a medic pistol instead of standard 9mm."
}