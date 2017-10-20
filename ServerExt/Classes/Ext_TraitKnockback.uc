Class Ext_TraitKnockback extends Ext_TraitRagdoll;

static function ApplyEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	if( ExtHumanPawn(Player)!=None )
		ExtHumanPawn(Player).KnockbackResist = Default.ChanceValues[Level-1];
}
static function CancelEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	if( ExtHumanPawn(Player)!=None )
		ExtHumanPawn(Player).KnockbackResist = 1.f;
}

defaultproperties
{
	TraitName="Knockback Resistance"
	NumLevels=4
	DefLevelCosts(0)=30
	DefLevelCosts(1)=30
	DefLevelCosts(2)=40
	DefLevelCosts(3)=60
	DefMinLevel=70
	Description="Reduce the amount of knockback zeds do to you in a rate of:|Lvl1-4: -20%, -50%, -70%, -90%"
	
	ChanceValues(0)=0.8
	ChanceValues(1)=0.5
	ChanceValues(2)=0.3
	ChanceValues(3)=0.1
}