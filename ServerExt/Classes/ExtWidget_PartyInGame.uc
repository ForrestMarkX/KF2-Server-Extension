class ExtWidget_PartyInGame extends KFGFxWidget_PartyInGame;

var class<Ext_PerkBase> PPerkSlots[6];
var byte PPerkLevels[6];

struct ExtMemberSlotStruct
{
	var class<Ext_PerkBase> PerkClass;
	
	structdefaultproperties
	{
		PerkClass=none
	}
};
var ExtMemberSlotStruct ExtMemberSlots[13];

function GFxObject RefreshSlot( int SlotIndex, KFPlayerReplicationInfo KFPRI )
{
	local string PlayerName;	
	local UniqueNetId AdminId;
	local bool bIsLeader;
	local bool bIsMyPlayer;
	local ExtPlayerController EPC;
	local GFxObject PlayerInfoObject;
	local ExtPlayerReplicationInfo EPRI;

	PlayerInfoObject = CreateObject("Object");
	EPC = ExtPlayerController(GetPC());
	
	if( KFPRI != none )
	{
		EPRI = ExtPlayerReplicationInfo(KFPRI);
	}
	if( OnlineLobby != none )
	{
		OnlineLobby.GetLobbyAdmin( OnlineLobby.GetCurrentLobbyId(), AdminId);
	}
	bIsLeader = EPRI.UniqueId == AdminId;
	PlayerInfoObject.SetBool("bLeader", bIsLeader);
	bIsMyPlayer = EPC.PlayerReplicationInfo.UniqueId == KFPRI.UniqueId;
	ExtMemberSlots[SlotIndex].PerkClass = EPRI.ECurrentPerk;
	PlayerInfoObject.SetBool("myPlayer", bIsMyPlayer);
	if( ExtMemberSlots[SlotIndex].PerkClass != none )
	{
		PlayerInfoObject.SetString("perkLevel", string(EPRI.ECurrentPerkLevel));
		PlayerInfoObject.SetString("perkIconPath", ExtMemberSlots[SlotIndex].PerkClass.static.GetPerkIconPath(EPRI.ECurrentPerkLevel));
	}
	if( !bIsMyPlayer )
	{
		PlayerInfoObject.SetBool("muted", EPC.IsPlayerMuted(EPRI.UniqueId));	
	}
	if( class'WorldInfo'.static.IsE3Build() )
	{
		PlayerName = EPRI.PlayerName;
	}
	else
	{
		PlayerName = EPRI.PlayerName;
	}
	PlayerInfoObject.SetString("playerName", PlayerName);
	if( class'WorldInfo'.static.IsConsoleBuild(CONSOLE_Orbis) )
	{
		PlayerInfoObject.SetString("profileImageSource", "img://"$KFPC.GetPS4Avatar(PlayerName));
	}
	else
	{
		PlayerInfoObject.SetString("profileImageSource", "img://"$KFPC.GetSteamAvatar(EPRI.UniqueId));
	}	
	if( KFGRI != none )
	{
		PlayerInfoObject.SetBool("ready", EPRI.bReadyToPlay && !KFGRI.bMatchHasBegun);
	}

	return PlayerInfoObject;	
}

DefaultProperties
{
	PlayerSlots=12
}
