class X2Effect_ApplyMedikitChargeCost extends X2Effect;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit	TargetUnit;
	local StateObjectReference	AbilityRef;
	local XComGameState_Ability AbilityState;
	local XComGameStateHistory	History;
	local X2AbilityTemplate		AbilityTemplate;
	local X2AbilityCost			AbilityCost;
	local XComGameState_Item	ItemState;

	local XComGameStateContext_Ability AbilityContext;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	if (TargetUnit == none)
		return;

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
	if (AbilityState == none)
		return;

	AbilityTemplate = AbilityState.GetMyTemplate();
	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());

	if (AbilityState.SourceWeapon.ObjectID != 0)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(AbilityState.SourceWeapon.ObjectID));
		if (ItemState != none)
		{
			ItemState = XComGameState_Item(NewGameState.ModifyStateObject(ItemState.Class, ItemState.ObjectID));
		}
	}

	foreach AbilityTemplate.AbilityCosts(AbilityCost)
	{
		if (AbilityCost.IsA('X2AbilityCost_ActionPoints'))
			continue;

		if (AbilityCost.IsA('X2AbilityCost_ReserveActionPoints'))
			continue;
		
		AbilityCost.ApplyCost(AbilityContext, AbilityState, TargetUnit, ItemState, NewGameState);
	}
}
	