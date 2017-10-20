Class xVotingHandler extends xVotingHandlerBase
	config(xMapVote);

struct FGameModeOption
{
	var config string GameName,GameShortName,GameClass,Mutators,Options,Prefix;
};
var config array<FGameModeOption> GameModes;
var config int LastVotedGameInfo,VoteTime,MaxMapsOnList;
var config float MidGameVotePct,MapWinPct,MapChangeDelay;
var config bool bNoWebAdmin;

var class<Mutator> BaseMutator;

var array<SoundCue> AnnouncerCues;
var array<FMapEntry> Maps;
var array<FVotedMaps> ActiveVotes;
var array<xVotingReplication> ActiveVoters;
var int iCurrentHistory,VoteTimeLeft,ShowMenuDelay;
var string PendingMapURL;
var KFGameReplicationInfo KF;
var bool bMapvoteHasEnded,bMapVoteTimer,bHistorySaved;

function PostBeginPlay()
{
	local int i,j,z,n,UpV,DownV,Seq,NumPl;
	local string S,MapFile;

	if( WorldInfo.Game.BaseMutator==None )
		WorldInfo.Game.BaseMutator = Self;
	else WorldInfo.Game.BaseMutator.AddMutator(Self);
	
	if( bDeleteMe ) // This was a duplicate instance of the mutator.
		return;

	MapFile = string(WorldInfo.GetPackageName());
	iCurrentHistory = class'xMapVoteHistory'.Static.GetMapHistory(MapFile,WorldInfo.Title);
	if( LastVotedGameInfo<0 || LastVotedGameInfo>=GameModes.Length )
		LastVotedGameInfo = 0;
	
	if( MapChangeDelay==0 )
		MapChangeDelay = 3;
	if( GameModes.Length==0 ) // None specified, so use current settings.
	{
		GameModes.Length = 1;
		GameModes[0].GameName = "Killing Floor";
		GameModes[0].GameShortName = "KF";
		GameModes[0].GameClass = PathName(WorldInfo.Game.Class);
		GameModes[0].Mutators = "";
		GameModes[0].Prefix = "";
		MidGameVotePct = 0.51;
		MapWinPct = 0.75;
		VoteTime = 35;
		SaveConfig();
	}

	// Build maplist.
	z = 0;
	for( i=(Class'KFGameInfo'.Default.GameMapCycles.Length-1); i>=0; --i )
	{
		for( j=(Class'KFGameInfo'.Default.GameMapCycles[i].Maps.Length-1); j>=0; --j )
		{
			if( MaxMapsOnList>0 && Class'KFGameInfo'.Default.GameMapCycles[i].Maps[j]~=MapFile ) // If we limit the maps count, remove current map.
				continue;
			Maps.Length = z+1;
			Maps[z].MapName = Class'KFGameInfo'.Default.GameMapCycles[i].Maps[j];
			n = class'xMapVoteHistory'.Static.GetMapHistory(Maps[z].MapName,"");
			class'xMapVoteHistory'.Static.GetHistory(n,UpV,DownV,Seq,NumPl,S);
			Maps[z].UpVotes = UpV;
			Maps[z].DownVotes = DownV;
			Maps[z].Sequence = Seq;
			Maps[z].NumPlays = NumPl;
			Maps[z].History = n;
			Maps[z].MapTitle = S;
			++z;
		}
	}
	
	if( MaxMapsOnList>0 )
	{
		// Remove random maps from list.
		while( Maps.Length>MaxMapsOnList )
			Maps.Remove(Rand(Maps.Length),1);
	}

	SetTimer(0.15,false,'SetupBroadcast');
	SetTimer(1,true,'CheckEndGameEnded');
}
function AddMutator(Mutator M)
{
	if( M!=Self ) // Make sure we don't get added twice.
	{
		if( M.Class==Class )
			M.Destroy();
		else Super.AddMutator(M);
	}
}

function SetupBroadcast()
{
	local xVoteBroadcast B;
	local WebServer W;
	local WebAdmin A;
	local xVoteWebApp xW;
	local byte i;
	
	B = Spawn(class'xVoteBroadcast');
	B.Handler = Self;
	B.NextBroadcaster = WorldInfo.Game.BroadcastHandler;
	WorldInfo.Game.BroadcastHandler = B;
	if( !bNoWebAdmin )
	{
		foreach AllActors(class'WebServer',W)
			break;
		if( W!=None )
		{
			for( i=0; (i<10 && A==None); ++i )
				A = WebAdmin(W.ApplicationObjects[i]);
			if( A!=None )
			{
				xW = new (None) class'xVoteWebApp';
				A.addQueryHandler(xW);
			}
			else `Log("X-VoteWebAdmin ERROR: No valid WebAdmin application found!");
		}
		else `Log("X-VoteWebAdmin ERROR: No WebServer object found!");
	}
}
final function AddVote( int Count, int MapIndex, int GameIndex )
{
	local int i,j;

	if( bMapvoteHasEnded )
		return;
	for( i=0; i<ActiveVotes.Length; ++i )
		if( ActiveVotes[i].GameIndex==GameIndex && ActiveVotes[i].MapIndex==MapIndex )
		{
			ActiveVotes[i].NumVotes += Count;
			for( j=(ActiveVoters.Length-1); j>=0; --j )
				ActiveVoters[j].ClientReceiveVote(GameIndex,MapIndex,ActiveVotes[i].NumVotes);
			if( ActiveVotes[i].NumVotes<=0 )
			{
				for( j=(ActiveVoters.Length-1); j>=0; --j )
					if( ActiveVoters[j].DownloadStage==2 && ActiveVoters[j].DownloadIndex>=i && ActiveVoters[j].DownloadIndex>0 ) // Make sure client doesn't skip a download at this point.
						--ActiveVoters[j].DownloadIndex;
				ActiveVotes.Remove(i,1);
			}
			return;
		}
	if( Count<=0 )
		return;
	ActiveVotes.Length = i+1;
	ActiveVotes[i].GameIndex = GameIndex;
	ActiveVotes[i].MapIndex = MapIndex;
	ActiveVotes[i].NumVotes = Count;
	for( j=(ActiveVoters.Length-1); j>=0; --j )
		ActiveVoters[j].ClientReceiveVote(GameIndex,MapIndex,Count);
}
final function LogoutPlayer( PlayerController PC )
{
	local int i;
	
	for( i=(ActiveVoters.Length-1); i>=0; --i )
		if( ActiveVoters[i].PlayerOwner==PC )
		{
			ActiveVoters[i].Destroy();
			break;
		}
}
final function LoginPlayer( PlayerController PC )
{
	local xVotingReplication R;
	local int i;
	
	for( i=(ActiveVoters.Length-1); i>=0; --i )
		if( ActiveVoters[i].PlayerOwner==PC )
			return;
	R = Spawn(class'xVotingReplication',PC);
	R.VoteHandler = Self;
	ActiveVoters.AddItem(R);
}

function NotifyLogout(Controller Exiting)
{
	if( PlayerController(Exiting)!=None )
		LogoutPlayer(PlayerController(Exiting));
	if ( NextMutator != None )
		NextMutator.NotifyLogout(Exiting);
}
function NotifyLogin(Controller NewPlayer)
{
	if( PlayerController(NewPlayer)!=None )
		LoginPlayer(PlayerController(NewPlayer));
	if ( NextMutator != None )
		NextMutator.NotifyLogin(NewPlayer);
}

function ClientDownloadInfo( xVotingReplication V )
{
	if( bMapvoteHasEnded )
	{
		V.DownloadStage = 255;
		return;
	}
	
	switch( V.DownloadStage )
	{
	case 0: // Game modes.
		if( V.DownloadIndex>=GameModes.Length )
			break;
		V.ClientReceiveGame(V.DownloadIndex,GameModes[V.DownloadIndex].GameName,GameModes[V.DownloadIndex].GameShortName,GameModes[V.DownloadIndex].Prefix);
		++V.DownloadIndex;
		return;
	case 1: // Maplist.
		if( V.DownloadIndex>=Maps.Length )
			break;
		if( Maps[V.DownloadIndex].MapTitle=="" )
			V.ClientReceiveMap(V.DownloadIndex,Maps[V.DownloadIndex].MapName,Maps[V.DownloadIndex].UpVotes,Maps[V.DownloadIndex].DownVotes,Maps[V.DownloadIndex].Sequence,Maps[V.DownloadIndex].NumPlays);
		else V.ClientReceiveMap(V.DownloadIndex,Maps[V.DownloadIndex].MapName,Maps[V.DownloadIndex].UpVotes,Maps[V.DownloadIndex].DownVotes,Maps[V.DownloadIndex].Sequence,Maps[V.DownloadIndex].NumPlays,Maps[V.DownloadIndex].MapTitle);
		++V.DownloadIndex;
		return;
	case 2: // Current votes.
		if( V.DownloadIndex>=ActiveVotes.Length )
			break;
		V.ClientReceiveVote(ActiveVotes[V.DownloadIndex].GameIndex,ActiveVotes[V.DownloadIndex].MapIndex,ActiveVotes[V.DownloadIndex].NumVotes);
		++V.DownloadIndex;
		return;
	default:
		V.ClientReady(LastVotedGameInfo);
		V.DownloadStage = 255;
		return;
	}
	++V.DownloadStage;
	V.DownloadIndex = 0;
}
function ClientCastVote( xVotingReplication V, int GameIndex, int MapIndex, bool bAdminForce )
{
	local int i;

	if( bMapvoteHasEnded )
		return;

	if( bAdminForce && V.PlayerOwner.PlayerReplicationInfo.bAdmin )
	{
		SwitchToLevel(GameIndex,MapIndex,true);
		return;
	}
	if( !Class'xUI_MapVote'.Static.BelongsToPrefix(Maps[MapIndex].MapName,GameModes[GameIndex].Prefix) )
	{
		V.PlayerOwner.ClientMessage("Error: Can't vote that map (wrong Prefix to that game mode)!");
		return;
	}
	if( V.CurrentVote[0]>=0 )
		AddVote(-1,V.CurrentVote[1],V.CurrentVote[0]);
	V.CurrentVote[0] = GameIndex;
	V.CurrentVote[1] = MapIndex;
	AddVote(1,MapIndex,GameIndex);
	for( i=(ActiveVoters.Length-1); i>=0; --i )
		ActiveVoters[i].ClientNotifyVote(V.PlayerOwner.PlayerReplicationInfo,GameIndex,MapIndex);
	TallyVotes();
}
function ClientRankMap( xVotingReplication V, bool bUp )
{
	class'xMapVoteHistory'.Static.AddMapKarma(iCurrentHistory,bUp);
}
function ClientDisconnect( xVotingReplication V )
{
	ActiveVoters.RemoveItem(V);
	if( V.CurrentVote[0]>=0 )
		AddVote(-1,V.CurrentVote[1],V.CurrentVote[0]);
	TallyVotes();
}

final function float GetPctOf( int Nom, int Denom )
{
	local float R;
	
	R = float(Nom) / float(Denom);
	return R;
}
final function TallyVotes( optional bool bForce )
{
	local int i,NumVotees,c,j;
	local array<int> Candidates;

	if( bMapvoteHasEnded )
		return;

	NumVotees = ActiveVoters.Length;
	c = 0;

	if( bForce )
	{
		// First check for highest result.
		for( i=(ActiveVotes.Length-1); i>=0; --i )
			c = Max(c,ActiveVotes[i].NumVotes);
		
		if( c>0 )
		{
			// Then check how many votes for the best.
			for( i=(ActiveVotes.Length-1); i>=0; --i )
				if( ActiveVotes[i].NumVotes==c )
					Candidates.AddItem(i);
			
			// Finally pick a random winner from the best.
			c = Candidates[Rand(Candidates.Length)];
			
			if( NumVotees>=4 && ActiveVotes.Length==1 ) // If more then 4 voters and everyone voted same map?!!! Give the mapvote some orgy.
			{
				for( j=(ActiveVoters.Length-1); j>=0; --j )
					ActiveVoters[j].PlayerOwner.ClientPlaySound(AnnouncerCues[13]);
			}
			SwitchToLevel(ActiveVotes[c].GameIndex,ActiveVotes[c].MapIndex,false);
		}
		else
		{
			// Pick a random map to win.
			c = Rand(Maps.Length);
			
			// Pick a random gametype to win along with it.
			for( i=(GameModes.Length-1); i>=0; --i )
				if( Class'xUI_MapVote'.Static.BelongsToPrefix(Maps[c].MapName,GameModes[i].Prefix) )
					Candidates.AddItem(i);
			
			if( Candidates.Length==0 ) // Odd, a map without gametype...
				i = Rand(GameModes.Length);
			else i = Candidates[Rand(Candidates.Length)];
			
			SwitchToLevel(i,c,false);
		}
		return;
	}

	// Check for insta-win vote.
	for( i=(ActiveVotes.Length-1); i>=0; --i )
	{
		c+=ActiveVotes[i].NumVotes;
		if( GetPctOf(ActiveVotes[i].NumVotes,NumVotees)>=MapWinPct )
		{
			if( NumVotees>=4 && ActiveVotes.Length==1 ) // If more then 4 voters and everyone voted same map?!!! Give the mapvote some orgy.
			{
				for( j=(ActiveVoters.Length-1); j>=0; --j )
					ActiveVoters[j].PlayerOwner.ClientPlaySound(AnnouncerCues[13]);
			}
			SwitchToLevel(ActiveVotes[i].GameIndex,ActiveVotes[i].MapIndex,false);
			return;
		}
	}
	
	// Check for mid-game voting timer.
	if( !bMapVoteTimer && NumVotees>0 && GetPctOf(c,NumVotees)>=MidGameVotePct )
		StartMidGameVote(true);
}
final function StartMidGameVote( bool bMidGame )
{
	local int i;

	if( bMapVoteTimer || bMapvoteHasEnded )
		return;
	bMapVoteTimer = true;
	if( bMidGame )
	{
		for( i=(ActiveVoters.Length-1); i>=0; --i )
			ActiveVoters[i].ClientNotifyVoteTime(0);
	}
	ShowMenuDelay = 5;
	VoteTimeLeft = Max(VoteTime,10);
	SetTimer(1,true);
}
function CheckEndGameEnded()
{
	if( KF==None )
	{
		KF = KFGameReplicationInfo(WorldInfo.GRI);
		if( KF==None )
			return;
	}
	if( KF.bMatchIsOver ) // HACK, since KFGameInfo_Survival doesn't properly notify mutators of this!
	{
		if( !bMapVoteTimer )
			StartMidGameVote(false);
		ClearTimer('CheckEndGameEnded');
		WorldInfo.Game.ClearTimer('ShowPostGameMenu');
	}
}
function bool HandleRestartGame()
{
	if( !bMapVoteTimer )
		StartMidGameVote(false);
	return true;
}
function Timer()
{
	local int i;
	local SoundCue FX;

	if( bMapvoteHasEnded )
	{
		if( WorldInfo.NextSwitchCountdown<=0.f ) // Mapswitch failed, force to random other map.
		{
			ActiveVotes.Length = 0;
			bMapvoteHasEnded = false;
			TallyVotes(true);
		}
		return;
	}
	if( ShowMenuDelay>0 && --ShowMenuDelay==0 )
	{
		for( i=(ActiveVoters.Length-1); i>=0; --i )
			ActiveVoters[i].ClientOpenMapvote(true);
	}
	--VoteTimeLeft;
	if( VoteTimeLeft==0 )
	{
		TallyVotes(true);
	}
	else if( VoteTimeLeft<=10 || VoteTimeLeft==20 || VoteTimeLeft==30 || VoteTimeLeft==60 )
	{
		FX = None;
		if( VoteTimeLeft<=10 )
			FX = AnnouncerCues[VoteTimeLeft-1];
		else if( VoteTimeLeft==20 )
			FX = AnnouncerCues[10];
		else if( VoteTimeLeft==30 )
			FX = AnnouncerCues[11];
		else if( VoteTimeLeft==60 )
			FX = AnnouncerCues[12];
		for( i=(ActiveVoters.Length-1); i>=0; --i )
		{
			ActiveVoters[i].ClientNotifyVoteTime(VoteTimeLeft);
			if( FX!=None )
				ActiveVoters[i].PlayerOwner.ClientPlaySound(FX);
		}
	}
}
final function SwitchToLevel( int GameIndex, int MapIndex, bool bAdminForce )
{
	local int i;
	local string S;

	if( bMapvoteHasEnded )
		return;
	
	Default.LastVotedGameInfo = GameIndex;
	Class.Static.StaticSaveConfig();
	bMapvoteHasEnded = true;
	if( !bAdminForce && !bHistorySaved )
	{
		class'xMapVoteHistory'.Static.UpdateMapHistory(Maps[MapIndex].History);
		class'xMapVoteHistory'.Static.StaticSaveConfig();
		bHistorySaved = true;
	}
	
	S = Maps[MapIndex].MapName$" ("$GameModes[GameIndex].GameName$")";
	for( i=(ActiveVoters.Length-1); i>=0; --i )
	{
		KFPlayerController(ActiveVoters[i].PlayerOwner).ShowConnectionProgressPopup(PMT_AdminMessage,"Switching to level:",S);
		ActiveVoters[i].ClientNotifyVoteWin(GameIndex,MapIndex,bAdminForce);
	}
	
	PendingMapURL = Maps[MapIndex].MapName$"?Game="$GameModes[GameIndex].GameClass$"?Mutator="$PathName(BaseMutator);
	if( GameModes[GameIndex].Mutators!="" )
		PendingMapURL $= ","$GameModes[GameIndex].Mutators;
	if( GameModes[GameIndex].Options!="" )
		PendingMapURL $= "?"$GameModes[GameIndex].Options;
	`Log("MapVote: Switch map to "$PendingMapURL);
	SetTimer(FMax(MapChangeDelay,0.1),false,'PendingSwitch');
}
function PendingSwitch()
{
	WorldInfo.ServerTravel(PendingMapURL,false);
	SetTimer(1,true);
}

final function ParseCommand( string Cmd, PlayerController PC )
{
	if( Cmd~="Help" )
	{
		PC.ClientMessage("MapVote commands:");
		PC.ClientMessage("!MapVote - Show mapvote menu");
		PC.ClientMessage("!AddMap <Mapname> - Add map to mapvote");
		PC.ClientMessage("!RemoveMap <Mapname> - Remove map from mapvote");
	}
	else if( Cmd~="MapVote" )
		ShowMapVote(PC);
	else if( !PC.PlayerReplicationInfo.bAdmin && !PC.IsA('MessagingSpectator') )
		return;
	else if( Left(Cmd,7)~="AddMap " )
	{
		Cmd = Mid(Cmd,7);
		PC.ClientMessage("Added map '"$Cmd$"'!");
		AddMap(Cmd);
	}
	else if( Left(Cmd,10)~="RemoveMap " )
	{
		Cmd = Mid(Cmd,10);
		if( RemoveMap(Cmd) )
			PC.ClientMessage("Removed map '"$Cmd$"'!");
		else PC.ClientMessage("Map '"$Cmd$"' not found!");
	}
}
function ShowMapVote( PlayerController PC )
{
	local int i;

	if( bMapvoteHasEnded )
		return;
	for( i=(ActiveVoters.Length-1); i>=0; --i )
		if( ActiveVoters[i].PlayerOwner==PC )
		{
			ActiveVoters[i].ClientOpenMapvote(false);
			return;
		}
}
final function AddMap( string M )
{
	if( Class'KFGameInfo'.Default.GameMapCycles.Length==0 )
		Class'KFGameInfo'.Default.GameMapCycles.Length = 1;
	Class'KFGameInfo'.Default.GameMapCycles[0].Maps.AddItem(M);
	Class'KFGameInfo'.Static.StaticSaveConfig();
}
final function bool RemoveMap( string M )
{
	local int i,j;

	for( i=(Class'KFGameInfo'.Default.GameMapCycles.Length-1); i>=0; --i )
	{
		for( j=(Class'KFGameInfo'.Default.GameMapCycles[i].Maps.Length-1); j>=0; --j )
		{
			if( Class'KFGameInfo'.Default.GameMapCycles[i].Maps[j]~=M )
			{
				Class'KFGameInfo'.Default.GameMapCycles[i].Maps.Remove(j,1);
				Class'KFGameInfo'.Static.StaticSaveConfig();
				return true;
			}
		}
	}
	return false;
}

defaultproperties
{
	BaseMutator=Class'xVotingHandler'
	AnnouncerCues.Add(SoundCue'xVoteAnnouncer.VX_one_Cue')
	AnnouncerCues.Add(SoundCue'xVoteAnnouncer.VX_two_Cue')
	AnnouncerCues.Add(SoundCue'xVoteAnnouncer.VX_three_Cue')
	AnnouncerCues.Add(SoundCue'xVoteAnnouncer.VX_four_Cue')
	AnnouncerCues.Add(SoundCue'xVoteAnnouncer.VX_five_Cue')
	AnnouncerCues.Add(SoundCue'xVoteAnnouncer.VX_six_Cue')
	AnnouncerCues.Add(SoundCue'xVoteAnnouncer.VX_seven_Cue')
	AnnouncerCues.Add(SoundCue'xVoteAnnouncer.VX_eight_Cue')
	AnnouncerCues.Add(SoundCue'xVoteAnnouncer.VX_nine_Cue')
	AnnouncerCues.Add(SoundCue'xVoteAnnouncer.VX_ten_Cue')
	AnnouncerCues.Add(SoundCue'xVoteAnnouncer.VX_20_seconds_Cue')
	AnnouncerCues.Add(SoundCue'xVoteAnnouncer.VX_30_seconds_Cue')
	AnnouncerCues.Add(SoundCue'xVoteAnnouncer.VX_1_minute_Cue')
	AnnouncerCues.Add(SoundCue'xVoteAnnouncer.VX_HolyShit_Cue')
}