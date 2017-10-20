Class KFGUI_Button extends KFGUI_Clickable;

var() Canvas.CanvasIcon OverlayTexture;
var() string ButtonText;
var() color TextColor;
var() Canvas.FontRenderInfo TextFontInfo;
var() byte FontScale,ExtravDir;
var bool bIsHighlighted;

function DrawMenu()
{
	Owner.CurrentStyle.RenderButton(Self);
}

function HandleMouseClick( bool bRight )
{
	PlayMenuSound(MN_ClickButton);
	if( bRight )
		OnClickRight(Self);
	else OnClickLeft(Self);
}

Delegate OnClickLeft( KFGUI_Button Sender );
Delegate OnClickRight( KFGUI_Button Sender );

defaultproperties
{
	ButtonText="Button!"
	TextColor=(R=255,G=255,B=255,A=255)
	TextFontInfo=(bClipText=true,bEnableShadow=true)
	FontScale=1
}