Class Ext_TraitPenetrator extends Ext_TraitBase;

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
	
	for( i=0; i<Perk.PerkTraits.Length; ++i )
	{
		if( Perk.PerkTraits[i].TraitType==Class'Ext_TraitAPShots' )
		{
			if( Perk.PerkTraits[i].CurrentLevel <= 0 )
				return false;
			else break;
		}
	}
	
	return true;
}

static function TraitActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkSupport(Perk).bUsePerforate = true;
}

static function TraitDeActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkSupport(Perk).bUsePerforate = false;
}

defaultproperties
{
	SupportedPerk=class'Ext_PerkSupport'
	TraitGroup=class'Ext_TGroupZEDTime'
	TraitName="ZED TIME - Penetrator"
	NumLevels=1
	DefLevelCosts(0)=50
	DefMinLevel=65
	Description="During Zed time, your perk weapons penetrate through any targets they hit! ||-REQUIREMENT: Armor Piercing Shots trait needs to be level 1!"
}