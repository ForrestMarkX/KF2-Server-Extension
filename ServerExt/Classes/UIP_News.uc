Class UIP_News extends KFGUI_MultiComponent;

var KFGUI_TextField NewsField;
var string WebsiteURL;
var KFGUI_Button WebsiteButton;

function InitMenu()
{
	Super.InitMenu();

	// Client settings
	NewsField = KFGUI_TextField(FindComponentID('News'));
	WebsiteButton = KFGUI_Button(FindComponentID('Website'));
	Timer();
}
function ShowMenu()
{
	local KFGameReplicationInfo GRI;
	
	Super.ShowMenu();
	GRI = KFGameReplicationInfo(GetPlayer().WorldInfo.GRI);
	WebsiteButton.SetDisabled(GRI==None || GRI.ServerAdInfo.WebsiteLink=="");
	if( !WebsiteButton.bDisabled )
	{
		WebsiteURL = GRI.ServerAdInfo.WebsiteLink;
		WebsiteButton.ChangeToolTip("Visit the server website at: "$WebsiteURL);
	}
}
function Timer()
{
	if( !ExtPlayerController(GetPlayer()).bMOTDReceived )
		SetTimer(0.2,false);
	else NewsField.SetText(ExtPlayerController(GetPlayer()).ServerMOTD);
}
function ButtonClicked( KFGUI_Button Sender )
{
	switch( Sender.ID )
	{
	case 'Website':
		class'GameEngine'.static.GetOnlineSubsystem().OpenURL(WebsiteURL);
		break;
	}
}

defaultproperties
{
	Begin Object Class=KFGUI_TextField Name=NewsText
		ID="News"
		XPosition=0.025
		YPosition=0.025
		XSize=0.95
		YSize=0.893
	End Object
	Begin Object Class=KFGUI_Button Name=WebSiteButton
		ID="Website"
		ButtonText="Visit Website"
		XPosition=0.44
		YPosition=0.92
		XSize=0.12
		YSize=0.06
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object

	Components.Add(NewsText)
	Components.Add(WebSiteButton)
}