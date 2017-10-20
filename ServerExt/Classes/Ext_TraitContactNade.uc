Class Ext_TraitContactNade extends Ext_TraitBase;

static function TraitActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Perk.bExplodeOnContact = true;
}
static function TraitDeActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Perk.bExplodeOnContact = false;
}

defaultproperties
{
	TraitName="Explode on Contact"
	DefLevelCosts(0)=25
	Description="Make dynamites explode on contact with the ZED."
}