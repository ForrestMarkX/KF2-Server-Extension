// HUD minigame base.
Class MX_MiniGameBase extends Object within PlayerController
	config(Game)
	abstract;

var config int Data;
var config float Sensitivity;
var transient Canvas Canvas;
var bool bGameStarted;

function Init()
{
	if( Sensitivity==0 )
	{
		Sensitivity = 1;
		SaveConfig();
	}
}

function AdjustSensitivity( bool bUp )
{
	if( bUp )
		Sensitivity = FMin(Sensitivity+0.05,3.f);
	else Sensitivity = FMax(Sensitivity-0.05,0.05f);
	SetTimer(2,false,'DelayedSaveConfig',Self);
}

final function DelayedSaveConfig()
{
	SaveConfig();
}

function SetFXTrack( Object O );

function StartGame()
{
	bGameStarted = true;
}

function Render( float XPos, float YPos, float XSize, float YSize );

function SetMouse( float X, float Y );
function UpdateMouse( float X, float Y );

function Tick( float Delta );

final function bool Box8DirTrace( vector Start, vector Dir, vector HitTest, vector Ext, vector ExtB, out vector HitNorm, out float HitTime ) // free movement trace.
{
	local vector V;
	local float tmin,tmax,tymin,tymax,tmp;
	local bool bMaxY,bMinY;

	V = HitTest-Start;
	Ext+=ExtB;

	// AABB check if start inside box.
	if( Abs(V.X)<Ext.X && Abs(V.Y)<Ext.Y )
	{
		if( (V Dot Dir)<0.f ) // Moving out from origin.
			return false;
		V = Normal2D(V);
		
		// Check which normal axis to use.
		if( Abs(V.X)>Normal2D(ExtB).Y )
		{
			if( V.X<0 )
				HitNorm = vect(1,0,0);
			else HitNorm = vect(-1,0,0);
		}
		else if( V.Y<0 )
			HitNorm = vect(0,1,0);
		else HitNorm = vect(0,-1,0);
		
		HitTime = 0.f;
		return true;
	}
	
	// Actually perform the trace check.
	tmp = Dir.X==0.f ? 0.00001 : (1.f / Dir.X);
	tmin = (V.X - Ext.X) * tmp;
	tmax = (V.X + Ext.X) * tmp;

	if( tmin > tmax )
	{
		tmp = tmax;
		tmax = tmin;
		tmin = tmp;
	}

	tmp = Dir.Y==0.f ? 0.00001 : (1.f / Dir.Y);
	tymin = (V.Y - Ext.Y) * tmp;
	tymax = (V.Y + Ext.Y) * tmp;

	if (tymin > tymax)
	{
		tmp = tymax;
		tymax = tymin;
		tymin = tmp;
	}

	// Fully missed.
	if( (tmin > tymax) || (tymin > tmax) )
		return false;

	if (tymin > tmin)
	{
		bMinY = true;
		tmin = tymin;
	}

	if (tymax < tmax)
	{
		bMaxY = true;
		tmax = tymax;
	}
	
	if( tmin<tmax )
	{
		bMaxY = bMinY;
		tmax = tmin;
	}
	if( tmax<0.f || tmax>1.f ) // Too far away
		return false;

	if( bMaxY )
	{
		if( Dir.Y>0.f )
			HitNorm = vect(0,-1,0);
		else HitNorm = vect(0,1,0);
	}
	else if( Dir.X>0.f )
		HitNorm = vect(-1,0,0);
	else HitNorm = vect(1,0,0);
	
	HitTime = tmax;
	return true;
}
