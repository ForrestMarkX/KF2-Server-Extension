Class UIP_AdminMenu extends KFGUI_MultiComponent;

var KFGUI_ColumnList PlayersList;
var editinline export KFGUI_RightClickMenu PlayerContext;
var int SelectedID;

function InitMenu()
{
	PlayersList = KFGUI_ColumnList(FindComponentID('Players'));
	Super.InitMenu();
}
function ShowMenu()
{
	Super.ShowMenu();
	SetTimer(2,true);
	Timer();
}
function CloseMenu()
{
	Super.CloseMenu();
	SetTimer(0,false);
}

function Timer()
{
	class'UIP_PlayerSpecs'.Static.UpdatePlayerList(PlayersList,GetPlayer().WorldInfo.GRI);
}

function SelectedRow( KFGUI_ListItem Item, int Row, bool bRight, bool bDblClick )
{
	if( bRight || bDblClick )
	{
		PlayerContext.ItemRows[0].Text = "-- EDIT: "$Item.Columns[0];
		SelectedID = Item.Value;
		PlayerContext.OpenMenu(Self);
	}
}
function SelectedRCItem( int Index )
{
	if( Index>0 && !PlayerContext.ItemRows[Index].bSplitter )
	{
		if( PlayerContext.ItemRows[Index].Value>=0 )
			ExtPlayerController(GetPlayer()).AdminRPGHandle(SelectedID,PlayerContext.ItemRows[Index].Value);
		else UI_AdminPerkLevel(Owner.OpenMenu(class'UI_AdminPerkLevel')).InitPage(SelectedID,-PlayerContext.ItemRows[Index].Value);
	}
}
function ButtonClicked( KFGUI_Button Sender )
{
	switch( Sender.ID )
	{
	case 'MOTD':
		Owner.OpenMenu(class'UI_AdminMOTD');
		break;
	}
}

defaultproperties
{
	Begin Object Class=KFGUI_RightClickMenu Name=PlayerContextMenu
		ItemRows.Add((Text="",Value=-1))
		ItemRows.Add((Text="Show Debug Info",Value=9))
		ItemRows.Add((bSplitter=true))
		ItemRows.Add((Text="Add 1,000 XP",Value=2))
		ItemRows.Add((Text="Add 10,000 XP",Value=3))
		ItemRows.Add((Text="Advance Perk Level",Value=4))
		ItemRows.Add((Text="Set Perk Level",Value=-1))
		ItemRows.Add((Text="Set Prestige Level",Value=-2))
		ItemRows.Add((bSplitter=true))
		ItemRows.Add((Text="Unload all stats",Value=5))
		ItemRows.Add((Text="Unload all traits",Value=6))
		ItemRows.Add((bSplitter=true))
		ItemRows.Add((Text="Remove 1,000 XP",Value=7))
		ItemRows.Add((Text="Remove 10,000 XP",Value=8))
		ItemRows.Add((bSplitter=true))
		ItemRows.Add((Text="Reset ALL Stats",Value=0))
		ItemRows.Add((Text="Reset Current Perk Stats",Value=1))
		OnSelectedItem=SelectedRCItem
	End Object
	PlayerContext=PlayerContextMenu
	
	Begin Object Class=KFGUI_Button Name=EditMOTDButton
		ID="MOTD"
		ButtonText="Edit MOTD"
		Tooltip="Edit the server Message of the Day"
		XPosition=0.2
		YPosition=0.997
		XSize=0.1
		YSize=0.03
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(EditMOTDButton)
	
	Begin Object Class=KFGUI_ColumnList Name=PlayerList
		ID="Players"
		XPosition=0.05
		YPosition=0.05
		XSize=0.9
		YSize=0.92
		Columns.Add((Text="Player",Width=0.55))
		Columns.Add((Text="Total Kills",Width=0.15))
		Columns.Add((Text="Total EXP",Width=0.15))
		Columns.Add((Text="Total PlayTime",Width=0.15))
		OnSelectedRow=SelectedRow
	End Object
	Components.Add(PlayerList)
}