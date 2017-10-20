Class Ext_TraitZED_SummonExt extends Ext_TraitZEDBase
	abstract;

static function ApplyEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	local int i;
	local byte MaxLevel;

	MaxLevel = 0;
	for( i=0; i<Perk.PerkTraits.Length; ++i )
		if( Perk.PerkTraits[i].TraitType==Class'Ext_TraitZED_Summon' )
		{
			MaxLevel = Max(Perk.PerkTraits[i].CurrentLevel,1)-1;
			break;
		}

	switch( Level )
	{
	case 3:
		AddHelperType(MaxLevel*0.8,Player);
	case 1:
		AddHelperType(Rand(MaxLevel*0.4),Player);
		break;
	case 4:
		AddHelperType(MaxLevel*0.8,Player);
	case 2:
		AddHelperType(MaxLevel*0.8,Player);
		break;
	}
	
	// Make other traits refresh (apply HP/damage scalers).
	for( i=0; i<Perk.PerkTraits.Length; ++i )
		if( Perk.PerkTraits[i].CurrentLevel>0 && Class<Ext_TraitZEDBase>(Perk.PerkTraits[i].TraitType)!=None && !Class<Ext_TraitZEDBase>(Perk.PerkTraits[i].TraitType).Default.bIsSummoner )
			Perk.PerkTraits[i].TraitType.Static.ApplyEffectOn(Player,Perk,Level,Data);
}
static function CancelEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	local Ext_T_ZEDHelper H;

	foreach Player.ChildActors(class'Ext_T_ZEDHelper',H)
		if( H.bIsExtra )
			H.Destroy();
}
static final function AddHelperType( byte Lv, KFPawn_Human Player )
{
	local Ext_T_ZEDHelper H;
	
	H = Player.Spawn(class'Ext_T_ZEDHelper',Player);
	if( H!=None )
	{
		H.CurLevel = Lv;
		H.bIsExtra = true;
	}
}

defaultproperties
{
	bIsSummoner=true
	NumLevels=4
	TraitName="Monster Tongue Extra"
	Description="With this trait you will spawn yourself extra helper zeds.|Lv 1: Spawn one extra weak zed.|Lv 2: Spawn one extra strong zed.|Lv 3: Spawn one weak and one strong zed.|Lv 4: Spawn two strong zeds.||-Requires Monster Tongue trait."
	DefLevelCosts(0)=100
	DefLevelCosts(1)=40
	DefLevelCosts(2)=80
	DefLevelCosts(3)=50
	DefMinLevel=100
}