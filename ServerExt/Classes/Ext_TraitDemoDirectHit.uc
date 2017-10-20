Class Ext_TraitDemoDirectHit extends Ext_TraitBase;

static function TraitActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkDemolition(Perk).bDirectHit = true;
}
static function TraitDeActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkDemolition(Perk).bDirectHit = false;
}

defaultproperties
{
	SupportedPerk=class'Ext_PerkDemolition'
	TraitName="High Impact"
	DefLevelCosts(0)=65
	DefMinLevel=35
	Description="Demo weapons will do 25% more damage on a direct hit!"
}