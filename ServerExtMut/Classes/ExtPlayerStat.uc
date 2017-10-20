// Byte serialization, written by Marco.
Class ExtPlayerStat extends Object implements(ExtSaveDataBase);

var int ArVersion,SaveNum;
var transient int BufferOffset,BufferSize;
var transient array<int> EOFStack;
var array<byte> Buffer;
var array<string> StrMap;
const CurrentSaveVer=1;

final function bool LoadStatFile( PlayerController Other )
{
	local string S;

	FlushData();
	S = class'ServerExtMut'.Static.GetStatFile(Other.PlayerReplicationInfo.UniqueId);
	if( Class'Engine'.Static.BasicLoadObject(Self,S,false,CurrentSaveVer) )
	{
		BufferSize = Buffer.Length;
		return true;
	}
	BufferSize = 0;
	Buffer.Length = 0;
	return false;
}
final function SaveStatFile( PlayerController Other )
{
	local string S;

	S = class'ServerExtMut'.Static.GetStatFile(Other.PlayerReplicationInfo.UniqueId);
	Class'Engine'.Static.BasicSaveObject(Self,S,false,CurrentSaveVer);
}

function SaveInt( int Value, optional byte MaxVal )
{
	++MaxVal;
	if( (BufferOffset+MaxVal)>Buffer.Length )
	{
		Buffer.Length = (BufferOffset+MaxVal);
		BufferSize = Buffer.Length;
	}
	Buffer[BufferOffset++] = Value & 255;
	if( MaxVal>1 )
	{
		Buffer[BufferOffset++] = (Value >> 8) & 255;
		if( MaxVal>2 )
		{
			Buffer[BufferOffset++] = (Value >> 16) & 255;
			if( MaxVal>3 )
				Buffer[BufferOffset++] = (Value >> 24) & 255;
		}
	}
}
function int ReadInt( optional byte MaxVal )
{
	local int Res;

	++MaxVal;
	if( (BufferOffset+MaxVal)>BufferSize )
		return 0;

	Res = Buffer[BufferOffset++];
	if( MaxVal>1 )
	{
		Res = Res | (Buffer[BufferOffset++] << 8);
		if( MaxVal>2 )
		{
			Res = Res | (Buffer[BufferOffset++] << 16);
			if( MaxVal>3 )
				Res = Res | (Buffer[BufferOffset++] << 24);
		}
	}
	return Res;
}
function SaveStr( string S )
{
	local int i;
	
	if( S=="" )
	{
		SaveInt(0,1);
		return;
	}
	S = Left(S,255);
	i = StrMap.Find(S);
	if( i==-1 )
	{
		i = StrMap.Length;
		StrMap[StrMap.Length] = S;
	}
	SaveInt((i+1),1);
}
function string ReadStr()
{
	local int i;
	
	i = ReadInt(1);
	if( i==0 || i>StrMap.Length )
		return "";
	return StrMap[i-1];
}

function int TellOffset()
{
	return BufferOffset;
}
function SeekOffset( int Offset )
{
	BufferOffset = Clamp(Offset,0,BufferSize);
}
function int TotalSize()
{
	return BufferSize;
}
function ToEnd()
{
	BufferOffset = BufferSize;
}
function ToStart()
{
	BufferOffset = 0;
}
function bool AtEnd()
{
	return (BufferOffset>=BufferSize);
}
function SkipBytes( int Count )
{
	BufferOffset = Clamp(BufferOffset+Count,0,BufferSize);
}

function FlushData()
{
	ArVersion = 0;
	SaveNum = 0;
	BufferOffset = 0;
	BufferSize = 0;
	Buffer.Length = 0;
	EOFStack.Length = 0;
	StrMap.Length = 0;
}

final function DebugData()
{
	local string S,SS;
	local array<byte> B;
	local int i;
	
	GetData(B);
	`Log("DEBUG DATA: Data size: "$B.Length);
	for( i=0; i<B.Length; ++i )
	{
		S $= Chr(Max(B[i],1));
		SS $= "."$B[i];
	}
	`Log("DEBUG DATA: "$S);
	`Log("DEBUG DATA: "$SS);
}

function GetData( out array<byte> Res )
{
	local int i,l,o,j;

	Res = Buffer;
	Res.Insert(0,1);
	Res[0] = ArVersion;
	
	// Add string map to start.
	// Write string map length.
	Res.Insert(1,2);
	l = StrMap.Length;
	Res[1] = l & 255;
	Res[2] = (l >> 8) & 255;
	o = 3;
	
	// write each entry.
	for( i=0; i<StrMap.Length; ++i )
	{
		l = Len(StrMap[i]);
		Res.Insert(o,l+1);
		Res[o++] = l;
		for( j=0; j<l; ++j )
			Res[o++] = Asc(Mid(StrMap[i],j,1));
	}
}
function SetData( out array<byte> S )
{
	local int i,o,l,j;

	ArVersion = S[0];
	Buffer = S;

	// read string map length.
	StrMap.Length = Buffer[1] | (Buffer[2] << 8);
	o = 3;
	
	// read each string map entry.
	for( i=0; i<StrMap.Length; ++i )
	{
		l = Buffer[o++];
		StrMap[i] = "";
		for( j=0; j<l; ++j )
			StrMap[i] $= Chr(Buffer[o++]);
	}
	Buffer.Remove(0,o);

	BufferSize = Buffer.Length;
}

function int GetArVer()
{
	return ArVersion;
}
function SetArVer( int Ver )
{
	ArVersion = Ver;
}

function PushEOFLimit( int EndOffset )
{
	EOFStack.AddItem(BufferSize);
	BufferSize = EndOffset;
}
function PopEOFLimit()
{
	if( EOFStack.Length==0 )
	{
		`Log(Self@"WARNING: Tried to pop one EoF stack down too far!!!");
		return; // Whoops, error.
	}
	BufferSize = EOFStack[EOFStack.Length-1];
	EOFStack.Length = EOFStack.Length-1;
}

function int GetSaveVersion()
{
	return SaveNum;
}
function SetSaveVersion( int Num )
{
	SaveNum = Num;
}

defaultproperties
{
}