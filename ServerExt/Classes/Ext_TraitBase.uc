Class Ext_TraitBase extends Object
	abstract
	config(ServerExt)
	DependsOn(ExtWebAdmin_UI);

var array<FWebAdminConfigInfo> WebConfigs;

var() class<Ext_TGroupBase> TraitGroup; // With groups you can prevent player from buying multiple traits of same group.
var() string TraitName,Description; // UI name.
var() byte NumLevels; // Maximum number of levels.
var config array<int> LevelCosts;
var() array<int> DefLevelCosts; // Point price tag for each level.
var() class<Ext_TraitDataStore> TraitData; // Optional additional data that this trait requires for each player.
var config int MinLevel; // Minimum perk level player needs to be in order to be allowed to get this trait.
var() int DefMinLevel;
var() const byte LoadPriority; // Order of loading the trait class, if for example one trait depends on progress of another trait.
var() class<Ext_PerkBase> SupportedPerk; // Only functions on this perk.

// Config init stuff.
var config int ConfigVersion;
var const int CurrentConfigVer;

var config bool bDisabled; // This trait is currently disabled on server.

var() bool bGroupLimitToOne, // TraitGroup should limit so you can only buy one of them.
			bHighPriorityDeath, // Should receive PreventDeath call before any other trait.
			bPostApplyEffect; // Apply effects on second pass (relies on that another trait is activated first).

// Check if trait is enabled and usable on this perk.
static function bool IsEnabled( Ext_PerkBase Perk )
{
	return !Default.bDisabled && (Default.SupportedPerk==None || ClassIsChildOf(Perk.Class,Default.SupportedPerk));
}

// Check if player meets the requirements to buy this trait.
static function bool MeetsRequirements( byte Lvl, Ext_PerkBase Perk )
{
	// First check level.
	if( Perk.CurrentLevel<Default.MinLevel )
		return false;
	
	// Then check grouping.
	if( Lvl==0 && Default.TraitGroup!=None && Default.TraitGroup.Static.GroupLimited(Perk,Default.Class) )
		return false;
	return true;
}

// Return UI description player will see before bying this trait.
static function string GetPerkDescription()
{
	local string S;
	local byte i;
	
	for( i=0; i<Default.NumLevels; ++i )
	{
		if( i==0 )
			S = string(GetTraitCost(i));
		else S $= ", "$GetTraitCost(i);
	}
	S = "Max level: #{9FF781}"$Default.NumLevels$"#{DEF}|Level costs: #{F3F781}"$S$"#{DEF}";
	if( Default.MinLevel>0 )
		S = "Min perk level: #{FF4000}"$Default.MinLevel$"#{DEF}|"$S;
	return Default.Description$"||"$S;
}

// Return tooltip description of this trait
static function string GetTooltipInfo()
{
	return Default.TraitName$"|"$Default.Description;
}

// Return level specific trait prices.
static function int GetTraitCost( byte LevelNum )
{
	if( Default.LevelCosts.Length>0 )
	{
		if( LevelNum<Default.LevelCosts.Length )
			return Default.LevelCosts[LevelNum];
		return Default.LevelCosts[Default.LevelCosts.Length-1];
	}
	return 5;
}

// Trait initialization/cleanup.
static function Ext_TraitDataStore InitializeFor( Ext_PerkBase Perk, ExtPlayerController Player )
{
	local Ext_TraitDataStore T;

	T = None;
	if( Default.TraitData!=None )
	{
		T = Player.Spawn(Default.TraitData,Player);
		T.Perk = Perk;
		T.PlayerOwner = Player;
		T.TraitClass = Default.Class;
	}
	return T;
}
static function CleanupTrait( ExtPlayerController Player, Ext_PerkBase Perk, optional Ext_TraitDataStore Data )
{
	if( Data!=None )
		Data.Destroy();
}

// Called when trait is first activated/deactivated (might even have a dead pawn).
static function TraitActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data );
static function TraitDeActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data );

// Called everytime player spawns in on the game (cancel effect is called on level up/level reset/perk change).
static function ApplyEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data );
static function CancelEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data );

// Owner died with this trait active.
static function PlayerDied( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data );

// Prevent death.
static function bool PreventDeath( KFPawn_Human Player, Controller Instigator, Class<DamageType> DamType, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data );

// Give/modify default inventory.
static function AddDefaultInventory( KFPawn Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data );

// Data that server should replicate to client.
static final function string IntToStr( int Value, optional byte MaxVal ) // Helper function to put integer into one character of string.
{
	switch( MaxVal )
	{
	case 0: // 0-65535
		return Chr(Max(Value,0)+1);
	case 1: // 0-1073741823
		return Chr((Value & 32767)+1) $ Chr(((Value >> 15) & 32767)+1);
	}
}
static final function string InlineString( string Str ) // Helper function to append a string line to a text using a length char in front.
{
	return IntToStr(Len(Str))$Str;
}
static final function int StrToInt( out string Value, optional byte MaxVal ) // Reverse.
{
	local int Res;

	switch( MaxVal )
	{
	case 0: // 0-65535
		Res = Asc(Left(Value,1))-1;
		Value = Mid(Value,1);
		break;
	case 1: // 0-1073741823
		Res =(Asc(Mid(Value,0,1))-1) | ((Asc(Mid(Value,1,1)) << 15)-1);
		Value = Mid(Value,2);
		break;
	}
	return Res;
}
static final function string GetInlineStr( out string S ) // Reverse.
{
	local int l;
	local string Res;
	
	l = StrToInt(S);
	Res = Left(S,l);
	S = Mid(S,l);
	return Res;
}

static function string GetRepData()
{
	local string S;
	local int i;
	
	S = IntToStr(Default.MinLevel)$IntToStr(Default.LevelCosts.Length);
	for( i=0; i<Default.LevelCosts.Length; ++i )
		S $= IntToStr(Default.LevelCosts[i]);
	return S;
}
static function string ClientSetRepData( string S )
{
	local int i;

	Default.MinLevel = StrToInt(S);
	Default.LevelCosts.Length = StrToInt(S);
	for( i=0; i<Default.LevelCosts.Length; ++i )
		Default.LevelCosts[i] = StrToInt(S);
	return S;
}

// Configure initialization.
static function CheckConfig()
{
	if( Default.ConfigVersion!=Default.CurrentConfigVer )
	{
		UpdateConfigs(Default.ConfigVersion);
		Default.ConfigVersion = Default.CurrentConfigVer;
		StaticSaveConfig();
	}
}
static function UpdateConfigs( int OldVer )
{
	if( OldVer==0 )
	{
		Default.LevelCosts = Default.DefLevelCosts;
		Default.MinLevel = Default.DefMinLevel;
	}
}

// WebAdmin UI
static function InitWebAdmin( ExtWebAdmin_UI UI )
{
	UI.AddSettingsPage("Trait "$Default.TraitName,Default.Class,Default.WebConfigs,GetValue,ApplyValue);
}
static function string GetValue( name PropName, int ElementIndex )
{
	switch( PropName )
	{
	case 'MinLevel':
		return string(Default.MinLevel);
	case 'LevelCosts':
		return (ElementIndex==-1 ? string(Default.LevelCosts.Length) : string(Default.LevelCosts[ElementIndex]));
	case 'bDisabled':
		return string(Default.bDisabled);
	}
}
static function ApplyValue( name PropName, int ElementIndex, string Value )
{
	switch( PropName )
	{
	case 'MinLevel':
		Default.MinLevel = int(Value);		break;
	case 'LevelCosts':
		Default.LevelCosts.Length = Default.DefLevelCosts.Length;
		if( Value!="#DELETE" && ElementIndex<Default.LevelCosts.Length )
			Default.LevelCosts[ElementIndex] = int(Value);
		break;
	case 'bDisabled':
		Default.bDisabled = bool(Value);	break;
	default:
		return;
	}
	StaticSaveConfig();
}

defaultproperties
{
	CurrentConfigVer=1
	DefLevelCosts.Add(5)
	NumLevels=1
	DefMinLevel=0

	WebConfigs.Add((PropType=1,PropName="bDisabled",UIName="Disabled",UIDesc="Disable this trait (hides from UI and makes it unusable)!"))
	WebConfigs.Add((PropType=0,PropName="MinLevel",UIName="Minimum Level",UIDesc="Minimum Level required for this trait"))
	WebConfigs.Add((PropType=0,PropName="LevelCosts",UIName="Level Costs",UIDesc="EXP cost for each trait level (array length is a constant)!",NumElements=-1))
}