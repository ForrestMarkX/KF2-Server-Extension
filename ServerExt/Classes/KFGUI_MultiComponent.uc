Class KFGUI_MultiComponent extends KFGUI_Base;

var() export editinline array<KFGUI_Base> Components;

function InitMenu()
{
	local int i;
	
	for( i=0; i<Components.Length; ++i )
	{
		Components[i].Owner = Owner;
		Components[i].ParentComponent = Self;
		Components[i].InitMenu();
	}
}
function ShowMenu()
{
	local int i;
	
	for( i=0; i<Components.Length; ++i )
		Components[i].ShowMenu();
}
function PreDraw()
{
	local int i;
	local byte j;

	ComputeCoords();
	Canvas.SetDrawColor(255,255,255);
	Canvas.SetOrigin(CompPos[0],CompPos[1]);
	Canvas.SetClip(CompPos[0]+CompPos[2],CompPos[1]+CompPos[3]);
	DrawMenu();
	for( i=0; i<Components.Length; ++i )
	{
		Components[i].Canvas = Canvas;
		for( j=0; j<4; ++j )
			Components[i].InputPos[j] = CompPos[j];
		Components[i].PreDraw();
	}
}
function MenuTick( float DeltaTime )
{
	local int i;

	Super.MenuTick(DeltaTime);
	for( i=0; i<Components.Length; ++i )
		Components[i].MenuTick(DeltaTime);
}

function AddComponent( KFGUI_Base C )
{
	Components[Components.Length] = C;
	C.Owner = Owner;
	C.ParentComponent = Self;
	C.InitMenu();
}

function CloseMenu()
{
	local int i;
	
	for( i=0; i<Components.Length; ++i )
		Components[i].CloseMenu();
}
function bool CaptureMouse()
{
	local int i;
	
	for( i=0; i<Components.Length; ++i )
		if( Components[i].CaptureMouse() )
		{
			MouseArea = Components[i];
			return true;
		}
	MouseArea = None;
	return Super.CaptureMouse(); // check with frame itself.
}
function KFGUI_Base FindComponentID( name InID )
{
	local int i;
	local KFGUI_Base Result;

	if( ID==InID )
		Result = Self;
	else
	{
		for( i=0; i<Components.Length && Result==None; ++i )
			Result = Components[i].FindComponentID(InID);
	}
	return Result;
}
function FindAllComponentID( name InID, out array<KFGUI_Base> Res )
{
	local int i;

	if( ID==InID )
		Res[Res.Length] = Self;
	for( i=0; i<Components.Length; ++i )
		Components[i].FindAllComponentID(InID,Res);
}
function RemoveComponent( KFGUI_Base B )
{
	local int i;
	
	for( i=0; i<Components.Length; ++i )
		if( Components[i]==B )
		{
			Components.Remove(i,1);
			B.CloseMenu();
			return;
		}
	for( i=0; i<Components.Length; ++i )
		Components[i].RemoveComponent(B);
}
function NotifyLevelChange()
{
	local int i;
	
	for( i=0; i<Components.Length; ++i )
		Components[i].NotifyLevelChange();
}
