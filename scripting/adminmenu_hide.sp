#pragma semicolon 1
#pragma newdecls required
#include <sdkhooks>
#include <sdktools>
#include <csgo_colors>
#include <adminmenu>

bool g_bVisible[MAXPLAYERS + 1] = true;
int g_iIsConnectedOffset = -1;

TopMenu g_hAdminMenu = null;

public Plugin myinfo =
{
	name = "[AdminMenu] Hide",
	author = "1mpulse (Discord -> 1mpulse#6496)",
	version = "1.0.0",
	url = "http://plugins.thebestcsgo.ru"
};

public void OnPluginStart()
{
	TopMenu hTopMenu;
	if((hTopMenu = GetAdminTopMenu()) != null) OnAdminMenuReady(hTopMenu);
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu hTopMenu = TopMenu.FromHandle(aTopMenu);
	if (hTopMenu == g_hAdminMenu) return;
	g_hAdminMenu = hTopMenu;
	TopMenuObject hMyCategory = g_hAdminMenu.FindCategory("PlayerCommands");
	if(hMyCategory != INVALID_TOPMENUOBJECT) g_hAdminMenu.AddItem("sm_hide_item", MenuCallBack1, hMyCategory, "sm_hide_menu", ADMFLAG_ROOT, "Скрыть игрока");
}

public void MenuCallBack1(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, maxlength, "Скрыть игрока");
		case TopMenuAction_SelectOption: MainMenu(iClient);
	}
}

public void OnMapStart() 
{
	g_iIsConnectedOffset = FindSendPropInfo("CCSPlayerResource", "m_bConnected");
	if(g_iIsConnectedOffset == -1) SetFailState("CCSPlayerResource.m_bConnected offset is invalid");
	int CSPlayerManager = FindEntityByClassname(-1, "cs_player_manager");
	if(CSPlayerManager > 0) SDKHook(CSPlayerManager, SDKHook_ThinkPost, OnThinkPost);
} 

public void OnThinkPost(int entity) 
{
	int isConnected[MAXPLAYERS+1];
	GetEntDataArray(entity, g_iIsConnectedOffset, isConnected, sizeof(isConnected));
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && !IsFakeClient(i)) isConnected[i] = g_bVisible[i];
	}
	SetEntDataArray(entity, g_iIsConnectedOffset, isConnected, sizeof(isConnected));
}
public void OnClientPostAdminCheck(int iClient) { if(IsClientInGame(iClient) && !IsFakeClient(iClient)) g_bVisible[iClient] = true; }
public void OnClientDisconnect(int iClient) { if(IsClientInGame(iClient) && !IsFakeClient(iClient)) g_bVisible[iClient] = true; }
stock void MainMenu(int iClient)
{
	Menu hMenu = new Menu(MainMenu_Callback);
	hMenu.SetTitle("Выберите Игрока:\n[] - Видим\n[✔] - Скрыт");
	hMenu.ExitBackButton = true;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			char szBuffer[70], userid[15], sName[64];
			IntToString(GetClientUserId(i), userid, sizeof(userid));
			GetClientName(i, sName, sizeof(sName));
			if(g_bVisible[i]) FormatEx(szBuffer, sizeof(szBuffer), "%s []", sName);
			else FormatEx(szBuffer, sizeof(szBuffer), "%s [✔]", sName);
			hMenu.AddItem(userid, szBuffer);
		}
	}
	hMenu.Display(iClient, 0);
}

public int MainMenu_Callback(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
        {
            if(iItem == MenuCancel_ExitBack) g_hAdminMenu.Display(iClient, TopMenuPosition_LastCategory);	
        }
		case MenuAction_Select:
		{
			int u, target;
			char userid[15];
			hMenu.GetItem(iItem, userid, sizeof(userid));
			u = StringToInt(userid);
			target = GetClientOfUserId(u);
			if(target)
			{
				if(g_bVisible[target])
				{
					g_bVisible[target] = false;
					CGOPrintToChat(iClient, " {BLUE}[{LIGHTRED}AdminMenu HIDE{BLUE}]{DEFAULT} Вы скрыли игрока {GRAY}%N {DEFAULT}в таблице(TAB).", target);
				}
				else
				{
					g_bVisible[target] = true;
					CGOPrintToChat(iClient, " {BLUE}[{LIGHTRED}AdminMenu HIDE{BLUE}]{DEFAULT} Вы сделали игрока {GRAY}%N {DEFAULT}видимым в таблице(TAB).", target);
				}
				MainMenu(iClient);
			}
		}
	}
}