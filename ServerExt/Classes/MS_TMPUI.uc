Class MS_TMPUI extends UIInteraction;

var UIInteraction RealUI;
var ObjectReferencer Referencer;

static final function Apply()
{
	local GameViewportClient G;
	local MS_TMPUI T;

	G = class'Engine'.Static.GetEngine().GameViewport;
	if( MS_TMPUI(G.UIController)!=None )
		return;
	T = new(G)class'MS_TMPUI';
	T.RealUI = G.UIController;
	T.UIManager = T.RealUI.UIManager;
	G.UIController = T;
}
static final function Remove()
{
	local GameViewportClient G;
	local MS_TMPUI T;

	G = class'Engine'.Static.GetEngine().GameViewport;
	T = MS_TMPUI(G.UIController);
	if( T==None )
		return;
	G.UIController = T.RealUI;
}

defaultproperties
{
	Begin Object Class=ObjectReferencer Name=MSGameReference
		ReferencedObjects.Add(class'MS_Game')
		ReferencedObjects.Add(class'MS_PC')
	End Object
	Referencer=MSGameReference
}