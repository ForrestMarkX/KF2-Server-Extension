Class MS_PendingData extends Object;

var SoundCue PendingSong;
var Object PendingFX;
var string PendingURL;

final function Reset()
{
	PendingSong = None;
	PendingFX = None;
	PendingURL = "";
}
