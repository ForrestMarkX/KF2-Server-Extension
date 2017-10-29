/*
	Extended Perk Manager
	Written by Marco
*/
Class ExtPerkManager extends KFPerk;

enum EReplicateState
{
	REP_CustomCharacters,
	REP_CustomInventory,
	REP_PerkClasses,
	REP_Done
};
const CUR_SaveVersion=2;

var int UserDataVersion;
var transient float LastNapalmTime;

// Server -> Client rep status
var byte RepState;
var int RepIndex;

var array<Ext_PerkBase> UserPerks;
var Ext_PerkBase CurrentPerk;
var int ExpUpStatus[2];
var string StrPerkName;

var ExtPlayerReplicationInfo PRIOwner;
var Controller PlayerOwner;

// Stats
var int TotalEXP,TotalKills,TotalPlayTime;

var bool bStatsDirty,bServerReady,bUserStatsBroken,bCurrentlyHealing;

replication
{
	// Things the server should send to the client.
	if ( bNetDirty )
		CurrentPerk;
}

final function SetGrenadeCap( byte AddedCap )
{
	MaxGrenadeCount = Default.MaxGrenadeCount + AddedCap;
	if( RepState==REP_Done )
		ClientSetGrenadeCap(MaxGrenadeCount);
}
simulated reliable client function ClientSetGrenadeCap( byte NewCap )
{
	MaxGrenadeCount = NewCap;
}

function bool ApplyPerkClass( class<Ext_PerkBase> P )
{
	local int i;
	
	for( i=0; i<UserPerks.Length; ++i )
		if( UserPerks[i].Class==P )
		{
			ApplyPerk(UserPerks[i]);
			return true;
		}
	return false;
}
function bool ApplyPerkName( string S )
{
	local int i;
	
	for( i=0; i<UserPerks.Length; ++i )
		if( string(UserPerks[i].Class.Name)~=S )
		{
			ApplyPerk(UserPerks[i]);
			return true;
		}
	return false;
}
function ApplyPerk( Ext_PerkBase P )
{
	local KFPawn_Human HP;
	local KFInventoryManager InvMan;
	local Ext_T_ZEDHelper H;
	local int i;
	
	if( P==None )
		return;
		
	if( PlayerOwner.Pawn != None )
	{
		InvMan = KFInventoryManager(PlayerOwner.Pawn.InvManager);
		if( InvMan != None )
			InvMan.MaxCarryBlocks = InvMan.Default.MaxCarryBlocks;
			
		foreach PlayerOwner.Pawn.ChildActors(class'Ext_T_ZEDHelper',H)
		{
			H.Destroy();
		}
		
		HP = KFPawn_Human(PlayerOwner.Pawn);
		if( HP != None )
			HP.DefaultInventory = HP.Default.DefaultInventory;
	}
	
	if( CurrentPerk != None )
	{
		CurrentPerk.DeactivateTraits();
		
		for( i=0; i<CurrentPerk.PerkTraits.Length; ++i )
		{
			CurrentPerk.PerkTraits[i].TraitType.Static.CancelEffectOn(KFPawn_Human(PlayerOwner.Pawn),CurrentPerk,CurrentPerk.PerkTraits[i].CurrentLevel,CurrentPerk.PerkTraits[i].Data);
		}
	}
		
	bStatsDirty = true;
	CurrentPerk = P;
	
	if( PRIOwner!=None )
	{
		PRIOwner.ECurrentPerk = P.Class;
		PRIOwner.FCurrentPerk = P;
		P.UpdatePRILevel();
	}
	
	if( CurrentPerk!=None )
	{
		CurrentPerk.ActivateTraits();
		
		if( PlayerOwner.Pawn != None )
		{
			HP = KFPawn_Human(PlayerOwner.Pawn);
			if( HP != None )
			{
				HP.HealthMax = HP.default.Health;
				HP.MaxArmor = HP.default.MaxArmor;
			
				ModifyHealth(HP.HealthMax);
				ModifyArmor(HP.MaxArmor);
				
				if( HP.Health > HP.HealthMax ) HP.Health = HP.HealthMax;
				if( HP.Armor > HP.MaxArmor ) HP.Armor = HP.MaxArmor;
			}
		}
	}
}
simulated final function Ext_PerkBase FindPerk( class<Ext_PerkBase> P )
{
	local int i;
	
	for( i=0; i<UserPerks.Length; ++i )
		if( UserPerks[i].Class==P )
			return UserPerks[i];
	return None;
}

simulated function PostBeginPlay()
{
	SetTimer(0.01,false,'InitPerks');
	if( WorldInfo.NetMode!=NM_Client )
		SetTimer(1,true,'CheckPlayTime');
}

simulated function InitPerks()
{
	local Ext_PerkBase P;
	
	if( WorldInfo.NetMode==NM_Client )
	{
		foreach DynamicActors(class'Ext_PerkBase',P)
			if( P.PerkManager!=Self )
				RegisterPerk(P);
	}
	else if( PRIOwner!=PlayerOwner.PlayerReplicationInfo ) // See if was assigned an inactive PRI.
	{
		PRIOwner = ExtPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo);
		if( PRIOwner!=None )
		{
			if( CurrentPerk!=None )
			{
				PRIOwner.ECurrentPerk = CurrentPerk.Class;
				CurrentPerk.UpdatePRILevel();
			}
			PRIOwner.RepKills = TotalKills;
			PRIOwner.RepEXP = TotalEXP;
			PRIOwner.SetInitPlayTime(TotalPlayTime);
			PRIOwner.PerkManager = Self;
		}
	}
}
function CheckPlayTime()
{
	++TotalPlayTime; // Stats.
}
function ServerInitPerks()
{
	local int i;
	
	for( i=0; i<UserPerks.Length; ++i )
		UserPerks[i].SetInitialLevel();
	bServerReady = true;
	CurrentPerk = None;
	if( StrPerkName!="" )
		ApplyPerkName(StrPerkName);
	if( CurrentPerk==None )
		ApplyPerk(UserPerks[Rand(UserPerks.Length)]);
}

simulated function RegisterPerk( Ext_PerkBase P )
{
	UserPerks[UserPerks.Length] = P;
	P.PerkManager = Self;
}
simulated function UnregisterPerk( Ext_PerkBase P )
{
	UserPerks.RemoveItem(P);
	P.PerkManager = None;
}

function Destroyed()
{
	local int i;
	
	for( i=(UserPerks.Length-1); i>=0; --i )
	{
		UserPerks[i].PerkManager = None;
		UserPerks[i].Destroy();
	}
}

function EarnedEXP( int EXP, optional byte Mode )
{
	if( CurrentPerk!=None )
	{
		// Limit how much EXP we got for healing and welding.
		switch( Mode )
		{
		case 1:
			ExpUpStatus[0]+=EXP;
			EXP = ExpUpStatus[0]/CurrentPerk.WeldExpUpNum;
			if( EXP>0 )
				ExpUpStatus[0]-=(EXP*CurrentPerk.WeldExpUpNum);
			break;
		case 2:
			ExpUpStatus[1]+=EXP;
			EXP = ExpUpStatus[1]/CurrentPerk.HealExpUpNum;
			if( EXP>0 )
				ExpUpStatus[1]-=(EXP*CurrentPerk.HealExpUpNum);
			break;
		}
		if( EXP>0 && CurrentPerk.EarnedEXP(EXP) )
		{
			TotalEXP+=EXP;
			PRIOwner.RepEXP+=EXP;
			bStatsDirty = true;
		}
	}
}

// XML stat writing
function OutputXML( ExtStatWriter Data )
{
	local string S;
	local int i;

	Data.StartIntendent("user","ver",string(CUR_SaveVersion));
	Data.WriteValue("id64",OnlineSubsystemSteamworks(class'GameEngine'.Static.GetOnlineSubsystem()).UniqueNetIdToInt64(PRIOwner.UniqueId));
	Data.WriteValue("name",PRIOwner.PlayerName);
	Data.WriteValue("exp",string(TotalEXP));
	Data.WriteValue("kills",string(TotalKills));
	Data.WriteValue("time",string(TotalPlayTime));
	if( ExtPlayerController(Owner)!=None && ExtPlayerController(Owner).PendingPerkClass!=None )
		S = string(ExtPlayerController(Owner).PendingPerkClass.Name);
	else S = (CurrentPerk!=None ? string(CurrentPerk.Class.Name) : "None");
	Data.WriteValue("activeperk",S);

	for( i=0; i<UserPerks.Length; ++i )
		if( UserPerks[i].HasAnyProgress() )
			UserPerks[i].OutputXML(Data);

	Data.EndIntendent();
}

// Data saving.
function SaveData( ExtSaveDataBase Data )
{
	local int i,o;

	Data.FlushData();
	Data.SetSaveVersion(++UserDataVersion);
	Data.SetArVer(CUR_SaveVersion);

	// Write global stats.
	Data.SaveInt(TotalEXP,3);
	Data.SaveInt(TotalKills,3);
	Data.SaveInt(TotalPlayTime,3);
	
	// Write character.
	if( PRIOwner!=None )
		PRIOwner.SaveCustomCharacter(Data);
	else class'ExtPlayerReplicationInfo'.Static.DummySaveChar(Data);

	// Write selected perk.
	if( ExtPlayerController(Owner)!=None && ExtPlayerController(Owner).PendingPerkClass!=None )
		Data.SaveStr(string(ExtPlayerController(Owner).PendingPerkClass.Name));
	else Data.SaveStr(CurrentPerk!=None ? string(CurrentPerk.Class.Name) : "");

	// Count how many progressed perks we have.
	o = 0;
	for( i=0; i<UserPerks.Length; ++i )
		if( UserPerks[i].HasAnyProgress() )
			++o;
	
	// Then write count we have.
	Data.SaveInt(o);
	
	// Then perk stats.
	for( i=0; i<UserPerks.Length; ++i )
	{
		if( !UserPerks[i].HasAnyProgress() ) // Skip this perk.
			continue;

		Data.SaveStr(string(UserPerks[i].Class.Name));
		o = Data.TellOffset(); // Mark checkpoint.
		Data.SaveInt(0,1); // Reserve space for later.
		UserPerks[i].SaveData(Data);

		// Now save the skip offset for perk data incase perk gets removed from server.
		Data.SeekOffset(o);
		Data.SaveInt(Data.TotalSize(),1);
		Data.ToEnd();
	}
}

// Data loading.
function LoadData( ExtSaveDataBase Data )
{
	local int i,j,l,o;
	local string S;

	Data.ToStart();
	UserDataVersion = Data.GetSaveVersion();

	// Read global stats.
	TotalEXP = Data.ReadInt(3);
	TotalKills = Data.ReadInt(3);
	TotalPlayTime = Data.ReadInt(3);

	// Read character.
	if( PRIOwner!=None )
	{
		PRIOwner.RepKills = TotalKills;
		PRIOwner.RepEXP = TotalEXP;
		PRIOwner.SetInitPlayTime(TotalPlayTime);
		PRIOwner.LoadCustomCharacter(Data);
	}
	else class'ExtPlayerReplicationInfo'.Static.DummyLoadChar(Data);

	// Find selected perk.
	CurrentPerk = None;
	StrPerkName = Data.ReadStr();

	l = Data.ReadInt(); // Perk stats length.
	for( i=0; i<l; ++i )
	{
		S = Data.ReadStr();
		o = Data.ReadInt(1); // Read skip offset.
		Data.PushEOFLimit(o);
		for( j=0; j<UserPerks.Length; ++j )
			if( S~=string(UserPerks[j].Class.Name) )
			{
				UserPerks[j].LoadData(Data);
				break;
			}
		Data.PopEOFLimit();
		Data.SeekOffset(o); // Jump to end of this section.
	}
	bStatsDirty = false;
}

function AddDefaultInventory( KFPawn P )
{
	local KFInventoryManager KFIM;

	if( P != none && P.InvManager != none )
	{
		KFIM = KFInventoryManager(P.InvManager);
		if( KFIM != none )
		{
			//Grenades added on spawn
			KFIM.GiveInitialGrenadeCount();
		}

		if( CurrentPerk!=None )
			CurrentPerk.AddDefaultInventory(P);
	}
}

simulated function PlayerDied()
{
	if( CurrentPerk!=None )
		CurrentPerk.PlayerDied();
}

function PreNotifyPlayerLeave()
{
	if( CurrentPerk!=None )
		CurrentPerk.DeactivateTraits();
}

// Start client replication of perks data.
// Call this once the stats has been properly loaded serverside!
function InitiateClientRep()
{
	RepState = 0;
	RepIndex = 0;
	SetTimer(0.01,true,'ReplicateTimer');
}
function ReplicateTimer()
{
	switch( RepState )
	{
	case REP_CustomCharacters: // Replicate custom characters.
		if( RepIndex>=PRIOwner.CustomCharList.Length )
		{
			PRIOwner.AllCharReceived();
			RepIndex = 0;
			++RepState;
		}
		else
		{
			PRIOwner.ReceivedCharacter(RepIndex,PRIOwner.CustomCharList[RepIndex]);
			++RepIndex;
		}
		break;
	case REP_CustomInventory: // Replicate custom trader inventory
		if( !PRIOwner.OnRepNextItem(PRIOwner,RepIndex) )
		{
			RepIndex = 0;
			++RepState;
		}
		else ++RepIndex;
		break;
	case REP_PerkClasses: // Open up all actor channel connections.
		if( RepIndex>=UserPerks.Length )
		{
			RepIndex = 0;
			++RepState;
		}
		else if( UserPerks[RepIndex].bClientAuthorized )
		{
			if( UserPerks[RepIndex].bPerkNetReady )
				++RepIndex;
		}
		else
		{
			UserPerks[RepIndex].RemoteRole = ROLE_SimulatedProxy;
			if( UserPerks[RepIndex].NextAuthTime<WorldInfo.RealTimeSeconds )
			{
				UserPerks[RepIndex].NextAuthTime = WorldInfo.RealTimeSeconds+0.5;
				UserPerks[RepIndex].ClientAuth();
			}
		}
		break;
	default:
		if( MaxGrenadeCount!=Default.MaxGrenadeCount )
			ClientSetGrenadeCap(MaxGrenadeCount);
		ClearTimer('ReplicateTimer');
	}
}

function bool CanEarnSmallRadiusKillXP( class<DamageType> DT )
{
	return true;
}

simulated function ModifySpeed( out float Speed )
{
	if( CurrentPerk!=None )
		Speed *= CurrentPerk.Modifiers[0];
}
function ModifyDamageGiven( out int InDamage, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx )
{
	if( CurrentPerk!=None )
		CurrentPerk.ModifyDamageGiven(InDamage,DamageCauser,MyKFPM,DamageInstigator,DamageType,HitZoneIdx);
}
simulated function ModifyDamageTaken( out int InDamage, optional class<DamageType> DamageType, optional Controller InstigatedBy )
{
	if( CurrentPerk!=None )
		CurrentPerk.ModifyDamageTaken(InDamage,DamageType,InstigatedBy);
}
simulated function ModifyRecoil( out float CurrentRecoilModifier, KFWeapon KFW )
{
	if( CurrentPerk!=None )
		CurrentPerk.ModifyRecoil(CurrentRecoilModifier,KFW);
}
simulated function ModifySpread( out float InSpread )
{
	if( CurrentPerk!=None )
		CurrentPerk.ModifySpread(InSpread);
}
simulated function ModifyRateOfFire( out float InRate, KFWeapon KFW )
{
	if( CurrentPerk!=None )
		CurrentPerk.ModifyRateOfFire(InRate,KFW);
}
simulated function float GetReloadRateScale(KFWeapon KFW)
{
	return (CurrentPerk!=None ? CurrentPerk.GetReloadRateScale(KFW) : 1.f);
}
simulated function bool GetUsingTactialReload( KFWeapon KFW )
{
	return (CurrentPerk!=None ? CurrentPerk.GetUsingTactialReload(KFW) : false);
}
function ModifyHealth( out int InHealth )
{
	if( CurrentPerk!=None )
		CurrentPerk.ModifyHealth(InHealth);
}
function ModifyArmor( out byte MaxArmor )
{
	if( CurrentPerk!=None )
		CurrentPerk.ModifyArmor(MaxArmor);
}
function float GetKnockdownPowerModifier( optional class<DamageType> DamageType, optional byte BodyPart, optional bool bIsSprinting=false )
{
	return (CurrentPerk!=None ? CurrentPerk.GetKnockdownPowerModifier() : 1.f);
}
function float GetStumblePowerModifier( optional KFPawn KFP, optional class<KFDamageType> DamageType, optional out float CooldownModifier, optional byte BodyPart )
{
	return (CurrentPerk!=None ? CurrentPerk.GetKnockdownPowerModifier() : 1.f);
}
function float GetStunPowerModifier( optional class<DamageType> DamageType, optional byte HitZoneIdx )
{
	return (CurrentPerk!=None ? CurrentPerk.GetStunPowerModifier(DamageType,HitZoneIdx) : 1.f);
}
simulated function ModifyMeleeAttackSpeed( out float InDuration, KFWeapon KFW )
{
	if( CurrentPerk!=None )
		CurrentPerk.ModifyMeleeAttackSpeed(InDuration);
}
simulated function class<KFProj_Grenade> GetGrenadeClass()
{
    return (CurrentPerk!=None ? CurrentPerk.GrenadeClass : GrenadeClass);
}
simulated function ModifyWeldingRate( out float FastenRate, out float UnfastenRate )
{
	if( CurrentPerk!=None )
		CurrentPerk.ModifyWeldingRate(FastenRate,UnfastenRate);
}
simulated function bool HasNightVision()
{
	return (CurrentPerk!=None ? CurrentPerk.bHasNightVision : false);
}
function bool RepairArmor( Pawn HealTarget )
{
	return (CurrentPerk!=None ? CurrentPerk.RepairArmor(HealTarget) : false);
}
function bool ModifyHealAmount( out float HealAmount )
{
	return (CurrentPerk!=None ? CurrentPerk.ModifyHealAmount(HealAmount) : false);
}
function bool CanNotBeGrabbed()
{
	return (CurrentPerk!=None ? !CurrentPerk.bCanBeGrabbed : false);
}
simulated function ModifyMagSizeAndNumber( KFWeapon KFW, out byte MagazineCapacity, optional array< Class<KFPerk> > WeaponPerkClass, optional bool bSecondary=false, optional name WeaponClassname )
{
	if( CurrentPerk!=None )
		CurrentPerk.ModifyMagSizeAndNumber(KFW,MagazineCapacity,WeaponPerkClass,bSecondary,WeaponClassname);
}
simulated function ModifySpareAmmoAmount( KFWeapon KFW, out int PrimarySpareAmmo, optional const out STraderItem TraderItem, optional bool bSecondary=false )
{
	if( CurrentPerk!=None )
		CurrentPerk.ModifySpareAmmoAmount(KFW,PrimarySpareAmmo,TraderItem,bSecondary);
}
simulated function ModifyMaxSpareAmmoAmount( KFWeapon KFW, out int SpareAmmoCapacity, optional const out STraderItem TraderItem, optional bool bSecondary=false )
{
	if( CurrentPerk!=None )
		CurrentPerk.ModifySpareAmmoAmount(KFW,SpareAmmoCapacity,TraderItem,bSecondary);
}
simulated function bool ShouldMagSizeModifySpareAmmo( KFWeapon KFW, optional Class<KFPerk> WeaponPerkClass )
{
	return (CurrentPerk!=None ? CurrentPerk.ShouldMagSizeModifySpareAmmo(KFW,WeaponPerkClass) : false);
}
simulated function ModifyHealerRechargeTime( out float RechargeRate )
{
	if( CurrentPerk!=None )
		CurrentPerk.ModifyHealerRechargeTime(RechargeRate);
}
simulated function bool CanExplosiveWeld()
{
	return (CurrentPerk!=None ? CurrentPerk.bExplosiveWeld : false);
}
simulated function bool IsOnContactActive()
{
	return (CurrentPerk!=None ? CurrentPerk.bExplodeOnContact : false);
}
function bool CanSpreadNapalm()
{
	if( CurrentPerk!=None && CurrentPerk.bNapalmFire && LastNapalmTime!=WorldInfo.TimeSeconds )
	{
		LastNapalmTime = WorldInfo.TimeSeconds; // Avoid infinite script recursion in KFPawn_Monster.
		return true;
	}
	return false;
}
simulated function bool IsRangeActive()
{
	return MyPRI!=None ? MyPRI.bExtraFireRange : false;
}
simulated function DrawSpecialPerkHUD(Canvas C)
{
	if( CurrentPerk!=None )
		CurrentPerk.DrawSpecialPerkHUD(C);
}
function PlayerKilled( KFPawn_Monster Victim, class<DamageType> DamageType )
{
	if( CurrentPerk!=None )
		CurrentPerk.PlayerKilled(Victim,DamageType);
}
function ModifyBloatBileDoT( out float DoTScaler )
{
	if( CurrentPerk!=None )
		CurrentPerk.ModifyBloatBileDoT(DoTScaler);
}
simulated function bool GetIsUberAmmoActive( KFWeapon KFW )
{
	return (CurrentPerk!=None ? CurrentPerk.GetIsUberAmmoActive(KFW) : false);
}
function UpdatePerkHeadShots( ImpactInfo Impact, class<DamageType> DamageType, int NumHit )
{
	if( CurrentPerk!=None )
		CurrentPerk.UpdatePerkHeadShots(Impact,DamageType,NumHit);
}
function CheckForAirborneAgent( KFPawn HealTarget, class<DamageType> DamType, int HealAmount )
{
	if( !bCurrentlyHealing && CurrentPerk!=None )
	{
		// Using boolean to avoid infinite recursion.
		bCurrentlyHealing = true;
		CurrentPerk.CheckForAirborneAgent(HealTarget,DamType,HealAmount);
		bCurrentlyHealing = false;
	}
}
simulated function float GetZedTimeModifier( KFWeapon W )
{
	return (CurrentPerk!=None ? CurrentPerk.GetZedTimeModifier(W) : 0.f);
}

// Poison darts
function bool IsAcidicCompoundActive()
{
	return (CurrentPerk!=None ? CurrentPerk.bToxicDart : false);
}
function ModifyACDamage( out int InDamage )
{
	if( CurrentPerk!=None && CurrentPerk.bToxicDart )
		InDamage += CurrentPerk.ToxicDartDamage;
}

// Zombie explosion!
function bool CouldBeZedShrapnel( class<KFDamageType> KFDT )
{
	return (CurrentPerk!=None ? (CurrentPerk.bFireExplode && class<KFDT_Fire>(KFDT)!=None) : false);
}
simulated function bool ShouldShrapnel()
{
	return (CurrentPerk!=None ? (CurrentPerk.bFireExplode && Rand(3)==0) : false);
}
function GameExplosion GetExplosionTemplate()
{
	return class'KFPerk_Firebug'.Default.ExplosionTemplate;
}

// Additional functions
function OnWaveEnded()
{
	CurrentPerk.OnWaveEnded();
}
function NotifyZedTimeStarted()
{
	CurrentPerk.NotifyZedTimeStarted();
}
simulated function float GetZedTimeExtensions( byte Level )
{
	return CurrentPerk.GetZedTimeExtensions(Level);
}

// SWAT:
simulated function bool HasHeavyArmor()
{
	return (CurrentPerk!=None && CurrentPerk.bHeavyArmor);
}
simulated function float GetIronSightSpeedModifier( KFWeapon KFW )
{
	return (CurrentPerk!=None ? CurrentPerk.GetIronSightSpeedModifier(KFW) : 1.f);
}
simulated function float GetCrouchSpeedModifier( KFWeapon KFW )
{
	return (CurrentPerk!=None ? CurrentPerk.GetIronSightSpeedModifier(KFW) : 1.f);
}
simulated function bool ShouldKnockDownOnBump()
{
	return (CurrentPerk!=None && CurrentPerk.bHasSWATEnforcer);
}

// DEMO:
simulated function bool ShouldRandSirenResist()
{
	return (Ext_PerkDemolition(CurrentPerk)!=None ? Ext_PerkDemolition(CurrentPerk).bSirenResistance : false);
}
simulated function bool IsAoEActive()
{
	return (Ext_PerkDemolition(CurrentPerk)!=None ? Ext_PerkDemolition(CurrentPerk).AOEMult > 1.0f : false);
}
simulated function bool ShouldSacrifice()
{
	return (Ext_PerkDemolition(CurrentPerk)!=None ? (Ext_PerkDemolition(CurrentPerk).bCanUseSacrifice && !Ext_PerkDemolition(CurrentPerk).bUsedSacrifice) : false);
}
simulated function bool ShouldNeverDud()
{
	return (Ext_PerkDemolition(CurrentPerk)!=None ? Ext_PerkDemolition(CurrentPerk).bProfessionalActive : false);
}
function NotifyPerkSacrificeExploded()
{
	if( Ext_PerkDemolition(CurrentPerk) != none ) Ext_PerkDemolition(CurrentPerk).bUsedSacrifice = true;
}
simulated function float GetAoERadiusModifier()
{
	return (Ext_PerkDemolition(CurrentPerk)!=None ? Ext_PerkDemolition(CurrentPerk).GetAoERadiusModifier() : 1.0);
}

// MEDIC:
simulated function bool GetHealingSpeedBoostActive()
{
	return (Ext_PerkFieldMedic(CurrentPerk)!=None ? Ext_PerkFieldMedic(CurrentPerk).GetHealingSpeedBoostActive() : false);
}
simulated function bool GetHealingDamageBoostActive()
{
	return (Ext_PerkFieldMedic(CurrentPerk)!=None ? Ext_PerkFieldMedic(CurrentPerk).GetHealingDamageBoostActive() : false);
}
simulated function bool GetHealingShieldActive()
{
	return (Ext_PerkFieldMedic(CurrentPerk)!=None ? Ext_PerkFieldMedic(CurrentPerk).GetHealingShieldActive() : false);
}
simulated function float GetSelfHealingSurgePct()
{ 
	return (Ext_PerkFieldMedic(CurrentPerk)!=None ? Ext_PerkFieldMedic(CurrentPerk).GetSelfHealingSurgePct() : 0.f);
}
function bool IsToxicDmgActive()
{
	return (Ext_PerkFieldMedic(CurrentPerk)!=None ? Ext_PerkFieldMedic(CurrentPerk).bUseToxicDamage : false);
}
static function class<KFDamageType> GetToxicDmgTypeClass()
{
	return class'Ext_PerkFieldMedic'.static.GetToxicDmgTypeClass();
}
static function ModifyToxicDmg( out int ToxicDamage )
{
	ToxicDamage = class'Ext_PerkFieldMedic'.static.ModifyToxicDmg(ToxicDamage);
}
simulated function float GetSnarePower( optional class<DamageType> DamageType, optional byte HitZoneIdx )
{
	return (Ext_PerkFieldMedic(CurrentPerk)!=None ? Ext_PerkFieldMedic(CurrentPerk).GetSnarePower(DamageType, HitZoneIdx) : 0.f);
}

// SUPPORT:
simulated function bool CanRepairDoors()
{
	return (Ext_PerkSupport(CurrentPerk)!=None ? Ext_PerkSupport(CurrentPerk).CanRepairDoors() : false);
}
simulated function float GetPenetrationModifier( byte Level, class<KFDamageType> DamageType, optional bool bForce  )
{
	return (Ext_PerkSupport(CurrentPerk)!=None ? Ext_PerkSupport(CurrentPerk).GetPenetrationModifier(Level, DamageType, bForce) : 0.f);
}

// Other
function ApplySkillsToPawn()
{
	if( CheckOwnerPawn() )
	{
		OwnerPawn.UpdateGroundSpeed();
		OwnerPawn.bMovesFastInZedTime = false;

		if( MyPRI == none )
			MyPRI = KFPlayerReplicationInfo(OwnerPawn.PlayerReplicationInfo);

		ApplyWeightLimits();
	}
}

defaultproperties
{
	bTickIsDisabled=false
	NetPriority=3.5
}