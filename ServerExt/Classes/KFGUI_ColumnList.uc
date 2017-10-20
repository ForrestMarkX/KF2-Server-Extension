// Columned list box (only for text lines).
Class KFGUI_ColumnList extends KFGUI_List;

struct FColumnItem
{
	var() string Text;
	var() float Width;
	
	var transient bool bHidden;
	var transient int X,XSize;
};
var() array<FColumnItem> Columns;
var() class<KFGUI_ListItem> ListItemClass;
var() int FontSize;
var() color FocusedLineColor,SelectedLineColor;
var KFGUI_ColumnTop ColumnComp;
var Canvas.FontRenderInfo LineFontInfo;

var int SelectedRowIndex;
var int LastSortedColumn;

var transient float TextHeight,ScalerSize,TextScaler;
var transient int OldItemsPerFrame;

var KFGUI_ListItem FirstItem,UnusedItem;

var transient bool bListSizeDirty;
var bool bLastSortedReverse;
var() bool bShouldSortList; // Should sort any new items added to the list instantly.
var() bool bCanSortColumn; // Allow user to sort columns.

delegate OnSelectedRow( KFGUI_ListItem Item, int Row, bool bRight, bool bDblClick );

function KFGUI_ListItem AddLine( string Value, optional int iValue, optional string SortValue, optional int Index=-1 )
{
	local KFGUI_ListItem N,O;
	local int i;
	
	// Allocate list item object.
	if( UnusedItem!=None )
	{
		N = UnusedItem;
		UnusedItem = N.Next;
		N.Next = None;
	}
	else N = new (None) ListItemClass;
	
	// Setup column text value.
	N.SetValue(Value,iValue,SortValue);

	// Insert into list.
	if( bShouldSortList && Index==-1 )
	{
		N.Temp = N.GetSortStr(LastSortedColumn);
		
		if( ListCount==0 ) // No sorting needed yet.
		{
			N.Next = FirstItem;
			FirstItem = N;
		}
		else if( bLastSortedReverse )
		{
			if( FirstItem.Temp<N.Temp )
			{
				N.Next = FirstItem;
				FirstItem = N;
			}
			else
			{
				for( O=FirstItem; O!=None; O=O.Next )
				{
					if( O.Next==None || O.Next.Temp<N.Temp )
					{
						N.Next = O.Next;
						O.Next = N;
						break;
					}
				}
			}
		}
		else if( FirstItem.Temp>N.Temp )
		{
			N.Next = FirstItem;
			FirstItem = N;
		}
		else
		{
			for( O=FirstItem; O!=None; O=O.Next )
			{
				if( O.Next==None || O.Next.Temp>N.Temp )
				{
					N.Next = O.Next;
					O.Next = N;
					break;
				}
			}
		}
	}
	else if( Index==-1 || Index>ListCount )
		Index = ListCount;
	if( Index==0 )
	{
		N.Next = FirstItem;
		FirstItem = N;
	}
	else
	{
		i = 0;
		for( O=FirstItem; O!=None; O=O.Next )
		{
			if( (++i)==Index )
			{
				N.Next = O.Next;
				O.Next = N;
				break;
			}
		}
	}
	UpdateListSize();
	
	return N;
}
final function RemoveLine( KFGUI_ListItem I )
{
	local KFGUI_ListItem N;
	
	if( I.Index==-1 )
		return;
	
	// Update selected row info.
	if( SelectedRowIndex==I.Index )
		SelectedRowIndex = -1;
	else if( SelectedRowIndex>I.Index )
		--SelectedRowIndex;

	// Remove from list.
	if( FirstItem==I )
		FirstItem = I.Next;
	else
	{
		for( N=FirstItem; N!=None; N=N.Next )
			if( N.Next==I )
			{
				N.Next = I.Next;
				break;
			}
	}
	
	// Add to unused list.
	I.Next = UnusedItem;
	UnusedItem = I;
	I.Index = -1;

	UpdateListSize();
}
final function EmptyList()
{
	local KFGUI_ListItem N,I;

	for( I=FirstItem; I!=None; I=N )
	{
		N = I.Next;
		
		// Add to unused list.
		I.Next = UnusedItem;
		UnusedItem = I;
		I.Index = -1;
	}

	FirstItem = None;
	UpdateListSize();
}

final function KFGUI_ListItem GetFromIndex( int Index )
{
	local KFGUI_ListItem N;

	if( Index<0 || Index>=ListCount )
		return None;
	for( N=FirstItem; N!=None; N=N.Next )
		if( (Index--)==0 )
			return N;
	return None;
}

function SortColumn( int Column, optional bool bReverse )
{
	local array<KFGUI_ListItem> List;
	local KFGUI_ListItem Sel,N,P;
	local int i;
	
	if( !bCanSortColumn || Column<0 || Column>=Columns.Length )
		return;

	LastSortedColumn = Column;
	bLastSortedReverse = bReverse;
	bShouldSortList = true;

	// Allocate memory space first.
	List.Length = ListCount;
	List.Length = 0;
	
	// Grab current selected line.
	Sel = GetFromIndex(SelectedRowIndex);
	SelectedRowIndex = -1;
	
	// Slow, sort it all.
	for( N=FirstItem; N!=None; N=N.Next )
	{
		N.Temp = N.GetSortStr(Column);

		if( bReverse )
		{
			for( i=0; i<List.Length; ++i )
				if( List[i].Temp<N.Temp )
					break;
		}
		else
		{
			for( i=0; i<List.Length; ++i )
				if( List[i].Temp>N.Temp )
					break;
		}
		List.Insert(i,1);
		List[i] = N;
	}
	
	// Rebuild list.
	FirstItem = None;
	P = None;
	for( i=0; i<List.Length; ++i )
	{
		N = List[i];
		if( Sel==N )
			SelectedRowIndex = i;
		N.Index = i;
		N.Next = None;
		if( P==None )
			FirstItem = N;
		else P.Next = N;
		P = N;
	}
}

function ChangeListSize( int NewSize );

final function UpdateListSize()
{
	local KFGUI_ListItem N;
	
	ListCount = 0;
	for( N=FirstItem; N!=None; N=N.Next )
		N.Index = ListCount++;
	bListSizeDirty = true;
}

function InitMenu()
{
	ListCount = 0;
	Super.InitMenu();
	ColumnComp = KFGUI_ColumnTop(FindComponentID('Columns'));
}

final function DrawStrClipped( string S )
{
	Canvas.PushMaskRegion(Canvas.OrgX,Canvas.OrgY,Canvas.ClipX,Canvas.ClipY);
	Canvas.DrawText(S,,TextScaler,TextScaler,LineFontInfo);
	Canvas.PopMaskRegion();
}

function DrawMenu()
{
	local int i,n,j;
	local float Y,TextY,YClip,XOffset;
	local KFGUI_ListItem C;
	local bool bCheckMouse;

	Canvas.DrawColor = BackgroundColor;
	Canvas.SetPos(0.f,0.f);
	Owner.CurrentStyle.DrawWhiteBox(CompPos[2],CompPos[3]);
	
	// Mouse focused item check.
	bCheckMouse = bClickable && bFocused;
	FocusMouseItem = -1;
	if( bCheckMouse )
		MouseYHit = Owner.MousePosition.Y - CompPos[1];

	n = ScrollBar.CurrentScroll;
	i = 0;
	for( C=FirstItem; C!=None; C=C.Next )
		if( (i++)==n )
			break;
	Y = 0.f;
	TextY = (ItemHeight-TextHeight)*0.5f;
	XOffset = TextY*0.75;
	YClip = CompPos[1]+CompPos[3];
	Canvas.SetDrawColor(250,250,250,255);

	for( i=0; (i<ListItemsPerPage && C!=None); ++i )
	{
		// Check for mouse hit.
		if( bCheckMouse && FocusMouseItem==-1 )
		{
			if( MouseYHit<ItemHeight )
				FocusMouseItem = n;
			else MouseYHit-=ItemHeight;
		}
		
		// Draw selection background.
		if( SelectedRowIndex==n ) // Selected
		{
			Canvas.SetPos(0,Y);
			Canvas.DrawColor = SelectedLineColor;
			Owner.CurrentStyle.DrawWhiteBox(CompPos[2],ItemHeight);
			Canvas.SetDrawColor(250,250,250,255);
		}
		else if( FocusMouseItem==n ) // Focused
		{
			Canvas.SetPos(0,Y);
			Canvas.DrawColor = FocusedLineColor;
			Owner.CurrentStyle.DrawWhiteBox(CompPos[2],ItemHeight);
			Canvas.SetDrawColor(250,250,250,255);
		}
		
		// Draw columns of text
		for( j=0; j<Columns.Length; ++j )
			if( !Columns[j].bHidden )
			{
				Canvas.SetClip(Columns[j].X+Columns[j].XSize,YClip);
				Canvas.SetPos(Columns[j].X+XOffset,TextY);
				DrawStrClipped(C.GetDisplayStr(j));
			}
		Y+=ItemHeight;
		TextY+=ItemHeight;
		++n;
		C = C.Next;
	}
}

function PreDraw()
{
	local byte j;
	local float XS,SpaceX;

	ComputeCoords();
	
	// Check font to use.
	Canvas.Font = Owner.CurrentStyle.PickFont(Min(FontSize+Owner.CurrentStyle.DefaultFontSize,Owner.CurrentStyle.MaxFontScale),TextScaler);
	Canvas.TextSize("ABC",XS,TextHeight,TextScaler,TextScaler);
	
	for( j=0; j<4; ++j )
	{
		ScrollBar.InputPos[j] = CompPos[j];
		ColumnComp.InputPos[j] = CompPos[j];
	}
	
	// Setup positioning.
	// First compute the width scrollbar.
	if( OldXSize!=InputPos[2] )
	{
		OldXSize = InputPos[2];
		ScalerSize = ScrollBar.GetWidth();
		ScrollBar.XPosition = 1.f - ScalerSize;
		ColumnComp.XSize = ScrollBar.XPosition;
	}
	SpaceX = ScalerSize*CompPos[2];
	CompPos[2] -= SpaceX;
	ScrollBar.InputPos[3] = CompPos[3];

	// Draw columns.
	ColumnComp.YSize = (TextHeight*1.05) / CompPos[3];
	ColumnComp.Canvas = Canvas;
	ColumnComp.PreDraw();
	
	// Move down to give space for columns.
	CompPos[1] += ColumnComp.CompPos[3];
	CompPos[3] -= ColumnComp.CompPos[3];

	// Compute how many rows fit in with this setting.
	ItemHeight = TextHeight*1.025;
	ListItemsPerPage = CompPos[3]/ItemHeight;
	ItemHeight = CompPos[3]/ListItemsPerPage;
	if( OldItemsPerFrame!=ListItemsPerPage || bListSizeDirty )
	{
		if( SelectedRowIndex>=ListCount )
			SelectedRowIndex = -1;
		OldItemsPerFrame = ListItemsPerPage;
		bListSizeDirty = false;
		UpdateListVis();
	}

	// Draw vertical scrollbar
	ScrollBar.Canvas = Canvas;
	ScrollBar.PreDraw();
	
	// Draw self.
	Canvas.SetOrigin(CompPos[0],CompPos[1]);
	Canvas.SetClip(CompPos[0]+CompPos[2],CompPos[1]+CompPos[3]);
	DrawMenu();
	
	// Reset scaling to allow mouse to capture input.
	CompPos[1] -= ColumnComp.CompPos[3];
	CompPos[2] += SpaceX;
	CompPos[3] += ColumnComp.CompPos[3];
}
function InternalClickedItem( int Index, bool bRight, int MouseX, int MouseY )
{
	SelectedRowIndex = Index;
	OnSelectedRow(GetFromIndex(Index),Index,bRight,false);
}
function InternalDblClickedItem( int Index, bool bRight, int MouseX, int MouseY )
{
	SelectedRowIndex = Index;
	OnSelectedRow(GetFromIndex(Index),Index,bRight,true);
}

defaultproperties
{
	ListItemClass=class'KFGUI_ListItem'
	OnClickedItem=InternalClickedItem
	OnDblClickedItem=InternalDblClickedItem
	SelectedRowIndex=-1
	bClickable=true
	FocusedLineColor=(R=64,G=3,B=48,A=255)
	SelectedLineColor=(R=84,G=26,B=128,A=255)
	bCanSortColumn=true

	Begin Object Class=KFGUI_ColumnTop Name=ColumnComps
		XPosition=0
		YPosition=0
		XSize=1
		YSize=0.04
		ID="Columns"
	End Object
	Components.Add(ColumnComps)
	
	LineFontInfo=(bClipText=true,bEnableShadow=false)
}