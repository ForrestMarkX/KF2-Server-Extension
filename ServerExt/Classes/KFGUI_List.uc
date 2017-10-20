// List box with custom render code for the items.
Class KFGUI_List extends KFGUI_MultiComponent;

var() bool bDrawBackground;
var() protected int ListCount;
var() int ListItemsPerPage;
var() color BackgroundColor;
var KFGUI_ScrollBarV ScrollBar;

var transient float OldXSize,ItemHeight,MouseYHit;
var transient int FocusMouseItem,LastFocusItem;

var byte PressedDown[2];
var bool bPressedDown;

delegate OnDrawItem( Canvas C, int Index, float YOffset, float Height, float Width, bool bFocus );

// Requires bClickable=true to receive this event.
delegate OnClickedItem( int Index, bool bRight, int MouseX, int MouseY );
delegate OnDblClickedItem( int Index, bool bRight, int MouseX, int MouseY );

function InitMenu()
{
	Super.InitMenu();
	ScrollBar = KFGUI_ScrollBarV(FindComponentID('Scrollbar'));
	UpdateListVis();
}

function DrawMenu()
{
	local int i,n;
	local float Y;
	local bool bCheckMouse;

	if( bDrawBackground )
	{
		Canvas.DrawColor = BackgroundColor;
		Canvas.SetPos(0.f,0.f);
		Owner.CurrentStyle.DrawWhiteBox(CompPos[2],CompPos[3]);
	}

	// Mouse focused item check.
	bCheckMouse = bClickable && bFocused;
	FocusMouseItem = -1;
	if( bCheckMouse )
		MouseYHit = Owner.MousePosition.Y - CompPos[1];

	n = ScrollBar.CurrentScroll;
	ItemHeight = CompPos[3] / ListItemsPerPage;
	Y = 0;
	for( i=0; i<ListItemsPerPage; ++i )
	{
		if( n>=ListCount )
			break;
		if( bCheckMouse && FocusMouseItem==-1 )
		{
			if( MouseYHit<ItemHeight )
				FocusMouseItem = n;
			else MouseYHit-=ItemHeight;
		}
		OnDrawItem(Canvas,n,Y,ItemHeight,CompPos[2],(FocusMouseItem==n));
		Y+=ItemHeight;
		++n;
	}
	if( LastFocusItem!=FocusMouseItem )
	{
		if( LastFocusItem!=-1 && !bDisabled && bClickable )
			PlayMenuSound(MN_DropdownChange);
		LastFocusItem = FocusMouseItem;
	}
}

function PreDraw()
{
	local int i;
	local byte j;

	ComputeCoords();
	
	// First draw scrollbar to allow it to resize itself.
	for( j=0; j<4; ++j )
		ScrollBar.InputPos[j] = CompPos[j];
	if( OldXSize!=InputPos[2] )
	{
		OldXSize = InputPos[2];
		ScrollBar.XPosition = 1.f - ScrollBar.GetWidth();
	}
	ScrollBar.Canvas = Canvas;
	ScrollBar.PreDraw();
	
	// Then downscale our selves to give room for scrollbar.
	CompPos[2] -= ScrollBar.CompPos[2];
	Canvas.SetOrigin(CompPos[0],CompPos[1]);
	Canvas.SetClip(CompPos[0]+CompPos[2],CompPos[1]+CompPos[3]);
	DrawMenu();
	CompPos[2] += ScrollBar.CompPos[2];
	
	// Then draw rest of components.
	for( i=0; i<Components.Length; ++i )
	{
		if( Components[i]!=ScrollBar )
		{
			Components[i].Canvas = Canvas;
			for( j=0; j<4; ++j )
				Components[i].InputPos[j] = CompPos[j];
			Components[i].PreDraw();
		}
	}
}
function UpdateListVis()
{
	if( ListCount<=ListItemsPerPage )
	{
		ScrollBar.UpdateScrollSize(0,1,1,1);
		ScrollBar.SetDisabled(true);
	}
	else
	{
		ScrollBar.UpdateScrollSize(ScrollBar.CurrentScroll,(ListCount-ListItemsPerPage),1,ListItemsPerPage);
		ScrollBar.SetDisabled(false);
	}
}
function ChangeListSize( int NewSize )
{
	if( ListCount==NewSize )
		return;
	ListCount = NewSize;
	UpdateListVis();
}
final function int GetListSize()
{
	return ListCount;
}

function DoubleMouseClick( bool bRight )
{
	if( !bDisabled && bClickable )
	{
		PlayMenuSound(MN_ClickButton);
		PressedDown[byte(bRight)] = 0;
		bPressedDown = (PressedDown[0]!=0 || PressedDown[1]!=0);
		OnDblClickedItem(FocusMouseItem,bRight,Owner.MousePosition.X-CompPos[0],MouseYHit);
	}
}
function MouseClick( bool bRight )
{
	if( !bDisabled && bClickable )
	{
		PressedDown[byte(bRight)] = 1;
		bPressedDown = true;
	}
}
function MouseRelease( bool bRight )
{
	if( !bDisabled && bClickable && PressedDown[byte(bRight)]==1 )
	{
		PlayMenuSound(MN_ClickButton);
		PressedDown[byte(bRight)] = 0;
		bPressedDown = (PressedDown[0]!=0 || PressedDown[1]!=0);
		OnClickedItem(FocusMouseItem,bRight,Owner.MousePosition.X-CompPos[0],MouseYHit);
	}
}
function MouseLeave()
{
	Super.MouseLeave();
	if( !bDisabled && bClickable )
		PlayMenuSound(MN_LostFocus);
	PressedDown[0] = 0;
	PressedDown[1] = 0;
	bPressedDown = false;
}
function MouseEnter()
{
	Super.MouseEnter();
	LastFocusItem = -1;
	if( !bDisabled && bClickable )
		PlayMenuSound(MN_Focus);
}

function ScrollMouseWheel( bool bUp )
{
	if( !ScrollBar.bDisabled )
		ScrollBar.ScrollMouseWheel(bUp);
}

function NotifyMousePaused()
{
	if( Owner.InputFocus==None && FocusMouseItem>=0 )
		OnMouseRest(FocusMouseItem);
}

Delegate OnMouseRest( int Item );

defaultproperties
{
	ListItemsPerPage=10
	ListCount=1
	BackgroundColor=(R=32,G=3,B=2,A=255)
	bDrawBackground=true

	Begin Object Class=KFGUI_ScrollBarV Name=ListScroller
		XPosition=0.96
		YPosition=0
		XSize=0.04
		YSize=1
		ID="Scrollbar"
	End Object
	Components.Add(ListScroller)
}