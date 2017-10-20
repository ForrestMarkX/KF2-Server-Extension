Class Ext_TraitBoomWeld extends Ext_TraitBase
	abstract;

static function TraitActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Perk.bExplosiveWeld = true;
}
static function TraitDeActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Perk.bExplosiveWeld = false;
}

defaultproperties
{
	TraitName="Explosive Weld"
	DefLevelCosts(0)=30
	Description="Cases welded doors explode when broken by zeds. The more you weld one door, the bigger explosion."
}