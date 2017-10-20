// Serialization system in UnrealScript, written by Marco.
Interface ExtSaveDataBase;

// File accessor helpers.
// MaxVal for integers are as follow (the lower number you use, the less bits will be reserved):
/*	0: 0-255
	1: 0-65535
	2: 0-16777215
	3: -2147483647 - 2147483647
*/
function SaveInt( int Value, optional byte MaxVal );
function int ReadInt( optional byte MaxVal );
function SaveStr( string S );
function string ReadStr();

// File offset management.
function int TellOffset();
function SeekOffset( int Offset );
function int TotalSize();
function ToEnd();
function ToStart();
function bool AtEnd();
function SkipBytes( int Count );

// Wipe out any saved data.
function FlushData();

// Get file contents in a byte array line.
function GetData( out array<byte> Res );
function SetData( out array<byte> S );

// Archive version (to allow modder to make upgraded stat binarily compatible)
function int GetArVer();
function SetArVer( int Ver );

// Push/Pop file limitators (to prevent it from reading EoF in sub sections).
function PushEOFLimit( int EndOffset );
function PopEOFLimit();

// Get most recent save version for this user.
function int GetSaveVersion();
function SetSaveVersion( int Num );
