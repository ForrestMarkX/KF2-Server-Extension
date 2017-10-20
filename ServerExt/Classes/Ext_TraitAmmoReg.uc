Class Ext_TraitAmmoReg extends Ext_TraitBase;

var array<float> RegenValues;

static function ApplyEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	local Ext_T_AmmoRegHelp H;
	
	H = Player.Spawn(class'Ext_T_AmmoRegHelp',Player);
	if( H!=None )
		H.RegCount = Default.RegenValues[Level-1];
}
static function CancelEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	local Ext_T_AmmoRegHelp H;

	foreach Player.ChildActors(class'Ext_T_AmmoRegHelp',H)
		H.Destroy();
}

defaultproperties
{
	TraitGroup=class'Ext_TGroupRegen'
	TraitName="Ammo Regeneration"
	NumLevels=3
	DefLevelCosts(0)=10
	DefLevelCosts(1)=20
	DefLevelCosts(2)=40
	Description="With this trait all your weapons ammo (not grenades) will regen every half minute at rate of:|Lvl1-3: 2%, 5%, 10% of max ammo"
	RegenValues.Add(0.02)
	RegenValues.Add(0.05)
	RegenValues.Add(0.1)
}