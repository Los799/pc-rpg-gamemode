/*******************************************************************************
* FILENAME :        modules/job/trucker.pwn
*
* DESCRIPTION :
*       Adds trucker job to the server.
*
* NOTES :
*       -
*
*       Copyright Paradise Devs 2015.  All rights reserved.
*
*/

#include <YSI\y_hooks>

//------------------------------------------------------------------------------

// Amount of XP multipled by job level to level up.
static const REQUIRED_XP = 90;

// Amount of XP multipled by job level the player will recieve for deliver.
static const XP_SCALE = 10;

// Job position
static const Float:JOB_POSITION[] = {2442.5039, -2110.0667, 13.5530};

// Load position
static const Float:LOAD_POSITION[] = {2434.1604, -2094.9910, 13.5469};

// Player Current CP
static gPlayerCurrentCP[MAX_PLAYERS];

// Player Selected Service
static gplSelectedService[MAX_PLAYERS];

// Tickcout to not spam truck cargo message
static gplTickCount[MAX_PLAYERS];
//------------------------------------------------------------------------------

static gTruckerServices[][][] =
{
    // Service        Payment Level isLegal
    {"Roupas",          500,   1,  1},
    {"Drogas",          750,   1,  0},
    {"Comida",          1250,   2,  1},
    {"Armas",           1500,   2,  0},
    {"Materiais",       3000,   3,  1},
    {"Animais",         3750,   3,  0},
    {"Combutível",      6000,  4,  1},
    {"Pessoas",         7500,  4,  0}
};

//------------------------------------------------------------------------------

static const Float:gTruckLocations[][][] =
{
    {
        {452.7070,  -1501.0168,     31.4884},
        {510.0989,   -1364.2018,    16.5673},
        {1458.8278,  -1157.4393,    24.2775},
        {2113.9033,  -1217.5211,    24.4115}
    },
    {
        {2345.9380,		-1497.9634,		24.4404},
        {483.49620,		-1532.0349,		20.1346},
        {2512.0964,		-1253.1033,		35.4902},
        {2646.6526,		-1593.3977,		13.8756}
    },
    {
        {1037.1023,		-1330.9777,		13.9965},
        {275.22420,		-1426.6449,		14.2896},
        {1499.5875,		-1588.8528,		13.9893},
        {787.69740,		-1620.6924,		13.9897}
    },
    {
        {2075.4602,		-1159.0679,		24.2988},
        {2306.4221,		-1194.6791,		25.4348},
        {2719.2214,		-1113.9396,		70.0175},
        {2837.2656,		-1181.8094,		25.1662}
    },
    {
        {826.6459,       857.97440,     11.9438},
        {-1880.4219,    -1719.7815,     21.4548},
        {2656.5735,     861.8781,       5.9623},
        {1901.8885,		-1337.3693,		13.9930}
    },
    {
        {-1977.9874,    518.3494,       32.1621},
        {-2664.2083,    224.8965,       3.9788},
        {2429.7324,     1133.0864,      10.3990},
        {920.7543,		-1353.4326,		13.8093}
    },
    {
        {-1602.8993,    -2709.5364,     48.2404},
        {-1320.9473,    2689.2898,      49.7681},
        {-2009.5188,    157.2660,       27.2661},
        {645.20210,		-562.6168,		16.7984}
    },
    {
        {-2600.8521,    -42.3441,       3.9068},
        {-2869.4487,    750.6318,       30.9712},
        {-2148.4202,    643.4442,       51.9927},
        {920.7543,		-1353.4326,		13.8093}
    }
};

//------------------------------------------------------------------------------

enum TRAILER_CARGO (+=1)
{
    TRAILER_CARGO_NONE,
    TRAILER_CARGO_CLOTHES = 1,
    TRAILER_CARGO_DRUGS,
    TRAILER_CARGO_FOOD,
    TRAILER_CARGO_GUNS,
    TRAILER_CARGO_MATERIALS,
    TRAILER_CARGO_ANIMALS,
    TRAILER_CARGO_FUEL,
    TRAILER_CARGO_PEOPLE
}
static TRAILER_CARGO:gTrailerCargo[MAX_PLAYERS];

//------------------------------------------------------------------------------

static gPlayerTruckID[MAX_PLAYERS] = {INVALID_VEHICLE_ID, ...};
static gPlayerTrailerID[MAX_PLAYERS] = {INVALID_VEHICLE_ID, ...};
static Text3D:gPlayer3DTextID[MAX_PLAYERS] = {Text3D:INVALID_3DTEXT_ID, ...};

//------------------------------------------------------------------------------

GetTrailerCargo(playerid)
{
    new cargo[32];
    switch(gTrailerCargo[playerid])
    {
        case TRAILER_CARGO_CLOTHES:
            cargo = "Roupas";
        case TRAILER_CARGO_DRUGS:
            cargo = "Drogas";
        case TRAILER_CARGO_FOOD:
            cargo = "Comida";
        case TRAILER_CARGO_GUNS:
            cargo = "Armas";
        case TRAILER_CARGO_MATERIALS:
            cargo = "Materiais";
        case TRAILER_CARGO_ANIMALS:
            cargo = "Animais";
        case TRAILER_CARGO_FUEL:
            cargo = "Combustível";
        case TRAILER_CARGO_PEOPLE:
            cargo = "Pessoas";
        default:
            cargo = "Nada";
    }
    return cargo;
}

//------------------------------------------------------------------------------

hook OnGameModeInit()
{
    CreateDynamicPickup(1210, 1, JOB_POSITION[0], JOB_POSITION[1], JOB_POSITION[2], 0, 0, -1, MAX_PICKUP_RANGE);
    CreateDynamic3DTextLabel("Caminhoneiro\nPressione {1add69}Y", 0xFFFFFFFF, JOB_POSITION[0], JOB_POSITION[1], JOB_POSITION[2], MAX_TEXT3D_RANGE, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1);

    CreateDynamicPickup(1239, 1, LOAD_POSITION[0], LOAD_POSITION[1], LOAD_POSITION[2], 0, 0, -1, MAX_PICKUP_RANGE);
    CreateDynamic3DTextLabel("Serviços\nPressione {1add69}Y", 0xFFFFFFFF, LOAD_POSITION[0], LOAD_POSITION[1], LOAD_POSITION[2], MAX_TEXT3D_RANGE, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1);
    return 1;
}

//------------------------------------------------------------------------------

hook OnPlayerDisconnect(playerid, reason)
{
    if(gPlayerTruckID[playerid] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(gPlayerTruckID[playerid]);
        DestroyVehicle(gPlayerTrailerID[playerid]);
        DestroyDynamic3DTextLabel(gPlayer3DTextID[playerid]);

        gPlayerTruckID[playerid] = INVALID_VEHICLE_ID;
        gPlayerTrailerID[playerid] = INVALID_VEHICLE_ID;
        gPlayer3DTextID[playerid] = Text3D:INVALID_3DTEXT_ID;

        gPlayerCurrentCP[playerid] = 0;
    }
    return 1;
}

//------------------------------------------------------------------------------

hook OnPlayerDeath(playerid, killerid, reason)
{
    if(gPlayerTruckID[playerid] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(gPlayerTruckID[playerid]);
        DestroyVehicle(gPlayerTrailerID[playerid]);
        DestroyDynamic3DTextLabel(gPlayer3DTextID[playerid]);

        gPlayerTruckID[playerid] = INVALID_VEHICLE_ID;
        gPlayerTrailerID[playerid] = INVALID_VEHICLE_ID;
        gPlayer3DTextID[playerid] = Text3D:INVALID_3DTEXT_ID;

        gPlayerCurrentCP[playerid] = 0;

        DisablePlayerRaceCheckpoint(playerid);
        SendClientMessage(playerid, COLOR_ERROR, "* Você não conseguiu completar o serviço.");
    }
    return 1;
}

//------------------------------------------------------------------------------

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case DIALOG_TRUCK_JOB:
        {
            if(!response)
                PlayCancelSound(playerid);
            else
            {
                if(GetPlayerJobID(playerid) != INVALID_JOB_ID)
                {
                    PlayErrorSound(playerid);
                    SendClientMessage(playerid, COLOR_ERROR, "* Você já possui um emprego.");
                }
                else
                {
                    SetPlayerJobID(playerid, TRUCKER_JOB_ID);
                    SendClientMessage(playerid, COLOR_SPECIAL, "* Agora você é um caminhoneiro!");
                    SendClientMessage(playerid, COLOR_SUB_TITLE, "* Vá até o ícone na entrada para escolher um serviço.");
                    PlayConfirmSound(playerid);
                }
            }
        }
        case DIALOG_TRUCKER_SERVICES:
        {
            if(!response)
                PlayCancelSound(playerid);
            else
            {
                if(!response)
                    PlayCancelSound(playerid);
                else if(GetPlayerJobLV(playerid) < gTruckerServices[listitem][2][0])
                {
                    SendClientMessage(playerid, COLOR_ERROR, "* Você não tem nível de emprego suficiente para este serviço.");
                    PlayErrorSound(playerid);
                }
                else
                {
                    SendClientMessage(playerid, COLOR_SPECIAL, "* Vá entregar a mercadoria no local indicado.");

                    if(!gTruckerServices[listitem][3][0])
                        SendClientMessage(playerid, COLOR_SUB_TITLE, "* Você está carregando uma carga ilegal, cuidado com a polícia.");
                    else
                        SendClientMessage(playerid, COLOR_SUB_TITLE, "* Cuidado com a mercadoria.");

                    gplSelectedService[playerid] = listitem;
                    gTrailerCargo[playerid] = TRAILER_CARGO:(listitem+1);
                    gPlayerTruckID[playerid] = CreateVehicle(515, 2444.2415, -2091.3992, 14.5237, 89.4204, -1, -1, -1);
                    gPlayerTrailerID[playerid] = CreateVehicle(591, 2453.3735, -2091.9829, 14.2064, 84.7415, -1, -1, -1);
                    gPlayer3DTextID[playerid] = CreateDynamic3DTextLabel("Pressione {1add69}Y\n{ffffff}Para ver a carga", 0xFFFFFFFF, 0.0, 0.0, 0.0, MAX_TEXT3D_RANGE, INVALID_PLAYER_ID, gPlayerTrailerID[playerid], 1, 0, 0);
                    AttachTrailerToVehicle(gPlayerTrailerID[playerid], gPlayerTruckID[playerid]);
                    PutPlayerInVehicle(playerid, gPlayerTruckID[playerid], 0);
                    SetVehicleFuel(gPlayerTruckID[playerid], 100.0);

                    TogglePlayerControllable(playerid, false);
                    defer UnfreezePlayer(playerid);
                    GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~n~~n~~n~~w~carregando...", 5000, 3);

                    new rand = random(sizeof(gTruckLocations[]));
                    SetPlayerRaceCheckpoint(playerid, 0, gTruckLocations[listitem][rand][0], gTruckLocations[listitem][rand][1], gTruckLocations[listitem][rand][2], 2509.3311, -2089.5120, 14.1535, 10.0);
                    SetPlayerCPID(playerid, CHECKPOINT_TRUCKER);
                }
            }
        }
    }
    return 1;
}

//------------------------------------------------------------------------------

hook OnPlayerEnterRaceCPT(playerid)
{
    if(GetPlayerCPID(playerid) != CHECKPOINT_TRUCKER)
        return 1;

    if(!IsPlayerInVehicle(playerid, gPlayerTruckID[playerid]))
        return SendClientMessage(playerid, COLOR_ERROR, "* Você não está no caminhão do serviço.");
    else if(GetVehicleTrailer(gPlayerTruckID[playerid]) != gPlayerTrailerID[playerid])
        return SendClientMessage(playerid, COLOR_ERROR, "* Você não está com o trailer que você carregou.");

    switch(gPlayerCurrentCP[playerid])
    {
        case 0:
        {
            PlaySelectSound(playerid);
            gTrailerCargo[playerid] = TRAILER_CARGO_NONE;
            SendClientMessage(playerid, COLOR_SPECIAL, "* Entrega completa!");
            SendClientMessage(playerid, COLOR_SUB_TITLE, "* Volte com o caminhão para a empresa para receber o pagamento.");

            TogglePlayerControllable(playerid, false);
            defer UnfreezePlayer(playerid);
            GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~n~~n~~n~~w~descarregando...", 5000, 3);

            SetPlayerRaceCheckpoint(playerid, 1, 2509.3311, -2089.5120, 14.1535, 0.0, 0.0, 0.0, 10.0);
            gPlayerCurrentCP[playerid]++;
        }
        case 1:
        {
            PlayConfirmSound(playerid);
            SendClientMessage(playerid, COLOR_SPECIAL, "* Serviço completo!");
            SendClientMessagef(playerid, COLOR_SUB_TITLE, "* Você recebeu $%s de pagamento.", formatnumber(gTruckerServices[gplSelectedService[playerid]][1][0]));
            GivePlayerCash(playerid, gTruckerServices[gplSelectedService[playerid]][1][0]);

            DestroyVehicle(gPlayerTruckID[playerid]);
            DestroyVehicle(gPlayerTrailerID[playerid]);
            DestroyDynamic3DTextLabel(gPlayer3DTextID[playerid]);

            gPlayerTruckID[playerid] = INVALID_VEHICLE_ID;
            gPlayerTrailerID[playerid] = INVALID_VEHICLE_ID;
            gPlayer3DTextID[playerid] = Text3D:INVALID_3DTEXT_ID;

            gPlayerCurrentCP[playerid] = 0;

            DisablePlayerRaceCheckpoint(playerid);
            SetPlayerCPID(playerid, CHECKPOINT_NONE);

            SetPlayerXP(playerid, GetPlayerXP(playerid) + 2);
            SetPlayerJobXP(playerid, GetPlayerJobXP(playerid) + (GetPlayerJobLV(playerid) * XP_SCALE));
            if(GetPlayerJobXP(playerid) > (GetPlayerJobLV(playerid) * REQUIRED_XP))
            {
                SetPlayerJobXP(playerid, 0);
                SetPlayerJobLV(playerid, GetPlayerJobLV(playerid) + 1);
            }
        }
    }
    return 1;
}

//------------------------------------------------------------------------------

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if((newkeys == KEY_YES) && IsPlayerInRangeOfPoint(playerid, 1.5, JOB_POSITION[0], JOB_POSITION[1], JOB_POSITION[2]))
    {
        if(GetPlayerLevel(playerid) < 2)
        {
            SendClientMessage(playerid, COLOR_ERROR, "* Você precisa ser nível 2.");
        }
        else
        {
            PlaySelectSound(playerid);
            ShowPlayerDialog(playerid, DIALOG_TRUCK_JOB, DIALOG_STYLE_MSGBOX, "Emprego: Caminhoneiro", "Você deseja se tornar um caminhoneiro?", "Sim", "Não");
        }
        return 1;
    }
    else if((newkeys == KEY_YES) && IsPlayerInRangeOfPoint(playerid, 1.5, LOAD_POSITION[0], LOAD_POSITION[1], LOAD_POSITION[2]))
    {
        if(GetPlayerJobID(playerid) != TRUCKER_JOB_ID)
            return SendClientMessage(playerid, COLOR_ERROR, "* Você não é um caminhoneiro.");
        else if(gPlayerTruckID[playerid] != INVALID_VEHICLE_ID)
            return SendClientMessage(playerid, COLOR_ERROR, "* Você já está em um serviço.");

        PlaySelectSound(playerid);
        new info[300], buffer[60], sIsLegal[4];
        strcat(info, "Serviço\tPagamento\tNível\tLegal");
        for(new i = 0; i < sizeof(gTruckerServices); i++)
        {
            if(gTruckerServices[i][3][0]) format(sIsLegal, sizeof(sIsLegal), "Sim");
            else format(sIsLegal, sizeof(sIsLegal), "Não");
            format(buffer, sizeof(buffer), "\n%s\t$%s\t%i\t%s", gTruckerServices[i][0], formatnumber(gTruckerServices[i][1][0]), gTruckerServices[i][2][0], sIsLegal);
            strcat(info, buffer);
        }
        ShowPlayerDialog(playerid, DIALOG_TRUCKER_SERVICES,  DIALOG_STYLE_TABLIST_HEADERS, "Caminhoneiro -> Serviços", info, "Aceitar", "Recusar");
    }
    else if(newkeys == KEY_YES)
    {
        if(IsPlayerInAnyVehicle(playerid) || gplTickCount[playerid] > GetTickCount())
            return 1;

        new Float:x, Float:y, Float:z;
        foreach(new i: Player)
        {
            if(gPlayerTrailerID[i] == INVALID_VEHICLE_ID)
                continue;

            GetVehiclePos(gPlayerTrailerID[i], x, y, z);
            if(IsPlayerInRangeOfPoint(playerid, 7.5, x, y, z))
            {
                new Float:vx, Float:vy, Float:vz;
                GetVehicleVelocity(gPlayerTrailerID[i], vx, vy, vz);
                if(vx > 0.5 || vy > 0.5 || vz > 0.5)
                    SendClientMessage(playerid, COLOR_ERROR, "* O veículo precisa estar parado para ver a carga.");
                else
                {
                    SendClientMessagef(playerid, COLOR_TITLE, "~~~~~~~~~~~~~~~~~~ Carga do caminhão de %s ~~~~~~~~~~~~~~~~~~", GetPlayerNamef(i));
                    SendClientMessagef(playerid, COLOR_SUB_TITLE, "* O caminhão está carregado com: %s.", GetTrailerCargo(i));
                }
                gplTickCount[playerid] = GetTickCount() + 2500;
                break;
            }
        }
    }
    return 1;
}

//------------------------------------------------------------------------------
