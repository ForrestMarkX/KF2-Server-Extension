Class UIR_TraitInfoPopup extends KFGUI_FloatingWindow;

var KFGUI_TextField TraitInfo;
var KFGUI_Button YesButton;

var class<Ext_TraitBase> MyTrait;
var int TraitIndex;
var Ext_PerkBase MyPerk;
var int OldPoints,OldLevel;

function InitMenu()
{
	TraitInfo = KFGUI_TextField(FindComponentID('Info'));
	YesButton = KFGUI_Button(FindComponentID('Yes'));
	Super.InitMenu();
}
function CloseMenu()
{
	Super.CloseMenu();
	MyPerk = None;
	MyTrait = None;
	SetTimer(0,false);
}

function ShowTraitInfo( int Index, Ext_PerkBase Perk )
{
	MyTrait = Perk.PerkTraits[Index].TraitType;
	WindowTitle = MyTrait.Default.TraitName;
	TraitInfo.SetText(MyTrait.Static.GetPerkDescription());
	
	OldPoints = -1;
	OldLevel = -1;
	TraitIndex = Index;
	MyPerk = Perk;
	Timer();
	SetTimer(0.2,true);
}
function Timer()
{
	local int Cost;

	if( OldPoints!=MyPerk.CurrentSP || OldLevel!=MyPerk.PerkTraits[TraitIndex].CurrentLevel )
	{
		OldPoints = MyPerk.CurrentSP;
		OldLevel = MyPerk.PerkTraits[TraitIndex].CurrentLevel;
		if( OldLevel>=MyTrait.Default.NumLevels )
		{
			YesButton.ButtonText = "Max level";
			YesButton.SetDisabled(true);
			return;
		}
		Cost = MyTrait.Static.GetTraitCost(OldLevel);
		YesButton.ButtonText = "Buy ("$Cost$")";
		if( Cost>OldPoints || !MyTrait.Static.MeetsRequirements(OldLevel,MyPerk) )
			YesButton.SetDisabled(true);
		else YesButton.SetDisabled(false);
	}
}
function ButtonClicked( KFGUI_Button Sender )
{
	switch( Sender.ID )
	{
	case 'Yes':
		ExtPlayerController(GetPlayer()).BoughtTrait(MyPerk.Class,MyTrait);
		break;
	case 'No':
		DoClose();
		break;
	}
}

defaultproperties
{
	XPosition=0.3
	YPosition=0.15
	XSize=0.4
	YSize=0.7
	bAlwaysTop=true
	bOnlyThisFocus=true

	Begin Object Class=KFGUI_TextField Name=TraitInfoLbl
		ID="Info"
		XPosition=0.05
		YPosition=0.1
		XSize=0.9
		YSize=0.8
	End Object
	Begin Object Class=KFGUI_Button Name=BuyButten
		ID="Yes"
		Tooltip="Purchase this trait (you can not undo this action!)"
		XPosition=0.3
		YPosition=0.91
		XSize=0.19
		YSize=0.07
		ExtravDir=1
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Begin Object Class=KFGUI_Button Name=CancelButten
		ID="No"
		ButtonText="Cancel"
		Tooltip="Abort without doing anything"
		XPosition=0.5
		YPosition=0.91
		XSize=0.19
		YSize=0.07
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	
	Components.Add(TraitInfoLbl)
	Components.Add(BuyButten)
	Components.Add(CancelButten)
}