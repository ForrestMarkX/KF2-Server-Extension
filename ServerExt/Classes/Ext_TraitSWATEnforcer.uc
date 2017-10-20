Class Ext_TraitSWATEnforcer extends Ext_TraitBase;

static function ApplyEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	if( ExtHumanPawn(Player)!=None )
		ExtHumanPawn(Player).bMovesFastInZedTime = true;
}
static function CancelEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	if( ExtHumanPawn(Player)!=None )
		ExtHumanPawn(Player).bMovesFastInZedTime = false;
}
static function TraitActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Perk.bHasSWATEnforcer = true;
}
static function TraitDeActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Perk.bHasSWATEnforcer = false;
}

defaultproperties
{
	TraitName="ZED TIME - SWAT Enforcer"
	TraitGroup=class'Ext_TGroupZEDTime'
	DefLevelCosts(0)=50
	Description="This trait makes you move at normal speed and allows you to knock down zeds by bumping into them during ZED-time."
}