//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_WOTCCoreCollection.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_WOTCCoreCollection extends X2DownloadableContentInfo;

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{}

static event OnPostTemplatesCreated()
{
	PatchOverwatchAllMod();	
}

static function PatchOverwatchAllMod()
{
	local X2AbilityTemplate				Template;
    local X2AbilityTemplateManager		AbilityTemplateManager;
	local X2AbilityCost					AbilityCost;
	local X2AbilityCost_ActionPoints	ActionCost;

    AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

    Template = AbilityTemplateManager.FindAbilityTemplate('OverwatchOthers');
    if (Template != none)
    {
		foreach Template.AbilityCosts(AbilityCost)
		{
			ActionCost = X2AbilityCost_ActionPoints(AbilityCost);
			if (ActionCost != none && ActionCost.bFreeCost && ActionCost.bConsumeAllPoints)
			{
				ActionCost.iNumPoints = 1;
			}
		}
    }
	Template = AbilityTemplateManager.FindAbilityTemplate('OverwatchAll');
    if (Template != none)
    {
		foreach Template.AbilityCosts(AbilityCost)
		{
			ActionCost = X2AbilityCost_ActionPoints(AbilityCost);
			if (ActionCost != none && ActionCost.bFreeCost && ActionCost.bConsumeAllPoints)
			{
				ActionCost.iNumPoints = 1;
			}
		}
    }
}