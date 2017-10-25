Class GUIStyleBase extends Object
	abstract;

var Texture2D ItemTex;
var() byte MaxFontScale;
var byte DefaultFontSize; // Default medium font size of current resolution.
var float DefaultHeight; // Default font text size.
var transient Canvas Canvas;

function InitStyle()
{
	ItemTex = Texture2D(DynamicLoadObject("UI_LevelChevrons_TEX.UI_LevelChevron_Icon_02",class'Texture2D'));
	if( ItemTex==None )
		ItemTex = Texture2D'EngineMaterials.DefaultWhiteGrid';
}
function RenderFramedWindow( KFGUI_FloatingWindow P );
function RenderWindow( KFGUI_Page P );
function RenderToolTip( KFGUI_Tooltip TT );
function RenderButton( KFGUI_Button B );
function RenderEditBox( KFGUI_EditBox E );
function RenderScrollBar( KFGUI_ScrollBarBase S );
function RenderColumnHeader( KFGUI_ColumnTop C, float XPos, float Width, int Index, bool bFocus, bool bSort );
function RenderCheckbox( KFGUI_CheckBox C );
function RenderComboBox( KFGUI_ComboBox C );
function RenderComboList( KFGUI_ComboSelector C );
function RenderRightClickMenu( KFGUI_RightClickMenu C );

function Font PickFont( byte i, out float Scaler );
function PickDefaultFontSize( float YRes )
{
	local int XL,YL;
	local string S;

	DefaultFontSize = 0;
	if( YRes>800 )
		++DefaultFontSize;
	if( YRes>1000 )
		++DefaultFontSize;
	//if( YRes>1200 )
		//++DefaultFontSize;
	//if( YRes>1300 )
		//++DefaultFontSize;

	S = "ABC";
	PickFont(DefaultFontSize,YRes).GetStringHeightAndWidth(S,YL,XL);
	DefaultHeight = float(YL)*YRes;
}
final function DrawText( byte Res, string S )
{
	local float Scale;
	
	Canvas.Font = PickFont(Res,Scale);
	Canvas.DrawText(S,,Scale,Scale);
}

final function DrawCornerTexNU( int SizeX, int SizeY, byte Dir ) // Draw non-uniform corner.
{
	switch( Dir )
	{
	case 0: // Up-left
		Canvas.DrawTile(ItemTex,SizeX,SizeY,77,15,-66,58);
		break;
	case 1: // Up-right
		Canvas.DrawTile(ItemTex,SizeX,SizeY,11,15,66,58);
		break;
	case 2: // Down-left
		Canvas.DrawTile(ItemTex,SizeX,SizeY,77,73,-66,-58);
		break;
	default: // Down-right
		Canvas.DrawTile(ItemTex,SizeX,SizeY,11,73,66,-58);
	}
}
final function DrawCornerTex( int Size, byte Dir )
{
	switch( Dir )
	{
	case 0: // Up-left
		Canvas.DrawTile(ItemTex,Size,Size,77,15,-66,58);
		break;
	case 1: // Up-right
		Canvas.DrawTile(ItemTex,Size,Size,11,15,66,58);
		break;
	case 2: // Down-left
		Canvas.DrawTile(ItemTex,Size,Size,77,73,-66,-58);
		break;
	default: // Down-right
		Canvas.DrawTile(ItemTex,Size,Size,11,73,66,-58);
	}
}
final function DrawWhiteBox( int XS, int YS )
{
	Canvas.DrawTile(ItemTex,XS,YS,19,45,1,1);
}

final function DrawRectBox( int X, int Y, int XS, int YS, int Edge, optional byte Extrav )
{
	if( Extrav==2 )
		Edge = Min(FMin(Edge,(XS)*0.5),YS);// Verify size.
	else Edge = Min(FMin(Edge,(XS)*0.5),(YS)*0.5);// Verify size.

	// Top left
	Canvas.SetPos(X,Y);
	DrawCornerTex(Edge,0);
	
	if( Extrav<=1 )
	{
		if( Extrav==0 )
		{
			// Top right
			Canvas.SetPos(X+XS-Edge,Y);
			DrawCornerTex(Edge,1);
			
			// Bottom right
			Canvas.SetPos(X+XS-Edge,Y+YS-Edge);
			DrawCornerTex(Edge,3);
			
			// Fill
			Canvas.SetPos(X+Edge,Y);
			DrawWhiteBox(XS-Edge*2,YS);
			Canvas.SetPos(X,Y+Edge);
			DrawWhiteBox(Edge,YS-Edge*2);
			Canvas.SetPos(X+XS-Edge,Y+Edge);
			DrawWhiteBox(Edge,YS-Edge*2);
		}
		else if( Extrav==1 )
		{
			// Top right
			Canvas.SetPos(X+XS,Y);
			DrawCornerTex(Edge,3);
			
			// Bottom right
			Canvas.SetPos(X+XS,Y+YS-Edge);
			DrawCornerTex(Edge,1);

			// Fill
			Canvas.SetPos(X+Edge,Y);
			DrawWhiteBox(XS-Edge,YS);
			Canvas.SetPos(X,Y+Edge);
			DrawWhiteBox(Edge,YS-Edge*2);
		}
		
		// Bottom left
		Canvas.SetPos(X,Y+YS-Edge);
		DrawCornerTex(Edge,2);
	}
	else
	{
		// Top right
		Canvas.SetPos(X+XS-Edge,Y);
		DrawCornerTex(Edge,1);
		
		// Bottom right
		Canvas.SetPos(X+XS-Edge,Y+YS);
		DrawCornerTex(Edge,2);
		
		// Bottom left
		Canvas.SetPos(X,Y+YS);
		DrawCornerTex(Edge,3);
		
		// Fill
		Canvas.SetPos(X,Y+Edge);
		DrawWhiteBox(XS,YS-Edge);
		Canvas.SetPos(X+Edge,Y);
		DrawWhiteBox(XS-Edge*2,Edge);
	}
}
