Class xMapVoteHistory extends Object
	config(xMapVoteHistory);

var config array<string> M;
struct FMapInfoEntry
{
	var config int U,D,S,N;
	var config string T;
};
var config array<FMapInfoEntry> N;

static final function int GetMapHistory( string MapName, string MapTitle )
{
	local int i;

	MapName = Caps(MapName);
	i = Default.M.Find(MapName);
	if( i==-1 )
	{
		i = Default.M.Length;
		Default.M.Length = i+1;
		Default.M[i] = MapName;
		Default.N.Length = i+1;
	}
	if( !(MapTitle~=MapName) && MapTitle!=Class'WorldInfo'.Default.Title && MapTitle!="" )
		Default.N[i].T = MapTitle;
	return i;
}
static final function GetHistory( int i, out int UpVotes, out int DownVotes, out int Seq, out int NumP, out string Title )
{
	UpVotes = Default.N[i].U;
	DownVotes = Default.N[i].D;
	Seq = Default.N[i].S;
	NumP = Default.N[i].N;
	Title = Default.N[i].T;
}

static final function UpdateMapHistory( int iWon )
{
	local int i;
	
	for( i=(Default.M.Length-1); i>=0; --i )
	{
		if( i==iWon )
		{
			++Default.N[i].N;
			Default.N[i].S = 0;
		}
		else ++Default.N[i].S;
	}
}
static final function AddMapKarma( int i, bool bUp )
{
	if( bUp )
		++Default.N[i].U;
	else ++Default.N[i].D;
}
