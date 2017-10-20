// Menu system written by Marco.
Class KFGUI_Base extends Object
	abstract;

var KF2GUIController Owner;
var KFGUI_Base ParentComponent; // Parent component if any.
var transient Canvas Canvas;

enum EMenuSound
{
	MN_Focus,
	MN_LostFocus,
	MN_ClickButton,
	MN_ClickCheckboxOn,
	MN_ClickCheckboxOff,
	MN_Dropdown,
	MN_DropdownChange,
};

var() float XPosition,YPosition,XSize,YSize;
var() name ID; // Just for internal purposes, you can give the components unique ID values.
var() int IDValue; // Integer ID value.
var transient float CompPos[4],InputPos[4];
var float TimerRate,TimerCounter;

var transient KFGUI_Base MouseArea; // Next in recurse line of the mouse pointer focus area.

var() bool bDisabled,bClickable,bCanFocus;
var bool bFocusedPostDrawItem; // If this component has been given input focus, should it receive draw menu call after everything else been drawn?
var bool bTimerActive,bLoopTimer;
var transient bool bFocused;

function InitMenu(); // Menu was initialized for the first time.
function ShowMenu(); // Menu was opened.
function PreDraw()
{
	ComputeCoords();
	Canvas.SetDrawColor(255,255,255);
	Canvas.SetOrigin(CompPos[0],CompPos[1]);
	Canvas.SetClip(CompPos[0]+CompPos[2],CompPos[1]+CompPos[3]);
	DrawMenu();
}
function DrawMenu(); // Draw menu now.
function CloseMenu(); // Menu was closed.

function MenuTick( float DeltaTime )
{
	if( bTimerActive && (TimerCounter-=DeltaTime)<=0.f )
	{
		if( bLoopTimer )
			TimerCounter = TimerRate;
		else bTimerActive = false;
		Timer();
	}
}
final function SetTimer( float Rate, optional bool bLoop )
{
	bTimerActive = (Rate>0.f);
	if( bTimerActive )
	{
		bLoopTimer = bLoop;
		TimerRate = Rate;
		TimerCounter = Rate;
	}
}
function Timer();

function MouseEnter()
{
	bFocused = true;
	OnFocus(Self,True);
}
function MouseLeave()
{
	bFocused = false;
	OnFocus(Self,False);
}
function MouseClick( bool bRight );
function MouseRelease( bool bRight );
function DoubleMouseClick( bool bRight ) // User rapidly double clicked this component.
{
	MouseClick(bRight);
}

function ScrollMouseWheel( bool bUp );

final function PlayerController GetPlayer()
{
	return Owner.PlayerOwner;
}

function SetDisabled( bool bDisable )
{
	bDisabled = bDisable;
}

Delegate OnFocus( KFGUI_Base Sender, bool bBecame );

final function ComputeCoords()
{
	CompPos[0] = XPosition*InputPos[2]+InputPos[0];
	CompPos[1] = YPosition*InputPos[3]+InputPos[1];
	CompPos[2] = XSize*InputPos[2];
	CompPos[3] = YSize*InputPos[3];
}

function bool CaptureMouse()
{
	return ( Owner.MousePosition.X>=CompPos[0] && Owner.MousePosition.Y>=CompPos[1] && Owner.MousePosition.X<=(CompPos[0]+CompPos[2]) && Owner.MousePosition.Y<=(CompPos[1]+CompPos[3]) );
}

final function KFGUI_Base GetMouseFocus()
{
	local KFGUI_Base M;
	
	for( M=Self; M.MouseArea!=None; M=M.MouseArea )
	{}
	return M;
}

function DoClose()
{
	if( ParentComponent!=None )
		ParentComponent.DoClose();
	else Owner.PopCloseMenu(Self);
}

function byte GetCursorStyle()
{
	return (bClickable ? 1 : 0);
}

function UserPressedEsc() // user pressed escape while this menu was active.
{
	if( ParentComponent!=None )
		ParentComponent.UserPressedEsc();
	else DoClose();
}
function bool BringPageToFront()
{
	if( ParentComponent!=None )
		return ParentComponent.BringPageToFront();
	return true; // Allow user to bring this page to front.
}
final function bool IsTopMenu()
{
	return (Owner.ActiveMenus.Length>0 && GetPageTop()==Owner.ActiveMenus[0]);
}
final function KFGUI_Page GetPageTop()
{
	local KFGUI_Base M;
	
	for( M=Self; M.ParentComponent!=None; M=M.ParentComponent )
	{}
	return KFGUI_Page(M);
}
function KFGUI_Base FindComponentID( name InID )
{
	if( ID==InID )
		return Self;
	return None;
}
function FindAllComponentID( name InID, out array<KFGUI_Base> Res )
{
	if( ID==InID )
		Res[Res.Length] = Self;
}
function RemoveComponent( KFGUI_Base B );

function GetInputFocus()
{
	if( Owner.InputFocus!=None )
		Owner.InputFocus.LostInputFocus();
	Owner.InputFocus = Self;
}
function DropInputFocus()
{
	if( Owner.InputFocus==Self )
	{
		Owner.InputFocus.LostInputFocus();
		Owner.InputFocus = None;
	}
}
function LostInputFocus();

// Obtain keyboard focus.
final function GrabKeyFocus()
{
	Owner.GrabInputFocus(Self);
}
final function ReleaseKeyFocus()
{
	if( Owner.KeyboardFocus==Self )
		Owner.GrabInputFocus(None);
}
function LostKeyFocus();

function bool NotifyInputKey( int ControllerId, name Key, EInputEvent Event, float AmountDepressed, bool bGamepad )
{
	return false;
}
function bool NotifyInputChar( int ControllerId, string Unicode )
{
	return false;
}

// While on input focus mode, notify that mouse just moved over the threshold.
function InputMouseMoved();

// Notify any focused menu element that mouse has been idle over it.
function NotifyMousePaused();

final function GetActualPos( out float X, out float Y )
{
	X = ((XPosition+X)*InputPos[2]) + InputPos[0];
	Y = ((YPosition+Y)*InputPos[3]) + InputPos[1];
}
final function GetRealtivePos( out float X, out float Y )
{
	X = X / CompPos[2];
	Y = Y / CompPos[2];
}

simulated final function PlayMenuSound( EMenuSound Slot )
{
	/*local SoundCue S;
	
	switch( Slot )
	{
	case MN_Focus:
		S = SoundCue'a_interface.menu.UT3MenuMouseOverCue';
		break;
	case MN_LostFocus:
		S = SoundCue'a_interface.menu.UT3MenuNavigateDownCue';
		break;
	case MN_ClickButton:
		S = SoundCue'a_interface.menu.UT3MenuSliderBarMoveCue';
		break;
	case MN_ClickCheckboxOn:
		S = SoundCue'a_interface.menu.UT3MenuCheckboxSelectCue';
		break;
	case MN_ClickCheckboxOff:
		S = SoundCue'a_interface.menu.UT3MenuCheckboxDeselectCue';
		break;
	case MN_Dropdown:
		S = SoundCue'a_interface.menu.UT3MenuScreenSlideCue';
		break;
	case MN_DropdownChange:
		S = SoundCue'a_interface.menu.UT3MenuNavigateUpCue';
		break;
	}
	if( S!=None )
		GetPlayer().PlaySound(S,true,,false);*/
}

// Pre level change notification.
function NotifyLevelChange();

final function SetPosition( float X, float Y, float XS, float YS )
{
	XPosition = X;
	YPosition = Y;
	XSize = XS;
	YSize = YS;
}

static final function string MakeSortStr( int Value )
{
	local string S;
	local int i;
	
	// Prefix with zeroes to properly sort this string.
	S = string(Value);
	i = Len(S);
	if( i<10 )
		return Mid("0000000000",i)$S;
	return S;
}

defaultproperties
{
	XSize=1
	YSize=1
	bCanFocus=true
}