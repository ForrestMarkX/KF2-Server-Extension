Class KFGUI_FloatingWindowHeader extends KFGUI_Base;

var bool bDragWindow;

function PreDraw()
{
	ComputeCoords();
}
function MouseClick( bool bRight )
{
	if( !bRight )
		KFGUI_FloatingWindow(ParentComponent).SetWindowDrag(true);
}
function MouseRelease( bool bRight )
{
	if( !bRight )
		KFGUI_FloatingWindow(ParentComponent).SetWindowDrag(false);
}

defaultproperties
{
	bClickable=true
}