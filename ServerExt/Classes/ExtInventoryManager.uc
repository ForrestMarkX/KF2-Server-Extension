class ExtInventoryManager extends KFInventoryManager;

// Dosh spamming barrier.
var transient float MoneyTossTime;
var transient byte MoneyTossCount;

reliable server function ServerThrowMoney()
{
	if( MoneyTossTime>WorldInfo.TimeSeconds )
	{
		if( MoneyTossCount>=10 )
			return;
		++MoneyTossCount;
		MoneyTossTime = FMax(MoneyTossTime,WorldInfo.TimeSeconds+0.5);
	}
	else
	{
		MoneyTossCount = 0;
		MoneyTossTime = WorldInfo.TimeSeconds+1;
	}
	Super.ServerThrowMoney();
}
