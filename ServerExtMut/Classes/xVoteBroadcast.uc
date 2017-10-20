class xVoteBroadcast extends BroadcastHandler;

var BroadcastHandler NextBroadcaster;
var xVotingHandler Handler;

function UpdateSentText()
{
	NextBroadcaster.UpdateSentText();
}

function Broadcast( Actor Sender, coerce string Msg, optional name Type )
{
	if( (Type=='Say' || Type=='TeamSay') && Left(Msg,1)=="!" && PlayerController(Sender)!=None )
		Handler.ParseCommand(Mid(Msg,1),PlayerController(Sender));
	NextBroadcaster.Broadcast(Sender,Msg,Type);
}

function BroadcastTeam( Controller Sender, coerce string Msg, optional name Type )
{
	if( (Type=='Say' || Type=='TeamSay') && Left(Msg,1)=="!" && PlayerController(Sender)!=None )
		Handler.ParseCommand(Mid(Msg,1),PlayerController(Sender));
	NextBroadcaster.BroadcastTeam(Sender,Msg,Type);
}

function AllowBroadcastLocalized( actor Sender, class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	NextBroadcaster.AllowBroadcastLocalized(Sender,Message,Switch,RelatedPRI_1,RelatedPRI_2,OptionalObject);
}

event AllowBroadcastLocalizedTeam( int TeamIndex, actor Sender, class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	NextBroadcaster.AllowBroadcastLocalizedTeam(TeamIndex,Sender,Message,Switch,RelatedPRI_1,RelatedPRI_2,OptionalObject);
}

defaultproperties
{
}