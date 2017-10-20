class ExtWidget_BossHealthBar extends KFGFxWidget_BossHealthBar;

var transient array<KFPawn_Monster> BossList;
var transient float NextBossDistTime,LastHP,LastShield;
var transient byte NumBosses;
var transient bool bVisib,bHasInit;

function TickHud(float DeltaTime)
{
	if( !KFPC.bHideBossHealthBar && BossList.Length>0 )
	{
		if( KFPC.WorldInfo.RealTimeSeconds>LastUpdateTime && HasBossesAlive() )
		{
			LastUpdateTime = KFPC.WorldInfo.RealTimeSeconds + UpdateTickTime;
			if( !bVisib )
			{
				LastHP = -1;
				LastShield = -1;
				bVisib = true;
				SetVisible(true);
			}
			UpdateBossInfo();
		}
	}
	else if( bHasInit )
	{
		NumBosses = 0;
		bHasInit = false;
		BossList.Length = 0;
		if( bVisib )
		{
			bVisib = false;
			SetVisible(false);
		}
	}
}

final function bool HasBossesAlive()
{
	local int i;
	
	for( i=(BossList.Length-1); i>=0; --i )
	{
		if( BossList[i]==None || BossList[i].bDeleteMe || BossList[i].GetTeamNum()==0 )
		{
			BossList.Remove(i,1);
			--NumBosses;
		}
		else if( !BossList[i].IsAliveAndWell() )
			BossList.Remove(i,1);
	}
	return (BossList.Length>0);
}

function SetBossPawn(KFInterface_MonsterBoss NewBoss)
{
	if( !KFPC.bHideBossHealthBar && NewBoss!=None && NewBoss.GetMonsterPawn().IsAliveAndWell() )
	{
		bHasInit = true;
		++NumBosses;
		BossList.AddItem(NewBoss.GetMonsterPawn());
	}
}

final function UpdateBossInfo()
{
	local float V;
	local KFPawn_Monster B;

	if( NextBossDistTime<KFPC.WorldInfo.RealTimeSeconds )
	{
		NextBossDistTime = KFPC.WorldInfo.RealTimeSeconds + 1.f;
		CheckBestBoss();
	}

	V = (BossPawn!=None ? FClamp(float(BossPawn.GetMonsterPawn().Health) / float(BossPawn.GetMonsterPawn().HealthMax),0.f,1.f) : 0.f);
	if( LastHP!=V )
	{
		LastHP = V;
		SetFloat("currentHealthPercentValue",V);
	}
	
	V = 0.f;
	if( NumBosses>1 )
	{
		foreach BossList(B)
			V += FClamp(float(B.Health) / float(B.HealthMax),0.f,1.f);
		V /= NumBosses;
	}
	if( LastShield!=V )
	{
		LastShield = V;
		SetFloat("currentShieldPercecntValue",V);
	}
}

final function CheckBestBoss()
{
	local KFPawn_Monster B,Best;
	local vector Pos;
	local float Dist,BestDist;

	Pos = (KFPC.ViewTarget!=None ? KFPC.ViewTarget.Location : KFPC.Location);
	foreach BossList(B)
	{
		Dist = VSizeSq(Pos-B.Location);
		if( Best==None || Dist<BestDist )
		{
			Best = B;
			BestDist = Dist;
		}
	}
	
	if( Best!=BossPawn )
	{
		BossPawn = Best;
		SetBossName(Best.static.GetLocalizedName());
	}
}

function OnNamePlateHidden();

function UpdateBossHealth();

function UpdateBossBattlePhase(int BattlePhase);

function UpdateBossShield(float NewShieldPercect);

DefaultProperties
{
}