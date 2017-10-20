Class Ext_TraitMedBoost extends Ext_TraitBase;

static function ApplyEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkFieldMedic(Perk).HealingSpeedBoostPct = 10.0f + (5.f + ((float(Level) - 1.f) * 5.f));
}

static function CancelEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkFieldMedic(Perk).HealingSpeedBoostPct = 10.0f;
}

static function TraitActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkFieldMedic(Perk).bHealingBoost = true;
}

static function TraitDeActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkFieldMedic(Perk).bHealingBoost = false;
}

defaultproperties
{
	SupportedPerk=class'Ext_PerkFieldMedic'
	TraitName="Adrenaline Shot"
	NumLevels=5
	DefLevelCosts(0)=35
	DefLevelCosts(1)=10
	DefLevelCosts(2)=20
	DefLevelCosts(3)=30
	DefLevelCosts(4)=40
	DefMinLevel=25
	Description="Healing players will increase there speed 10% up to 30%. The percent is increased by every level in:|Lv1-5: 10%, 15%, 20%, 25%, 30%"
}