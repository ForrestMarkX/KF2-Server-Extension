Class Ext_TraitAirborneAgent extends Ext_TraitBase;

static function string GetPerkDescription()
{
	local string S;

	S = Super.GetPerkDescription();
	S $= "|Trait requires prestige level: #{FF4000}1";
	return S;
}

static function bool MeetsRequirements( byte Lvl, Ext_PerkBase Perk )
{
	local int i;

	if( Perk.CurrentLevel<Default.MinLevel || Perk.CurrentPrestige<1 )
		return false;
		
	for( i=0; i<Perk.PerkTraits.Length; ++i )
	{
		if( Perk.PerkTraits[i].TraitType==Class'Ext_TraitGrenadeUpg' )
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
	Ext_PerkFieldMedic(Perk).bUseAirborneAgent = true;
}
static function TraitDeActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkFieldMedic(Perk).bUseAirborneAgent = false;
}

defaultproperties
{
	SupportedPerk=class'Ext_PerkFieldMedic'
	TraitGroup=class'Ext_TGroupZEDTime'
	TraitName="ZED TIME - Airborne Agent"
	NumLevels=1
	DefLevelCosts(0)=60
	DefMinLevel=75
	Description="You release a healing gas during Zed time, healing teammates close by. ||-REQUIREMENT: Grenade Upgrade trait needs to be level 1!"
}