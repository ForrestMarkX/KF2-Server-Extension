class ExtHUD_WaveInfo extends KFGFxHUD_WaveInfo;

function TickHud(float DeltaTime)
{
	local int i;

    if(KFGRI == none)
        KFGRI = KFGameReplicationInfo(GetPC().WorldInfo.GRI);
    else
    {
        if(KFGRI.bTraderIsOpen)
        {
			i = KFGRI.GetTraderTimeRemaining();
			if(LastTraderTimeRemaining != i)
			{
				SetInt("remainingTraderTime" ,i);
				LastTraderTimeRemaining = i;
			}
		}
        else
		{
			i = KFGRI.IsFinalWave() ? INDEX_NONE : Max(KFGRI.AIRemaining,0);
			if(LastZEDCount != i)
			{
				SetInt("remainingZEDs" ,i);
				LastZEDCount = i;
			}
		}
		
		// Max # of waves.
		if(LastWaveMax != KFGRI.WaveMax)
		{
			LastWaveMax = KFGRI.WaveMax;
			SetInt("maxWaves" ,LastWaveMax-1);
		}
		
		// Current wave we're on.
		if( LastWave!=KFGRI.WaveNum )
		{
			LastWave = KFGRI.WaveNum;
			if( LastWave>LastWaveMax )
			{
				SetInt("currentWave",0); // Force text to refresh.
				SetString("finalText", "END");
			}
			SetInt("currentWave",Min(LastWave,LastWaveMax));
		}
    }
}

function UpdateWaveCount();

DefaultProperties
{
	LastWave=-1
}