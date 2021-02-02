#include <sourcemod>
#include <cstrike>
#include <ripext> 
#include <sdktools>
#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.00"

methodmap Bot < StringMap {
    public Bot() {
        return view_as<Bot>(new StringMap());
    }
    
    public void init(){
    	float vel[3];
    	float pos[3];
    	float view[3];
    	
    	this.SetValue("clientID", -1);
    	this.SetValue("playerID", -1);
    	this.SetArray("vel", vel, 3);
    	this.SetArray("pos", pos, 3);
    	this.SetArray("view", view, 3);
    	this.SetString("name", "Unknown");
    	this.SetValue("duck", 0);
    	this.SetValue("walk", 0);
    	this.SetValue("fFlags", 0);
    	this.SetValue("health", 100);
    	this.SetValue("armor", 100);
    	this.SetValue("helmet", 0);
    	this.SetValue("defuser", 0);
    }
    
    public void SetClientID(int clientID) {
        this.SetValue("clientID", clientID);
    }
    
    public int GetClientID() {
        int clientID;
        this.GetValue("clientID", clientID);
        return clientID;
    }    
    
    public void SetTick(JSONArray teams, int[] tbots_valid, int[] ctbots_valid){
    	int clientID;
    	int playerID;

    	this.GetValue("clientID", clientID);
    	this.GetValue("playerID", playerID);
    	
    	    	
    	if(clientID > 0){  
    		//1=Spec
			//2=Terrorist
			//3=CT
    		int teamID = GetClientTeam(clientID);
			if(teamID > 1){
		    	if(playerID == -1){
		    		for(int i=0;i<5;i++){
		    			if(teamID == 2 && tbots_valid[i] == 0){
		    				tbots_valid[i] = 1;
		    				playerID = i;
		    				this.SetValue("playerID", playerID);
		    				break;
		    			}
		    			if(teamID == 3 && ctbots_valid[i] == 0){
		    				ctbots_valid[i] = 1;
		    				playerID = i;
		    				this.SetValue("playerID", playerID);
		    				break;
		    			}
		    		}
		    	}
		    	
		    	if(teamID == 2){
		    		teamID = 1;
		    	} else if (teamID == 3){
		    		teamID = 0;
		    	}
				
				if(playerID != -1){
			    	JSONObject team = view_as<JSONObject>(teams.Get(teamID));
					JSONArray players = view_as<JSONArray>(team.Get("players"));
					JSONObject player = view_as<JSONObject>(players.Get(playerID));
			    	
			    	char name[32];
			    	player.GetString("name", name, 32);

					int fFlags = player.GetInt("fFlags");
					
					int health = player.GetInt("health");
					int armor = player.GetInt("armor");
					int helmet = player.GetInt("hasHelmet");
					int defuser = player.GetInt("hasDefuser");
					
			    	float vel[3];
			    	float pos[3];
			    	float view[3];

					JSONObject velJSON = view_as<JSONObject>(player.Get("vel"));
					
					vel[0] = velJSON.GetFloat("x");
					vel[1] = velJSON.GetFloat("y");
					vel[2] = velJSON.GetFloat("z");
					
					JSONObject posJSON = view_as<JSONObject>(player.Get("position"));
					
					pos[0] = posJSON.GetFloat("x");
					pos[1] = posJSON.GetFloat("y");
					pos[2] = posJSON.GetFloat("z");
				
					JSONObject viewJSON = view_as<JSONObject>(player.Get("view"));
				
					view[0] = viewJSON.GetFloat("pitch");
					view[1] = viewJSON.GetFloat("yaw");
				
					this.SetString("name", name);
					this.SetArray("vel",vel, 3);
					this.SetArray("pos",pos, 3);
					this.SetArray("view",view, 3);
					this.SetValue("fFlags", fFlags);
					this.SetValue("health", health);
					this.SetValue("armor", armor);
					this.SetValue("helmet", helmet);
					this.SetValue("defuser", defuser);
					
					delete viewJSON;
					delete velJSON; 
					delete posJSON;
					delete team;
					delete players; 
					delete player; 
				}
			}
		}
    }
    
    public void ApplyTick(){
    	int clientID;
    	float vel[3];
    	float pos[3];
    	float view[3];
    	char name[32];
    	char currName[32];
		int fFlags;
    	int health;
    	int armor;
    	int helmet;
    	int defuser;
    	
    	this.GetString("name", name, 32);
    	this.GetValue("clientID", clientID);
    	this.GetArray("vel", vel, 3);
    	this.GetArray("pos", pos, 3);
    	this.GetArray("view", view, 3);
    	this.GetValue("fFlags", fFlags);
    	this.GetValue("armor", armor);
    	this.GetValue("health", health);
    	this.GetValue("helmet", helmet);
    	this.GetValue("defuser", defuser);
    	if(clientID > 0){ 	
			GetClientName(clientID, currName, 32);	
			
			if(StrContains(currName,name) == -1){
				SetClientName(clientID, name);
			}
			
			if(health == 0 && IsPlayerAlive(clientID)){
				ForcePlayerSuicide(clientID);
			}
						
			int hasHelmet = 0;
			GetEntProp(clientID, Prop_Send, "m_bHasHelmet", hasHelmet);	
			
			if(helmet == 1 && hasHelmet == 0){
				FakeClientCommand(clientID, "give item_assaultsuit");
				PrintToServer("Give Helmet to Client %d", clientID);
			}
						
			SetEntityHealth(clientID, health);
			SetEntProp(clientID, Prop_Data, "m_ArmorValue", armor);
			//SetEntProp(clientID, Prop_Send, "m_bHasDefuser", defuser);
			//SetEntProp(clientID, Prop_Send, "m_bHasHelmet", helmet);
			SetEntProp(clientID, Prop_Data, "m_fFlags", fFlags);  			
			SetEntPropVector(clientID, Prop_Data, "m_vecVelocity", vel);
			SetEntPropVector(clientID, Prop_Data, "m_vecOrigin", pos);
			TeleportEntity(clientID, NULL_VECTOR, view, NULL_VECTOR);
		}
    }
}


HTTPClient httpClient; 
Bot bots[10];

int tbot_valid[5];
int ctbot_valid[5];

int tick = 10;
bool running = false;


public Plugin myinfo = 
{
	name = "DemoPlayback",
	author = "Logo",
	description = "Replays Demos",
	version = PLUGIN_VERSION,
	url = "logochris.de/demo"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// No need for the old GetGameFolderName setup.
	EngineVersion g_engineversion = GetEngineVersion();
	if (g_engineversion != Engine_CSGO)
	{
		SetFailState("This plugin was made for use with Counter-Strike: Global Offensive only.");
	}
} 

public void OnPluginStart()
{
	/**
	 * @note For the love of god, please stop using FCVAR_PLUGIN.
	 * Console.inc even explains this above the entry for the FCVAR_PLUGIN define.
	 * "No logic using this flag ever existed in a released game. It only ever appeared in the first hl2sdk."
	 */
	PrintToServer("Plugin Started");
	
	httpClient = new HTTPClient("http://logochris.de");
	CreateConVar("sm_dp_version", PLUGIN_VERSION, "Demoplayback plugin version ConVar. Please don't change me!", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegConsoleCmd("sm_dp_tick", SetTick, "Set Current Tick");
	RegConsoleCmd("sm_dp_run", ToggleRun, "Starts/Pauses the playback");
	RegConsoleCmd("sm_dp_init", SetupBots, "Initializes Bots");
	
	httpClient.Get("demo/10", OnNextTick); 	
	
	for(int i=0;i<10;i++){
		bots[i] = new Bot();
		bots[i].init();
	}
	
}



public Action ToggleRun(int client, int args){
	if(args < 1 || args > 1) {
		ReplyToCommand(client, "[SM] Usage: sm_dp_run 1/0");
		return Plugin_Handled;
	}
	
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	running = view_as<bool>(StringToInt(arg));
	
	return Plugin_Handled;
}

public Action SetTick(int client, int args){
	if(args < 1 || args > 1) {
		ReplyToCommand(client, "[SM] Usage: sm_dp_tick <int>");
		return Plugin_Handled;
	}
	
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	tick = StringToInt(arg);
	
	return Plugin_Handled;
}

public Action SetupBots(int client, int args){

	for (int i=1; i <= MaxClients; i++)
	{
	    if (IsClientInGame(i) && GetClientTeam(i) > 1 && IsFakeClient(i))
	    {	
	    	bool found = false;
	        for(int j=0;j<10;j++){
				int id = bots[j].GetClientID();
				if(id == -1){
					bots[j].SetClientID(i);
					PrintToServer("New Bot with clientID: %d added", i);
					found = true;
					break;
				}
			}
			if(!found){
				PrintToServer("No Bot for clientID: %d found", i);
			}
	    }
	}

	
	return Plugin_Handled;
}


void OnNextTick(HTTPResponse response, any value)
{        
    if (response.Status != HTTPStatus_OK) {
        PrintToServer("HTTP Failed");
        return;
    }

    // Indicate that the response is a JSON object
    JSONObject data = view_as<JSONObject>(response.Data);
	JSONArray teams = view_as<JSONArray>(data.Get("teams"));
	

	for(int i=0;i<10;i++){
		bots[i].SetTick(teams, tbot_valid, ctbot_valid);
	}
	
	
	delete data; 
	delete teams;
	
	tick += 1;
}

public void OnGameFrame() {

	if(running){
		GetNextTick();
		
		for(int i=0;i<10;i++){
			bots[i].ApplyTick();
		}
	}
	
}

void GetNextTick() {
	char getPath[100] = "demo/";
	char tickStr[95];
	IntToString(tick, tickStr, sizeof(tickStr));
	StrCat(getPath, sizeof(getPath), tickStr);
	
	httpClient.Get(getPath, OnNextTick);
	tick += 1;
}





