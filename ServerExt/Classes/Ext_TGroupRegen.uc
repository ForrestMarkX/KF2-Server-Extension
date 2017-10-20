class Ext_TGroupRegen extends Ext_TGroupBase;

static function string GetUIInfo( Ext_PerkBase Perk )
{
	return Default.GroupInfo$" (MAX "$GetMaxLimit(Perk)$")";
}
static function string GetUIDesc()
{
	return Super.GetUIDesc()$"|To buy additional regen abilities:|-Prestige level 1 + Perk level 100 = MAX 2 traits|-Prestige level 5 + Perk level 150 = MAX 3 traits";
}

static function bool GroupLimited( Ext_PerkBase Perk, class<Ext_TraitBase> Trait )
{
	local int i;
	local byte n;

	n = GetMaxLimit(Perk);
	for( i=0; i<Perk.PerkTraits.Length; ++i )
		if( Perk.PerkTraits[i].CurrentLevel>0 && Perk.PerkTraits[i].TraitType!=Trait && Perk.PerkTraits[i].TraitType.Default.TraitGroup==Default.Class && --n==0 )
			return true;
	return false;
}

static final function byte GetMaxLimit( Ext_PerkBase Perk )
{
	if( Perk.CurrentPrestige<1 || Perk.CurrentLevel<100 )
		return 1;
	return ((Perk.CurrentPrestige<5 || Perk.CurrentLevel<150) ? 2 : 3);
}

defaultproperties
{
	GroupInfo="Regeneration"
}