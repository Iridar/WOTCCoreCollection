class X2Condition_TargetHasMedikit extends X2Condition;

// Issue #15 - used to replace the original X2Condition_StabilizeMedkitOwner condition, which has a log of log spam.
// Also it looks for any ability that can remove bleeding effect rather than for Stabilize by name, which is weird and unnecessary.

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{ 
	local XComGameState_Unit	TargetUnit;
	local StateObjectReference	AbilityRef;
	local XComGameState_Ability AbilityState;
	local XComGameStateHistory	History;

	TargetUnit = XComGameState_Unit(kTarget);
	if (TargetUnit == none)
		return 'AA_NotAUnit';

	History = `XCOMHISTORY;

	AbilityRef = TargetUnit.FindAbility('GremlinStabilize');
	if (AbilityRef.ObjectID != 0)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
	}
	if (AbilityState == none)
	{
		AbilityRef = TargetUnit.FindAbility('MedikitStabilize');
		if (AbilityRef.ObjectID != 0)
		{
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
		}
	}

	if (AbilityState != none)
	{
		if (AbilityState.GetCharges() > 0)
		{
			return 'AA_Success';
		}
		else
		{
			return 'AA_CannotAfford_Charges';
		}
	}

	return 'AA_AbilityUnavailable';
}
