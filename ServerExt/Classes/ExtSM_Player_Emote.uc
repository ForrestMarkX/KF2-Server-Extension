class ExtSM_Player_Emote extends KFSM_Player_Emote;

static function byte PackFlagsBase( KFPawn P )
{
	return class'ExtEmoteList'.static.GetEmoteIndex( class'ExtEmoteList'.static.GetEquippedEmoteId(ExtPlayerController(P.Controller)) );
}

function PlayAnimation()
{
	AnimName = class'ExtEmoteList'.static.GetEmoteFromIndex( KFPOwner.SpecialMoveFlags );

	PlaySpecialMoveAnim( AnimName, AnimStance, BlendInTime, BlendOutTime, 1.f );

	if( KFPOwner.Role == ROLE_Authority )
	{	
		KFGameInfo(KFPOwner.WorldInfo.Game).DialogManager.PlayDialogEvent( KFPOwner, 31 );
	}

	// Store camera mode for restoration after move ends
	LastCameraMode = 'FirstPerson';
	if( PCOwner != none && PCOwner.PlayerCamera != none )
	{
		LastCameraMode = PCOwner.PlayerCamera.CameraStyle;
	}

	// Set camera to emote third person camera
	if( PCOwner == none || !PawnOwner.IsLocallyControlled() )
	{
		KFPOwner.SetWeaponAttachmentVisibility( false );
		return;
	}

	if( PCOwner.CanViewCinematics() )
	{
		PCOwner.ClientSetCameraFade( true, FadeInColor, vect2d(1.f, 0.f), FadeInTime, true );
		PCOwner.PlayerCamera.CameraStyle = 'Emote';

		// Switch camera modes immediately in single player or on client
		if( PCOwner.WorldInfo.NetMode != NM_DedicatedServer )
		{
			PCOwner.ClientSetCameraMode( 'Emote' );
		}

		KFPOwner.SetWeaponAttachmentVisibility( false );
	}
}

DefaultProperties
{
}