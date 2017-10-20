Class KFGUI_RightClickMenu extends KFGUI_Clickable;

struct FRowItem
{
	var string Text;
	var int Value;
	var bool bSplitter,bDisabled;
};
var array<FRowItem> ItemRows;
var int CurrentRow,OldRow;
var int EdgeSize;

function OpenMenu( KFGUI_Base Menu )
{
	Owner = Menu.Owner;
	InitMenu();
	PlayMenuSound(MN_Dropdown);
	
	// Calc needed size for this menu.
	ComputeSize();
	XPosition = float(Owner.MousePosition.X+4) / Owner.ScreenSize.X;
	YPosition = float(Owner.MousePosition.Y+4) / Owner.ScreenSize.Y;
	if( (XPosition+XSize)>1.f )
		YPosition = (float(Owner.MousePosition.X) / Owner.ScreenSize.X) - XSize; // Move to left side of mouse pointer.
	if( (YPosition+YSize)>1.f )
		YPosition-=((YPosition+YSize)-1.f); // Move up until fit on screen.
	GetInputFocus();
}
final function ComputeSize()
{
	local float XS,YS,Scalar;
	local int i,XL,YL;
	local Font F;
	local string S;

	if( ItemRows.Length==0 )
	{
		YS = 0;
		XS = 50;
	}
	else
	{
		YS = Owner.CurrentStyle.DefaultHeight * ItemRows.Length;
		XS = 20;
		F = Owner.CurrentStyle.PickFont(Owner.CurrentStyle.DefaultFontSize,Scalar);
		for( i=0; i<ItemRows.Length; ++i )
		{
			if( ItemRows[i].bSplitter )
				S = "----";
			else S = ItemRows[i].Text;
			F.GetStringHeightAndWidth(S,YL,XL);
			XS = FMax(XS,float(XL)*Scalar);
		}
	}
	XSize = (XS+(EdgeSize*2)) / Owner.ScreenSize.X;
	YSize = (YS+(EdgeSize*2)) / Owner.ScreenSize.Y;
}
final function AddRow( string Text, bool bDisable )
{
	local int i;
	
	i = ItemRows.Length;
	ItemRows.Length = i+1;
	if( Text=="-" )
		ItemRows[i].bSplitter = true;
	else
	{
		ItemRows[i].Text = Text;
		ItemRows[i].bDisabled = bDisable;
	}
}
function DrawMenu()
{
	Owner.CurrentStyle.RenderRightClickMenu(Self);
}
function HandleMouseClick( bool bRight )
{
	if( CurrentRow>=0 && (ItemRows[CurrentRow].bSplitter || ItemRows[CurrentRow].bDisabled) )
		return;
	PlayMenuSound(MN_ClickButton);
	DropInputFocus();
	if( CurrentRow>=0 )
		OnSelectedItem(CurrentRow);
}
function LostInputFocus()
{
	OnBecameHidden(Self);
}

Delegate OnSelectedItem( int Index );
Delegate OnBecameHidden( KFGUI_RightClickMenu M );

defaultproperties
{
	CurrentRow=-1
	OldRow=-1
	bFocusedPostDrawItem=true
	EdgeSize=4
}