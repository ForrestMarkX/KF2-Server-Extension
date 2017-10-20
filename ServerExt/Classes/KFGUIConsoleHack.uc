// Ugly hack to draw ontop of flash UI!
Class KFGUIConsoleHack extends Console;

var KF2GUIController OutputObject;

function PostRender_Console(Canvas Canvas)
{
	OutputObject.RenderMenu(Canvas);
}
