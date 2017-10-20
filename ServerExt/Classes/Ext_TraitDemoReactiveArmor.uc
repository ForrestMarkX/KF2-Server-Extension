Class Ext_TraitDemoReactiveArmor extends Ext_TraitBase;

static function TraitActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkDemolition(Perk).bCanUseSacrifice = true;
}
static function TraitDeActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkDemolition(Perk).bCanUseSacrifice = false;
}

defaultproperties
{
	SupportedPerk=class'Ext_PerkDemolition'
	TraitName="Reactive Armor"
	DefLevelCosts(0)=25
	DefMinLevel=45
	Description="When near death you will explode and leave yourself with 5 health"
}