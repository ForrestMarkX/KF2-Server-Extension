Class Ext_TraitWeapons extends Ext_TraitBase
	abstract;

struct FLevelFX
{
	var array< class<Inventory> > LoadoutClasses;
};
var array<FLevelFX> LevelEffects;

static function bool MeetsRequirements( byte Lvl, Ext_PerkBase Perk )
{
	if( Lvl>=3 && (Perk.CurrentLevel<50 || !HasMaxCarry(Perk)) )
		return false;
	return Super.MeetsRequirements(Lvl,Perk);
}
static final function bool HasMaxCarry( Ext_PerkBase Perk )
{
	local int i;
	
	i = Perk.PerkTraits.Find('TraitType',Class'Ext_TraitCarryCap');
	return (i==-1 || Perk.PerkTraits[i].CurrentLevel>=3);
}
static function string GetPerkDescription()
{
	return Super.GetPerkDescription()$"|- Level 4 requires perk level 50 and level 3 carry capacity trait!";
}

static function TraitActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Perk.PrimaryWeapon = None; // Give a new primary weapon.
}
static function TraitDeActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Perk.PrimaryWeapon = Perk.Default.PrimaryWeapon;
}

static function ApplyEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	local class<Inventory> IC;
	local KFInventoryManager M;
	local Inventory Inv;

	Level = Min(Level-1,Default.LevelEffects.Length-1);
	M = KFInventoryManager(Player.InvManager);
	if( M!=None )
		M.bInfiniteWeight = true;
	foreach Default.LevelEffects[Level].LoadoutClasses(IC)
	{
		if( Player.FindInventoryType(IC)==None )
		{
			Inv = Player.CreateInventory(IC,Player.Weapon!=None);
			if ( KFWeapon(Inv)!=None )
             	KFWeapon(Inv).bGivenAtStart = true;
		}
	}
	if( M!=None )
		M.bInfiniteWeight = false;
}
static function CancelEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	local class<Inventory> IC;
	local Inventory Inv;

	if( Level==0 )
		return;
	Level = Min(Level-1,Default.LevelEffects.Length-1);
	foreach Default.LevelEffects[Level].LoadoutClasses(IC)
	{
		Inv = Player.FindInventoryType(IC);
		if( Inv!=None )
			Inv.Destroy();
	}
}

defaultproperties
{
	NumLevels=4
	DefLevelCosts(0)=10
	DefLevelCosts(1)=15
	DefLevelCosts(2)=20
	DefLevelCosts(3)=40
	LoadPriority=1 // Make sure Carry Cap trait gets loaded first.
}