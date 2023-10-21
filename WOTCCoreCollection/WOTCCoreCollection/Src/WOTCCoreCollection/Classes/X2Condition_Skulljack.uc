class X2Condition_Skulljack extends X2Condition;

var name FinalzeHackAbilityName;

// Issue #26
// This is an optimized version of X2Condition_StasisLanceTarget, which checks if the target should be Skulljackable.

// Skulljack is available only during specific points in the story.
function bool CanEverBeValid(XComGameState_Unit SourceUnit, bool bStrategyCheck)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));

	return	XComHQ.GetObjectiveStatus('T1_M2_S3_SKULLJACKCaptain') == eObjectiveState_InProgress	||
			XComHQ.GetObjectiveStatus('T1_M3_KillCodex') == eObjectiveState_InProgress				||
			XComHQ.GetObjectiveStatus('T1_M5_SKULLJACKCodex') == eObjectiveState_InProgress			||
			XComHQ.GetObjectiveStatus('T1_M6_KillAvatar') == eObjectiveState_InProgress;
}

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit				UnitTarget;
	local X2CharacterTemplate				CharacterTemplate;
	local XComGameState_HeadquartersXCom	XComHQ;
	//local XComTacticalCheatManager		CheatMan;
	local array<Name>						PossibleHackRewards;

	UnitTarget = XComGameState_Unit(kTarget);
	if (UnitTarget == none)
		return 'AA_NotAUnit';

	if (UnitTarget.IsDead())
		return 'AA_UnitIsDead';

	// Skulljacking and Skullmining kills the target, seems to be a pointless legacy check
	//if (UnitTarget.IsStasisLanced())
	//	return 'AA_UnitIsImmune';
	
	// No need to check that for Skulljack.
	//if (UnitTarget.IsTurret())
	//	return 'AA_UnitIsImmune';

	PossibleHackRewards = UnitTarget.GetHackRewards(FinalzeHackAbilityName);
	if (PossibleHackRewards.Length == 0)
		return 'AA_UnitIsImmune';

	// No idea what X2GoldenPathHacks does, but I'm not leaving a performance cost for everyone 
	// for the sake of one person who will use it in the future
	//CheatMan = `CHEATMGR;
	//if (CheatMan != None && CheatMan.bGoldenPathHacks)
	//{
	//	return 'AA_Success';
	//}

	CharacterTemplate = UnitTarget.GetMyTemplate();
	if (CharacterTemplate == None)
		return 'AA_NotAUnit';

	switch (CharacterTemplate.CharacterGroupName)
	{
		case 'AdventCaptain':

			XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
			if (XComHQ == None)
				return 'AA_UnitIsImmune';

			if (XComHQ.GetObjectiveStatus('T1_M2_S3_SKULLJACKCaptain') == eObjectiveState_InProgress ||
				XComHQ.GetObjectiveStatus('T1_M3_KillCodex') == eObjectiveState_InProgress )
			{
				return 'AA_Success';
			}
			return 'AA_UnitIsImmune';

		case 'Cyberus': // Codex Skulljack Fix by RealityMachina:: check character group name, not character template name, to allow targeting mod-added Codexes.

			XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
			if (XComHQ == None)
				return 'AA_UnitIsImmune';

			if( XComHQ.GetObjectiveStatus('T1_M5_SKULLJACKCodex') == eObjectiveState_InProgress ||
				XComHQ.GetObjectiveStatus('T1_M6_KillAvatar') == eObjectiveState_InProgress )
			{
				return 'AA_Success';
			}
			return 'AA_UnitIsImmune';

		default:
			return 'AA_UnitIsImmune';
	}
	return 'AA_UnitIsImmune';
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	local XComGameState_Unit UnitSource;
	local XComGameState_Unit UnitTarget;

	UnitTarget = XComGameState_Unit(kTarget);

	if (UnitTarget == none)
		return 'AA_NotAUnit';

	UnitSource = XComGameState_Unit(kSource);
	if (UnitSource == none)
		return 'AA_NotAUnit';

	// [WOTC] Skulljack Mind-Controlled Enemies by HotBlooded: allow skulljacking mindcontrolled units
	// Exact implementation is different; I check if the unit's original team is hostile to the source unit.
	if (!UnitSource.IsEnemyTeam(UnitTarget.GetPreviousTeam()))
		return 'AA_UnitIsFriendly';

	return 'AA_Success';
}
