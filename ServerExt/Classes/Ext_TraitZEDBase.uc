Class Ext_TraitZEDBase extends Ext_TraitBase
	abstract;

var class<Ext_TraitZEDBase> BaseTrait;
var bool bIsSummoner;

static function bool MeetsRequirements( byte Lvl, Ext_PerkBase Perk )
{
	local int i;

	// First check level.
	if( Perk.CurrentLevel<Default.MinLevel )
		return false;
	
	// Then check stats.
	if( Lvl==0 && Default.BaseTrait!=None )
	{
		i = Perk.PerkTraits.Find('TraitType',Default.BaseTrait);
		if( i>=0 )
			return (Perk.PerkTraits[i].CurrentLevel>0);
	}
	return true;
}

defaultproperties
{
	TraitGroup=class'Ext_TGroupMonster'
	BaseTrait=class'Ext_TraitZED_Summon'
}