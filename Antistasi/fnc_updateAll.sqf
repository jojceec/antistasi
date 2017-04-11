#include "macros.hpp"
private _AAFnewMoney = 0;
private _FIAnewMoney = 25;
private _FIAnewHR = 0;

private _FIAtotalPop = 0;
private _AAFtotalPop = 0;
private _AAFResIncomeMultiplier = 1;
private _FIAResIncomeMultiplier = 1;

// forEach city, add to HR and money
{
    _city = _x;
    private _incomeAAF = 0;
    private _incomeFIA = 0;
    private _HRincomeFIA = 0;

    private _data = [_city, ["population", "prestigeBLUFOR", "prestigeOPFOR"]] call AS_fnc_getCityAttrs;
    private _population = _data select 0;
    private _prestigeFIA = _data select 1;
    private _prestigeAAF = _data select 2;

    private _power = [_city] call powerCheck;

    private _popFIA = (_population * (_prestigeFIA / 100));
    private _popAAF = (_population * (_prestigeAAF / 100));
    _FIAtotalPop = _FIAtotalPop + _popFIA;
    _AAFtotalPop = _AAFtotalPop + _popAAF;

    if !(_city in destroyedCities) then {
        _incomeMultiplier = 0.33;
        if (not _power) then {_incomeMultiplier = 0.5*0.33};

        _incomeAAF = _incomeMultiplier*_popAAF;
        _incomeFIA = _incomeMultiplier*_popFIA;
        _HRincomeFIA = (_population * (_prestigeFIA / 20000));

        if (_city in mrkFIA) then {
            _incomeAAF = _incomeAAF/2;
            if (_power) then {
                if (_prestigeFIA + _prestigeAAF + 1 <= 100) then {[0,1,_city] spawn citySupportChange};
            }
            else {
                if (_prestigeFIA > 6) then {
                    [0,-1,_city] spawn citySupportChange;
                } else {
                    [1,0,_city] spawn citySupportChange;
                };
            };
        } else {
            _incomeFIA = (_incomeFIA/2);
            _HRincomeFIA = (_HRincomeFIA/2);
            if (_power) then {
                if (_prestigeAAF + _prestigeFIA + 1 <= 100) then {[1,0,_city] call citySupportChange};
            }
            else {
                if (_prestigeAAF > 6) then {
                    [-1,0,_city] spawn citySupportChange;
                } else {
                    [0,1,_city] spawn citySupportChange;
                };
            };
        };
    };

    _AAFnewMoney = _AAFnewMoney + _incomeAAF;
    _FIAnewMoney = _FIAnewMoney + _incomeFIA;
    _FIAnewHR = _FIAnewHR + _HRincomeFIA;

    // flip cities due to majority change.
    if ((_prestigeAAF < _prestigeFIA) and (_city in mrkAAF)) then {
        [["TaskSucceeded", ["", format ["%1 joined FIA",[_city, false] call AS_fnc_getLocationName]]],"BIS_fnc_showNotification"] call BIS_fnc_MP;
        mrkAAF = mrkAAF - [_city];
        mrkFIA = mrkFIA + [_city];
        if (hayBE) then {["con_cit"] remoteExec ["fnc_BE_XP", 2]};
        publicVariable "mrkAAF";
        publicVariable "mrkFIA";
        [0,5] remoteExec ["prestige",2];
        _mrkD = format ["Dum%1",_city];
        _mrkD setMarkerColor "colorBLUFOR";
        [_city, !_power] spawn apagon;
        sleep 5;
        {[_city,_x] spawn deleteControles} forEach controles;

        if (!("CONVOY" in misiones)) then {
            _base = [_city] call findBasesForConvoy;
            if ((_base != "") and (random 3 < 1)) then {
                [_city,_base,"city"] remoteExec ["CONVOY",HCattack];
            };
        };
    };
    if ((_prestigeAAF > _prestigeFIA) and (_city in mrkFIA)) then {
        [["TaskFailed", ["", format ["%1 joined AAF",[_city, false] call AS_fnc_getLocationName]]],"BIS_fnc_showNotification"] call BIS_fnc_MP;
        mrkAAF = mrkAAF + [_city];
        mrkFIA = mrkFIA - [_city];
        publicVariable "mrkAAF";
        publicVariable "mrkFIA";
        [0,-5] remoteExec ["prestige",2];
        _mrkD = format ["Dum%1",_city];
        _mrkD setMarkerColor "colorGUER";
        sleep 5;
        [_city, !_power] spawn apagon;
    };
} forEach ciudades;

// control the airport and have majority => win game.
if ((_FIAtotalPop > _AAFtotalPop) and ("airport_3" in mrkFIA)) exitWith {["end1",true,true,true,true] remoteExec ["BIS_fnc_endMission",0]};

// forEach factory, add to multiplier
{
    _fabrica = _x;
    _power = [_fabrica] call powerCheck;
    if ((_power) and (not(_fabrica in destroyedCities))) then {
        if (_fabrica in mrkFIA) then {_FIAResIncomeMultiplier = _FIAResIncomeMultiplier + 0.25};
        if (_fabrica in mrkAAF) then {_AAFResIncomeMultiplier = _AAFResIncomeMultiplier + 0.25};
    };
} forEach fabricas;

// forEach resource, add to money
{
    _recurso = _x;
    _power = [_recurso] call powerCheck;
    if !(_recurso in destroyedCities) then {
        _powerMultiplier = 1;
        if (_power) then {
            _powerMultiplier = 3;
        };
        if (_recurso in mrkFIA) then {_FIAnewMoney = _FIAnewMoney + (100 * _powerMultiplier * _FIAResIncomeMultiplier)};
        if (_recurso in mrkAAF) then {_AAFnewMoney = _AAFnewMoney + (100 * _powerMultiplier * _AAFResIncomeMultiplier)};
    };
} forEach recursos;

private _texto = format ["<t size='0.6' color='#C1C0BB'>Taxes Income.<br/> <t size='0.5' color='#C1C0BB'><br/>Manpower: +%1<br/>Money: +%2 €",round _FIAnewHR, round _FIAnewMoney];

_AAFnewMoney = AS_P("resourcesAAF") + round _AAFnewMoney;
_FIAnewMoney = AS_P("resourcesFIA") + round _FIAnewMoney;
_FIAnewHR = AS_P("hr") + round _FIAnewHR;

if (hayBE) then {
    if (_FIAnewHR > 0) then {
        _FIAnewHR = _FIAnewHR min (["HR"] call fnc_BE_permission);
    };
};

[[petros,"taxRep",_texto],"commsMP"] call BIS_fnc_MP;

AS_Pset("hr",_FIAnewHR);
AS_Pset("resourcesFIA",_FIAnewMoney);
AS_Pset("resourcesAAF",_AAFnewMoney);