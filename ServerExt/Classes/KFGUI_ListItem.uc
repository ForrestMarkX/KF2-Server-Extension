Class KFGUI_ListItem extends Object
	transient;

var KFGUI_ListItem Next;
var array<string> Columns,SortColumns;
var int Index,Value;

var transient string Temp; // Cache sorting key.

function SetValue( string S, int i, string SortStr )
{
	ParseStringIntoArray(S,Columns,"\n",false);
	if( SortStr=="" )
		SortColumns.Length = 0;
	else ParseStringIntoArray(Caps(SortStr),SortColumns,"\n",false);
	Value = i;
}

// Return string to draw on HUD.
function string GetDisplayStr( int Column )
{
	if( Column<Columns.Length )
		return Columns[Column];
	return "";
}

// Return string to compare string with.
function string GetSortStr( int Column )
{
	if( SortColumns.Length>0 )
	{
		if( Column<SortColumns.Length )
			return SortColumns[Column];
	}
	if( Column<Columns.Length )
		return Caps(Columns[Column]);
	return "";
}

// Clear
function Clear()
{
	Columns.Length = 0;
}
