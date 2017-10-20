class ExtMenu_Perks extends KFGFxMenu_Perks;

var ExtPlayerController ExtKFPC;
var Ext_PerkBase ExtPrevPerk;

function OnOpen()
{
	KFPC = KFPlayerController( GetPC() );
	if( ExtKFPC == none )
		ExtKFPC = ExtPlayerController(KFPC);

	if( ExtKFPC.ActivePerkManager==None )
	{
		ExtKFPC.SetTimer(0.25,true,'OnOpen',Self);
		return;
	}
	ExtKFPC.ClearTimer('OnOpen',Self);

	if( ExtPrevPerk==None )
		ExtPrevPerk = ExtKFPC.ActivePerkManager.CurrentPerk;

	ExUpdateContainers(ExtPrevPerk); 
	SetBool( "locked", true);
}
final function ExUpdateContainers( Ext_PerkBase PerkClass )
{
	LastPerkLevel = PerkClass.CurrentLevel;
	if ( ExtPerksContainer_Header(HeaderContainer)!=none )
		ExtPerksContainer_Header(HeaderContainer).ExUpdatePerkHeader( PerkClass );
	if ( ExtPerksContainer_Details(DetailsContainer)!=none )
	{
		ExtPerksContainer_Details(DetailsContainer).ExUpdateDetails( PerkClass );
		ExtPerksContainer_Details(DetailsContainer).ExUpdatePassives( PerkClass );
	}
	if ( SelectionContainer != none )
		SelectionContainer.UpdatePerkSelection(ExtKFPC.ActivePerkManager.UserPerks.Find(PerkClass));
}

function CheckTiersForPopup();

event OnClose()
{
	ExtPrevPerk = None;
	if ( ExtKFPC != none )
		ExtKFPC.ClearTimer('OnOpen',Self);
	super.OnClose();
}

function PerkChanged( byte NewPerkIndex, bool bClickedIndex)
{
	ExUpdateContainers(ExtPrevPerk);
}

function OneSecondLoop()
{
	if( ExtPrevPerk!=None && LastPerkLevel!=ExtPrevPerk.CurrentLevel )
		ExUpdateContainers(ExtPrevPerk);
}

function UpdateLock();
function SavePerkData();

function Callback_PerkSelected(byte NewPerkIndex, bool bClickedIndex)
{
	ExtPrevPerk = ExtKFPC.ActivePerkManager.UserPerks[NewPerkIndex];
	ExUpdateContainers(ExtPrevPerk);
	
	ExtKFPC.PendingPerkClass = ExtPrevPerk.Class;
	ExtKFPC.SwitchToPerk(ExtPrevPerk.Class);
}
function Callback_SkillSelectionOpened();

defaultproperties
{
	SubWidgetBindings(0)=(WidgetClass=Class'ExtPerksContainer_Selection')
	SubWidgetBindings(1)=(WidgetClass=Class'ExtPerksContainer_Header')
	SubWidgetBindings(3)=(WidgetClass=Class'ExtPerksContainer_Details')
}