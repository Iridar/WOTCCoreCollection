class X2EventListener_CoreCollection extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(TacticalListeners());

	return Templates;
}

/*
'AbilityActivated', AbilityState, SourceUnitState, NewGameState
'PlayerTurnBegun', PlayerState, PlayerState, NewGameState
'PlayerTurnEnded', PlayerState, PlayerState, NewGameState
'UnitDied', UnitState, UnitState, NewGameState
'KillMail', UnitState, Killer, NewGameState
'UnitTakeEffectDamage', UnitState, UnitState, NewGameState
'OnUnitBeginPlay', UnitState, UnitState, NewGameState
'OnTacticalBeginPlay', X2TacticalGameRuleset, none, NewGameState
*/

static function CHEventListenerTemplate TacticalListeners()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'IRI_X2EventListener_CoreCollection_Tactical');

	Template.RegisterInTactical = true;
	Template.RegisterInStrategy = false;

	Template.AddCHEvent('EvacZoneDestroyed', OnEvacZoneDestroyed, ELD_OnStateSubmitted, 90); // Issue #19

	return Template;
}

// Issue #19 - remove the Evac State if the Evac Zone was destroyed.
static private function EventListenerReturn OnEvacZoneDestroyed(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_EvacZone EvacState;
	local XComGameState NewGameState;

	EvacState = XComGameState_EvacZone(EventData);
	if (EvacState != none)
	{
		`LOG("Evac Zone destroyed, removing Evac Zone state object.",, 'CCMM');
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Remove Evac State for destroyed Evac Zone");
		NewGameState.RemoveStateObject(EvacState.ObjectID);
		`GAMERULES.SubmitGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}
