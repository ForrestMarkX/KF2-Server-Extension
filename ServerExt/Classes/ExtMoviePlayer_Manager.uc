Class ExtMoviePlayer_Manager extends KFGFxMoviePlayer_Manager;

var ExtMenu_Gear EGearMenu;
var KF2GUIController MyGUIController;

event bool WidgetInitialized(name WidgetName, name WidgetPath, GFxObject Widget)
{
	local PlayerController PC;

	switch ( WidgetName )
	{
	case 'gearMenu':
		PC = GetPC();
		if( PC.PlayerReplicationInfo.bReadyToPlay && PC.WorldInfo.GRI.bMatchHasBegun )
			return true;
		if (EGearMenu == none)
		{
			EGearMenu = ExtMenu_Gear(Widget);
			EGearMenu.InitializeMenu(self);
		}
		OnMenuOpen( WidgetPath, EGearMenu );
		return true;
	default:
		return Super.WidgetInitialized(WidgetName,WidgetPath,Widget);
	}
}
function LaunchMenus( optional bool bForceSkipLobby )
{
	local GFxWidgetBinding WidgetBinding;
	local bool bSkippedLobby;

	// Add either the in game party or out of game party widget
	WidgetBinding.WidgetName = 'partyWidget';
	bSkippedLobby = bForceSkipLobby || CheckSkipLobby();
	WidgetBinding.WidgetClass = class'ExtWidget_PartyInGame';
	ManagerObject.SetBool("backgroundVisible", false);
	ManagerObject.SetBool("IISMovieVisible", false);
	if(bSkippedLobby)
		CurrentBackgroundMovie.Stop();

	WidgetBindings.AddItem(WidgetBinding);

	// Load the platform-specific graphics options menu
	switch( class'KFGameEngine'.static.GetPlatform() )
	{
		case PLATFORM_PC_DX10:
			WidgetBinding.WidgetName = 'optionsGraphicsMenu';
			WidgetBinding.WidgetClass = class'KFGFxOptionsMenu_Graphics_DX10';
			WidgetBindings.AddItem(WidgetBinding);
			break;
		default:
			WidgetBinding.WidgetName = 'optionsGraphicsMenu';
			WidgetBinding.WidgetClass = class'KFGFxOptionsMenu_Graphics';
			WidgetBindings.AddItem(WidgetBinding);
	}

	if (!bSkippedLobby)
	{
		LoadWidgets(WidgetPaths);
		OpenMenu(UI_Start);
		AllowCloseMenu();
	}

	// do this stuff in case CheckSkipLobby failed
	if( bForceSkipLobby )
	{
		bAfterLobby = true;
		CloseMenus(true);
	}
}

defaultproperties
{
	WidgetBindings.Remove((WidgetName="PerksMenu",WidgetClass=class'KFGFxMenu_Perks'))
	WidgetBindings.Add((WidgetName="PerksMenu",WidgetClass=class'ExtMenu_Perks'))
	WidgetBindings.Remove((WidgetName="gearMenu",WidgetClass=class'KFGFxMenu_Gear'))
	WidgetBindings.Add((WidgetName="gearMenu",WidgetClass=class'ExtMenu_Gear'))
	WidgetBindings.Remove((WidgetName="traderMenu",WidgetClass=class'KFGFxMenu_Trader'))
	WidgetBindings.Add((WidgetName="traderMenu",WidgetClass=class'ExtMenu_Trader'))
}