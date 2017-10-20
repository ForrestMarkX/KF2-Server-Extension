Class UIP_Settings extends KFGUI_MultiComponent;

var KFGUI_ComponentList SettingsBox;
var KFGUI_Button KeyBindButton;
var KFGUI_TextLable KeyBindLabel;
var name CurKeybind;
var bool bSetKeybind,bDelayedSet;

function InitMenu()
{
	Super.InitMenu();

	// Client settings
	SettingsBox = KFGUI_ComponentList(FindComponentID('SettingsBox'));
	
	//AddCheckBox("Text-To-Speech:","Enable Text-to-Speech talk for player chat messages",'TTS', bool bDefault );
	AddCheckBox("First person legs:","Show first person body",'FP',class'ExtPlayerController'.Default.bShowFPLegs);
	if( class'ExtPlayerController'.Default.bShowFPLegs )
		ExtPlayerController(GetPlayer()).ToggleFPBody(false);
	AddCheckBox("Hide name beacons:","Hide the player name beacons",'NB',class'ExtPlayerController'.Default.bHideNameBeacons);
	AddCheckBox("Hide kill messages:","Hide player kill messages",'KM',class'ExtPlayerController'.Default.bHideKillMsg);
	AddCheckBox("Hide damage messages:","Hide player damage messages",'DM',class'ExtPlayerController'.Default.bHideDamageMsg);
	AddCheckBox("Hide damage popup:","Hide damage popup messages",'PP',class'ExtPlayerController'.Default.bHideNumberMsg);
	AddCheckBox("Use KF2 DeathMessages:","Use KF2 death message display format.",'K2DM',class'ExtPlayerController'.Default.bUseKF2DeathMessages);
	AddCheckBox("Use KF2 Kill Messages:","Use KF2 kill message display format.",'K2KM',class'ExtPlayerController'.Default.bUseKF2KillMessages);
	KeyBindButton = AddButton("","Toggle Behindview keybind:","With this desired button you can toggle your behindview (click to change it)",'KB',KeyBindLabel);
	AddCheckBox("Don't become zombie:","Disable zombie player mode (for game modes that support it)",'ZP',class'ExtPlayerController'.Default.bNoMonsterPlayer);
	AddCheckBox("No screen shake:","Disable screen shake (from explosions)",'NS',class'ExtPlayerController'.Default.bNoScreenShake);
	InitBehindviewKey();
}
final function InitBehindviewKey()
{
	local PlayerInput IN;
	local int i;

	CurKeybind = '';

	// Check what keys now using!
	IN = Owner.BackupInput;
	for( i=0; i<IN.Bindings.Length; ++i )
	{
		if( IN.Bindings[i].Command~="Camera FirstPerson" )
		{
			CurKeybind = IN.Bindings[i].Name;
			break;
		}
	}
	KeyBindButton.ButtonText = (CurKeybind!='' ? string(CurKeybind) : "<Not set>");
}
final function KFGUI_CheckBox AddCheckBox( string Cap, string TT, name IDN, bool bDefault )
{
	local KFGUI_CheckBox CB;
	
	CB = KFGUI_CheckBox(SettingsBox.AddListComponent(class'KFGUI_CheckBox'));
	CB.LableString = Cap;
	CB.ToolTip = TT;
	CB.bChecked = bDefault;
	CB.InitMenu();
	CB.ID = IDN;
	CB.OnCheckChange = CheckChange;
	return CB;
}
final function KFGUI_Button AddButton( string ButtonText, string Cap, string TT, name IDN, out KFGUI_TextLable Label )
{
	local KFGUI_Button CB;
	local KFGUI_MultiComponent MC;
	
	MC = KFGUI_MultiComponent(SettingsBox.AddListComponent(class'KFGUI_MultiComponent'));
	MC.InitMenu();
	Label = new(MC) class'KFGUI_TextLable';
	Label.SetText(Cap);
	Label.XSize = 0.75;
	Label.FontScale = 0;
	Label.AlignY = 1;
	MC.AddComponent(Label);
	CB = new(MC) class'KFGUI_Button';
	CB.XPosition = 0.77;
	CB.XSize = 0.22;
	CB.ButtonText = ButtonText;
	CB.ToolTip = TT;
	CB.ID = IDN;
	CB.OnClickLeft = ButtonClicked;
	CB.OnClickRight = ButtonClicked;
	MC.AddComponent(CB);
	return CB;
}

function CheckChange( KFGUI_CheckBox Sender )
{
	local ExtPlayerController PC;
	
	PC = ExtPlayerController(GetPlayer());
	switch( Sender.ID )
	{
	case 'FP':
		PC.ToggleFPBody(Sender.bChecked);
		break;
	case 'NB':
		PC.bHideNameBeacons = Sender.bChecked;
		break;
	case 'KM':
		PC.bHideKillMsg = Sender.bChecked;
		PC.SendServerSettings();
		break;
	case 'DM':
		PC.bHideDamageMsg = Sender.bChecked;
		PC.SendServerSettings();
		break;
	case 'PP':
		PC.bHideNumberMsg = Sender.bChecked;
		PC.SendServerSettings();
		break;
	case 'ZP':
		PC.bNoMonsterPlayer = Sender.bChecked;
		PC.SendServerSettings();
		break;
	case 'NS':
		PC.bNoScreenShake = Sender.bChecked;
		break;
	case 'K2DM':
		PC.bUseKF2DeathMessages = Sender.bChecked;
		break;
	case 'K2KM':
		PC.bUseKF2KillMessages = Sender.bChecked;
		break;
	}
	PC.SaveConfig();
}
function ButtonClicked( KFGUI_Button Sender )
{
	switch( Sender.ID )
	{
	case 'KB':
		KeyBindButton.ButtonText = "Press a button";
		KeyBindButton.SetDisabled(true);
		GrabKeyFocus();
		bSetKeybind = true;
		bDelayedSet = false;
		SetTimer(0.4,false);
		break;
	}
}
function Timer()
{
	bDelayedSet = false;
}
function bool NotifyInputKey( int ControllerId, name Key, EInputEvent Event, float AmountDepressed, bool bGamepad )
{
	if( Event==IE_Pressed && !bDelayedSet && InStr(Caps(string(Key)),"MOUSE")==-1 )
	{
		if( Key!='Escape' )
			BindNewKey(Key,"Camera FirstPerson");
		ReleaseKeyFocus();
	}
	return true;
}
function LostKeyFocus()
{
	KeyBindButton.SetDisabled(false);
	bSetKeybind = false;
	InitBehindviewKey();
}
final function BindNewKey( name Key, string Cmd )
{
	local int i;
	local PlayerInput IN;

	// First unbind old key.
	IN = Owner.BackupInput;
	if( CurKeybind!='' )
	{
		for( i=0; i<IN.Bindings.Length; ++i )
		{
			if( IN.Bindings[i].Name==CurKeybind )
				IN.Bindings.Remove(i,1);
		}
	}
	
	// Then bind a new key.
	for( i=0; i<IN.Bindings.Length; ++i )
	{
		if( IN.Bindings[i].Name==Key )
		{
			IN.Bindings[i].Command = Cmd;
			break;
		}
	}
	if( i==IN.Bindings.Length )
		IN.Bindings.Length = i+1;
	IN.Bindings[i].Name = Key;
	IN.Bindings[i].Command = Cmd;
	IN.Bindings[i].Control = false;
	IN.Bindings[i].Shift = false;
	IN.Bindings[i].Alt = false;
	IN.Bindings[i].bIgnoreCtrl = false;
	IN.Bindings[i].bIgnoreShift = (Key=='F1'); // Hack, fix Steam overlay commands.
	IN.Bindings[i].bIgnoreAlt = (Key=='F7');

	// Check for any other duplicates of same key.
	for( i=(i+1); i<IN.Bindings.Length; ++i )
	{
		if( IN.Bindings[i].Name==Key )
			IN.Bindings.Remove(i,1);
	}
	
	if( IN.Class!=Class'KFPlayerInput' )
	{
		Class'KFPlayerInput'.Default.Bindings = IN.Bindings; // Hack!
		Class'KFPlayerInput'.Static.StaticSaveConfig();
	}
	else IN.SaveConfig();
}

defaultproperties
{
	Begin Object Class=KFGUI_ComponentList Name=ClientSettingsBox
		XPosition=0.025
		YPosition=0.025
		XSize=0.95
		YSize=0.95
		ID="SettingsBox"
		ListItemsPerPage=14
	End Object
	
	Components.Add(ClientSettingsBox)
}