class ExtEmoteList extends Object
	abstract;

var const array<Emote> Emotes;

static final function name GetUnlockedEmote( int ItemId, ExtPlayerController PC )
{
    local int i;
	local name Anim;
	local ExtPlayerReplicationInfo PRI;
	
	i = default.Emotes.Find('Id', ItemId);
	if( i > -1 )
	{
		Anim = default.Emotes[i].AnimName;
		PRI = ExtPlayerReplicationInfo(PC.PlayerReplicationInfo);
		
		if( PRI == None )
			return Anim;
			
		/*
		if( InStr(string(Anim), "Deluxe") != INDEX_NONE && PRI.AdminType == 255 )
			return 'NONE';
		*/
		else return Anim;
	}

	return 'NONE';
}

static final function SaveEquippedEmote( int ItemId, ExtPlayerController PC )
{
	if( PC == None )
		return;
		
	PC.SelectedEmoteIndex = ItemId;
	PC.SaveConfig();
}

static final function array<Emote> GetEmoteArray()
{
	return default.Emotes;
}

static final function byte GetEmoteIndex( int ItemId )
{
    local int i;
	i = default.Emotes.Find('Id', ItemId);
	if( i > -1 )
		return i;

	return -1;
}

static final function int GetEquippedEmoteId(ExtPlayerController PC)
{
	if( PC == None )
		return -1;
		
	return PC.SelectedEmoteIndex;
}

static final function name GetEmoteFromIndex(byte EmoteIndex)
{
	return default.Emotes[EmoteIndex].AnimName;
}

defaultproperties
{
	Emotes.Add((Id=4515, ItemName = "LetsGetCrazy", 		AnimName="Emote_01_LetsGetCrazy", 		IconPath="EMOTE_TEX.Emote_LetsGoCrazy_512"))
	Emotes.Add((Id=4516, ItemName = "ThunderClap", 			AnimName="Emote_02_ThunderClap", 		IconPath="EMOTE_TEX.Emote_Thunderclap_512"))
	Emotes.Add((Id=4517, ItemName = "UncleCharlie", 		AnimName="Emote_03_UncleCharlie", 		IconPath="EMOTE_TEX.Emote_UncleCharlie_512"))
	Emotes.Add((Id=4518, ItemName = "WackyWave", 			AnimName="Emote_04_WackyWave", 			IconPath="EMOTE_TEX.Emote_WackyWave_512"))
	Emotes.Add((Id=4519, ItemName = "RainingDosh", 			AnimName="Emote_05_RainingDosh", 		IconPath="EMOTE_TEX.Emote_RainingDosh_512"))
	Emotes.Add((Id=4520, ItemName = "LionUppercut", 		AnimName="Emote_06_LionUppercut", 		IconPath="EMOTE_TEX.Emote_Uppercut_512"))
	Emotes.Add((Id=0, 	 ItemName = "MatingRitual", 		AnimName="Emote_07_MatingRitual", 		IconPath="EMOTE_TEX.Emote_MatingRitual_512"))
	Emotes.Add((Id=4522, ItemName = "KickinIt", 			AnimName="Emote_08_KickinIt", 			IconPath="EMOTE_TEX.Emote_KicknIt_512"))
	Emotes.Add((Id=4523, ItemName = "Fireball", 			AnimName="Emote_09_Fireball", 			IconPath="EMOTE_TEX.Emote_Fireball_512"))
	Emotes.Add((Id=4524, ItemName = "Makeitrain", 			AnimName="Emote_10_Makeitrain", 		IconPath="EMOTE_TEX.Emote_MknRain_512"))
	Emotes.Add((Id=4744, ItemName = "TheCossack", 			AnimName="Emote_01_Dance", 				IconPath="EMOTE_TEX_02.Emote_02_Squat_Dance_512"))
	Emotes.Add((Id=4745, ItemName = "TheWave", 				AnimName="Emote_02_Dance", 				IconPath="EMOTE_TEX_02.Emote_02_The_Wave_512"))
	Emotes.Add((Id=4746, ItemName = "Breakin", 				AnimName="Emote_03_Dance", 				IconPath="EMOTE_TEX_02.Emote_02_Handstand_512"))
	Emotes.Add((Id=4747, ItemName = "NoHands", 				AnimName="Emote_04_Dance", 				IconPath="EMOTE_TEX_02.Emote_02_Kap_Kick_512"))
	Emotes.Add((Id=4748, ItemName = "HealClick", 			AnimName="Emote_05_Dance", 				IconPath="EMOTE_TEX_02.Emote_02_Click_It_512"))
	Emotes.Add((Id=4749, ItemName = "TheSprinkler", 		AnimName="Emote_06_Dance", 				IconPath="EMOTE_TEX_02.Emote_02_The_Sprinkler_512"))
	Emotes.Add((Id=4750, ItemName = "Maniac", 				AnimName="Emote_07_Dance", 				IconPath="EMOTE_TEX_02.Emote_02_Running_Dosh_512"))
	Emotes.Add((Id=4751, ItemName = "RunningMan", 			AnimName="Emote_08_Dance", 				IconPath="EMOTE_TEX_02.Emote_02_Running_Man_512"))
	Emotes.Add((Id=4752, ItemName = "TheRobot", 			AnimName="Emote_09_Dance", 				IconPath="EMOTE_TEX_02.Emote_02_The_Robot_512"))
	Emotes.Add((Id=4753, ItemName = "AirMetal", 			AnimName="Emote_10_Dance", 				IconPath="EMOTE_TEX_02.Emote_02_Guitar_Solo_512"))
	Emotes.Add((Id=4525, ItemName = "Fireball_Deluxe", 		AnimName="Emote_09_Fireball_Deluxe", 	IconPath="EMOTE_TEX.Emote_Fireball_DLX_512"))
	Emotes.Add((Id=4526, ItemName = "Makeitrain_Deluxe", 	AnimName="Emote_10_Makeitrain_Deluxe", 	IconPath="EMOTE_TEX.Emote_MknRain_DLX_512"))
	Emotes.Add((Id=4527, ItemName = "ThunderClap_Deluxe", 	AnimName="Emote_02_ThunderClap_Deluxe", IconPath="EMOTE_TEX.Emote_Thunderclap_DLX_512"))
	Emotes.Add((Id=4528, ItemName = "UncleCharlie_Deluxe", 	AnimName="Emote_03_UncleCharlie_Deluxe",IconPath="EMOTE_TEX.Emote_UncleCharlie_DLX_512"))
	Emotes.Add((Id=4529, ItemName = "LetsGetCrazy_Deluxe", 	AnimName="Emote_01_LetsGetCrazy_Deluxe",IconPath="EMOTE_TEX.Emote_LetsGoCrazy_DLX_512"))
	Emotes.Add((Id=4530, ItemName = "WackyWave_Deluxe", 	AnimName="Emote_04_WackyWave_Deluxe", 	IconPath="EMOTE_TEX.Emote_WackyWave_DLX_512"))	
	Emotes.Add((Id=4531, ItemName = "RainingDosh_Deluxe", 	AnimName="Emote_05_RainingDosh_Deluxe", IconPath="EMOTE_TEX.Emote_RainingDosh_DLX_512"))
	Emotes.Add((Id=4532, ItemName = "LionUppercut_Deluxe", 	AnimName="Emote_06_LionUppercut_Deluxe",IconPath="EMOTE_TEX.Emote_Uppercut_DLX_512"))
	Emotes.Add((Id=4533, ItemName = "MatingRitual_Deluxe", 	AnimName="Emote_07_MatingRitual_Deluxe",IconPath="EMOTE_TEX.Emote_MatingRitual_DLX_512"))
	Emotes.Add((Id=4534, ItemName = "KickinIt_Deluxe", 		AnimName="Emote_08_KickinIt_Deluxe", 	IconPath="EMOTE_TEX.Emote_KicknIt_DLX_512"))
	Emotes.Add((Id=4754, ItemName = "TheCossack_Deluxe", 	AnimName="Emote_01_Dance_Deluxe", 		IconPath="EMOTE_TEX_02.Emote_02_Squat_Dance_DLX_512"))
	Emotes.Add((Id=4755, ItemName = "TheWave_Deluxe", 		AnimName="Emote_02_Dance_Deluxe", 		IconPath="EMOTE_TEX_02.Emote_02_The_Wave_DLX_512"))
	Emotes.Add((Id=4756, ItemName = "Breakin_Deluxe", 		AnimName="Emote_03_Dance_Deluxe", 		IconPath="EMOTE_TEX_02.Emote_02_Handstand_DLX_512"))
	Emotes.Add((Id=4757, ItemName = "NoHands_Deluxe", 		AnimName="Emote_04_Dance_Deluxe", 		IconPath="EMOTE_TEX_02.Emote_02_Kap_Kick_DLX_512"))
	Emotes.Add((Id=4758, ItemName = "HealClick_Deluxe", 	AnimName="Emote_05_Dance_Deluxe", 		IconPath="EMOTE_TEX_02.Emote_02_Click_It_DLX_512"))
	Emotes.Add((Id=4759, ItemName = "TheSprinkler_Deluxe", 	AnimName="Emote_06_Dance_Deluxe", 		IconPath="EMOTE_TEX_02.Emote_02_The_Sprinkler_DLX_512"))
	Emotes.Add((Id=4760, ItemName = "Maniac_Deluxe", 		AnimName="Emote_07_Dance_Deluxe", 		IconPath="EMOTE_TEX_02.Emote_02_Running_Dosh_DLX_512"))
	Emotes.Add((Id=4761, ItemName = "RunningMan_Deluxe", 	AnimName="Emote_08_Dance_Deluxe", 		IconPath="EMOTE_TEX_02.Emote_02_Running_Man_DLX_512"))
	Emotes.Add((Id=4762, ItemName = "TheRobot_Deluxe", 		AnimName="Emote_09_Dance_Deluxe", 		IconPath="EMOTE_TEX_02.Emote_02_The_Robot_DLX_512"))
	Emotes.Add((Id=4763, ItemName = "AirMetal_Deluxe", 		AnimName="Emote_10_Dance_Deluxe", 		IconPath="EMOTE_TEX_02.Emote_02_Guitar_Solo_DLX_512"))
}