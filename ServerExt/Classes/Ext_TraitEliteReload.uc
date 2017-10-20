Class Ext_TraitEliteReload extends Ext_TraitBase;

static function ApplyEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Perk.bTacticalReload = true;
}
static function CancelEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Perk.bTacticalReload = false;
}

defaultproperties
{
	TraitName="Tactical Reload"
	DefLevelCosts(0)=50
	Description="With this trait you will have extra speedy tactical reload moves for your perked weapons."
	DefMinLevel=50
}