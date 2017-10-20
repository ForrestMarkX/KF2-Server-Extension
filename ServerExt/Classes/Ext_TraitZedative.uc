Class Ext_TraitZedative extends Ext_TraitBase;

static function string GetPerkDescription()
{
	local string S;

	S = Super.GetPerkDescription();
	S $= "|Trait requires prestige level: #{FF4000}2";
	return S;
}

static function bool MeetsRequirements( byte Lvl, Ext_PerkBase Perk )
{
	local int i;

	if( Perk.CurrentLevel<Default.MinLevel || Perk.CurrentPrestige<2 )
		return false;
	
	if( Lvl==0 )
	{
		i = Perk.PerkStats.Find('StatType','Heal');
		if( i>=0 )
			return (Perk.PerkStats[i].CurrentValue>=25);
	}
	
	return true;
}

static function TraitActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkFieldMedic(Perk).bUseSlug = true;
}

static function TraitDeActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkFieldMedic(Perk).bUseSlug = false;
}

defaultproperties
{
	SupportedPerk=class'Ext_PerkFieldMedic'
	TraitGroup=class'Ext_TGroupZEDTime'
	TraitName="ZED TIME - Zedative"
	NumLevels=1
	DefLevelCosts(0)=50
	DefMinLevel=65
	Description="During Zed time, damaging Zeds with perk weapons will slow them 30% and do massive amounts of poison damage. ||-REQUIREMENT: Healing bonus trait needs to have at least 25 points!"
}