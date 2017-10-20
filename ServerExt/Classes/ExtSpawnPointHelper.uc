// Helper actor to find all possible spawnpoints for humans on the map.
Class ExtSpawnPointHelper extends Info
	transient;

var transient array<NavigationPoint> PendingList,CheckedList;
var array<Actor> ValidSpawnSpots;

static final function ExtSpawnPointHelper FindHelper( WorldInfo Level )
{
	local ExtSpawnPointHelper H;
	
	foreach Level.DynamicActors(class'ExtSpawnPointHelper',H)
		return H;
	return Level.Spawn(class'ExtSpawnPointHelper');
}
final function Actor PickBestSpawn()
{
	local Actor N,BestN;
	local KFPawn P;
	local float Score,BestScore,Dist;
	local KFPawn_Human H;
	
	BestN = None;
	BestScore = 0;
	foreach ValidSpawnSpots(N)
	{
		if( Rand(4)==0 )
		{
			Score = FRand();
			foreach WorldInfo.AllPawns(class'KFPawn',P,N.Location,2000.f)
			{
				if( !P.IsAliveAndWell() )
					continue;
				Dist = VSize(N.Location-P.Location);
				if( FastTrace(P.Location,N.Location) )
					Dist*=0.75;
				if( P.IsA('KFPawn_Human') )
					Score+=(3000.f-Dist)/2000.f;
				else Score-=(3500.f-Dist)/2500.f;
			}
			if( BestN==None || Score>BestScore )
			{
				BestN = N;
				BestScore = Score;
			}
		}
	}

	// See if can spawn ontop of other players.
	foreach WorldInfo.AllPawns(class'KFPawn_Human',H)
	{
		if( !H.IsAliveAndWell() || H.Physics==PHYS_Falling || (ExtHumanPawn(H)!=None && ExtHumanPawn(H).bFeigningDeath) )
			continue;
		Score = FRand();
		foreach WorldInfo.AllPawns(class'KFPawn',P,H.Location,2000.f)
		{
			if( !P.IsAliveAndWell() )
				continue;
			Dist = VSize(H.Location-P.Location);
			if( FastTrace(P.Location,H.Location) )
				Dist*=0.75;
			if( P.IsA('KFPawn_Human') )
				Score+=(3000.f-Dist)/3000.f;
			else Score-=(3500.f-Dist)/3500.f;
		}
		if( BestN==None || Score>BestScore )
		{
			BestN = H;
			BestScore = Score;
		}
	}
	return BestN;
}

function PreBeginPlay()
{
	SetTimer(0.2,false,'InitChecker');
}
function InitChecker()
{
	local PlayerStart PS,Fallback;

	foreach WorldInfo.AllNavigationPoints(class'PlayerStart',PS)
	{
		Fallback = PS;
		if( PS.bEnabled && PS.TeamIndex==0 )
		{
			CheckSpawn(PS);
			if( PendingList.Length!=0 )
				break;
		}
	}
	if( PendingList.Length==0 && Fallback!=None )
		CheckSpawn(Fallback);
	SetTimer(0.001,true,'NextCheck');
}
function NextCheck()
{
	local NavigationPoint N;
	local byte i;

	if( PendingList.Length!=0 )
	{
		while( ++i<5 && PendingList.Length!=0 )
		{
			N = PendingList[PendingList.Length-1];
			PendingList.Remove(PendingList.Length-1,1);
			CheckSpawn(N);
		}
	}
	else
	{
		ClearTimer('NextCheck');
		CheckedList.Length = 0;
	}
}
final function CheckSpawn( NavigationPoint N )
{
	local vector V;
	local ReachSpec R;
	local NavigationPoint E;
	local KFPawnBlockingVolume P;

	V = N.Location;
	if( N.MaxPathSize.Radius>30 && N.MaxPathSize.Height>80 && FindSpot(vect(36,36,86),V) && KFDoorMarker(N)==None && PickupFactory(N)==None )
	{
		//DrawDebugLine(V,V+vect(0,0,50),255,255,255,true);
		ValidSpawnSpots.AddItem(N);
	}
	CheckedList.AddItem(N);
	
	foreach N.PathList(R)
	{
		E = R.GetEnd();
		if( E==None || R.CollisionRadius<30 || R.CollisionHeight<80 || R.Class==Class'ProscribedReachSpec' )
		{
			//if( E!=None )
			//	DrawDebugLine(E.Location,N.Location,255,255,0,true);
			continue;
		}
		if( CheckedList.Find(E)!=INDEX_NONE )
			continue;
		// DO NOT go through any blocking volumes.
		V = (N.Location+E.Location) * 0.5;
		foreach OverlappingActors(class'KFPawnBlockingVolume',P,VSize(N.Location-V),V)
		{
			if( P.bBlockPlayers && TraceComponent(V,V,P.CollisionComponent,E.Location,N.Location,vect(36,36,50)) )
				break;
		}
		if( P==None )
		{
			//DrawDebugLine(E.Location,N.Location,0,255,0,true);
			PendingList.AddItem(E);
		}
		//else DrawDebugLine(E.Location,N.Location,255,0,0,true);
	}
}
