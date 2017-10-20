Class KFGUI_FloatingWindow extends KFGUI_Page
	abstract;

var() string WindowTitle; // Title of this window.
var float DragOffset[2];
var KFGUI_FloatingWindowHeader HeaderComp;
var bool bDragWindow;

function InitMenu()
{
	Super.InitMenu();
	HeaderComp = new (Self) class'KFGUI_FloatingWindowHeader';
	AddComponent(HeaderComp);
}
function DrawMenu()
{
	Owner.CurrentStyle.RenderFramedWindow(Self);
	
	if( HeaderComp!=None )
	{
		HeaderComp.CompPos[3] = Owner.CurrentStyle.DefaultHeight;
		HeaderComp.YSize = HeaderComp.CompPos[3] / CompPos[3]; // Keep header height fit the window height.
	}
}
function SetWindowDrag( bool bDrag )
{
	bDragWindow = bDrag;
	if( bDrag )
	{
		DragOffset[0] = Owner.MousePosition.X-CompPos[0];
		DragOffset[1] = Owner.MousePosition.Y-CompPos[1];
	}
}
function bool CaptureMouse()
{
	if( bDragWindow && HeaderComp!=None ) // Always keep focus on window frame now!
	{
		MouseArea = HeaderComp;
		return true;
	}
	return Super.CaptureMouse();
}
function PreDraw()
{
	if( bDragWindow )
	{
		XPosition = FClamp(Owner.MousePosition.X-DragOffset[0],0,InputPos[2]-CompPos[2]) / InputPos[2];
		YPosition = FClamp(Owner.MousePosition.Y-DragOffset[1],0,InputPos[3]-CompPos[3]) / InputPos[3];
	}
	Super.PreDraw();
}

defaultproperties
{
}