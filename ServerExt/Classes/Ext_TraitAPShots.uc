Class Ext_TraitAPShots extends Ext_TraitBase;

static function ApplyEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkSupport(Perk).APShotMul = 1 + (0.25 + (((float(Level) - 1.f) * 5.f) / 100.f));
}

static function CancelEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkSupport(Perk).APShotMul = 0.f;
}

static function TraitActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkSupport(Perk).bUseAPShot = true;
}

static function TraitDeActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkSupport(Perk).bUseAPShot = false;
}

defaultproperties
{
	SupportedPerk=class'Ext_PerkSupport'
	TraitName="Armor Piercing Rounds"
	NumLevels=4
	DefLevelCosts(0)=15
	DefLevelCosts(1)=30
	DefLevelCosts(2)=40
	DefLevelCosts(3)=50
	DefMinLevel=15
	Description="Greatly increases penetration with perk weapons! The penetration strength is increased by every level in:|Lv1-4: 25%, 30%, 35%, 40%"
}