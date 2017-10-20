Class Ext_TraitUberAmmo extends Ext_TraitBase;

static function TraitActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkGunslinger(Perk).bHasUberAmmo = true;
}
static function TraitDeActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkGunslinger(Perk).bHasUberAmmo = false;
}

defaultproperties
{
	SupportedPerk=class'Ext_PerkGunslinger'
	TraitGroup=class'Ext_TGroupZEDTime'
	TraitName="ZED TIME - Uber Ammo"
	DefLevelCosts(0)=30
	Description="Gives player unlimited ammunition for perked weapons during ZED-time."
}