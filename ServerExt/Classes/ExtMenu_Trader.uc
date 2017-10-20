class ExtMenu_Trader extends KFGFxMenu_Trader;

var ExtPlayerController ExtKFPC;
var Ext_PerkBase ExLastPerkClass;

function InitializeMenu( KFGFxMoviePlayer_Manager InManager )
{
	Super.InitializeMenu(InManager);
	ExtKFPC = ExtPlayerController ( GetPC() );
}
function int GetPerkIndex()
{
	return (ExtKFPC.ActivePerkManager!=None ? Max(ExtKFPC.ActivePerkManager.UserPerks.Find(ExtKFPC.ActivePerkManager.CurrentPerk),0) : 0);
}
function UpdatePlayerInfo()
{
	if( ExtKFPC != none && PlayerInfoContainer != none )
	{
		PlayerInfoContainer.SetPerkInfo();
		PlayerInfoContainer.SetPerkList();
		if( ExtKFPC.ActivePerkManager!=None && ExtKFPC.ActivePerkManager.CurrentPerk!=ExLastPerkClass)
		{
			ExLastPerkClass = ExtKFPC.ActivePerkManager.CurrentPerk;
			OnPerkChanged(GetPerkIndex());
		}

		RefreshItemComponents();
	}
}

function Callback_PerkChanged(int PerkIndex)
{
	ExtKFPC.PendingPerkClass = ExtKFPC.ActivePerkManager.UserPerks[PerkIndex].Class;
	ExtKFPC.SwitchToPerk(ExtKFPC.PendingPerkClass);
		
	if( PlayerInventoryContainer != none )
	{
		PlayerInventoryContainer.UpdateLock();
	}
	UpdatePlayerInfo();

	// Refresht he UI
	RefreshItemComponents();
}

defaultproperties
{
	SubWidgetBindings.Remove((WidgetName="filterContainer",WidgetClass=class'KFGFxTraderContainer_Filter'))
	SubWidgetBindings.Add((WidgetName="filterContainer",WidgetClass=class'ExtTraderContainer_Filter'))
	SubWidgetBindings.Remove((WidgetName="shopContainer",WidgetClass=class'KFGFxTraderContainer_Store'))
	SubWidgetBindings.Add((WidgetName="shopContainer",WidgetClass=class'ExtTraderContainer_Store'))
	SubWidgetBindings.Remove((WidgetName="playerInfoContainer",WidgetClass=class'KFGFxTraderContainer_PlayerInfo'))
	SubWidgetBindings.Add((WidgetName="playerInfoContainer",WidgetClass=class'ExtTraderContainer_PlayerInfo'))
}