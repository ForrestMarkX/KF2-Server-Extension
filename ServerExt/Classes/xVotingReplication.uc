// Written by Marco.
// Mapvote manager client.
Class xVotingReplication extends ReplicationInfo;

struct FGameTypeEntry
{
	var string GameName,GameShortName,Prefix;
};
struct FMapEntry
{
	var string MapName,MapTitle;
	var int UpVotes,DownVotes,Sequence,NumPlays,History;
};
struct FVotedMaps
{
	var int GameIndex,MapIndex,NumVotes;
};

var array<FGameTypeEntry> GameModes;
var array<FMapEntry> Maps;
var array<FVotedMaps> ActiveVotes;

var PlayerController PlayerOwner;
var xVotingHandlerBase VoteHandler;
var byte DownloadStage;
var int DownloadIndex,ClientCurrentGame;
var int CurrentVote[2];
var transient float RebunchTimer,NextVoteTimer;
var bool bClientConnected,bAllReceived,bClientRanked;
var transient bool bListDirty;

function PostBeginPlay()
{
	PlayerOwner = PlayerController(Owner);
	RebunchTimer = WorldInfo.TimeSeconds+5.f;
}
function Tick( float Delta )
{
	if( PlayerOwner==None || PlayerOwner.Player==None )
	{
		Destroy();
		return;
	}
	if( !bClientConnected )
	{
		if( RebunchTimer<WorldInfo.TimeSeconds )
		{
			RebunchTimer = WorldInfo.TimeSeconds+0.75;
			ClientVerify();
		}
	}
	else if( DownloadStage<255 )
		VoteHandler.ClientDownloadInfo(Self);
}

reliable server function ServerNotifyReady()
{
	bClientConnected = true;
}
unreliable client simulated function ClientVerify()
{
	SetOwner(GetPlayer());
	ServerNotifyReady();
}

simulated final function PlayerController GetPlayer()
{
	if( PlayerOwner==None )
		PlayerOwner = GetALocalPlayerController();
	return PlayerOwner;
}
reliable client simulated function ClientReceiveGame( int Index, string GameName, string GameSName, string Prefix )
{
	if( GameModes.Length<=Index )
		GameModes.Length = Index+1;
	GameModes[Index].GameName = GameName;
	GameModes[Index].GameShortName = GameSName;
	GameModes[Index].Prefix = Prefix;
	bListDirty = true;
}
reliable client simulated function ClientReceiveMap( int Index, string MapName, int UpVote, int DownVote, int Sequence, int NumPlays, optional string MapTitle )
{
	if( Maps.Length<=Index )
		Maps.Length = Index+1;
	Maps[Index].MapName = MapName;
	Maps[Index].MapTitle = (MapTitle!="" ? MapTitle : MapName);
	Maps[Index].UpVotes = UpVote;
	Maps[Index].DownVotes = DownVote;
	Maps[Index].Sequence = Sequence;
	Maps[Index].NumPlays = NumPlays;
	bListDirty = true;
}
reliable client simulated function ClientReceiveVote( int GameIndex, int MapIndex, int VoteCount )
{
	local int i;
	
	for( i=0; i<ActiveVotes.Length; ++i )
		if( ActiveVotes[i].GameIndex==GameIndex && ActiveVotes[i].MapIndex==MapIndex )
		{
			if( VoteCount==0 )
				ActiveVotes.Remove(i,1);
			else ActiveVotes[i].NumVotes = VoteCount;
			bListDirty = true;
			return;
		}
	if( VoteCount==0 )
		return;
	ActiveVotes.Length = i+1;
	ActiveVotes[i].GameIndex = GameIndex;
	ActiveVotes[i].MapIndex = MapIndex;
	ActiveVotes[i].NumVotes = VoteCount;
	bListDirty = true;
}
reliable client simulated function ClientReady( int CurGame )
{
	ClientCurrentGame = CurGame;
	bAllReceived = true;
	MapVoteMsg("Maplist successfully received.");
}

simulated final function MapVoteMsg( string S )
{
	if( S!="" )
		GetPlayer().ClientMessage("MapVote: "$S);
}
reliable client simulated function ClientNotifyVote( PlayerReplicationInfo PRI, int GameIndex, int MapIndex )
{
	if( bAllReceived )
		MapVoteMsg((PRI!=None ? PRI.PlayerName : "Someone")$" has voted for "$Maps[MapIndex].MapTitle$" ("$GameModes[GameIndex].GameShortName$").");
	else MapVoteMsg((PRI!=None ? PRI.PlayerName : "Someone")$" has voted for a map.");
}

reliable client simulated function ClientNotifyVoteTime( int Time )
{
	if( Time==0 )
		MapVoteMsg("Initializing mid-game mapvote...");
	if( Time<=10 )
		MapVoteMsg(string(Time)$"...");
	else if( Time<60 )
		MapVoteMsg(string(Time)$" seconds...");
	else if( Time==60 )
		MapVoteMsg("1 minute remains...");
	else if( Time==120 )
		MapVoteMsg("2 minutes remain...");
}
reliable client simulated function ClientNotifyVoteWin( int GameIndex, int MapIndex, bool bAdminForce )
{
	Class'KF2GUIController'.Static.GetGUIController(GetPlayer()).CloseMenu(None,true);
	if( bAdminForce )
	{
		if( bAllReceived )
			MapVoteMsg("An admin has forced mapswitch to "$Maps[MapIndex].MapTitle$" ("$GameModes[GameIndex].GameShortName$").");
		else MapVoteMsg("An admin has forced a mapswitch.");
	}
	else if( bAllReceived )
		MapVoteMsg(Maps[MapIndex].MapTitle$" ("$GameModes[GameIndex].GameShortName$") has won mapvote, switching map...");
	else MapVoteMsg("A map has won mapvote, switching map...");
}
reliable client simulated function ClientOpenMapvote( optional bool bShowRank )
{
	local xUI_MapRank R;

	if( bAllReceived )
		SetTimer(0.001,false,'DelayedOpenMapvote'); // To prevent no-mouse issue when local server host opens it from chat.
	if( bShowRank )
	{
		R = xUI_MapRank(Class'KF2GUIController'.Static.GetGUIController(GetPlayer()).OpenMenu(class'xUI_MapRank'));
		R.RepInfo = Self;
		
		if( KFGFxHudWrapper(GetPlayer().myHUD)!=None )
			KFGFxHudWrapper(GetPlayer().myHUD).HudMovie.DisplayPriorityMessage("MAP VOTE TIME","Cast your votes!",2);
		
		if( KFGameReplicationInfo(WorldInfo.GRI)!=none )
			KFGameReplicationInfo(WorldInfo.GRI).ProcessChanceDrop();
	}
}
simulated function DelayedOpenMapvote()
{
	local xUI_MapVote U;

	U = xUI_MapVote(Class'KF2GUIController'.Static.GetGUIController(GetPlayer()).OpenMenu(class'xUI_MapVote'));
	U.InitMapvote(Self);
}

reliable server simulated function ServerCastVote( int GameIndex, int MapIndex, bool bAdminForce )
{
	if( NextVoteTimer<WorldInfo.TimeSeconds )
	{
		NextVoteTimer = WorldInfo.TimeSeconds+1.f;
		VoteHandler.ClientCastVote(Self,GameIndex,MapIndex,bAdminForce);
	}
}
reliable server simulated function ServerRankMap( bool bUp )
{
	if( !bClientRanked )
	{
		bClientRanked = true;
		VoteHandler.ClientRankMap(Self,bUp);
	}
}

function Destroyed()
{
	VoteHandler.ClientDisconnect(Self);
}

defaultproperties
{
	bAlwaysRelevant=false
	bOnlyRelevantToOwner=true
	CurrentVote(0)=-1
	CurrentVote(1)=-1
}