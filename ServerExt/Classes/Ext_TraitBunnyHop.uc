Class Ext_TraitBunnyHop extends Ext_TraitBase;

static function ApplyEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	if( ExtHumanPawn(Player)!=None )
		ExtHumanPawn(Player).bHasBunnyHop = true;
}
static function CancelEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	if( ExtHumanPawn(Player)!=None )
		ExtHumanPawn(Player).bHasBunnyHop = false;
}

defaultproperties
{
	TraitName="Bunny Hop"
	DefLevelCosts(0)=50
	DefMinLevel=100
	Description="Enable player to do bunny hopping. It means the more you continiously make successful jumps while moving forward you will keep accelerating in speed."
}