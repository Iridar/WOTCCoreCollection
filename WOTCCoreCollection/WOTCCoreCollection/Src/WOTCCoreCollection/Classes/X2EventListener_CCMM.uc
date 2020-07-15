class X2EventListener_CCMM extends X2EventListener config(CoreCollection);

//	Start Issue #2
struct YAF1_AutopsyRequirementStruct
{
	var name		AutopsyName;
	var array<name> CharacterTemplates;
};
var config array<YAF1_AutopsyRequirementStruct> YAF1_AutopsyRequirement;
//	End Issue #2

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	//	Issue #2
	Templates.AddItem(Create_YAF1_Autopsy());

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

//	Start Issue #2
static function CHEventListenerTemplate Create_YAF1_Autopsy()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'X2EventListener_CCMM_YAF1_Autopsy');

	Template.RegisterInTactical = true;
	Template.RegisterInStrategy = false;

	Template.AddCHEvent('YAF1_OverrideShowInfo', YAF1_Autopsy_ListenerEventFunction, ELD_Immediate);

	return Template;
}
static function EventListenerReturn YAF1_Autopsy_ListenerEventFunction(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local LWTuple							Tuple;
	local XComGameState_HeadquartersXCom	XComHQ;
	local int								Index;
	local XComGameState_Unit				TargetUnit;
	local YAF1_AutopsyRequirementStruct		AutopsyStruct;
	local name								CharacterTemplateName;

	Tuple = LWTuple(EventData);

	if (Tuple == none)
		return ELR_NoInterrupt;
		
	TargetUnit = XComGameState_Unit(Tuple.Data[0].o);
	if (TargetUnit == none)
		return ELR_NoInterrupt;

	if (TargetUnit.IsFriendlyToLocalPlayer())
		return ELR_NoInterrupt;
	
	CharacterTemplateName = TargetUnit.GetMyTemplateName();
	foreach default.YAF1_AutopsyRequirement(AutopsyStruct)
	{
		if (AutopsyStruct.CharacterTemplates.Find(CharacterTemplateName) != INDEX_NONE)
		{
			XComHQ = `XCOMHQ;
			if (!XComHQ.IsTechResearched(AutopsyStruct.AutopsyName))
			{
				Tuple.Data[1].b = false;
			}
			break;
		}
	}

	return ELR_NoInterrupt;
}
//	End Issue #2