// Base perk.
Class Ext_PerkBase extends Info
	NotPlaceable
	Abstract
	Config(ServerExt)
	DependsOn(ExtWebAdmin_UI);

var array<FWebAdminConfigInfo> WebConfigs;

var ExtPerkManager PerkManager;
var Controller PlayerOwner;

var() string PerkName;
var() Texture2D PerkIcon;
var() class<KFPerk> BasePerk; // KF perk that this perk is based on.
var() class<KFWeapon> PrimaryMelee,PrimaryWeapon;
var() class<KFWeaponDefinition> PrimaryWeaponDef,SecondaryWeaponDef,KnifeWeaponDef,GrenadeWeaponDef;
var() class<KFProj_Grenade> GrenadeClass,PerkGrenade,SuperGrenade;
var() int HealExpUpNum,WeldExpUpNum; // Efficiency of healing and welding XP up.

// For trader.
var() array<class<KFWeaponDefinition> > AutoBuyLoadOutPath;

// Config init stuff.
var config int ConfigVersion;
var const int CurrentConfigVer;

// Variables.
var config int FirstLevelExp, // How much EXP needed for first level.
				LevelUpExpCost, // How much EXP needed for every level up.
				LevelUpIncCost, // How much EXP increase needed for each level up.
				MinimumLevel,
				MaximumLevel,
				StarPointsPerLevel,
				MinLevelForPrestige, // Minimum level required for perk prestige.
				PrestigeSPIncrease, // Starpoint increase per prestige levelup.
				MaxPrestige; // Maximum prestige level.
var config float PrestigeXPReduce; // Amount of XP cost is reduced for each prestige.
var config array<string> TraitClasses;

var array<float> Modifiers;

var int CurrentLevel, // Current level player is on.
		CurrentEXP, // Current amount of EXP user has.
		NextLevelEXP, // Experience needed for next level.
		CurrentSP, // Current amount of star points.
		LastLevelEXP, // Number of XP was needed for last level.
		CurrentPrestige; // Current prestige level.

struct FPerkStat
{
	var config int MaxValue,CostPerValue;
	var config float Progress;
	var config name StatType;
	var transient int CurrentValue,OldValue;
	var transient float DisplayValue;
	var transient string UIName;
};
var config array<FPerkStat> PerkStats;

struct FDefPerkStat
{
	var int MaxValue,CostPerValue;
	var float Progress;
	var name StatType;
	var string UIName;
	var bool bHiddenConfig; // Hide this config by default.
};
var() array<FDefPerkStat> DefPerkStats;
var() array< class<Ext_TraitBase> > DefTraitList;

struct FPlayerTrait
{
	var class<Ext_TraitBase> TraitType;
	var byte CurrentLevel;
	var Ext_TraitDataStore Data;
};
var array<FPlayerTrait> PerkTraits;

// Server -> Client replication variables
var byte RepState;
var int RepIndex;
var transient float NextAuthTime;

var int ToxicDartDamage;
var byte EnemyHealthRange;
var() array<float> EnemyDistDraw;

var bool bOwnerNetClient,bClientAuthorized,bPerkNetReady,bHasNightVision,bCanBeGrabbed,bExplosiveWeld,bExplodeOnContact,bNapalmFire,bFireExplode,bToxicDart,bTacticalReload,bHeavyArmor,bHasSWATEnforcer;

replication
{
	// Things the server should send to the client.
	if ( true )
		CurrentLevel,CurrentPrestige,CurrentEXP,NextLevelEXP,CurrentSP,LastLevelEXP,bHasNightVision,MinLevelForPrestige,PrestigeSPIncrease,MaxPrestige,bTacticalReload,EnemyHealthRange;
}

simulated final function bool IsWeaponOnPerk( KFWeapon W )
{
	if( class<KFPerk_Survivalist>(BasePerk) != None )
		return true;
		
	return W!=None && W.GetWeaponPerkClass(BasePerk)==BasePerk;
}

simulated static function string GetPerkIconPath( int Level )
{
	return "img://"$PathName(Default.PerkIcon);
}

simulated function PostBeginPlay()
{
	local int i,j;
	local class<Ext_TraitBase> T;

	if( WorldInfo.NetMode==NM_Client )
	{
		PerkStats.Length = 0; // Prevent client desync with client settings.
		PlayerOwner = GetALocalPlayerController();
		SetTimer(0.01,false,'InitPerk');
	}
	else
	{
		RemoteRole = ROLE_None; // Make sure these actors get replicated in order to client.
		PlayerOwner = Controller(Owner);
		if( PlayerOwner==None )
		{
			`Log(Self@"spawned without owner.");
			Destroy();
			return;
		}
		bOwnerNetClient = (PlayerController(Owner)!=None && LocalPlayer(PlayerController(Owner).Player)==None);
		
		// Load trait classes.
		j = 0;
		for( i=0; i<TraitClasses.Length; ++i )
		{
			T = class<Ext_TraitBase>(DynamicLoadObject(TraitClasses[i],Class'Class'));
			if( T==None || !T.Static.IsEnabled(Self) )
				continue;
			PerkTraits.Length = j+1;
			PerkTraits[j].TraitType = T;
			++j;
		}
		
		// Setup serverside stat info (for XML log files).
		for( j=0; j<PerkStats.Length; ++j )
		{
			i = DefPerkStats.Find('StatType',PerkStats[j].StatType);
			if( i>=0 )
				PerkStats[j].UIName = DefPerkStats[i].UIName;
			else
			{
				// Fallback to parent perk for trying to find name.
				i = Class'Ext_PerkBase'.Default.DefPerkStats.Find('StatType',PerkStats[j].StatType);
				if( i>=0 )
					PerkStats[j].UIName = Class'Ext_PerkBase'.Default.DefPerkStats[i].UIName;
				else PerkStats[j].UIName = string(PerkStats[j].StatType); // Fallback to stat name then...
			}
		}
	}
}
simulated function InitPerk()
{
	if( PlayerOwner==None )
		PlayerOwner = GetALocalPlayerController();
	if( PerkManager==None )
	{
		foreach DynamicActors(class'ExtPerkManager',PerkManager)
		{
			PerkManager.RegisterPerk(Self);
			break;
		}
	}
}
simulated function Destroyed()
{
	local int i;

	if( PerkManager!=None )
		PerkManager.UnregisterPerk(Self);
	if( WorldInfo.NetMode!=NM_Client )
	{
		for( i=0; i<PerkTraits.Length; ++i )
			PerkTraits[i].TraitType.Static.CleanupTrait(ExtPlayerController(Owner),Self,PerkTraits[i].Data);
	}
}

// For HUD UI
simulated final function string GetLevelString()
{
	return (CurrentPrestige>0 ? (string(CurrentPrestige)$"-"$string(CurrentLevel)) : string(CurrentLevel));
}

// For progress bar on HUD
simulated final function float GetProgressPercent()
{
	return FClamp(float(CurrentEXP-LastLevelEXP) / FMax(float(NextLevelEXP-LastLevelEXP),1.f),0.f,1.f);
}

// Whetever if user can use prestige now.
simulated final function bool CanPrestige()
{
	return (MinLevelForPrestige>=0 && CurrentPrestige<MaxPrestige) ? CurrentLevel>=MinLevelForPrestige : false;
}

// Whetever to save this perk status or not
final function bool HasAnyProgress()
{
	return (CurrentEXP>0 || CurrentPrestige>0);
}

reliable client simulated function ClientReceiveStat( int Index, int MaxValue, int CostPerValue, name Type, int CurValue, float Progress )
{
	local int i;

	if( WorldInfo.NetMode==NM_Client )
	{
		if( PerkStats.Length<=Index )
			PerkStats.Length = Index+1;
		PerkStats[Index].MaxValue = MaxValue;
		PerkStats[Index].CostPerValue = CostPerValue;
		PerkStats[Index].StatType = Type;
		PerkStats[Index].CurrentValue = CurValue;
		PerkStats[Index].DisplayValue = 0.f;
		PerkStats[Index].Progress = Progress;
	}
	i = DefPerkStats.Find('StatType',Type);
	if( i>=0 )
		PerkStats[Index].UIName = DefPerkStats[i].UIName;
	else
	{
		// Fallback to parent perk for trying to find name.
		i = Class'Ext_PerkBase'.Default.DefPerkStats.Find('StatType',Type);
		if( i>=0 )
			PerkStats[Index].UIName = Class'Ext_PerkBase'.Default.DefPerkStats[i].UIName;
		else PerkStats[Index].UIName = string(Type); // Fallback to stat name then...
	}
}
reliable client simulated function ClientSetStatValue( int Index, int NewValue )
{
	if( PerkStats.Length<=Index )
		PerkStats.Length = Index+1;
	PerkStats[Index].CurrentValue = NewValue;
	if( bPerkNetReady )
		ApplyEffects();
}
reliable client simulated function ClientReceiveTrait( int Index, class<Ext_TraitBase> TC, byte Lvl )
{
	if( PerkTraits.Length<=Index )
		PerkTraits.Length = Index+1;
	PerkTraits[Index].TraitType = TC;
	PerkTraits[Index].CurrentLevel = Lvl;
}
reliable client simulated function ClientReceiveTraitData( int Index, string Data )
{
	if( WorldInfo.NetMode==NM_Client )
		PerkTraits[Index].TraitType.Static.ClientSetRepData(Data);
}
reliable client simulated function ClientReceiveTraitLvl( int Index, byte NewLevel )
{
	PerkTraits[Index].CurrentLevel = NewLevel;
}

final function SetPerkStat( name Type, int Value )
{
	local int i;
	
	i = PerkStats.Find('StatType',Type);
	if( i>=0 )
		PerkStats[i].CurrentValue = Value;
}
final function int GetPerkStat( name Type )
{
	local int i;
	
	i = PerkStats.Find('StatType',Type);
	if( i==-1 )
		return 0;
	return PerkStats[i].CurrentValue;
}

function bool EarnedEXP( int EXP )
{
	local int n;

	bForceNetUpdate = true;
	CurrentEXP+=EXP;
	while( CurrentEXP>=NextLevelEXP && CurrentLevel<MaximumLevel && n<20 )
	{
		++n;
		LastLevelEXP = NextLevelEXP;
		NextLevelEXP = GetNeededExp(++CurrentLevel);
	}
	if( n>0 )
	{
		CurrentSP+=(n*(StarPointsPerLevel+CurrentPrestige*PrestigeSPIncrease));
		if( PerkManager.PRIOwner!=None && PerkManager.CurrentPerk==Self )
			UpdatePRILevel();
		// TODO - broadcast level up messages.
		if( ExtPlayerController(PlayerOwner)!=None )
			ExtPlayerController(PlayerOwner).ReceiveLevelUp(Self,CurrentLevel);
	}
	return true;
}

final function UpdatePRILevel()
{
	PerkManager.PRIOwner.SetLevelProgress(CurrentLevel,CurrentPrestige,MinimumLevel,MaximumLevel);
}

// XML output
function OutputXML( ExtStatWriter Data )
{
	local int i;

	Data.StartIntendent("perk","class",string(Class.Name));
	Data.WriteValue("perkname",PerkName);
	Data.WriteValue("level",string(CurrentLevel));
	Data.WriteValue("prestige",string(CurrentPrestige));
	Data.WriteValue("exp",string(CurrentEXP));
	Data.WriteValue("points",string(CurrentSP));
	Data.WriteValue("exptilnext",string(NextLevelEXP));
	Data.WriteValue("exponprev",string(LastLevelEXP));
	
	for( i=0; i<PerkStats.Length; ++i )
	{
		if( PerkStats[i].CurrentValue>0 )
		{
			Data.StartIntendent("stat","type",string(PerkStats[i].StatType));
			Data.WriteValue("name",GetStatUIStr(i));
			Data.WriteValue("value",string(PerkStats[i].CurrentValue));
			Data.WriteValue("progress",string(PerkStats[i].DisplayValue));
			Data.EndIntendent();
		}
	}
	
	for( i=0; i<PerkTraits.Length; ++i )
	{
		if( PerkTraits[i].CurrentLevel>0 )
		{
			Data.StartIntendent("trait","class",string(PerkTraits[i].TraitType.Name));
			Data.WriteValue("name",PerkTraits[i].TraitType.Default.TraitName);
			Data.WriteValue("level",string(PerkTraits[i].CurrentLevel));
			Data.EndIntendent();
		}
	}

	Data.EndIntendent();
}

// Data saving.
function SaveData( ExtSaveDataBase Data )
{
	local int i,j;
	
	// Write current EXP.
	Data.SaveInt(CurrentEXP,3);
	
	// Write current prestige
	Data.SaveInt(CurrentPrestige,3);

	// Count number of given stats
	j = 0;
	for( i=0; i<PerkStats.Length; ++i )
		if( PerkStats[i].CurrentValue>0 )
			++j;

	// Then perk stats.
	Data.SaveInt(j);
	for( i=0; i<PerkStats.Length; ++i )
	{
		if( PerkStats[i].CurrentValue>0 )
		{
			Data.SaveStr(string(PerkStats[i].StatType));
			Data.SaveInt(PerkStats[i].CurrentValue,1);
		}
	}
	
	// Count bought traits.
	j = 0;
	for( i=0; i<PerkTraits.Length; ++i )
		if( PerkTraits[i].CurrentLevel>0 )
			++j;

	// Then traits.
	Data.SaveInt(j);
	for( i=0; i<PerkTraits.Length; ++i )
	{
		if( PerkTraits[i].CurrentLevel>0 )
		{
			Data.SaveStr(string(PerkTraits[i].TraitType));
			Data.SaveInt(PerkTraits[i].CurrentLevel);
		}
	}
}

// Data loading.
function LoadData( ExtSaveDataBase Data )
{
	local int i,j,l,n;
	local string S;

	CurrentEXP = Data.ReadInt(3);
	
	if( Data.GetArVer()>=1 )
		CurrentPrestige = Data.ReadInt(3);

	l = Data.ReadInt(); // Perk stats length.
	for( i=0; i<l; ++i )
	{
		S = Data.ReadStr();
		n = Data.ReadInt(1);
		for( j=0; j<PerkStats.Length; ++j )
			if( S~=string(PerkStats[j].StatType) )
			{
				PerkStats[j].CurrentValue = n;
				break;
			}
	}
	
	l = Data.ReadInt(); // Traits stats length.
	for( i=0; i<l; ++i )
	{
		S = Data.ReadStr();
		n = Data.ReadInt();
		for( j=0; j<PerkTraits.Length; ++j )
			if( S~=string(PerkTraits[j].TraitType) )
			{
				PerkTraits[j].CurrentLevel = n;
				break;
			}
	}
}

final function int CalcLevelForExp( int InExp )
{
	local int i,a,b;

	// Fast method to calc level for a player.
	b = MaximumLevel+1;
	a = Min(MinimumLevel,b);
	while( true )
	{
		if( a==b || (a+1)==b )
		{
			if( a<MaximumLevel && InExp>=GetNeededExp(a) )
				++a;
			break;
		}
		i = a+((b-a)>>1);
		if( InExp<GetNeededExp(i) ) // Lower!
			b = i;
		else a = i; // Higher!
	}
	return Clamp(a,MinimumLevel,MaximumLevel);
}

// Initialize perk after stats have been loaded.
function SetInitialLevel()
{
	local int i,a,b;
	local byte MT,j;

	// Set to initial level player is on after configures has loaded.
	CurrentLevel = CalcLevelForExp(CurrentEXP);
	CurrentSP = CurrentLevel*(StarPointsPerLevel+CurrentPrestige*PrestigeSPIncrease);
	NextLevelEXP = GetNeededExp(CurrentLevel);
	LastLevelEXP = (CurrentLevel>MinimumLevel ? GetNeededExp(CurrentLevel-1) : 0);
	
	// Now verify the points player used on individual stats.
	for( i=0; i<PerkStats.Length; ++i )
	{
		if( PerkStats[i].CurrentValue>0 )
		{
			PerkStats[i].CurrentValue = Min(PerkStats[i].CurrentValue,PerkStats[i].MaxValue);
			a = PerkStats[i].CurrentValue*PerkStats[i].CostPerValue;
			if( CurrentSP>a )
				CurrentSP-=a;
			else if( CurrentSP<=0 ) // No points at all for this.
				PerkStats[i].CurrentValue = 0;
			else // Nope, reduce the stat!
			{
				a = CurrentSP/PerkStats[i].CostPerValue;
				PerkStats[i].CurrentValue = a;
				CurrentSP-=(a*PerkStats[i].CostPerValue);
			}
		}
	}

	// Then verify trait levels and costs.
	MT = 0;
	for( i=0; i<PerkTraits.Length; ++i )
	{
		if( PerkTraits[i].CurrentLevel>0 )
		{
			PerkTraits[i].CurrentLevel = Min(PerkTraits[i].CurrentLevel,PerkTraits[i].TraitType.Default.NumLevels);
			
			if( PerkTraits[i].TraitType.Default.LoadPriority>0 )
				MT = Max(MT,PerkTraits[i].TraitType.Default.LoadPriority);
			else
			{
				if( !PerkTraits[i].TraitType.Static.MeetsRequirements(PerkTraits[i].CurrentLevel-1,Self) )
					a = 0;
				else
				{
					for( a=0; a<PerkTraits[i].CurrentLevel; ++a )
					{
						b = PerkTraits[i].TraitType.Static.GetTraitCost(a);
						if( b>CurrentSP )
							break;
						CurrentSP-=b;
					}
				}
				PerkTraits[i].CurrentLevel = a;
				if( PerkTraits[i].CurrentLevel>0 && PerkTraits[i].Data==None )
					PerkTraits[i].Data = PerkTraits[i].TraitType.Static.InitializeFor(Self,ExtPlayerController(Owner));
			}
		}
		if( PerkTraits[i].CurrentLevel==0 && PerkTraits[i].Data!=None )
			PerkTraits[i].TraitType.Static.CleanupTrait(ExtPlayerController(Owner),Self,PerkTraits[i].Data);
	}
	
	// Delayed loads.
	for( j=1; j<=MT; ++j )
	{
		for( i=0; i<PerkTraits.Length; ++i )
		{
			if( PerkTraits[i].CurrentLevel>0 && PerkTraits[i].TraitType.Default.LoadPriority==j )
			{
				if( !PerkTraits[i].TraitType.Static.MeetsRequirements(PerkTraits[i].CurrentLevel-1,Self) )
					a = 0;
				else
				{
					for( a=0; a<PerkTraits[i].CurrentLevel; ++a )
					{
						b = PerkTraits[i].TraitType.Static.GetTraitCost(a);
						if( b>CurrentSP )
							break;
						CurrentSP-=b;
					}
				}
				PerkTraits[i].CurrentLevel = a;
				if( PerkTraits[i].CurrentLevel>0 && PerkTraits[i].Data==None )
					PerkTraits[i].Data = PerkTraits[i].TraitType.Static.InitializeFor(Self,ExtPlayerController(Owner));
			}
			if( PerkTraits[i].CurrentLevel==0 && PerkTraits[i].Data!=None )
				PerkTraits[i].TraitType.Static.CleanupTrait(ExtPlayerController(Owner),Self,PerkTraits[i].Data);
		}
	}

	ApplyEffects();
	if( PerkManager.CurrentPerk==Self )
		ActivateTraits();
}

// Check the needed amount of EXP for a perk.
function int GetNeededExp( int LevelNum )
{
	if( LevelNum<MinimumLevel || LevelNum>=MaximumLevel )
		return 0;
	LevelNum-=MinimumLevel;
	LevelNum = (FirstLevelExp+(LevelNum*LevelUpExpCost)+(LevelNum*LevelNum*LevelUpIncCost));
	if( CurrentPrestige>0 && PrestigeXPReduce>0 )
		LevelNum *= (1.f / (1.f + PrestigeXPReduce*CurrentPrestige));
	return LevelNum;
}

// Configure initialization.
static function CheckConfig()
{
	local int i;
	local class<Ext_TraitBase> T;

	if( Default.ConfigVersion!=Default.CurrentConfigVer )
	{
		UpdateConfigs(Default.ConfigVersion);
		Default.ConfigVersion = Default.CurrentConfigVer;
		StaticSaveConfig();
	}
	for( i=0; i<Default.TraitClasses.Length; ++i )
	{
		T = class<Ext_TraitBase>(DynamicLoadObject(Default.TraitClasses[i],Class'Class'));
		if( T!=None )
			T.Static.CheckConfig();
	}
}
static function UpdateConfigs( int OldVer )
{
	local int i,j;

	if( OldVer==0 )
	{
		Default.FirstLevelExp = 400;
		Default.LevelUpExpCost = 500;
		Default.LevelUpIncCost = 65;
		Default.MinimumLevel = 0;
		Default.MaximumLevel = 150;
		Default.StarPointsPerLevel = 15;
		
		// Prestige.
		Default.MinLevelForPrestige = 140;
		Default.PrestigeSPIncrease = 1;
		Default.MaxPrestige = 20;
		Default.PrestigeXPReduce = 0.05;
		
		Default.PerkStats.Length = 0;
		AddStatsCfg(0);
		Default.TraitClasses.Length = Default.DefTraitList.Length;
		for( i=0; i<Default.DefTraitList.Length; ++i )
			Default.TraitClasses[i] = PathName(Default.DefTraitList[i]);
	}
	else
	{
		// Add progress.
		if( OldVer==1 )
		{
			for( i=0; i<Default.PerkStats.Length; ++i )
			{
				j = Default.DefPerkStats.Find('StatType',Default.PerkStats[i].StatType);
				if( j>=0 )
					Default.PerkStats[i].Progress = Default.DefPerkStats[j].Progress;
			}
			// Add off-perk damage stat.
			AddStatsCfg(12);
		}
		else if( OldVer<=3 )
			AddStatsCfg(13); // Add self damage.
		else if( OldVer<=4 )
			AddStatsCfg(15); // Add poison damage.
		else if( OldVer<=7 )
			AddStatsCfg(16); // Add sonic/fire damage.
		else if( OldVer<=12 )
			AddStatsCfg(18); // Add all damage.
		if( OldVer<=5 )
		{
			// Add prestige
			Default.MinLevelForPrestige = 140;
			Default.PrestigeSPIncrease = 1;
			Default.MaxPrestige = 20;
			Default.PrestigeXPReduce = 0.05;
		}

		Default.TraitClasses.Length = Default.DefTraitList.Length;
		for( i=0; i<Default.DefTraitList.Length; ++i )
			Default.TraitClasses[i] = PathName(Default.DefTraitList[i]);
	}
}
static final function AddStatsCfg( int StartRange )
{
	local int i,j;

	j = Default.PerkStats.Length;
	for( i=StartRange; i<Default.DefPerkStats.Length; ++i )
	{
		if( Default.DefPerkStats[i].bHiddenConfig || Default.PerkStats.Find('StatType',Default.DefPerkStats[i].StatType)>=0 ) // Don't add if already found for some reason.
			continue;
		Default.PerkStats.Length = j+1;
		Default.PerkStats[j].MaxValue = Default.DefPerkStats[i].MaxValue;
		Default.PerkStats[j].CostPerValue = Default.DefPerkStats[i].CostPerValue;
		Default.PerkStats[j].StatType = Default.DefPerkStats[i].StatType;
		Default.PerkStats[j].Progress = Default.DefPerkStats[i].Progress;
		++j;
	}
}

// WebAdmin UI stuff.
static function InitWebAdmin( ExtWebAdmin_UI UI )
{
	local class<Ext_TraitBase> T;
	local int i;

	UI.AddSettingsPage("Perk "$Default.PerkName,Default.Class,Default.WebConfigs,GetValue,ApplyValue);
	
	for( i=0; i<Default.TraitClasses.Length; ++i )
	{
		T = class<Ext_TraitBase>(DynamicLoadObject(Default.TraitClasses[i],Class'Class'));
		if( T==None || UI.HasConfigFor(T) )
			continue;
		T.Static.InitWebAdmin(UI);
	}
}
static function string GetValue( name PropName, int ElementIndex )
{
	switch( PropName )
	{
	case 'FirstLevelExp':
		return string(Default.FirstLevelExp);
	case 'LevelUpExpCost':
		return string(Default.LevelUpExpCost);
	case 'LevelUpIncCost':
		return string(Default.LevelUpIncCost);
	case 'MinimumLevel':
		return string(Default.MinimumLevel);
	case 'MaximumLevel':
		return string(Default.MaximumLevel);
	case 'StarPointsPerLevel':
		return string(Default.StarPointsPerLevel);
	case 'TraitClasses':
		return ElementIndex==-1 ? string(Default.TraitClasses.Length) : Default.TraitClasses[ElementIndex];
	case 'PerkStats':
		return ElementIndex==-1 ? string(Default.PerkStats.Length) : Default.PerkStats[ElementIndex].StatType$","$Default.PerkStats[ElementIndex].MaxValue$","$Default.PerkStats[ElementIndex].CostPerValue$","$Default.PerkStats[ElementIndex].Progress;
	case 'MinLevelForPrestige':
		return string(Default.MinLevelForPrestige);
	case 'PrestigeSPIncrease':
		return string(Default.PrestigeSPIncrease);
	case 'MaxPrestige':
		return string(Default.MaxPrestige);
	case 'PrestigeXPReduce':
		return string(Default.PrestigeXPReduce);
	}
}
static function ApplyValue( name PropName, int ElementIndex, string Value )
{
	switch( PropName )
	{
	case 'FirstLevelExp':
		Default.FirstLevelExp = int(Value);		break;
	case 'LevelUpExpCost':
		Default.LevelUpExpCost = int(Value);	break;
	case 'LevelUpIncCost':
		Default.LevelUpIncCost = int(Value);	break;
	case 'MinimumLevel':
		Default.MinimumLevel = int(Value);		break;
	case 'MaximumLevel':
		Default.MaximumLevel = int(Value);		break;
	case 'StarPointsPerLevel':
		Default.StarPointsPerLevel = int(Value); break;
	case 'TraitClasses':
		if( Value=="#DELETE" )
			Default.TraitClasses.Remove(ElementIndex,1);
		else
		{
			if( ElementIndex>=Default.TraitClasses.Length )
				Default.TraitClasses.Length = ElementIndex+1;
			Default.TraitClasses[ElementIndex] = Value;
		}
		break;
	case 'PerkStats':
		if( Value=="#DELETE" )
			Default.PerkStats.Remove(ElementIndex,1);
		else
		{
			if( ElementIndex>=Default.PerkStats.Length )
				Default.PerkStats.Length = ElementIndex+1;
			Default.PerkStats[ElementIndex] = ParsePerkStatStr(Value);
		}
		break;
	case 'MinLevelForPrestige':
		Default.MinLevelForPrestige = int(Value); break;
	case 'PrestigeSPIncrease':
		Default.PrestigeSPIncrease = int(Value); break;
	case 'MaxPrestige':
		Default.MaxPrestige = int(Value);		break;
	case 'PrestigeXPReduce':
		Default.PrestigeXPReduce = float(Value); break;
	default:
		return;
	}
	StaticSaveConfig();
}
static final function FPerkStat ParsePerkStatStr( string S )
{
	local FPerkStat Res;
	local int i;

	i = InStr(S,",");
	if( i==-1 )
		return Res;
	Res.StatType = name(Left(S,i));
	S = Mid(S,i+1);
	i = InStr(S,",");
	if( i==-1 )
		return Res;
	Res.MaxValue = int(Left(S,i));
	S = Mid(S,i+1);
	i = InStr(S,",");
	if( i==-1 )
		return Res;
	Res.CostPerValue = int(Left(S,i));
	Res.Progress = float(Mid(S,i+1));
	return Res;
}

// Amount and iStat values are verified already by ServerExtMut.
function bool IncrementStat( int iStat, int Amount )
{
	PerkStats[iStat].CurrentValue+=Amount;
	if( bOwnerNetClient )
		ClientSetStatValue(iStat,PerkStats[iStat].CurrentValue);
	PerkManager.bStatsDirty = true;
	ApplyEffects();
	bForceNetUpdate = true;
	return true;
}

simulated function ApplyEffects()
{
	local int i;
	
	for( i=0; i<PerkStats.Length; ++i )
	{
		if( PerkStats[i].CurrentValue!=PerkStats[i].OldValue )
		{
			PerkStats[i].OldValue = PerkStats[i].CurrentValue;
			PerkStats[i].DisplayValue = ApplyEffect(PerkStats[i].StatType,PerkStats[i].CurrentValue,PerkStats[i].Progress/100.f);
		}
	}
}

// Notify that player just spawned.
function ApplyEffectsTo( KFPawn_Human P )
{
	local int i;
	local bool bSec;
	
	for( i=0; i<PerkTraits.Length; ++i )
	{
		if( PerkTraits[i].CurrentLevel>0 )
		{
			if( PerkTraits[i].TraitType.Default.bPostApplyEffect )
				bSec = true;
			else PerkTraits[i].TraitType.Static.ApplyEffectOn(P,Self,PerkTraits[i].CurrentLevel,PerkTraits[i].Data);
		}
	}
	if( bSec )
	{
		for( i=0; i<PerkTraits.Length; ++i )
		{
			if( PerkTraits[i].CurrentLevel>0 && PerkTraits[i].TraitType.Default.bPostApplyEffect )
				PerkTraits[i].TraitType.Static.ApplyEffectOn(P,Self,PerkTraits[i].CurrentLevel,PerkTraits[i].Data);
		}
	}
}

// Player joined/perk changed.
function ActivateTraits()
{
	local int i;
	local KFPawn_Human KFP;
	local bool bSec;
	
	KFP = KFPawn_Human(PlayerOwner.Pawn);
	if( KFP!=None && !KFP.IsAliveAndWell() )
		KFP = None;

	for( i=0; i<PerkTraits.Length; ++i )
	{
		if( PerkTraits[i].CurrentLevel>0 )
		{
			PerkTraits[i].TraitType.Static.TraitActivate(Self,PerkTraits[i].CurrentLevel,PerkTraits[i].Data);
			if( KFP!=None )
			{
				if( PerkTraits[i].TraitType.Default.bPostApplyEffect )
					bSec = true;
				else PerkTraits[i].TraitType.Static.ApplyEffectOn(KFP,Self,PerkTraits[i].CurrentLevel,PerkTraits[i].Data);
			}
		}
	}
	if( bSec )
	{
		for( i=0; i<PerkTraits.Length; ++i )
		{
			if( PerkTraits[i].CurrentLevel>0 && PerkTraits[i].TraitType.Default.bPostApplyEffect )
				PerkTraits[i].TraitType.Static.ApplyEffectOn(KFP,Self,PerkTraits[i].CurrentLevel,PerkTraits[i].Data);
		}
	}
}

// Player disconnected/perk changed.
function DeactivateTraits()
{
	local int i;
	
	for( i=0; i<PerkTraits.Length; ++i )
	{
		if( PerkTraits[i].CurrentLevel>0 )
			PerkTraits[i].TraitType.Static.TraitDeActivate(Self,PerkTraits[i].CurrentLevel,PerkTraits[i].Data);
	}
}

simulated unreliable client function ClientAuth()
{
	if( Owner==None )
		SetOwner(PlayerOwner);
	ServerAck();
}
unreliable server function ServerAck()
{
	if( !bClientAuthorized )
	{
		bClientAuthorized = true;
		RepState = 0;
		RepIndex = 0;
		SetTimer(0.01+FRand()*0.025,true,'ReplicateTimer');
	}
}
function ReplicateTimer()
{
	switch( RepState )
	{
	case 0: // Send all perk stats
		if( RepIndex>=PerkStats.Length )
		{
			++RepState;
			RepIndex = 0;
		}
		else
		{
			ClientReceiveStat(RepIndex,PerkStats[RepIndex].MaxValue,PerkStats[RepIndex].CostPerValue,PerkStats[RepIndex].StatType,PerkStats[RepIndex].CurrentValue,PerkStats[RepIndex].Progress);
			++RepIndex;
		}
		break;
	case 1: // Send all traits
		if( RepIndex>=PerkTraits.Length )
			++RepState;
		else
		{
			ClientReceiveTrait(RepIndex,PerkTraits[RepIndex].TraitType,PerkTraits[RepIndex].CurrentLevel);
			ClientReceiveTraitData(RepIndex,PerkTraits[RepIndex].TraitType.Static.GetRepData());
			++RepIndex;
		}
		break;
	default:
		ClearTimer('ReplicateTimer');
		bPerkNetReady = true;
		ClientIsReady(); // Notify client were ready.
	}
}
simulated reliable client function ClientIsReady()
{
	bPerkNetReady = true;
	ApplyEffects();
}
simulated function string GetStatUIStr( int iStat )
{
	local string S;
	local bool bLoop;

	S = string(Abs(PerkStats[iStat].DisplayValue*100.f));
	bLoop = true;

	// Chop off float digits that aren't needed.
	while( bLoop )
	{
		switch( Right(S,1) )
		{
		case "0":
			S = Left(S,Len(S)-1);
			break;
		case ".":
			S = Left(S,Len(S)-1);
			bLoop = false;
			break;
		default:
			bLoop = false;
		}
	}
	return Repl(PerkStats[iStat].UIName,"&",S);
}

final function UnloadStats( optional byte Mode )
{
	local int i,j;
	local KFPawn_Human KFP;

	PerkManager.bStatsDirty = true;
	if( Mode<=1 )
	{
		// Reset stats.
		for( i=0; i<PerkStats.Length; ++i )
		{
			if( PerkStats[i].CurrentValue>0 )
			{
				CurrentSP+=(PerkStats[i].CurrentValue*PerkStats[i].CostPerValue);
				PerkStats[i].CurrentValue = 0;
				if( bOwnerNetClient )
					ClientSetStatValue(i,0);
			}
		}
		ApplyEffects();
	}
	if( Mode==0 || Mode==2 )
	{
		KFP = KFPawn_Human(PlayerOwner.Pawn);
		if( KFP!=None && !KFP.IsAliveAndWell() )
			KFP = None;

		// Reset traits.
		for( i=0; i<PerkTraits.Length; ++i )
		{
			if( PerkTraits[i].CurrentLevel>0 )
			{
				for( j=0; j<PerkTraits[i].CurrentLevel; ++j )
					CurrentSP+=PerkTraits[i].TraitType.Static.GetTraitCost(j);
				if( PerkManager.CurrentPerk==Self )
				{
					PerkTraits[i].TraitType.Static.TraitDeActivate(Self,PerkTraits[i].CurrentLevel,PerkTraits[i].Data);
					if( KFP!=None )
						PerkTraits[i].TraitType.Static.CancelEffectOn(KFP,Self,PerkTraits[i].CurrentLevel,PerkTraits[i].Data);
				}
				PerkTraits[i].TraitType.Static.CleanupTrait(ExtPlayerController(Owner),Self,PerkTraits[i].Data);
				PerkTraits[i].CurrentLevel = 0;
				if( bOwnerNetClient )
					ClientReceiveTraitLvl(i,0);
			}
		}
	}
}
function FullReset( optional bool bNotPrestige )
{
	UnloadStats();

	// Set minimum values.
	CurrentEXP = 0;
	if( !bNotPrestige )
		CurrentPrestige = 0;
	CurrentLevel = MinimumLevel;
	CurrentSP = CurrentLevel*(StarPointsPerLevel+CurrentPrestige*PrestigeSPIncrease);
	NextLevelEXP = GetNeededExp(CurrentLevel);
	LastLevelEXP = 0;
	
	if( PerkManager.CurrentPerk==Self && PerkManager.PRIOwner!=None )
	{
		PerkManager.PRIOwner.SetLevelProgress(CurrentLevel,CurrentPrestige,MinimumLevel,MaximumLevel);
		PerkManager.PRIOwner.bForceNetUpdate = true;
	}

	bForceNetUpdate = true;
}

function bool PreventDeath( KFPawn_Human Player, Controller Killer, Class<DamageType> DamType )
{
	local int i;
	
	// Doing 2 passes of this so that things don't go out of order (spawn retaliation effect when you get redeemed etc)
	for( i=0; i<PerkTraits.Length; ++i )
	{
		if( PerkTraits[i].CurrentLevel>0 && PerkTraits[i].TraitType.Default.bHighPriorityDeath && PerkTraits[i].TraitType.Static.PreventDeath(Player,Killer,DamType,Self,PerkTraits[i].CurrentLevel,PerkTraits[i].Data) )
			return true;
	}
	for( i=0; i<PerkTraits.Length; ++i )
	{
		if( PerkTraits[i].CurrentLevel>0 && !PerkTraits[i].TraitType.Default.bHighPriorityDeath && PerkTraits[i].TraitType.Static.PreventDeath(Player,Killer,DamType,Self,PerkTraits[i].CurrentLevel,PerkTraits[i].Data) )
			return true;
	}
	return false;
}

simulated function PlayerDied()
{
	local int i;

	if( WorldInfo.NetMode!=NM_Client )
	{
		for( i=0; i<PerkTraits.Length; ++i )
		{
			if( PerkTraits[i].CurrentLevel>0 )
				PerkTraits[i].TraitType.Static.PlayerDied(Self,PerkTraits[i].CurrentLevel,PerkTraits[i].Data);
		}
	}
}

// Stat modifier functions.
simulated function float ApplyEffect( name Type, float Value, float Progress )
{
	local bool bActivePerk;
	
	bActivePerk = (PerkManager!=None && PerkManager.CurrentPerk==Self);
	switch( Type )
	{
	case 'Speed':
		Modifiers[0] = 1.f + (Value*Progress);
		break;
	case 'Damage':
		Modifiers[1] = 1.f + (Value*Progress);
		break;
	case 'Recoil':
		Modifiers[2] = 1.f / (1.f+Value*Progress);
		break;
	case 'Spread':
		Modifiers[3] = 1.f / (1.f+Value*Progress);
		break;
	case 'Rate':
		Modifiers[4] = 1.f / (1.f+Value*Progress);
		break;
	case 'Reload':
		Modifiers[5] = 1.f / (1.f+Value*Progress);
		break;
	case 'Health':
		Modifiers[6] = 1.f + (Value*Progress);
		if( bActivePerk && PlayerOwner.Pawn!=None )
		{
			PlayerOwner.Pawn.HealthMax = PlayerOwner.Pawn.Default.Health;
			ModifyHealth(PlayerOwner.Pawn.HealthMax);
		}
		break;
	case 'KnockDown':
		Modifiers[7] = FMin(1.f + (Value*Progress),2.f);
		return (Modifiers[7]-1.f);
	case 'Welder':
		Modifiers[8] = 1.f + (Value*Progress);
		break;
	case 'Heal':
		Modifiers[9] = 1.f + (Value*Progress);
		break;
	case 'Mag':
		Modifiers[10] = 1.f + (Value*Progress);
		if( bActivePerk && WorldInfo.NetMode!=NM_Client && PlayerOwner.Pawn!=None && PlayerOwner.Pawn.InvManager!=None )
			UpdateAmmoStatus(PlayerOwner.Pawn.InvManager);
		break;
	case 'Spare':
		Modifiers[11] = 1.f + (Value*Progress);
		if( bActivePerk && WorldInfo.NetMode!=NM_Client && PlayerOwner.Pawn!=None && PlayerOwner.Pawn.InvManager!=None )
			UpdateAmmoStatus(PlayerOwner.Pawn.InvManager);
		break;
	case 'OffDamage':
		Modifiers[12] = 1.f + (Value*Progress);
		break;
	case 'SelfDamage':
		Modifiers[13] = 1.f / (1.f+Value*Progress);
		break;
	case 'Armor':
		Modifiers[14] = (Value*Progress*100.f);
		if( bActivePerk && KFPawn_Human(PlayerOwner.Pawn)!=None )
		{
			KFPawn_Human(PlayerOwner.Pawn).MaxArmor = KFPawn_Human(PlayerOwner.Pawn).Default.MaxArmor;
			ModifyArmor(KFPawn_Human(PlayerOwner.Pawn).MaxArmor);
		}
		return FMin(Value*Progress,1.55);
	case 'PoisonDmg':
		Modifiers[15] = 1.f / (1.f+Value*Progress);
		break;
	case 'SonicDmg':
		Modifiers[16] = 1.f / (1.f+Value*Progress);
		break;
	case 'FireDmg':
		Modifiers[17] = 1.f / (1.f+Value*Progress);
		break;
	case 'AllDmg':
		Modifiers[18] = 1.f / (1.f+Value*Progress);
		break;
	}
	return (Value*Progress);
}

simulated function ModifyDamageGiven( out int InDamage, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx )
{
	if( BasePerk==None || (DamageType!=None && DamageType.Default.ModifierPerkList.Find(BasePerk)>=0) || (KFWeapon(DamageCauser)!=None && IsWeaponOnPerk(KFWeapon(DamageCauser))) )
		InDamage *= Modifiers[1];
	else if( DamageType==None || DamageType.Name!='KFDT_SuicideExplosive' )
		InDamage *= Modifiers[12];
}
simulated function ModifyDamageTaken( out int InDamage, optional class<DamageType> DamageType, optional Controller InstigatedBy )
{
	if( InDamage>0 )
	{
		if( (InstigatedBy==None || InstigatedBy==PlayerOwner) && class<KFDamageType>(DamageType)!=None )
			InDamage *= Modifiers[13];
		else if( Modifiers[15]<1 && class<KFDT_Toxic>(DamageType)!=None )
			InDamage = Max(InDamage*Modifiers[15],1); // Do at least 1 damage.
		else if( Modifiers[16]<1 && class<KFDT_Sonic>(DamageType)!=None )
			InDamage = Max(InDamage*Modifiers[16],1);
		else if( Modifiers[17]<1 && class<KFDT_Fire>(DamageType)!=None )
			InDamage = Max(InDamage*Modifiers[17],1);
		if( Modifiers[18]<1 && InstigatedBy!=None && InstigatedBy!=PlayerOwner )
			InDamage = Max(InDamage*Modifiers[18],1);
	}
}
simulated function ModifyRecoil( out float CurrentRecoilModifier, KFWeapon KFW )
{
	if( IsWeaponOnPerk(KFW) )
		CurrentRecoilModifier *= Modifiers[2];
}
simulated function ModifySpread( out float InSpread )
{
	InSpread *= Modifiers[3];
}
simulated function ModifyRateOfFire( out float InRate, KFWeapon KFW )
{
	if( IsWeaponOnPerk(KFW) )
		InRate *= Modifiers[4];
}
simulated function float GetReloadRateScale(KFWeapon KFW)
{
	return (IsWeaponOnPerk(KFW) ? Modifiers[5] : 1.f);
}
function ModifyHealth( out int InHealth )
{
	InHealth *= Modifiers[6];
}
function ModifyArmor( out byte MaxArmor )
{
	MaxArmor = Min(MaxArmor+Modifiers[14],255);
}
function float GetKnockdownPowerModifier()
{
	return Modifiers[7];
}
function float GetStunPowerModifier( optional class<DamageType> DamageType, optional byte HitZoneIdx )
{
	return Modifiers[7];
}

simulated function ModifyMeleeAttackSpeed( out float InDuration );

function AddDefaultInventory( KFPawn P )
{
	local int i;

	if( PrimaryWeapon!=None )
		P.DefaultInventory.AddItem(PrimaryWeapon);
	P.DefaultInventory.AddItem(PrimaryMelee);
	if( KFInventoryManager(P.InvManager)!=None )
		KFInventoryManager(P.InvManager).MaxCarryBlocks = KFInventoryManager(P.InvManager).Default.MaxCarryBlocks+Modifiers[10];
	
	for( i=0; i<PerkTraits.Length; ++i )
	{
		if( PerkTraits[i].CurrentLevel>0 )
			PerkTraits[i].TraitType.Static.AddDefaultInventory(P,Self,PerkTraits[i].CurrentLevel,PerkTraits[i].Data);
	}
}

simulated function ModifyWeldingRate( out float FastenRate, out float UnfastenRate )
{
	FastenRate *= Modifiers[8];
	UnfastenRate *= Modifiers[8];
}

function bool RepairArmor( Pawn HealTarget )
{
	return false;
}
function bool ModifyHealAmount( out float HealAmount )
{
	HealAmount*=Modifiers[9];
	return false;
}
simulated function ModifyMagSizeAndNumber( KFWeapon KFW, out byte MagazineCapacity, optional array< Class<KFPerk> > WeaponPerkClass, optional bool bSecondary=false, optional name WeaponClassname )
{
	if( MagazineCapacity>2 && (KFW==None ? WeaponPerkClass.Find(BasePerk)>=0 : IsWeaponOnPerk(KFW)) ) // Skip boomstick for this.
		MagazineCapacity = Min(MagazineCapacity*Modifiers[10],255);
}
simulated function ModifySpareAmmoAmount( KFWeapon KFW, out int PrimarySpareAmmo, optional const out STraderItem TraderItem, optional bool bSecondary )
{
	if( KFW==None ? TraderItem.AssociatedPerkClasses.Find(BasePerk)>=0 : IsWeaponOnPerk(KFW) )
		PrimarySpareAmmo*=Modifiers[11];
}
simulated function bool ShouldMagSizeModifySpareAmmo( KFWeapon KFW, optional Class<KFPerk> WeaponPerkClass )
{
	return (KFW==None ? WeaponPerkClass==BasePerk : IsWeaponOnPerk(KFW));
}

final function UpdateAmmoStatus( InventoryManager Inv )
{
	local KFWeapon W;

	foreach Inv.InventoryActors(class'KFWeapon',W)
	{
		if( IsWeaponOnPerk(W) )
			W.ReInitializeAmmoCounts(PerkManager);
	}
}

simulated function ModifyHealerRechargeTime( out float RechargeRate );

simulated function DrawSpecialPerkHUD(Canvas C)
{
	if( EnemyHealthRange>0 && PlayerOwner!=None && KFPawn_Human(PlayerOwner.Pawn)!=None )
		DrawEnemyHealth(C);
}

simulated final function DrawEnemyHealth( Canvas C )
{
	local KFPawn_Monster KFPM;
	local vector X,CameraLocation;
	
	X = vector(PlayerOwner.Pawn.GetViewRotation());
	CameraLocation = PlayerOwner.Pawn.GetPawnViewLocation();

	foreach WorldInfo.AllPawns(class'KFPawn_Monster',KFPM,CameraLocation,EnemyDistDraw[EnemyHealthRange-1])
	{
		if( KFPM.IsAliveAndWell() && `TimeSince(KFPM.Mesh.LastRenderTime)<0.1f && KFPM.CanShowHealth() && KFPM.GetTeamNum()!=0 && (X Dot (KFPM.Location - CameraLocation))>0 )
			DrawZedHealthbar(C,KFPM,CameraLocation);
	}
}

simulated final function DrawZedHealthbar(Canvas C, KFPawn_Monster KFPM, vector CameraLocation )
{
	local vector ScreenPos, TargetLocation;
	local float HealthBarLength, HealthbarHeight, HealthScale;

	HealthbarLength = FMin(50.f * (float(C.SizeX) / 1024.f), 50.f) * class'KFGFxHudWrapper'.Default.FriendlyHudScale;
	HealthbarHeight = FMin(6.f * (float(C.SizeX) / 1024.f), 6.f) * class'KFGFxHudWrapper'.Default.FriendlyHudScale;
	HealthScale = FClamp(float(KFPM.Health) / float(KFPM.HealthMax),0.f,1.f);

	if( KFPM.bCrawler && KFPM.Floor.Z <=  -0.7f && KFPM.Physics == PHYS_Spider )
	{
		TargetLocation = KFPM.Location + vect(0,0,-1) * KFPM.GetCollisionHeight() * 1.2;
	}
	else
	{
		TargetLocation = KFPM.Location + vect(0,0,1) * KFPM.GetCollisionHeight() * 1.2;
	}

	ScreenPos = C.Project(TargetLocation);
	if( ScreenPos.X < 0 || ScreenPos.X > C.SizeX || ScreenPos.Y < 0 || ScreenPos.Y > C.SizeY || !FastTrace(TargetLocation,  CameraLocation) )
		return;

	C.EnableStencilTest(true);
	C.SetDrawColor(0, 0, 0, 255);
	C.SetPos(ScreenPos.X - HealthBarLength * 0.5, ScreenPos.Y);
	C.DrawTileStretched(class'KFPerk_Commando'.Default.WhiteMaterial, HealthbarLength, HealthbarHeight, 0, 0, 32, 32);

	C.SetDrawColor(237, 8, 0, 255);
	C.SetPos(ScreenPos.X - HealthBarLength * 0.5 + 1.0, ScreenPos.Y + 1.0);
	C.DrawTileStretched(class'KFPerk_Commando'.Default.WhiteMaterial, (HealthBarLength - 2.0) * HealthScale, HealthbarHeight - 2.0, 0, 0, 32, 32);
	C.EnableStencilTest(false);
}

function PlayerKilled( KFPawn_Monster Victim, class<DamageType> DamageType );

function ModifyBloatBileDoT( out float DoTScaler )
{
	DoTScaler = Modifiers[15];
}

simulated function bool GetIsUberAmmoActive( KFWeapon KFW )
{
	return false;
}

function UpdatePerkHeadShots( ImpactInfo Impact, class<DamageType> DamageType, int NumHit );

function CheckForAirborneAgent( KFPawn HealTarget, class<DamageType> DamType, int HealAmount );

simulated function float GetZedTimeModifier( KFWeapon W )
{
	return 0.f;
}

simulated function bool GetUsingTactialReload( KFWeapon KFW )
{
	return (bTacticalReload && IsWeaponOnPerk(KFW));
}

simulated function float GetIronSightSpeedModifier( KFWeapon KFW )
{
	return 1.f;
}

function OnWaveEnded();
function NotifyZedTimeStarted();

simulated function float GetZedTimeExtensions( byte Level )
{
	return 1.f;
}

defaultproperties
{
	CurrentConfigVer=13
	bOnlyRelevantToOwner=true
	bCanBeGrabbed=true
	NetUpdateFrequency=1
	GrenadeClass=class'KFProj_FragGrenade'
	PerkGrenade=class'KFProj_FragGrenade'
	SuperGrenade=class'ExtProj_SUPERGrenade'
	HealExpUpNum=12
	WeldExpUpNum=180
	ToxicDartDamage=15
	NetPriority=4
	
	SecondaryWeaponDef=class'KFWeapDef_9mm'
	KnifeWeaponDef=class'KFWeapDef_Knife_Commando'
	GrenadeWeaponDef=class'KFWeapDef_Grenade_Support'
	
	DefTraitList.Add(class'Ext_TraitGrenadeUpg')
	DefTraitList.Add(class'Ext_TraitNightvision')
	DefTraitList.Add(class'Ext_TraitAmmoReg')
	DefTraitList.Add(class'Ext_TraitHealthReg')
	DefTraitList.Add(class'Ext_TraitArmorReg')
	DefTraitList.Add(class'Ext_TraitCarryCap')
	DefTraitList.Add(class'Ext_TraitGrenadeCap')
	DefTraitList.Add(class'Ext_TraitMedicPistol')
	DefTraitList.Add(class'Ext_TraitZED_Summon')
	DefTraitList.Add(class'Ext_TraitZED_Health')
	DefTraitList.Add(class'Ext_TraitZED_Damage')
	DefTraitList.Add(class'Ext_TraitZED_SummonExt')
	DefTraitList.Add(class'Ext_TraitGhost')
	DefTraitList.Add(class'Ext_TraitRetali')
	DefTraitList.Add(class'Ext_TraitDuracell')
	DefTraitList.Add(class'Ext_TraitRagdoll')
	DefTraitList.Add(class'Ext_TraitAutoFire')
	DefTraitList.Add(class'Ext_TraitBunnyHop')
	DefTraitList.Add(class'Ext_TraitKnockback')

	WebConfigs.Add((PropType=0,PropName="FirstLevelExp",UIName="First Level XP",UIDesc="EXP required for the FIRST level"))
	WebConfigs.Add((PropType=0,PropName="LevelUpExpCost",UIName="Level Up XP",UIDesc="EXP cost for every next level (Level * ThisValue"))
	WebConfigs.Add((PropType=0,PropName="LevelUpIncCost",UIName="Level Up Inc XP",UIDesc="Increased EXP cost for every level ((Level^2) * ThisValue)"))
	WebConfigs.Add((PropType=0,PropName="MinimumLevel",UIName="Minimum Level",UIDesc="The minimum level of players"))
	WebConfigs.Add((PropType=0,PropName="MaximumLevel",UIName="Maximum Level",UIDesc="The maximum level of players"))
	WebConfigs.Add((PropType=0,PropName="StarPointsPerLevel",UIName="Star Points Per Lvl",UIDesc="Number of star points players earn per level"))
	WebConfigs.Add((PropType=2,PropName="TraitClasses",UIName="Trait Classes",UIDesc="The class names of traits players can buy",NumElements=-1))
	WebConfigs.Add((PropType=2,PropName="PerkStats",UIName="Perk Stats",UIDesc="List of perk stats (format in: StatName,Max Stat,Cost Per Stat,Progress Per Level)",NumElements=-1))
	WebConfigs.Add((PropType=0,PropName="MinLevelForPrestige",UIName="Min Level For Prestige",UIDesc="Minimum level required to prestige the perk (-1 = disabled)"))
	WebConfigs.Add((PropType=0,PropName="PrestigeSPIncrease",UIName="Prestige SP Increase",UIDesc="Star points increase per level for every prestige"))
	WebConfigs.Add((PropType=0,PropName="MaxPrestige",UIName="Max Prestige",UIDesc="Maximum prestige level"))
	WebConfigs.Add((PropType=0,PropName="PrestigeXPReduce",UIName="Prestige XP Reduce",UIDesc="Percent amount of XP cost is reduced for each prestige (1.0 = 1/2, or 50 % of XP)"))
	
	DefPerkStats(0)=(MaxValue=50,CostPerValue=1,StatType="Speed",UIName="Movement Speed (+&%)",Progress=0.4)
	DefPerkStats(1)=(MaxValue=1000,CostPerValue=1,StatType="Damage",UIName="Perk Damage (+&%)",Progress=0.5)
	DefPerkStats(2)=(MaxValue=90,CostPerValue=1,StatType="Recoil",UIName="Fire Recoil (-&%)",Progress=1)
	DefPerkStats(3)=(MaxValue=80,CostPerValue=1,StatType="Spread",UIName="Fire Spread (-&%)",Progress=0.75)
	DefPerkStats(4)=(MaxValue=1000,CostPerValue=1,StatType="Rate",UIName="Perk Rate of Fire (+&%)",Progress=0.5)
	DefPerkStats(5)=(MaxValue=1000,CostPerValue=1,StatType="Reload",UIName="Perk Reload Time (-&%)",Progress=0.5)
	DefPerkStats(6)=(MaxValue=150,CostPerValue=1,StatType="Health",UIName="Health (+&HP)",Progress=1)
	DefPerkStats(7)=(MaxValue=100,CostPerValue=1,StatType="KnockDown",UIName="Knockback (+&%)",Progress=1)
	DefPerkStats(8)=(MaxValue=200,CostPerValue=1,StatType="Welder",UIName="Welding Rate (+&%)",bHiddenConfig=true,Progress=0.5)
	DefPerkStats(9)=(MaxValue=400,CostPerValue=1,StatType="Heal",UIName="Heal Efficiency (+&%)",bHiddenConfig=true,Progress=0.5)
	DefPerkStats(10)=(MaxValue=400,CostPerValue=1,StatType="Mag",UIName="Magazine Capacity (+&%)",Progress=1)
	DefPerkStats(11)=(MaxValue=500,CostPerValue=1,StatType="Spare",UIName="Max Ammo (+&%)",Progress=1)
	DefPerkStats(12)=(MaxValue=1000,CostPerValue=1,StatType="OffDamage",UIName="Off-Perk Damage (+&%)",Progress=0.25)
	DefPerkStats(13)=(MaxValue=1000,CostPerValue=1,StatType="SelfDamage",UIName="Self Damage Reduction (+&%)",Progress=1,bHiddenConfig=true)
	DefPerkStats(14)=(MaxValue=150,CostPerValue=1,StatType="Armor",UIName="Armor (+&)",Progress=1)
	DefPerkStats(15)=(MaxValue=1000,CostPerValue=1,StatType="PoisonDmg",UIName="Toxic Resistance (+&%)",Progress=1.5,bHiddenConfig=true)
	DefPerkStats(16)=(MaxValue=1000,CostPerValue=1,StatType="SonicDmg",UIName="Sonic Resistance (+&%)",Progress=1.5,bHiddenConfig=true)
	DefPerkStats(17)=(MaxValue=1000,CostPerValue=1,StatType="FireDmg",UIName="Fire Resistance (+&%)",Progress=1.5,bHiddenConfig=true)
	DefPerkStats(18)=(MaxValue=500,CostPerValue=1,StatType="AllDmg",UIName="Zed Damage Reduction (+&%)",Progress=0.25)

	Modifiers.Add(1.f)
	Modifiers.Add(1.f)
	Modifiers.Add(1.f)
	Modifiers.Add(1.f)
	Modifiers.Add(1.f)
	Modifiers.Add(1.f)
	Modifiers.Add(1.f)
	Modifiers.Add(1.f)
	Modifiers.Add(1.f)
	Modifiers.Add(1.f)
	Modifiers.Add(1.f)
	Modifiers.Add(1.f)
	Modifiers.Add(1.f)
	Modifiers.Add(1.f)
	Modifiers.Add(0.f)
	Modifiers.Add(1.f)
	Modifiers.Add(1.f)
	Modifiers.Add(1.f)
	Modifiers.Add(1.f)
	
	EnemyDistDraw.Add(500)
	EnemyDistDraw.Add(700)
	EnemyDistDraw.Add(1000)
	EnemyDistDraw.Add(1600)
}