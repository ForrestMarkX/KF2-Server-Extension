// Trait group info.
Class Ext_TGroupBase extends Object
	abstract;

var() string GroupInfo;
var() bool bLimitToOne; // Limit to only one trait for this group.

static function string GetUIInfo( Ext_PerkBase Perk )
{
	return (Default.bLimitToOne ? Default.GroupInfo$" (MAX 1)" : Default.GroupInfo);
}
static function string GetUIDesc()
{
	return Default.GroupInfo$" trait group";
}

// See if group is already using up limitation.
static function bool GroupLimited( Ext_PerkBase Perk, class<Ext_TraitBase> Trait )
{
	local int i;

	if( Default.bLimitToOne )
	{
		for( i=0; i<Perk.PerkTraits.Length; ++i )
			if( Perk.PerkTraits[i].CurrentLevel>0 && Perk.PerkTraits[i].TraitType!=Trait && Perk.PerkTraits[i].TraitType.Default.TraitGroup==Default.Class )
				return true;
	}
	return false;
}

defaultproperties
{
	GroupInfo="Group"
}