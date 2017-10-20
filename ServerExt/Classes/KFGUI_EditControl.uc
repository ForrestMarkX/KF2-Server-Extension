Class KFGUI_EditControl extends KFGUI_Clickable;

var export editinline KFGUI_TextLable TextLable;
var transient float TextHeight,TextScale;
var transient Font TextFont;
var Canvas.FontRenderInfo TextFontInfo;

var(Lable) float LableWidth;
var(Lable) string LableString;
var(Lable) color LableColor; // Label text color.
var(Lable) byte FontScale;
var(Lable) bool bScaleByFontSize; // Scale this component height by font height.

function InitMenu()
{
	if( LableString=="" )
		TextLable = None;
	else
	{
		TextLable.SetText(LableString);
		TextLable.FontScale = FontScale;
		TextLable.XPosition = XPosition;
		TextLable.YPosition = YPosition;
		TextLable.XSize = (XSize*LableWidth*0.975);
		TextLable.YSize = YSize;
		TextLable.Owner = Owner;
		TextLable.TextColor = LableColor;
		TextLable.ParentComponent = Self;
		TextLable.InitMenu();
		XPosition+=(XSize*LableWidth);
		XSize*=(1.f-LableWidth);
	}
	Super.InitMenu();
	bClickable = !bDisabled;
}

function UpdateSizes()
{
	// Update height.
	if( bScaleByFontSize )
		YSize = ((TextHeight*1.05) + 6) / InputPos[3];
}

function PreDraw()
{
	local float XS;
	local byte i;

	Canvas.Font = Owner.CurrentStyle.PickFont(Min(FontScale+Owner.CurrentStyle.DefaultFontSize,Owner.CurrentStyle.MaxFontScale),TextScale);
	TextFont = Canvas.Font;
	Canvas.TextSize("ABC",XS,TextHeight,TextScale,TextScale);
	
	UpdateSizes();

	Super.PreDraw();
	if( TextLable!=None )
	{
		TextLable.YSize = YSize;
		TextLable.Canvas = Canvas;
		for( i=0; i<4; ++i )
			TextLable.InputPos[i] = InputPos[i];
		TextLable.PreDraw();
	}
}

final function DrawClippedText( string S, float TScale, float MaxX )
{
	local int i,l;
	local float X,XL,YL;
	
	l = Len(S);
	for( i=0; i<l; ++i )
	{
		Canvas.TextSize(Mid(S,i,1),XL,YL,TScale,TScale);
		if( (Canvas.CurX+X+XL)>MaxX )
		{
			--i;
			break;
		}
		X+=XL;
	}
	Canvas.DrawText(Left(S,i),,TScale,TScale,TextFontInfo);
}

defaultproperties
{
	LableColor=(R=255,G=255,B=255,A=255)
	FontScale=0
	LableWidth=0.5
	bScaleByFontSize=true
	TextFontInfo=(bClipText=true,bEnableShadow=true)

	Begin Object Class=KFGUI_TextLable Name=MyBoxLableText
		AlignX=0
		AlignY=1
		TextFontInfo=(bClipText=true,bEnableShadow=true)
	End Object
	TextLable=MyBoxLableText
}