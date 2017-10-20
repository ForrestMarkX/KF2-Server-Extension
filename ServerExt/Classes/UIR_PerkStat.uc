Class UIR_PerkStat extends KFGUI_MultiComponent;

var KFGUI_TextLable InfoText;
var KFGUI_NumericBox StatCountBox;
var KFGUI_Button AddButton;

var Ext_PerkBase MyPerk;
var int StatIndex,OldValue,CurrentCost;
var string ProgressStr;
var bool bCostDirty;

function InitMenu()
{
	InfoText = KFGUI_TextLable(FindComponentID('Info'));
	StatCountBox = KFGUI_NumericBox(FindComponentID('CountBox'));
	AddButton = KFGUI_Button(FindComponentID('AddBox'));
	Super.InitMenu();
}

function ShowMenu()
{
	Super.ShowMenu();
	OldValue = -1;
	SetTimer(0.1,true);
	EditBoxChange(StatCountBox);
}
function CloseMenu()
{
	Super.CloseMenu();
	MyPerk = None;
	SetTimer(0,false);
}
function SetActivePerk( Ext_PerkBase P )
{
	MyPerk = P;
	StatCountBox.Value = "5";
	OldValue = -1;
}
function Timer()
{
	if( OldValue!=MyPerk.PerkStats[StatIndex].CurrentValue || bCostDirty )
	{
		bCostDirty = false;
		OldValue = MyPerk.PerkStats[StatIndex].CurrentValue;
		InfoText.SetText(MyPerk.GetStatUIStr(StatIndex)$" ["$OldValue$", Cost "$CurrentCost$", "$ProgressStr$"%]:");
	}
}
function BuyStatPoint( KFGUI_Button Sender )
{
	ExtPlayerController(GetPlayer()).BuyPerkStat(MyPerk.Class,StatIndex,StatCountBox.GetValueInt());
}
function EditBoxChange( KFGUI_EditBox Sender )
{
	CurrentCost = StatCountBox.GetValueInt()*MyPerk.PerkStats[StatIndex].CostPerValue;
	ProgressStr = ChopExtraDigits(MyPerk.PerkStats[StatIndex].Progress * StatCountBox.GetValueInt());
	bCostDirty = true;
	Timer();
}
final function CheckBuyLimit()
{
	local int i;

	i = Max(Min(MyPerk.CurrentSP/MyPerk.PerkStats[StatIndex].CostPerValue,MyPerk.PerkStats[StatIndex].MaxValue-MyPerk.PerkStats[StatIndex].CurrentValue),0);
	StatCountBox.MaxValue = i;
	if( i==0 )
		StatCountBox.MinValue = 0;
	else StatCountBox.MinValue = 1;

	// Make the value clamped.
	StatCountBox.ChangeValue(StatCountBox.Value);
	CurrentCost = StatCountBox.GetValueInt()*MyPerk.PerkStats[StatIndex].CostPerValue;
	ProgressStr = ChopExtraDigits(MyPerk.PerkStats[StatIndex].Progress * StatCountBox.GetValueInt());
	
	// Disable button if can not buy anymore.
	AddButton.SetDisabled(i==0);
	bCostDirty = true;
	Timer();
}

final function string ChopExtraDigits( float Value )
{
	local string S;
	local bool bLoop;

	S = string(Abs(Value));
	bLoop = true;

	// Chop off float digits that aren't needed.
	while( bLoop )
	{
		switch( Right(S,1) )
		{
		case "0":
			S = Left(S,Len(S)-1);
			break;
		case ".":
			S = Left(S,Len(S)-1);
			bLoop = false;
			break;
		default:
			bLoop = false;
		}
	}
	return S;
}

defaultproperties
{
	Begin Object Class=KFGUI_TextLable Name=InfoLable
		ID="Info"
		XPosition=0
		YPosition=0.2
		XSize=0.71
		YSize=0.7
		AlignX=2
		AlignY=1
		TextFontInfo=(bClipText=true)
	End Object
	Begin Object Class=KFGUI_NumericBox Name=BuyCount
		ID="CountBox"
		XPosition=0.72
		YPosition=0.1
		XSize=0.18
		YSize=0.8
		OnTextChange=EditBoxChange
		ToolTip="Here you can specify how many stat points to buy"
		MaxValue=100
		MinValue=1
		bScaleByFontSize=false
	End Object
	Begin Object Class=KFGUI_Button Name=AddSButton
		ID="AddBox"
		XPosition=0.91
		YPosition=0.1
		XSize=0.08
		YSize=0.8
		ButtonText="+"
		ToolTip="Click here to buy stats for this perk"
		OnClickLeft=BuyStatPoint
		OnClickRight=BuyStatPoint
	End Object

	Components.Add(InfoLable)
	Components.Add(BuyCount)
	Components.Add(AddSButton)
}