Class UIP_MiniGame extends KFGUI_MultiComponent;

var MX_MiniGameBase ActiveGame;
var transient float LastUpdateTime;
var WorldInfo Level;

function ShowMenu()
{
	Super.ShowMenu();
	
	Level = GetPlayer().WorldInfo;
	LastUpdateTime = Level.RealTimeSeconds;
	if( ActiveGame==None )
	{
		ActiveGame = new (GetPlayer()) class'MX_PongGame';
		ActiveGame.Init();
		ActiveGame.SetFXTrack(ExtPlayerController(GetPlayer()).BonusFX);
		ActiveGame.StartGame();
	}
}

function DrawMenu()
{
	// Update input.
	ActiveGame.SetMouse(Owner.MousePosition.X-CompPos[0],Owner.MousePosition.Y-CompPos[1]);
	
	// Handle tick.
	ActiveGame.Tick(FMin(Level.RealTimeSeconds-LastUpdateTime,0.05));
	LastUpdateTime = Level.RealTimeSeconds;
	
	// Draw background.
	Canvas.SetPos(0,0);
	Canvas.SetDrawColor(0,0,0,255);
	Canvas.DrawTile(Canvas.DefaultTexture,CompPos[2],CompPos[3],0,0,1,1);
	
	// Draw minigame
	ActiveGame.Canvas = Canvas;
	ActiveGame.Render(0,0,CompPos[2],CompPos[3]);
	ActiveGame.Canvas = None;
}

defaultproperties
{
}