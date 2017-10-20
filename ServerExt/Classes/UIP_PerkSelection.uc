Class UIP_PerkSelection extends KFGUI_MultiComponent;

var KFGUI_List PerkList;
var KFGUI_Button B_Prestige;
var KFGUI_ComponentList StatsList;
var UIR_PerkTraitList TraitsList;
var KFGUI_TextLable PerkLabel;
var ExtPerkManager CurrentManager;
var Ext_PerkBase PendingPerk,OldUsedPerk;
var class<Ext_PerkBase> PrevPendingPerk;
var array<UIR_PerkStat> StatBuyers;
var int OldPerkPoints;

function InitMenu()
{
	PerkList = KFGUI_List(FindComponentID('Perks'));
	StatsList = KFGUI_ComponentList(FindComponentID('Stats'));
	TraitsList = UIR_PerkTraitList(FindComponentID('Traits'));
	PerkLabel = KFGUI_TextLable(FindComponentID('Info'));
	PerkLabel.SetText("");
	B_Prestige = KFGUI_Button(FindComponentID('Prestige'));
	Super.InitMenu();
}
function ShowMenu()
{
	Super.ShowMenu();
	SetTimer(0.1,true);
	Timer();
}
function CloseMenu()
{
	Super.CloseMenu();
	CurrentManager = None;
	PrevPendingPerk = (PendingPerk!=None ? PendingPerk.Class : None);
	PendingPerk = None;
	OldUsedPerk = None;
	SetTimer(0,false);
}

function Timer()
{
	local int i;

	CurrentManager = ExtPlayerController(GetPlayer()).ActivePerkManager;
	if( CurrentManager!=None )
	{
		if( PrevPendingPerk!=None )
		{
			PendingPerk = CurrentManager.FindPerk(PrevPendingPerk);
			PrevPendingPerk = None;
		}
		PerkList.ChangeListSize(CurrentManager.UserPerks.Length);
		if( PendingPerk!=None && !PendingPerk.bPerkNetReady )
			return;
		
		// Huge code block to handle stat updating, but actually pretty well optimized.
		if( PendingPerk!=OldUsedPerk )
		{
			OldUsedPerk = PendingPerk;
			if( PendingPerk!=None )
			{
				OldPerkPoints = -1;
				if( StatsList.ItemComponents.Length!=PendingPerk.PerkStats.Length )
				{
					if( StatsList.ItemComponents.Length<PendingPerk.PerkStats.Length )
					{
						for( i=StatsList.ItemComponents.Length; i<PendingPerk.PerkStats.Length; ++i )
						{
							if( i>=StatBuyers.Length )
							{
								StatBuyers[StatBuyers.Length] = UIR_PerkStat(StatsList.AddListComponent(class'UIR_PerkStat'));
								StatBuyers[i].StatIndex = i;
								StatBuyers[i].InitMenu();
							}
							else
							{
								StatsList.ItemComponents.Length = i+1;
								StatsList.ItemComponents[i] = StatBuyers[i];
							}
						}
					}
					else if( StatsList.ItemComponents.Length>PendingPerk.PerkStats.Length )
					{
						for( i=PendingPerk.PerkStats.Length; i<StatsList.ItemComponents.Length; ++i )
							StatBuyers[i].CloseMenu();
						StatsList.ItemComponents.Length = PendingPerk.PerkStats.Length;
					}
				}
				OldPerkPoints = PendingPerk.CurrentSP;
				PerkLabel.SetText("Lv"$PendingPerk.GetLevelString()@PendingPerk.PerkName$" (Points: "$PendingPerk.CurrentSP$")");
				for( i=0; i<StatsList.ItemComponents.Length; ++i ) // Just make sure perk stays the same.
				{
					StatBuyers[i].SetActivePerk(PendingPerk);
					StatBuyers[i].CheckBuyLimit();
				}
				B_Prestige.SetDisabled(!PendingPerk.CanPrestige());
				if( PendingPerk.MinLevelForPrestige<0 )
					B_Prestige.ChangeToolTip("Prestige is disabled for this perk");
				else B_Prestige.ChangeToolTip("Prestige this perk.|Minimum level required: "$PendingPerk.MinLevelForPrestige);
				UpdateTraits();
			}
			else // Empty out if needed.
			{
				for( i=0; i<StatsList.ItemComponents.Length; ++i )
					StatBuyers[i].CloseMenu();
				StatsList.ItemComponents.Length = 0;
				PerkLabel.SetText("<No perk selected>");
			}
		}
		else if( PendingPerk!=None && OldPerkPoints!=PendingPerk.CurrentSP )
		{
			B_Prestige.SetDisabled(!PendingPerk.CanPrestige());

			OldPerkPoints = PendingPerk.CurrentSP;
			PerkLabel.SetText("Lv"$PendingPerk.GetLevelString()@PendingPerk.PerkName$" (Points: "$PendingPerk.CurrentSP$")");
			for( i=0; i<StatsList.ItemComponents.Length; ++i ) // Just make sure perk stays the same.
				StatBuyers[i].CheckBuyLimit();
			
			// Update traits list.
			UpdateTraits();
		}
	}
}

final function UpdateTraits()
{
	local array< class<Ext_TGroupBase> > CatList;
	local class<Ext_TGroupBase> N;
	local int i,j;
	local class<Ext_TraitBase> TC;
	local string S;

	// A bit hacky to delete and refill list again, but at least it works...
	TraitsList.EmptyList();
	TraitsList.ToolTip.Length = 0;
	
	CatList.AddItem(None);

	// First gather all the categories available.
	for( i=0; i<PendingPerk.PerkTraits.Length; ++i )
	{
		N = PendingPerk.PerkTraits[i].TraitType.Default.TraitGroup;
		if( N!=None && CatList.Find(N)==-1 )
			CatList.AddItem(N);
	}
	
	for( j=0; j<CatList.Length; ++j )
	{
		N = CatList[j];
		if( j>0 )
		{
			TraitsList.AddLine("--"$N.Static.GetUIInfo(PendingPerk),-1);
			TraitsList.ToolTip.AddItem(N.Static.GetUIDesc());
		}
		for( i=0; i<PendingPerk.PerkTraits.Length; ++i )
		{
			TC = PendingPerk.PerkTraits[i].TraitType;
			if( TC.Default.TraitGroup==N )
			{
				if( PendingPerk.PerkTraits[i].CurrentLevel>=TC.Default.NumLevels )
					S = "MAX\nN/A";
				else
				{
					S = PendingPerk.PerkTraits[i].CurrentLevel$"/"$TC.Default.NumLevels$"\n";
					if( TC.Static.MeetsRequirements(PendingPerk.PerkTraits[i].CurrentLevel,PendingPerk) )
						S $= string(TC.Static.GetTraitCost(PendingPerk.PerkTraits[i].CurrentLevel));
					else S $= "N/A";
				}
				TraitsList.AddLine(TC.Default.TraitName$"\n"$S,i);
				TraitsList.ToolTip.AddItem(TC.Static.GetTooltipInfo());
			}
		}
	}
}

function DrawPerkInfo( Canvas C, int Index, float YOffset, float Height, float Width, bool bFocus )
{
	local Ext_PerkBase P;
	local float Sc;

	if( CurrentManager==None || Index>=CurrentManager.UserPerks.Length )
		return;
	P = CurrentManager.UserPerks[Index];
	if( P.Class==ExtPlayerReplicationInfo(GetPlayer().PlayerReplicationInfo).ECurrentPerk )
	{
		if( PendingPerk==None )
			PendingPerk = P;
		C.SetDrawColor(164,164,32);
	}
	else if( P==PendingPerk )
		C.SetDrawColor(164,86,32);
	else C.SetDrawColor(32,32,128);
	
	if( bFocus )
	{
		C.DrawColor.R+=15;
		C.DrawColor.G+=15;
		C.DrawColor.B+=15;
	}
	C.SetPos(0,YOffset);
	Owner.CurrentStyle.DrawWhiteBox(Width,Height);
	
	C.SetDrawColor(240,240,240);
	C.SetPos(2,YOffset);
	C.DrawRect(Height,Height,P.PerkIcon);
	
	C.SetPos(6+Height,YOffset);
	C.Font = Owner.CurrentStyle.PickFont(Max(Owner.CurrentStyle.DefaultFontSize-1,0),Sc);
	C.DrawText(P.PerkName,,Sc,Sc);
	
	C.SetPos(6+Height,YOffset+Height*0.5);
	C.DrawText("Lv "$P.GetLevelString()$" ("$P.CurrentEXP$"/"$P.NextLevelEXP$" XP)",,Sc,Sc);
}
function SwitchedPerk( int Index, bool bRight, int MouseX, int MouseY )
{
	if( CurrentManager==None || Index>=CurrentManager.UserPerks.Length )
		return;
	
	PendingPerk = CurrentManager.UserPerks[Index];
	ExtPlayerController(GetPlayer()).SwitchToPerk(PendingPerk.Class);
}
function ShowTraitInfo( KFGUI_ListItem Item, int Row, bool bRight, bool bDblClick )
{
	local UIR_TraitInfoPopup T;
	if( (bRight || bDblClick) && Item.Value>=0 )
	{
		T = UIR_TraitInfoPopup(Owner.OpenMenu(class'UIR_TraitInfoPopup'));
		T.ShowTraitInfo(Item.Value,PendingPerk);
	}
}
function ButtonClicked( KFGUI_Button Sender )
{
	local KFGUI_Page T;

	switch( Sender.ID )
	{
	case 'Reset':
		if( PendingPerk!=None )
		{
			T = Owner.OpenMenu(class'UI_ResetWarning');
			UI_ResetWarning(T).SetupTo(PendingPerk);
		}
		break;
	case 'Unload':
		if( PendingPerk!=None )
		{
			T = Owner.OpenMenu(class'UI_UnloadInfo');
			UI_UnloadInfo(T).SetupTo(PendingPerk.Class);
		}
		break;
	case 'Prestige':
		if( PendingPerk!=None )
		{
			T = Owner.OpenMenu(class'UI_PrestigeNote');
			UI_PrestigeNote(T).SetupTo(PendingPerk);
		}
		break;
	}
}

defaultproperties
{
	Begin Object Class=KFGUI_List Name=PerksList
		ID="Perks"
		XPosition=0
		YPosition=0
		XSize=0.25
		YSize=1
		ListItemsPerPage=12
		bClickable=true
		OnDrawItem=DrawPerkInfo
		OnClickedItem=SwitchedPerk
	End Object
	
	Begin Object Class=KFGUI_ComponentList Name=PerkStats
		ID="Stats"
		XPosition=0.25
		YPosition=0.12
		XSize=0.375
		YSize=0.88
		ListItemsPerPage=16
	End Object
	
	Begin Object Class=UIR_PerkTraitList Name=PerkTraits
		ID="Traits"
		XPosition=0.625
		YPosition=0.12
		XSize=0.375
		YSize=0.88
		OnSelectedRow=ShowTraitInfo
	End Object
	
	Begin Object Class=KFGUI_TextLable Name=CurPerkLabel
		ID="Info"
		XPosition=0.4
		YPosition=0
		XSize=0.58
		YSize=0.12
		AlignX=1
		AlignY=1
		TextFontInfo=(bClipText=true)
	End Object
	
	Begin Object Class=KFGUI_Button Name=ResetPerkButton
		ID="Reset"
		ButtonText="Reset Level"
		ToolTip="Reset this perk by unloading all stats, traits and set XP gained and level to 0"
		XPosition=0.25
		YPosition=0.025
		XSize=0.074
		YSize=0.045
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
		ExtravDir=1
	End Object
	Begin Object Class=KFGUI_Button Name=UnloadPerkButton
		ID="Unload"
		ButtonText="Unload Perk"
		ToolTip="Reset all spent points on this perk and refund the points in exchange of some XP"
		XPosition=0.325
		YPosition=0.025
		XSize=0.074
		YSize=0.045
		ExtravDir=1
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Begin Object Class=KFGUI_Button Name=PrestigePerkButton
		ID="Prestige"
		ButtonText="Prestige"
		ToolTip="-"
		XPosition=0.4
		YPosition=0.025
		XSize=0.074
		YSize=0.045
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
		bDisabled=true
	End Object
	
	Components.Add(PerksList)
	Components.Add(PerkStats)
	Components.Add(PerkTraits)
	Components.Add(CurPerkLabel)
	Components.Add(ResetPerkButton)
	Components.Add(UnloadPerkButton)
	Components.Add(PrestigePerkButton)
}