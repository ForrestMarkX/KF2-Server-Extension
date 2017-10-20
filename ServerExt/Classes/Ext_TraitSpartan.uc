Class Ext_TraitSpartan extends Ext_TraitBase;

var array<float> AtkRates;

static function ApplyEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	if( ExtHumanPawn(Player)!=None )
		ExtHumanPawn(Player).bMovesFastInZedTime = true;
	Ext_PerkBerserker(Perk).ZedTimeMeleeAtkRate = 1.f/Default.AtkRates[Level-1];
}
static function CancelEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	if( ExtHumanPawn(Player)!=None )
		ExtHumanPawn(Player).bMovesFastInZedTime = false;
	Ext_PerkBerserker(Perk).ZedTimeMeleeAtkRate = 1.f;
}

defaultproperties
{
	SupportedPerk=class'Ext_PerkBerserker'
	TraitGroup=class'Ext_TGroupZEDTime'
	TraitName="ZED TIME - Spartan!"
	NumLevels=3
	DefLevelCosts(0)=50
	DefLevelCosts(1)=40
	DefLevelCosts(2)=80
	Description="This trait lets you move at normal speed and attack faster in ZED-time.|Lv1-3: +50,+120,+300% atk speed"
	AtkRates.Add(1.5)
	AtkRates.Add(2.2)
	AtkRates.Add(4.0)
	DefMinLevel=100
}