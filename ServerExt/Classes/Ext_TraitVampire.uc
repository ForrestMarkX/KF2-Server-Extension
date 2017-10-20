Class Ext_TraitVampire extends Ext_TraitBase;

var() array<float> RegenRate;

static function TraitActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkBerserker(Perk).VampRegenRate = Default.RegenRate[Level-1];
}
static function TraitDeActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkBerserker(Perk).VampRegenRate = 0;
}

defaultproperties
{
	SupportedPerk=class'Ext_PerkBerserker'
	TraitName="Vampire"
	NumLevels=4
	DefLevelCosts(0)=25
	DefLevelCosts(1)=15
	DefLevelCosts(2)=20
	DefLevelCosts(3)=25
	RegenRate.Add(0.02)
	RegenRate.Add(0.03)
	RegenRate.Add(0.04)
	RegenRate.Add(0.06)
	Description="With this trait you will recover some of your health by every kill (with a melee weapon), in a rate of:|Lv1-4: +2%, +3%, +4%, +6%"
}