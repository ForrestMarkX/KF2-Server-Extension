Class ExtGUI_PerkSelectionPage extends UI_MidGameMenu;

function InitMenu()
{
	local byte i;
	local KFGUI_Button B;
	
	PageSwitcher = KFGUI_SwitchMenuBar(FindComponentID('Pager'));
	Super(KFGUI_Page).InitMenu();
	
	for( i=0; i<Pages.Length; ++i )
	{
		PageSwitcher.AddPage(Pages[i].PageClass,Pages[i].Caption,Pages[i].Hint,B).InitMenu();
	}
}

function ShowMenu()
{
	Super(KFGUI_FloatingWindow).ShowMenu();
}

function PreDraw()
{
	local GameViewportClient Viewport;
	local ExtMoviePlayer_Manager MovieManager;
	
	Super.PreDraw();
	
	Viewport = LocalPlayer(GetPlayer().Player).ViewportClient;
	MovieManager = ExtMoviePlayer_Manager(KFPlayerController(GetPlayer()).MyGFxManager);
	if( CaptureMouse() )
	{
		Viewport.bDisplayHardwareMouseCursor = true;
		Viewport.ForceUpdateMouseCursor(true);

		MovieManager.SetMovieCanReceiveInput(false);
	}
	else if( Viewport.bDisplayHardwareMouseCursor )
	{
		Viewport.bDisplayHardwareMouseCursor = false;
		Viewport.ForceUpdateMouseCursor(true);
		
		MovieManager.SetMovieCanReceiveInput(true);
	}
}

function UserPressedEsc();

defaultproperties
{
	WindowTitle=""
	
	XPosition=0.01
	XSize=0.73
	YSize=0.73
	
	Pages.Empty
	Pages.Add((PageClass=Class'UIP_PerkSelectionLobby',Caption="Perk",Hint="Select and upgrade your perks"))
}