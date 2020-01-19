/*
 * MyStore - Info panel item module
 * by: shanapu
 * https://github.com/shanapu/
 * 
 * Copyright (C) 2018-2019 Thomas Schmidt (shanapu)
 * Credits:
 * Contributer:
 *
 * Original development by Zephyrus - https://github.com/dvarnai/store-plugin
 *
 * Love goes out to the sourcemod team and all other plugin developers!
 * THANKS FOR MAKING FREE SOFTWARE!
 *
 * This file is part of the MyStore SourceMod Plugin.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#include <mystore> //https://raw.githubusercontent.com/shanapu/MyStore/master/scripting/include/mystore.inc

char g_sInfoTitle[STORE_MAX_ITEMS][256];
char g_sInfo[STORE_MAX_ITEMS][256];

int g_iCount = 0;

/*
 * Build date: <DATE>
 * Build number: <BUILD>
 * Commit: https://github.com/shanapu/MyStore/commit/<COMMIT>
 */

public Plugin myinfo = 
{
	name = "MyStore - Info panel item module",
	author = "shanapu", // If you should change the code, even for your private use, please PLEASE add your name to the author here
	description = "",
	version = "0.1.<BUILD>", // If you should change the code, even for your private use, please PLEASE make a mark here at the version number
	url = "github.com/shanapu/MyStore"
};

public void OnPluginStart()
{
	if (MyStore_RegisterHandler("info", _, Info_Reset, Info_Config, Info_Equip, _, false, true) == -1)
	{
		SetFailState("Can't Register module to core - Reached max module types(%i).", STORE_MAX_TYPES);
	}

	LoadTranslations("mystore.phrases");
}

public void Info_Reset()
{
	g_iCount = 0;
}

public bool Info_Config(KeyValues &kv, int itemid)
{
	MyStore_SetDataIndex(itemid, g_iCount);

	kv.GetSectionName(g_sInfoTitle[g_iCount], sizeof(g_sInfoTitle[]));
	kv.GetString("text", g_sInfo[g_iCount], sizeof(g_sInfo[]));

	ReplaceString(g_sInfo[g_iCount], sizeof(g_sInfo[]), "\\n", "\n");

	g_iCount++;

	return true;
}

public void Info_Equip(int client, int itemid)
{
	int iIndex = MyStore_GetDataIndex(itemid);

	Panel panel = new Panel();
	panel.SetTitle(g_sInfoTitle[iIndex]);

	panel.DrawText(g_sInfo[iIndex]);

	char sBuffer[64];
	Format(sBuffer, sizeof(sBuffer), "%t", "Back");
	panel.CurrentKey = 7;
	panel.DrawItem(sBuffer, ITEMDRAW_DEFAULT);
	panel.DrawItem("", ITEMDRAW_SPACER);
	Format(sBuffer, sizeof(sBuffer), "%t", "Exit");
	panel.CurrentKey = 9;
	panel.DrawItem(sBuffer, ITEMDRAW_DEFAULT);

	panel.Send(client, PanelHandler_Info, MENU_TIME_FOREVER);
}

public int PanelHandler_Info(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 7)
		{
			MyStore_DisplayPreviousMenu(client);
		}
	}
}