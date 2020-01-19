/*
 * MyStore - Bullet impact item module
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

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#include <mystore> //https://raw.githubusercontent.com/shanapu/MyStore/master/scripting/include/mystore.inc

#include <colors> //https://raw.githubusercontent.com/shanapu/MyStore/master/scripting/include/colors.inc
#include <smartdm> //https://forums.alliedmods.net/attachment.php?attachmentid=136152&d=1406298576

#pragma semicolon 1
#pragma newdecls required

bool g_bEquipt[MAXPLAYERS + 1] = false;

char g_sPaintballDecals[STORE_MAX_ITEMS][32][PLATFORM_MAX_PATH];

ConVar gc_bEnable;

int g_iPaintballDecalIDs[STORE_MAX_ITEMS][32];
int g_iPaintballDecals[STORE_MAX_ITEMS] = {0, ...};
int g_iCount = 0;

bool g_bHide[MAXPLAYERS + 1];
Handle g_hHideCookie = INVALID_HANDLE;

char g_sChatPrefix[128];

/*
 * Build date: <DATE>
 * Build number: <BUILD>
 * Commit: https://github.com/shanapu/MyStore/commit/<COMMIT>
 */

public Plugin myinfo = 
{
	name = "MyStore - Bullet impact item module",
	author = "shanapu", // If you should change the code, even for your private use, please PLEASE add your name to the author here
	description = "",
	version = "0.1.<BUILD>", // If you should change the code, even for your private use, please PLEASE make a mark here at the version number
	url = "github.com/shanapu/MyStore"
};

public void OnPluginStart()
{
	if (MyStore_RegisterHandler("paintball", Paintball_OnMapStart, Paintball_Reset, Paintball_Config, Paintball_Equip, Paintball_Remove, true) == -1)
	{
		SetFailState("Can't Register module to core - Reached max module types(%i).", STORE_MAX_TYPES);
	}

	RegConsoleCmd("sm_hidepaintball", Command_Hide, "Hide the Paintball");

	HookEvent("bullet_impact", Event_BulletImpact);

	g_hHideCookie = RegClientCookie("Paintball_Hide_Cookie", "Cookie to check if Paintball are blocked", CookieAccess_Private);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!AreClientCookiesCached(i))
			continue;

		OnClientCookiesCached(i);
	}
}

public void OnClientCookiesCached(int client)
{
	char sValue[8];
	GetClientCookie(client, g_hHideCookie, sValue, sizeof(sValue));

	g_bHide[client] = (sValue[0] && StringToInt(sValue));
}

public Action Command_Hide(int client, int args)
{
	g_bHide[client] = !g_bHide[client];
	if (g_bHide[client])
	{
		CPrintToChat(client, "%s%t", g_sChatPrefix, "Item hidden", "paintball");
		SetClientCookie(client, g_hHideCookie, "1");
	}
	else
	{
		CPrintToChat(client, "%s%t", g_sChatPrefix, "Item visible", "paintball");
		SetClientCookie(client, g_hHideCookie, "0");
	}

	return Plugin_Handled;
}

public void MyStore_OnConfigExecuted(ConVar enable, char[] name, char[] prefix, char[] credits)
{
	gc_bEnable = enable;
	strcopy(g_sChatPrefix, sizeof(g_sChatPrefix), prefix);
}

public void Paintball_OnMapStart()
{
	char sBuffer[PLATFORM_MAX_PATH];
	for (int a = 0; a < g_iCount; a++)
	{
		for (int i = 0; i < g_iPaintballDecals[a]; i++)
		{
			g_iPaintballDecalIDs[a][i] = PrecacheDecal(g_sPaintballDecals[a][i], true);
			Format(sBuffer, sizeof(sBuffer), "materials/%s", g_sPaintballDecals[a][i]);
			Downloader_AddFileToDownloadsTable(sBuffer);
		}
	}
}

public void Paintball_Reset()
{
	for (int i = 0; i < g_iCount; i++)
	{
		g_iPaintballDecals[i] = 0;
	}

	g_iCount = 0;
}

public bool Paintball_Config(KeyValues &kv, int itemid)
{
	MyStore_SetDataIndex(itemid, g_iCount);

	kv.JumpToKey("Decals");
	kv.GotoFirstSubKey();

	do
	{
		kv.GetString("material", g_sPaintballDecals[g_iCount][g_iPaintballDecals[g_iCount]], PLATFORM_MAX_PATH);
		g_iPaintballDecals[g_iCount]++;
	}
	while kv.GotoNextKey();

	kv.GoBack();
	kv.GoBack();

	g_iCount++;

	return true;
}

public int Paintball_Equip(int client, int itemid)
{
	g_bEquipt[client] = true;

	return ITEM_EQUIP_SUCCESS;
}

public int Paintball_Remove(int client, int itemid)
{
	g_bEquipt[client] = false;

	return ITEM_EQUIP_REMOVE;
}

public void OnClientDisconnect(int client)
{
	g_bEquipt[client] = false;
}

public void Event_BulletImpact(Event event, const char[] name, bool dontBroadcast)
{
	if (!gc_bEnable.BoolValue)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!g_bEquipt[client])
		return;

	int[] clients = new int[MaxClients + 1];
	int numClients = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if (g_bHide[i])
			continue;

		clients[numClients] = i;
		numClients++;
	}

	if (numClients < 1)
		return;

	int iIndex = MyStore_GetDataIndex(MyStore_GetEquippedItem(client, "paintball", 0));

	float fImpact[3];
	fImpact[0] = event.GetFloat("x");
	fImpact[1] = event.GetFloat("y");
	fImpact[2] = event.GetFloat("z");

	TE_Start("World Decal");
	TE_WriteVector("m_vecOrigin", fImpact);
	TE_WriteNum("m_nIndex", g_iPaintballDecalIDs[iIndex][GetRandomInt(0, g_iPaintballDecals[iIndex]-1)]);

	TE_Send(clients, numClients, 0.0);
}