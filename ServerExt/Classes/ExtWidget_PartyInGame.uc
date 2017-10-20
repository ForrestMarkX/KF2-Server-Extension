class ExtWidget_PartyInGame extends KFGFxWidget_PartyInGame;

var class<Ext_PerkBase> PPerkSlots[6];
var byte PPerkLevels[6];

function GFxObject RefreshSlot(int SlotIndex, KFPlayerReplicationInfo KFPRI)
{
	local string PlayerName;	
	local UniqueNetId AdminId;
	local bool bIsLeader;
	local bool bIsMyPlayer;
	local PlayerController PC;
	local GFxObject PlayerInfoObject;
	local class<Ext_PerkBase> CurrentPerkClass;
	local int CurrentPerkLevel;
	local ExtPlayerReplicationInfo EPRI;

	PlayerInfoObject = CreateObject("Object");
	EPRI = ExtPlayerReplicationInfo(KFPRI);
	PC = GetPC();

	if(OnlineLobby != none)
	{
		OnlineLobby.GetLobbyAdmin( OnlineLobby.GetCurrentLobbyId(), AdminId);
	}
	
	//leader
	bIsLeader = (KFPRI.UniqueId == AdminId);
	PlayerInfoObject.SetBool("bLeader", bIsLeader);
	//my player
	bIsMyPlayer = PC.PlayerReplicationInfo.UniqueId == KFPRI.UniqueId;
	MemberSlots[SlotIndex].PlayerUID = KFPRI.UniqueId;
	MemberSlots[SlotIndex].PRI = KFPRI;
	PlayerInfoObject.SetBool("myPlayer", bIsMyPlayer);
	
	// Update this players perk information
	CurrentPerkClass = (EPRI!=None ? EPRI.ECurrentPerk : None);
	CurrentPerkLevel = (EPRI!=None ? EPRI.ECurrentPerkLevel : 0);

	if ( PPerkSlots[SlotIndex] != CurrentPerkClass || PPerkLevels[SlotIndex] != CurrentPerkLevel )
	{
		PPerkSlots[SlotIndex] = CurrentPerkClass;
		PPerkLevels[SlotIndex] = CurrentPerkLevel;
		PlayerInfoObject.SetString("perkLevel", string(CurrentPerkLevel) @ CurrentPerkClass.default.PerkName);
		PlayerInfoObject.SetString("perkIconPath", CurrentPerkClass.Static.GetPerkIconPath(CurrentPerkLevel));
	}

	//perk info
	if(MemberSlots[SlotIndex].PerkClass != none)
	{
		PlayerInfoObject.SetString("perkLevel", MemberSlots[SlotIndex].PerkLevel @MemberSlots[SlotIndex].PerkClass.default.PerkName);
		PlayerInfoObject.SetString("perkIconPath", "img://"$MemberSlots[SlotIndex].PerkClass.static.GetPerkIconPath());
	}
	//perk info
	if(!bIsMyPlayer)
	{
		PlayerInfoObject.SetBool("muted", PC.IsPlayerMuted(KFPRI.UniqueId));	
	}
	
	
	// E3 build force update of player name
	if( class'WorldInfo'.static.IsE3Build() )
	{
		// Update this slots player name
		PlayerName = KFPRI.PlayerName;
	}
	else
	{
		PlayerName = KFPRI.PlayerName;
	}
	PlayerInfoObject.SetString("playerName", PlayerName);
	//player icon
	if( class'WorldInfo'.static.IsConsoleBuild(CONSOLE_Orbis) )
	{
		PlayerInfoObject.SetString("profileImageSource", KFPC.GetPS4Avatar(PlayerName));
	}
	else
	{
		PlayerInfoObject.SetString("profileImageSource", KFPC.GetSteamAvatar(KFPRI.UniqueId));
	}	
	if(KFGRI != none)
	{
		PlayerInfoObject.SetBool("ready", KFPRI.bReadyToPlay && !KFGRI.bMatchHasBegun);
	}

	return PlayerInfoObject;
}
