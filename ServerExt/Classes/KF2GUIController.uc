Class KF2GUIController extends Info
	transient;

var() class<GUIStyleBase> DefaultStyle;

var PlayerController PlayerOwner;
var transient KF2GUIInput CustomInput;
var transient PlayerInput BackupInput;
var transient GameViewportClient ClientViewport;

var array<KFGUI_Page> ActiveMenus,PersistentMenus;
var transient KFGUI_Base MouseFocus,InputFocus,KeyboardFocus;
var IntPoint MousePosition,ScreenSize,OldMousePos,LastClickPos[2];
var transient float MousePauseTime,MenuTime,LastClickTimes[2];
var transient GUIStyleBase CurrentStyle;

var transient Console OrgConsole;
var transient KFGUIConsoleHack HackConsole;

var bool bMouseWasIdle,bIsInMenuState,bAbsorbInput,bIsInvalid;

static function KF2GUIController GetGUIController( PlayerController PC )
{
	local KF2GUIController G;

	if( PC.Player==None )
		return None;
	foreach PC.ChildActors(class'KF2GUIController',G)
		if( !G.bIsInvalid )
			break;
	if( G==None )
		G = PC.Spawn(class'KF2GUIController',PC);
	return G;
}

simulated function PostBeginPlay()
{
	PlayerOwner = PlayerController(Owner);
	ClientViewport = LocalPlayer(PlayerOwner.Player).ViewportClient;
	CurrentStyle = new (None) DefaultStyle;
	CurrentStyle.InitStyle();
}

simulated function Destroyed()
{
	if( PlayerOwner!=None )
		SetMenuState(false);
}

simulated function HandleDrawMenu()
{
	if( HackConsole==None )
	{
		HackConsole = new(ClientViewport)class'KFGUIConsoleHack';
		HackConsole.OutputObject = Self;
	}
	if( HackConsole!=ClientViewport.ViewportConsole )
	{
		OrgConsole = ClientViewport.ViewportConsole;
		ClientViewport.ViewportConsole = HackConsole;
		
		// Make sure nothing overrides these settings while menu is being open.
		PlayerOwner.PlayerInput = CustomInput;
		if( !ClientViewport.bDisplayHardwareMouseCursor )
		{
			ClientViewport.bDisplayHardwareMouseCursor = true;
			ClientViewport.ForceUpdateMouseCursor(TRUE);
		}
	}
}
simulated function RenderMenu( Canvas C )
{
	local int i;
	local float OrgX,OrgY,ClipX,ClipY;
	local vector2D V;

	ClientViewport.ViewportConsole = OrgConsole;

	ScreenSize.X = C.SizeX;
	ScreenSize.Y = C.SizeY;
	CurrentStyle.Canvas = C;
	CurrentStyle.PickDefaultFontSize(C.SizeY);

	V = ClientViewport.GetMousePosition();
	MouseMove(V.X,V.Y);

	OrgX = C.OrgX;
	OrgY = C.OrgY;
	ClipX = C.ClipX;
	ClipY = C.ClipY;

	for( i=(ActiveMenus.Length-1); i>=0; --i )
	{
		ActiveMenus[i].bWindowFocused = (i==0);
		ActiveMenus[i].InputPos[0] = 0.f;
		ActiveMenus[i].InputPos[1] = 0.f;
		ActiveMenus[i].InputPos[2] = ScreenSize.X;
		ActiveMenus[i].InputPos[3] = ScreenSize.Y;
		ActiveMenus[i].Canvas = C;
		ActiveMenus[i].PreDraw();
	}
	if( InputFocus!=None && InputFocus.bFocusedPostDrawItem )
	{
		InputFocus.InputPos[0] = 0.f;
		InputFocus.InputPos[1] = 0.f;
		InputFocus.InputPos[2] = ScreenSize.X;
		InputFocus.InputPos[3] = ScreenSize.Y;
		InputFocus.Canvas = C;
		InputFocus.PreDraw();
	}
	C.SetOrigin(OrgX,OrgY);
	C.SetClip(ClipX,ClipY);
	
	if( OrgConsole!=None )
		OrgConsole.PostRender_Console(C);
	OrgConsole = None;
}

simulated final function SetMenuState( bool bActive )
{
	if( PlayerOwner.PlayerInput==None )
	{
		NotifyLevelChange();
		bActive = false;
	}

	if( bIsInMenuState==bActive )
		return;
	bIsInMenuState = bActive;

	if( bActive )
	{
		if( CustomInput==None )
		{
			CustomInput = new (KFPlayerController(PlayerOwner)) class'KF2GUIInput';
			CustomInput.ControllerOwner = Self;
			CustomInput.OnReceivedNativeInputKey = ReceivedInputKey;
			CustomInput.BaseInput = PlayerOwner.PlayerInput;
			BackupInput = PlayerOwner.PlayerInput;
			PlayerOwner.Interactions.AddItem(CustomInput);
		}
		BackupInput.OnReceivedNativeInputKey = ReceivedInputKey;
		BackupInput.OnReceivedNativeInputChar = ReceivedInputChar;
		PlayerOwner.PlayerInput = CustomInput;
		ClientViewport.SetHardwareMouseCursorVisibility(true);
	}
	else
	{
		if( BackupInput!=None )
		{
			PlayerOwner.PlayerInput = BackupInput;
			BackupInput.OnReceivedNativeInputKey = BackupInput.OnReceivedNativeInputKey;
			BackupInput.OnReceivedNativeInputChar = BackupInput.OnReceivedNativeInputChar;
		}
		ClientViewport.SetHardwareMouseCursorVisibility(false);
		LastClickTimes[0] = 0;
		LastClickTimes[1] = 0;
	}
}

simulated function NotifyLevelChange()
{
	local int i;

	if( bIsInvalid )
		return;
	bIsInvalid = true;

	if( InputFocus!=None )
	{
		InputFocus.LostInputFocus();
		InputFocus = None;
	}

	for( i=(ActiveMenus.Length-1); i>=0; --i )
		ActiveMenus[i].NotifyLevelChange();
	for( i=(PersistentMenus.Length-1); i>=0; --i )
		PersistentMenus[i].NotifyLevelChange();

	SetMenuState(false);
}

simulated function MenuInput(float DeltaTime)
{
	local int i;

	if( PlayerOwner.PlayerInput==None )
	{
		NotifyLevelChange();
		return;
	}
	if( InputFocus!=None )
		InputFocus.MenuTick(DeltaTime);
	for( i=0; i<ActiveMenus.Length; ++i )
		ActiveMenus[i].MenuTick(DeltaTime);
	
	// Check idle.
	if( Abs(MousePosition.X-OldMousePos.X)>5.f || Abs(MousePosition.Y-OldMousePos.Y)>5.f || (bMouseWasIdle && MousePauseTime<0.5f) )
	{
		if( bMouseWasIdle )
		{
			bMouseWasIdle = false;
			if( InputFocus!=None )
				InputFocus.InputMouseMoved();
		}
		OldMousePos = MousePosition;
		MousePauseTime = 0.f;
	}
	else if( !bMouseWasIdle && (MousePauseTime+=DeltaTime)>0.5f )
	{
		bMouseWasIdle = true;
		if( MouseFocus!=None )
			MouseFocus.NotifyMousePaused();
	}

	if( ActiveMenus.Length>0 )
		MenuTime+=DeltaTime;
}

simulated function MouseMove( float MouseX, float MouseY )
{
	local int i;
	local KFGUI_Base F;

	// Handle mouse 
	MousePosition.X = Clamp(MouseX, 0, ScreenSize.X); 
	MousePosition.Y = Clamp(MouseY, 0, ScreenSize.Y); 

	// Capture mouse for GUI
	if( InputFocus!=None && InputFocus.bCanFocus )
	{
		if( InputFocus.CaptureMouse() )
		{
			F = InputFocus.GetMouseFocus();
			if( F!=MouseFocus )
			{
				MousePauseTime = 0;
				if( MouseFocus!=None )
					MouseFocus.MouseLeave();
				MouseFocus = F;
				F.MouseEnter();
			}
		}
		else i = ActiveMenus.Length;
	}
	else
	{
		for( i=0; i<ActiveMenus.Length; ++i )
		{
			if( ActiveMenus[i].CaptureMouse() )
			{
				F = ActiveMenus[i].GetMouseFocus();
				if( F!=MouseFocus )
				{
					MousePauseTime = 0;
					if( MouseFocus!=None )
						MouseFocus.MouseLeave();
					MouseFocus = F;
					F.MouseEnter();
				}
				break;
			}
			else if( ActiveMenus[i].bOnlyThisFocus ) // Discard any other menus after this one.
			{
				i = ActiveMenus.Length;
				break;
			}
		}
	}
	if( MouseFocus!=None && i==ActiveMenus.Length ) // Hovering over nothing.
	{
		MousePauseTime = 0;
		if( MouseFocus!=None )
			MouseFocus.MouseLeave();
		MouseFocus = None;
	}
}

simulated final function int GetFreeIndex( bool bNewAlwaysTop ) // Find first allowed top index of the stack.
{
	local int i;
	
	for( i=0; i<ActiveMenus.Length; ++i )
		if( bNewAlwaysTop || !ActiveMenus[i].bAlwaysTop )
		{
			ActiveMenus.Insert(i,1);
			return i;
		}
	i = ActiveMenus.Length;
	ActiveMenus.Length = i+1;
	return i;
}
simulated function KFGUI_Page OpenMenu( class<KFGUI_Page> MenuClass )
{
	local int i;
	local KFGUI_Page M;
	
	if( MenuClass==None )
		return None;

	if( KeyboardFocus!=None )
		GrabInputFocus(None);
	if( InputFocus!=None )
	{
		InputFocus.LostInputFocus();
		InputFocus = None;
	}

	// Enable mouse on UI if disabled.
	SetMenuState(true);
	
	// Check if should use pre-excisting menu.
	if( MenuClass.Default.bUnique )
	{
		for( i=0; i<ActiveMenus.Length; ++i )
			if( ActiveMenus[i].Class==MenuClass )
			{
				if( i>0 && ActiveMenus[i].BringPageToFront() ) // Sort it upfront.
				{
					M = ActiveMenus[i];
					ActiveMenus.Remove(i,1);
					i = GetFreeIndex(M.bAlwaysTop);
					ActiveMenus[i] = M;
				}
				return M;
			}
		
		if( MenuClass.Default.bPersistant )
		{
			for( i=0; i<PersistentMenus.Length; ++i )
				if( PersistentMenus[i].Class==MenuClass )
				{
					M = PersistentMenus[i];
					PersistentMenus.Remove(i,1);
					i = GetFreeIndex(M.bAlwaysTop);
					ActiveMenus[i] = M;
					M.ShowMenu();
					return M;
				}
		}
	}
	M = New(None)MenuClass;

	if( M==None ) // Probably abstract class.
		return None;
	
	i = GetFreeIndex(M.bAlwaysTop);
	ActiveMenus[i] = M;
	M.Owner = Self;
	M.InitMenu();
	M.ShowMenu();
	return M;
}
simulated function CloseMenu( class<KFGUI_Page> MenuClass, optional bool bCloseAll )
{
	local int i;
	local KFGUI_Page M;

	if( !bCloseAll && MenuClass==None )
		return;
	
	if( KeyboardFocus!=None )
		GrabInputFocus(None);
	if( InputFocus!=None )
	{
		InputFocus.LostInputFocus();
		InputFocus = None;
	}
	for( i=(ActiveMenus.Length-1); i>=0; --i )
		if( bCloseAll || ActiveMenus[i].Class==MenuClass )
		{
			M = ActiveMenus[i];
			ActiveMenus.Remove(i,1);
			M.CloseMenu();
			
			// Cache menu.
			if( M.bPersistant && M.bUnique )
				PersistentMenus[PersistentMenus.Length] = M;
		}
	if( ActiveMenus.Length==0 )
		SetMenuState(false);
}
simulated function PopCloseMenu( KFGUI_Base Item )
{
	local int i;
	local KFGUI_Page M;

	if( Item==None )
		return;
	
	if( KeyboardFocus!=None )
		GrabInputFocus(None);
	if( InputFocus!=None )
	{
		InputFocus.LostInputFocus();
		InputFocus = None;
	}
	for( i=(ActiveMenus.Length-1); i>=0; --i )
		if( ActiveMenus[i]==Item )
		{
			M = ActiveMenus[i];
			ActiveMenus.Remove(i,1);
			M.CloseMenu();
			
			// Cache menu.
			if( M.bPersistant && M.bUnique )
				PersistentMenus[PersistentMenus.Length] = M;
			break;
		}
	if( ActiveMenus.Length==0 )
		SetMenuState(false);
}
simulated function BringMenuToFront( KFGUI_Page Page )
{
	local int i;
	
	if( ActiveMenus[0].bAlwaysTop && !Page.bAlwaysTop )
		return; // Can't override this menu.

	// Try to remove from current position at stack.
	for( i=(ActiveMenus.Length-1); i>=0; --i )
		if( ActiveMenus[i]==Page )
		{
			ActiveMenus.Remove(i,1);
			break;
		}
	if( i==-1 )
		return; // Page isn't open.
	
	// Put on front of stack.
	ActiveMenus.Insert(0,1);
	ActiveMenus[0] = Page;
}
simulated final function bool MenuIsOpen( optional class<KFGUI_Page> MenuClass )
{
	local int i;
	
	for( i=(ActiveMenus.Length-1); i>=0; --i )
		if( MenuClass==None || ActiveMenus[i].Class==MenuClass )
			return true;
	return false;
}
simulated final function GrabInputFocus( KFGUI_Base Comp, optional bool bForce )
{
	if( Comp==KeyboardFocus && !bForce )
		return;

	if( KeyboardFocus!=None )
		KeyboardFocus.LostKeyFocus();

	if( Comp==None )
	{
		OnInputKey = InternalInputKey;
		OnReceivedInputChar = InternalReceivedInputChar;
	}
	else if( KeyboardFocus==None )
	{
		OnInputKey = Comp.NotifyInputKey;
		OnReceivedInputChar = Comp.NotifyInputChar;
	}
	KeyboardFocus = Comp;
}

simulated final function GUI_InputMouse( bool bPressed, bool bRight )
{
	local byte i;

	MousePauseTime = 0;
	
	if( bPressed )
	{
		if( KeyboardFocus!=None && KeyboardFocus!=MouseFocus )
		{
			GrabInputFocus(None);
			LastClickTimes[0] = 0;
			LastClickTimes[1] = 0;
		}
		if( MouseFocus!=None )
		{
			if( MouseFocus!=InputFocus && !MouseFocus.bClickable && !MouseFocus.IsTopMenu() && MouseFocus.BringPageToFront() )
			{
				BringMenuToFront(MouseFocus.GetPageTop());
				LastClickTimes[0] = 0;
				LastClickTimes[1] = 0;
			}
			else
			{
				i = byte(bRight);
				if( (MenuTime-LastClickTimes[i])<0.2 && Abs(LastClickPos[i].X-MousePosition.X)<5 && Abs(LastClickPos[i].Y-MousePosition.Y)<5 )
				{
					LastClickTimes[i] = 0;
					MouseFocus.DoubleMouseClick(bRight);
				}
				else
				{
					MouseFocus.MouseClick(bRight);
					LastClickTimes[i] = MenuTime;
					LastClickPos[i] = MousePosition;
				}
			}
		}
		else if( InputFocus!=None )
		{
			InputFocus.LostInputFocus();
			InputFocus = None;
			LastClickTimes[0] = 0;
			LastClickTimes[1] = 0;
		}
	}
	else
	{
		if( InputFocus!=None )
			InputFocus.MouseRelease(bRight);
		else if( MouseFocus!=None )
			MouseFocus.MouseRelease(bRight);
	}
}
simulated final function bool CheckMouse( name Key, EInputEvent Event )
{
	if ( Event == IE_Pressed )
	{
		switch( Key )
		{
		case 'LeftMouseButton':
			GUI_InputMouse(true,false);
			return true;
		case 'RightMouseButton':
			GUI_InputMouse(true,true);
			return true;
		}
	}
	else if ( Event == IE_Released )
	{
		switch( Key )
		{
		case 'LeftMouseButton':
			GUI_InputMouse(false,false);
			return true;
		case 'RightMouseButton':
			GUI_InputMouse(false,true);
			return true;
		}
	}
	return false;
}
simulated function bool ReceivedInputKey( int ControllerId, name Key, EInputEvent Event, optional float AmountDepressed=1.f, optional bool bGamepad )
{
	if( !bIsInMenuState )
		return false;
	if( !CheckMouse(Key,Event) && !OnInputKey(ControllerId,Key,Event,AmountDepressed,bGamepad) )
	{
		switch( Key )
		{
		case 'Escape':
			if( Event==IE_Pressed )
				ActiveMenus[0].UserPressedEsc(); // Pop top menu if possible.
			return true;
		case 'MouseScrollDown':
		case 'MouseScrollUp':
			if( Event==IE_Pressed && MouseFocus!=None )
				MouseFocus.ScrollMouseWheel(Key=='MouseScrollUp');
			return true;
		}
		return bAbsorbInput;
	}
	return true;
}
simulated function bool ReceivedInputChar( int ControllerId, string Unicode )
{
	if( !bIsInMenuState )
		return false;
	return OnReceivedInputChar(ControllerId,Unicode);
}

simulated Delegate bool OnInputKey( int ControllerId, name Key, EInputEvent Event, optional float AmountDepressed=1.f, optional bool bGamepad )
{
	return false;
}
simulated Delegate bool OnReceivedInputChar( int ControllerId, string Unicode )
{
	return false;
}
simulated Delegate bool InternalInputKey( int ControllerId, name Key, EInputEvent Event, optional float AmountDepressed=1.f, optional bool bGamepad )
{
	return false;
}
simulated Delegate bool InternalReceivedInputChar( int ControllerId, string Unicode )
{
	return false;
}

defaultproperties
{
	DefaultStyle=class'KF2Style'
	bAbsorbInput=true
}