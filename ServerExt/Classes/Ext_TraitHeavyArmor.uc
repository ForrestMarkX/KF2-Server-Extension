Class Ext_TraitHeavyArmor extends Ext_TraitBase;

static function TraitActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Perk.bHeavyArmor = true;
}
static function TraitDeActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Perk.bHeavyArmor = false;
}

static function ApplyEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	if( Level <= 1 )
		return;
		
	Level == 2 ? Player.AddArmor(50) : Player.AddArmor(Player.MaxArmor);
}

defaultproperties
{
	TraitName="Heavy Armor"
	NumLevels=3
	DefLevelCosts(0)=50
	DefLevelCosts(1)=20
	DefLevelCosts(2)=60
	DefMinLevel=50
	Description="Makes your armor stop all damage (except for Siren scream and fall damage).|Level 2 makes you in addition spawn with 50 points of armor.|Level 3 makes you spawn with full armor."
}