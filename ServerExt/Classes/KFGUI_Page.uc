Class KFGUI_Page extends KFGUI_MultiComponent
	abstract;

var() byte FrameOpacity; // Transperancy of the frame.
var() bool bPersistant, // Reuse the same menu object throughout the level.
			bUnique, // If calling OpenMenu multiple times with same menu class, only open one instance of it.
			bAlwaysTop, // This menu should stay always on top.
			bOnlyThisFocus; // Only this menu should stay focused.

var bool bWindowFocused; // This page is currently focused.

function DrawMenu()
{
	Owner.CurrentStyle.RenderWindow(Self);
}

defaultproperties
{
	bUnique=true
	bPersistant=true
	FrameOpacity=220
}