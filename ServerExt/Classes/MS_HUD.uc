Class MS_HUD extends HUD;

var bool bShowProgress,bProgressDC;
var array<string> ProgressLines;
var MX_MiniGameBase ActiveGame;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	ActiveGame = new (PlayerController(Owner)) class'MX_PongGame';
	ActiveGame.Init();
	ActiveGame.SetFXTrack(class'MS_PC'.Default.TravelData.PendingFX);
}
event PostRender()
{
	ActiveGame.Canvas = Canvas;
	ActiveGame.Render(Canvas.ClipX*0.1,Canvas.ClipY*0.2,Canvas.ClipX*0.8,Canvas.ClipY*0.7);
	ActiveGame.Canvas = None;
	if( bShowProgress )
		RenderProgress();
}

function Tick( float Delta )
{
	ActiveGame.Tick(Delta);
}

final function ShowProgressMsg( string S, optional bool bDis )
{
	if( S=="" )
	{
		bShowProgress = false;
		return;
	}
	bShowProgress = true;
	ParseStringIntoArray(S,ProgressLines,"|",false);
	bProgressDC = bDis;
	if( !bDis )
		ProgressLines.AddItem("Press [Esc] to cancel connection");
}

final function RenderProgress()
{
	local float Y,XL,YL,Sc;
	local int i;
	
	Canvas.Font = Canvas.GetDefaultCanvasFont();
	Sc = FMin(Canvas.ClipY/1000.f,3.f);
	if( bProgressDC )
		Canvas.SetDrawColor(255,80,80,255);
	else Canvas.SetDrawColor(255,255,255,255);
	Y = Canvas.ClipY*0.05;

	for( i=0; i<ProgressLines.Length; ++i )
	{
		Canvas.TextSize(ProgressLines[i],XL,YL,Sc,Sc);
		Canvas.SetPos((Canvas.ClipX-XL)*0.5,Y);
		Canvas.DrawText(ProgressLines[i],,Sc,Sc);
		Y+=YL;
	}
	Canvas.SetPos(Canvas.ClipX*0.2,Canvas.ClipY*0.91);
	Canvas.DrawText("Use Mouse scroll to adjust sensitivity: "$(ActiveGame.Sensitivity*100.f)$"%",,Sc,Sc);
}

defaultproperties
{
}