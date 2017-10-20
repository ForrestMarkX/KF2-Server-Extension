Class UI_ResetWarning extends KFGUI_FloatingWindow;

var KFGUI_TextField InfoLabel;
var class<Ext_PerkBase> PerkToReset;
var bool bIsPrestige;

function InitMenu()
{
	InfoLabel = KFGUI_TextField(FindComponentID('Info'));
	Super.InitMenu();
}
function SetupTo( Ext_PerkBase P )
{
	PerkToReset = P.Class;
	WindowTitle = "WARNING: Reset "$P.PerkName;
}
function ButtonClicked( KFGUI_Button Sender )
{
	switch( Sender.ID )
	{
	case 'Yes':
		ExtPlayerController(GetPlayer()).ServerResetPerk(PerkToReset,bIsPrestige);
		PerkToReset = None;
		DoClose();
		break;
	case 'No':
		DoClose();
		break;
	}
}

defaultproperties
{
	XPosition=0.35
	YPosition=0.2
	XSize=0.3
	YSize=0.45
	bAlwaysTop=true
	bOnlyThisFocus=true
	
	Begin Object Class=KFGUI_TextField Name=WarningLabel
		ID="Info"
		XPosition=0.01
		YPosition=0.12
		XSize=0.98
		YSize=0.775
		Text="#{FF0000}WARNING:#{DEF} If you reset your perk to initial status, you can not undo this operation!|#{FF0000}All your gained XP and level (including prestige level) will be reset to 0.#{DEF}|Do NOT cry to an admin later if this was a mistake!||Are you sure you want to do this?"
	End Object
	Begin Object Class=KFGUI_Button Name=YesButten
		ID="Yes"
		ButtonText="YES"
		Tooltip="Reset the perk (you can not undo this action!)"
		XPosition=0.2
		YPosition=0.9
		XSize=0.29
		YSize=0.07
		ExtravDir=1
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Begin Object Class=KFGUI_Button Name=NoButten
		ID="No"
		ButtonText="ABORT"
		Tooltip="Abort without doing anything"
		XPosition=0.5
		YPosition=0.9
		XSize=0.29
		YSize=0.07
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	
	Components.Add(WarningLabel)
	Components.Add(YesButten)
	Components.Add(NoButten)
}