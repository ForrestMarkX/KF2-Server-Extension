Class MX_PongGame extends MX_MiniGameBase;

var int Score,NumPlays;

var vector PlayerPad,EnemyPad,BallPos,BallVel,BallTrajectory;
var float ScreenHeight,BallWidth;
var enum EBallHeading
{
	BH_ToPlayer,
	BH_ToEnemy,
	BH_None,
} BallHeading;
var array<SoundCue> HitSoundsA,HitSoundsB;
var SoundCue MissSound[2];
var int HitSoundIndex[2];

var float EnemyPadVel,AITactic,AITacticTimer,AITrajOffset;
var bool bAIRandom;

const PadWidth=0.015;
const PadHeight=0.15;
const LevelBoarderSize=0.05;
const PadMoveLimit=0.125;
const BallHeight=0.03;
const InverseXOr=879379227;

function Init()
{
	local int i;

	Super.Init();
	if( Data!=0 )
		i = Data ^ InverseXOr;
	Score = (i >> 16) & 32767;
	if( Score>31767 )
		Score = Score-32768;
	NumPlays = i & 65535;
	SetAIRating();
}

final function UpdateScores()
{
	Data = (((Max(Score,-1000) & 32767) << 16) | (NumPlays & 65535)) ^ InverseXOr;
	SaveConfig();
}

function SetFXTrack( Object O )
{
	local ObjectReferencer R;
	local int i;

	if( SoundCue(O)!=None )
	{
		HitSoundsA.AddItem(SoundCue(O));
		HitSoundsB.AddItem(SoundCue(O));
	}
	else if( ObjectReferencer(O)!=None )
	{
		R = ObjectReferencer(O);
		if( R.ReferencedObjects.Length<2 )
			return;
		MissSound[0] = SoundCue(R.ReferencedObjects[0]);
		MissSound[1] = SoundCue(R.ReferencedObjects[1]);
		for( i=2; i<R.ReferencedObjects.Length; ++i )
		{
			if( (i & 1)==0 )
				HitSoundsA.AddItem(SoundCue(R.ReferencedObjects[i]));
			else HitSoundsB.AddItem(SoundCue(R.ReferencedObjects[i]));
		}
	}
}

function StartGame()
{
	Super.StartGame();
	SetTimer(2,false,'RespawnBall',Self);
}

function Render( float XPos, float YPos, float XSize, float YSize )
{
	local float H,W;
	
	ScreenHeight = YSize;

	// Score
	H = WorldInfo.RealTimeSeconds * 0.6;
	Canvas.Font = Canvas.GetDefaultCanvasFont();
	W = FMin(YSize/200.f,3.f);
	if( !bGameStarted )
	{
		Canvas.SetDrawColor(128,64,64,Abs(Sin(H))*96.f+128);
		Canvas.SetPos(XPos+XSize*0.4,YPos+YSize*0.2);
		Canvas.DrawText("Press Fire to start pong",,W,W);
	}
	else
	{
		Canvas.SetDrawColor(255,255,128,Abs(Sin(H))*96.f);
		Canvas.SetPos(XPos+XSize*0.2,YPos+YSize*0.22);
		Canvas.DrawText("Score: "$string(Score),,W,W);
		Canvas.SetPos(XPos+XSize*0.2,YPos+YSize*0.68);
		Canvas.DrawText("Plays: "$string(NumPlays),,W,W);
	}
	
	// Borders
	Canvas.SetDrawColor(Abs(Sin(H))*255.f,Abs(Sin(H+1.25))*255.f,Abs(Sin(H+2.35))*255.f,255);
	Canvas.SetPos(XPos,YPos);
	Canvas.DrawTile(Canvas.DefaultTexture,XSize,YSize*LevelBoarderSize,0,0,1,1);
	Canvas.SetPos(XPos,YPos+YSize*(1.f-LevelBoarderSize));
	Canvas.DrawTile(Canvas.DefaultTexture,XSize,YSize*LevelBoarderSize,0,0,1,1);
	
	// Player
	H = PadHeight*YSize;
	W = PadWidth*XSize;
	Canvas.SetDrawColor(128,255,128,255);
	Canvas.SetPos(XPos+PlayerPad.X*XSize,YPos+PlayerPad.Y*YSize-H*0.5);
	Canvas.DrawTile(Canvas.DefaultTexture,W,H,0,0,1,1);
	
	// Enemy
	Canvas.SetDrawColor(255,68,68,255);
	Canvas.SetPos(XPos+EnemyPad.X*XSize-W,YPos+EnemyPad.Y*YSize-H*0.5);
	Canvas.DrawTile(Canvas.DefaultTexture,W,H,0,0,1,1);
	
	// Pong ball
	Canvas.SetDrawColor(255,255,86,255);
	BallWidth = BallHeight*(YSize/XSize);
	H = BallHeight*YSize;
	W = H*0.5;
	Canvas.SetPos(XPos+BallPos.X*XSize-W,YPos+BallPos.Y*YSize-W);
	Canvas.DrawTile(Canvas.DefaultTexture,H,H,0,0,1,1);
	
	// Trajectory preview ball
	/*Canvas.SetDrawColor(255,255,86,64);
	Canvas.SetPos(XPos+BallTrajectory.X*XSize-W,YPos+BallTrajectory.Y*YSize-W);
	Canvas.DrawTile(Canvas.DefaultTexture,H,H,0,0,1,1);*/
}

function UpdateMouse( float X, float Y )
{
	Y /= (ScreenHeight*8/Sensitivity);
	PlayerPad.Y = FClamp(PlayerPad.Y-Y,PadMoveLimit,1.f-PadMoveLimit);
}

function SetMouse( float X, float Y )
{
	PlayerPad.Y = FClamp(Y/ScreenHeight,PadMoveLimit,1.f-PadMoveLimit);
}

final function RespawnBall()
{
	BallVel.X = -1;
	BallVel.Y = 0.5-FRand();
	BallVel = Normal2D(BallVel)*0.35;
	BallPos = Default.BallPos;
	BallHeading = BH_ToPlayer;
	EnemyPadVel = 0.f;
}

final function NewRound()
{
	BallVel = vect(0,0,0);
	BallPos = Default.BallPos;
	BallHeading = BH_None;
	SetTimer(1,false,'RespawnBall',Self);
}

final function PlayHitSound( bool bPlayer )
{
	if( bPlayer )
	{
		if( HitSoundsA.Length==0 )
			return;
		if( HitSoundsA[HitSoundIndex[0]]!=None )
			PlaySound(HitSoundsA[HitSoundIndex[0]],true);
		if( ++HitSoundIndex[0]==HitSoundsA.Length )
			HitSoundIndex[0] = 0;
	}
	else
	{
		if( HitSoundsB.Length==0 )
			return;
		if( HitSoundsB[HitSoundIndex[1]]!=None )
			PlaySound(HitSoundsB[HitSoundIndex[1]],true);
		if( ++HitSoundIndex[1]==HitSoundsB.Length )
			HitSoundIndex[1] = 0;
	}
}
final function PlayerScored( bool bPlayer )
{
	++NumPlays;
	if( bPlayer )
	{
		++Score;
		if( MissSound[1]!=None )
			PlaySound(MissSound[1],true);
	}
	else
	{
		--Score;
		if( MissSound[0]!=None )
			PlaySound(MissSound[0],true);
	}
	HitSoundIndex[0] = 0;
	HitSoundIndex[1] = 0;
	UpdateScores();
	SetAIRating();

	BallHeading = BH_None;
	SetTimer(2.5,false,'NewRound',Self);
}

// Calculate where the ball is going to hit on in enemy side.
final function CalcEndPosition()
{
	local float T,DY;
	local vector P,V;
	
	if( BallVel.X<=0.f ) // Never.
		return;
	
	V = BallVel;
	P = BallPos;

	// Get hit time.
	T = (EnemyPad.X - PadWidth - (BallWidth*0.5) - P.X) / V.X;

	// Now take bounces into account.
	while( true )
	{
		if( V.Y<0.f ) // Bottom.
		{
			DY = (LevelBoarderSize + (BallHeight*0.5) - P.Y) / V.Y; // Calc intersection time.
			if( DY<T )
			{
				P+=(V*DY);
				V.Y = -V.Y;
				T-=DY;
			}
			else break; // No more wallhits.
		}
		else if( V.Y>0.f ) // Top.
		{
			DY = (1.f - LevelBoarderSize - (BallHeight*0.5) - P.Y) / V.Y;
			if( DY<T )
			{
				P+=(V*DY);
				V.Y = -V.Y;
				T-=DY;
			}
			else break; // No more wallhits.
		}
		else break; // No wallhits!
	}
	BallTrajectory = P+(V*T);
}

function Tick( float Delta )
{
	local vector V,HN,ExtA,ExtB;
	local float DY;
	local bool bTraj,bRand;

	// Check collision unless out of bounds already.
	V = BallVel*Delta;
	if( BallHeading!=BH_None )
	{
		// Check paddles
		switch( BallHeading )
		{
		case BH_ToPlayer:
			if( BallPos.X<0.f )
				PlayerScored(false);
			else if( (BallPos.X+V.X)<0.05 )
			{
				ExtA.X = PadWidth*0.5;
				ExtA.Y = PadHeight*0.5;
				ExtB.X = BallWidth*0.5;
				ExtB.Y = BallHeight*0.5;
				if( Box8DirTrace(BallPos,V,PlayerPad+vect(0.5,0,0)*PadWidth,ExtB,ExtA,HN,DY) )
				{
					BallPos+=(V*DY);
					V = vect(0,0,0);

					if( HN.X<0.25 ) // Hit edge of the paddle
					{
						PlayerScored(false);
						BallVel = MirrorVectorByNormal(BallVel,HN);
					}
					else
					{
						AITrajOffset = 0.f;
						if( AITactic>3 )
							AITrajOffset = FMin((AITactic-3)*0.35,0.97)*(0.5-FRand())*(PadHeight+BallWidth); // Randomly chose to throw ball in the corners to give angular momentum.
						BallHeading = BH_ToEnemy;
						BallVel.X *= -1.05;
						BallVel.Y = (BallPos.Y-PlayerPad.Y) / PadHeight * Abs(BallVel.X) * 4.5;
						CalcEndPosition();
						PlayHitSound(true);
					}
				}
			}
			break;
		case BH_ToEnemy:
			if( BallPos.X>1.f )
				PlayerScored(true);
			else if( (BallPos.X+V.X)>0.95 )
			{
				ExtA.X = PadWidth*0.5;
				ExtA.Y = PadHeight*0.5;
				ExtB.X = BallWidth*0.5;
				ExtB.Y = BallHeight*0.5;
				if( Box8DirTrace(BallPos,V,EnemyPad-vect(0.5,0,0)*PadWidth,ExtB,ExtA,HN,DY) )
				{
					BallPos+=(V*DY);
					V = vect(0,0,0);

					if( HN.X>-0.25 ) // Hit edge of the paddle
					{
						PlayerScored(true);
						BallVel = MirrorVectorByNormal(BallVel,HN);
					}
					else
					{
						BallHeading = BH_ToPlayer;
						BallVel.X = -BallVel.X;
						BallVel.Y = (BallPos.Y-EnemyPad.Y) / PadHeight * Abs(BallVel.X) * 4.5;
						PlayHitSound(false);
					}
				}
			}
			break;
		}

		// Check edges
		// Top.
		if( V.Y<0.f )
		{
			DY = LevelBoarderSize + (BallHeight*0.5) - BallPos.Y;
			if( DY>V.Y )
			{
				DY = DY / V.Y; // Calc intersection time.
				BallPos+=(V*DY);
				V = vect(0,0,0);
				BallVel.Y = -BallVel.Y;
				BallPos.Y = FMax(BallPos.Y,LevelBoarderSize+(BallHeight*0.5));
				CalcEndPosition();
			}
		}
		// Bottom
		if( V.Y>0.f )
		{
			DY = 1.f - LevelBoarderSize - (BallHeight*0.5) - BallPos.Y;
			if( DY<V.Y )
			{
				DY = DY / V.Y;
				BallPos+=(V*DY);
				V = vect(0,0,0);
				BallVel.Y = -BallVel.Y;
				BallPos.Y = FMin(BallPos.Y,1.f-LevelBoarderSize-(BallHeight*0.5));
				CalcEndPosition();
			}
		}

		bRand = true;
		if( AITactic>0.f ) // Directly follow ball
		{
			bTraj = false;
			if( AITactic<1.f )
			{
				if( BallHeading==BH_ToEnemy )
					bRand = BallPos.X>AITactic;
			}
			else
			{
				bRand = false;
				if( AITactic>2.f && BallHeading==BH_ToEnemy )
					bTraj = (AITactic>=4.f || BallPos.X>(2.f - AITactic*0.5));
			}

			if( !bRand )
			{
				if( bTraj )
				{
					if( BallPos.X>0.5 )
						HN.Y = BallTrajectory.Y+AITrajOffset-EnemyPad.Y;
					else HN.Y = BallTrajectory.Y-EnemyPad.Y;
					HN.X = FMin(2.f + ((AITactic-1.f)*3.f),13.f); // Calc paddle changespeed rate
					DY = FMin(0.15 + (AITactic*0.02f),2.f); // Calc paddle max speed
				}
				else
				{
					HN.Y = BallPos.Y-EnemyPad.Y;
					HN.X = FMin(3.f + (AITactic*6.f),15.f); // Calc paddle changespeed rate
					DY = FMin(0.25 + (AITactic*0.025f),2.f); // Calc paddle max speed
				}
				EnemyPadVel *= (1.f-Delta*HN.X); // Deaccel all the time.
				EnemyPadVel = FClamp(EnemyPadVel+(HN.Y*Delta*HN.X*6.f),-DY,DY);
			}
		}
		
		// Update AI
		if( bRand ) // Random motion.
		{
			if( AITacticTimer<WorldInfo.TimeSeconds )
			{
				bAIRandom = (Rand(2)==0);
				AITacticTimer = WorldInfo.TimeSeconds+FRand();
			}
			DY = FMax(FMin(Delta,0.65f-Abs(EnemyPadVel)),0.f);
			if( bAIRandom )
				EnemyPadVel += DY;
			else EnemyPadVel -= DY;
		}
		
		// Apply by velocity and limit movement.
		EnemyPad.Y = EnemyPad.Y+(EnemyPadVel*Delta);
		if( EnemyPad.Y<PadMoveLimit )
		{
			EnemyPad.Y = PadMoveLimit;
			EnemyPadVel = FMax(EnemyPadVel,0.f);
		}
		else if( EnemyPad.Y>(1.f-PadMoveLimit) )
		{
			EnemyPad.Y = 1.f-PadMoveLimit;
			EnemyPadVel = FMin(EnemyPadVel,0.f);
		}
	}
	BallPos+=V;
}

final function SetAIRating()
{
	AITactic = float(Score)*0.1+0.5;
}

defaultproperties
{
	PlayerPad=(X=0.005,Y=0.5)
	EnemyPad=(X=0.995,Y=0.5)
	ScreenHeight=800
	BallPos=(X=0.75,Y=0.5)
	BallTrajectory=(X=1,Y=0.5)
	BallHeading=BH_None
}