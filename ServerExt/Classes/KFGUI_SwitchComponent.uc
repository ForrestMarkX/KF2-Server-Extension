// A component to have multiple "pages" of different components.
Class KFGUI_SwitchComponent extends KFGUI_MultiComponent;

var protected int CurrentComponent;

function PreDraw()
{
	local byte j;

	ComputeCoords();
	if( CurrentComponent<0 || CurrentComponent>=Components.Length )
		return;
	Components[CurrentComponent].Canvas = Canvas;
	for( j=0; j<4; ++j )
		Components[CurrentComponent].InputPos[j] = CompPos[j];
	Components[CurrentComponent].PreDraw();
}

function bool CaptureMouse()
{
	if( (CurrentComponent>=0 || CurrentComponent<Components.Length) && Components[CurrentComponent].CaptureMouse() )
	{
		MouseArea = Components[CurrentComponent];
		return true;
	}
	MouseArea = None;
	return Super(KFGUI_Base).CaptureMouse(); // check with frame itself.
}

final function int GetSelectedPage()
{
	return CurrentComponent;
}
final function name GetSelectedPageID()
{
	if( CurrentComponent<Components.Length )
		return Components[CurrentComponent].ID;
	return '';
}
final function bool SelectPageID( name PageID )
{
	local int i;
	
	if( Components[CurrentComponent].ID==PageID )
		return false;

	for( i=0; i<Components.Length; ++i )
		if( Components[i].ID==PageID )
		{
			Components[CurrentComponent].CloseMenu();
			CurrentComponent = i;
			Components[CurrentComponent].ShowMenu();
			return true;
		}
	return false;
}
final function bool SelectPageIndex( int Num )
{
	if( CurrentComponent==Num )
		return false;

	if( Num>=0 && Num<Components.Length )
	{
		Components[CurrentComponent].CloseMenu();
		CurrentComponent = Num;
		Components[CurrentComponent].ShowMenu();
		return true;
	}
	return false;
}

function ShowMenu()
{
	if( CurrentComponent<Components.Length )
		Components[CurrentComponent].ShowMenu();
}
function CloseMenu()
{
	if( CurrentComponent<Components.Length )
		Components[CurrentComponent].CloseMenu();
}
