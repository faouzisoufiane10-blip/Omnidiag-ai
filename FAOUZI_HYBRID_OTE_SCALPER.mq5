//+------------------------------------------------------------------+
//|                  FAOUZI_HYBRID_OTE_SCALPER.mq5                   |
//|       FAOUZI Smart Hybrid | XAUUSD SCALPER + OTE PATTERN         |
//|       "Optimal Trade Entry + Spread Filter + Quick Profit"       |
//+------------------------------------------------------------------+
#property copyright "FAOUZI & Antigravity AI"
#property version   "14.00"
#property description "Hybrid: XAUUSD Scalping + ICT OTE Pattern"

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//|   INPUT PARAMETERS                                               |
//+------------------------------------------------------------------+
input group "====== 💼 HYBRID MONEY MANAGEMENT ======"
input double InpLotSize        = 0.01;   
input int    InpMagicNumber    = 777999;  
input int    InpMaxTrades      = 5;      
input double InpFastProfit_USD = 1.5;    // Quick Scalp Profit
input double InpGlobalSL_USD   = 50.0;   // Emergency Global SL

input group "====== 📉 GRID / AVERAGING ======"
input double InpGridStepPoints = 200;    // Grid Step in points (e.g. 200 = $2 on XAUUSD)

input group "====== 🎯 OTE PATTERN RECOGNITION ======"
input bool   InpUseOTEFilter   = true;   // Require price in Fib Zone
input int    InpOTESwingBars   = 40;     
input bool   InpDrawOTEZone    = true;   

input group "====== 🛡️ MACRO & PRICE ACTION ======"
input bool   InpUseMacroTrend  = true;   // H1 EMA 200 direction
input bool   InpRequireRejection= true;  // Candle close confirmation

input group "====== ⚡ FAST SIGNALS & SAFETY ======"
input int    InpRSIPeriod      = 7;      
input int    InpRSIBuyLevel    = 40;     
input int    InpRSISellLevel   = 60;     
input int    InpMaxSpread      = 40;     // Pause if Spread > 40
input double InpMaxVelocityATR = 3.0;    // Pause if Chaotic

//+------------------------------------------------------------------+
//|   GLOBAL VARIABLES                                               |
//+------------------------------------------------------------------+
CTrade trade;
int h_rsi, h_atr, h_emaH1;
double rsiVal[], atrVal[], emaH1Val[];
bool g_isPaused = false; 

// OTE Tracking
double g_swingHigh = 0;
double g_swingLow = 999999;
double g_fib62 = 0;
double g_fib79 = 0;

//+------------------------------------------------------------------+
//|   INIT                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(50); 
    trade.SetTypeFilling(ORDER_FILLING_IOC);

    h_rsi   = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
    h_atr   = iATR(_Symbol, _Period, 14);
    h_emaH1 = iMA(_Symbol, PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE);
    
    ArraySetAsSeries(rsiVal, true);
    ArraySetAsSeries(atrVal, true);
    ArraySetAsSeries(emaH1Val, true);
    
    DrawProDashboard(0, 0, 0, 0, true, false, false, "INITIALIZING...", clrSilver, "LOADING...", clrSilver);
    
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    IndicatorRelease(h_rsi); 
    IndicatorRelease(h_atr);
    IndicatorRelease(h_emaH1);
    ObjectsDeleteAll(0, "FZP_");
    ObjectsDeleteAll(0, "OTE_");
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if(id == CHARTEVENT_OBJECT_CLICK && sparam == "FZP_BTN_PAUSE")
    {
        long state = ObjectGetInteger(0, "FZP_BTN_PAUSE", OBJPROP_STATE);
        if(state == 1) { 
            g_isPaused = true;
            ObjectSetString(0, "FZP_BTN_PAUSE", OBJPROP_TEXT, "▶ RESUME BOT");
            ObjectSetInteger(0, "FZP_BTN_PAUSE", OBJPROP_BGCOLOR, clrOrangeRed);
        } else { 
            g_isPaused = false;
            ObjectSetString(0, "FZP_BTN_PAUSE", OBJPROP_TEXT, "⏸ PAUSE BOT");
            ObjectSetInteger(0, "FZP_BTN_PAUSE", OBJPROP_BGCOLOR, C'40,40,40');
        }
        ChartRedraw();
    }
}

//+------------------------------------------------------------------+
//|   OTE SCANNER                                                    |
//+------------------------------------------------------------------+
void ScanOTEPattern(bool isBullishMacro)
{
    MqlRates r[]; ArraySetAsSeries(r, true);
    if(CopyRates(_Symbol, _Period, 0, InpOTESwingBars, r) < InpOTESwingBars) return;
    
    double highest = 0, lowest = 999999;
    datetime tHigh = 0, tLow = 0;
    
    for(int i=0; i<InpOTESwingBars; i++) {
        if(r[i].high > highest) { highest = r[i].high; tHigh = r[i].time; }
        if(r[i].low < lowest)   { lowest = r[i].low; tLow = r[i].time; }
    }
    
    g_swingHigh = highest;
    g_swingLow = lowest;
    double range = highest - lowest;
    
    if(isBullishMacro) {
        g_fib62 = highest - (range * 0.618);
        g_fib79 = highest - (range * 0.786);
        if(InpDrawOTEZone) DrawOTEBox(tLow, tHigh, g_fib62, g_fib79, clrDodgerBlue);
    } else {
        g_fib62 = lowest + (range * 0.618);
        g_fib79 = lowest + (range * 0.786);
        if(InpDrawOTEZone) DrawOTEBox(tHigh, tLow, g_fib79, g_fib62, clrCrimson); 
    }
}

void DrawOTEBox(datetime t1, datetime t2, double topPrice, double botPrice, color c)
{
    string name = "OTE_ZONE";
    if(ObjectFind(0, name) < 0) {
        ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, topPrice, t2, botPrice);
        ObjectSetInteger(0, name, OBJPROP_FILL, true);
        ObjectSetInteger(0, name, OBJPROP_BACK, true);
    } else {
        ObjectMove(0, name, 0, t1, topPrice);
        ObjectMove(0, name, 1, TimeCurrent()+PeriodSeconds()*5, botPrice); 
    }
    ObjectSetInteger(0, name, OBJPROP_COLOR, c);
    ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
}

//+------------------------------------------------------------------+
//|   MAIN TICK                                                      |
//+------------------------------------------------------------------+
void OnTick()
{
    if(CopyBuffer(h_rsi, 0, 0, 3, rsiVal) <= 0) return;
    if(CopyBuffer(h_atr, 0, 0, 3, atrVal) <= 0) return;
    if(CopyBuffer(h_emaH1, 0, 0, 1, emaH1Val) <= 0) return;
    
    double rsi0 = rsiVal[0]; double atr0 = atrVal[0]; double macEma = emaH1Val[0];
    if(atr0 == 0) return; 

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

    MqlRates r[]; ArraySetAsSeries(r, true);
    CopyRates(_Symbol, _Period, 0, 4, r);
    
    double velATR = MathAbs(r[0].close - r[3].close) / atr0;

    bool isMacroBullish = (bid > macEma);
    bool isMacroBearish = (ask < macEma);
    if(!InpUseMacroTrend) { isMacroBullish = true; isMacroBearish = true; } 

    ScanOTEPattern(isMacroBullish);

    // 1. MANAGE EXITS & PNL
    int buyCount = 0; int sellCount = 0;
    double totalBuyPnL = 0; double totalSellPnL = 0;
    double lowestBuyPrice = 999999; double highestSellPrice = 0;

    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

        double pnl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) { buyCount++; totalBuyPnL += pnl; if(openPrice < lowestBuyPrice) lowestBuyPrice = openPrice; } 
        else { sellCount++; totalSellPnL += pnl; if(openPrice > highestSellPrice) highestSellPrice = openPrice; }
    }

    // --- QUICK PROFIT CLOSE ---
    if(buyCount > 0 && totalBuyPnL >= InpFastProfit_USD) { CloseAllByType(POSITION_TYPE_BUY); buyCount = 0; totalBuyPnL = 0; }
    if(sellCount > 0 && totalSellPnL >= InpFastProfit_USD) { CloseAllByType(POSITION_TYPE_SELL); sellCount = 0; totalSellPnL = 0; }

    // --- EMERGENCY STOP LOSS ---
    if((totalBuyPnL < -InpGlobalSL_USD) && buyCount > 0) CloseAllByType(POSITION_TYPE_BUY);
    if((totalSellPnL < -InpGlobalSL_USD) && sellCount > 0) CloseAllByType(POSITION_TYPE_SELL);

    // 2. FILTERS & CONDITIONS
    bool isBullishRejection = (r[1].close > r[1].open); 
    bool isBearishRejection = (r[1].close < r[1].open); 
    if(!InpRequireRejection) { isBullishRejection = true; isBearishRejection = true; } 

    bool isTooFast = (velATR > InpMaxVelocityATR);
    bool isSpreadHigh = (spread > InpMaxSpread);
    
    // OTE CHECK
    bool inBuyOTE  = false; bool inSellOTE = false;
    if(InpUseOTEFilter && g_swingHigh > 0 && g_swingLow < 999999) {
        double range  = g_swingHigh - g_swingLow;
        double fib50  = g_swingHigh - (range * 0.50);
        double fib85  = g_swingHigh - (range * 0.85);
        double sfib50 = g_swingLow  + (range * 0.50);
        double sfib85 = g_swingLow  + (range * 0.85);
        if(isMacroBullish) inBuyOTE  = (bid <= fib50  && bid >= fib85);
        if(isMacroBearish) inSellOTE = (bid >= sfib50 && bid <= sfib85);
    } else { inBuyOTE = true; inSellOTE = true; }

    // UI Status Processing
    string state = "WAITING FOR RETRACEMENT"; color stClr = clrGray;
    string aiDec = "SCANNING ZONES"; color aiClr = clrGray;

    if(buyCount > 0 || sellCount > 0) { state = "MANAGING POSITIONS"; stClr = clrGold; aiDec = "PULLING PROFIT (SCALP)"; aiClr = clrLime; }
    else if(g_isPaused)  { state = "MANUALLY PAUSED"; stClr = clrRed; aiDec = "SYSTEM OFFLINE"; aiClr = clrRed; }
    else if(isSpreadHigh){ state = "HIGH SPREAD DETECTED"; stClr = clrOrangeRed; aiDec = "WAITING SPREAD DROP"; aiClr = clrOrangeRed; }
    else if(isTooFast)   { state = "EXCESSIVE VELOCITY"; stClr = clrOrange; aiDec = "AVOIDING CRASH"; aiClr = clrOrange; }
    else if(isMacroBullish && inBuyOTE) {
        state = "OTE BUY ZONE ACTIVE"; stClr = clrDodgerBlue;
        if(!isBullishRejection) { aiDec = "WAITING BULLISH CANDLE"; aiClr = clrSkyBlue; }
        else { aiDec = ">> READY TO BUY <<"; aiClr = clrLime; }
    }
    else if(isMacroBearish && inSellOTE) {
        state = "OTE SELL ZONE ACTIVE"; stClr = clrCrimson;
        if(!isBearishRejection) { aiDec = "WAITING BEARISH CANDLE"; aiClr = clrTomato; }
        else { aiDec = ">> READY TO SELL <<"; aiClr = clrLime; }
    }

    DrawProDashboard(rsi0, velATR, spread, isMacroBullish, inBuyOTE, inSellOTE, state, stClr, aiDec, aiClr);

    bool allowNewTrades = !g_isPaused && !isTooFast && !isSpreadHigh;

    // BUY LOGIC
    if(buyCount < InpMaxTrades) {
        bool rsiOk = (rsi0 < InpRSIBuyLevel);
        bool canOpenBuy = (buyCount == 0 && allowNewTrades && rsiOk && isMacroBullish && isBullishRejection && inBuyOTE) ||
                          (buyCount > 0 && allowNewTrades && ask <= lowestBuyPrice - (InpGridStepPoints * _Point));
        if(canOpenBuy) trade.Buy(InpLotSize, _Symbol, ask, 0, 0, "HYBRID_OTE_BUY");
    }

    // SELL LOGIC
    if(sellCount < InpMaxTrades) {
        bool rsiOk = (rsi0 > InpRSISellLevel);
        bool canOpenSell = (sellCount == 0 && allowNewTrades && rsiOk && isMacroBearish && isBearishRejection && inSellOTE) ||
                           (sellCount > 0 && allowNewTrades && bid >= highestSellPrice + (InpGridStepPoints * _Point));
        if(canOpenSell) trade.Sell(InpLotSize, _Symbol, bid, 0, 0, "HYBRID_OTE_SELL");
    }
}

void CloseAllByType(ENUM_POSITION_TYPE type)
{
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber) {
            if(PositionGetInteger(POSITION_TYPE) == type) trade.PositionClose(ticket);
        }
    }
}

//+------------------------------------------------------------------+
//|   PRO HOLOGRAPHIC DASHBOARD (HYBRID EDITION)                     |
//+------------------------------------------------------------------+
void DrawProDashboard(double rsi, double vel, long spread, bool macBull, bool inBuyOTE, bool inSellOTE, string state, color stClr, string aiDec, color aiClr)
{
    int x = 20; int y = 20;
    
    CreateRect("FZP_BG1", x, y, 320, 360, C'12,14,18', C'30,35,40'); 
    CreateRect("FZP_BG2", x+10, y+10, 300, 60, C'18,22,28', C'30,35,40'); 
    
    CreateText("FZP_LOGO1", x+20, y+20, "♛", clrGold, 20, "Webdings");
    CreateText("FZP_TITLE", x+60, y+20, "FAOUZI HYBRID", clrWhite, 14, "Arial Black");
    CreateText("FZP_SUB", x+60, y+45, "XAUUSD SCALPER + OTE PATTERN", clrDodgerBlue, 8, "Arial Bold");

    int pY = y + 85;
    CreateText("FZP_H1", x+15, pY, "QUANTITATIVE METRICS", clrGray, 8, "Arial Bold");
    
    CreateText("FZP_VEL_L", x+15, pY+20, "Velocity Filter:", clrSilver, 9);
    CreateText("FZP_VEL_V", x+150, pY+20, DoubleToString(vel, 2) + " ATR", (vel > InpMaxVelocityATR)?clrRed:clrLime, 9, "Consolas Bold");

    CreateText("FZP_SPR_L", x+15, pY+40, "Live Spread:", clrSilver, 9);
    CreateText("FZP_SPR_V", x+150, pY+40, IntegerToString((int)spread) + " pts", (spread > InpMaxSpread)?clrRed:clrLime, 9, "Consolas Bold");

    CreateText("FZP_RSI_L", x+15, pY+60, "Oscillator RSI:", clrSilver, 9);
    CreateText("FZP_RSI_V", x+150, pY+60, DoubleToString(rsi, 1), (rsi>60||rsi<40)?clrGold:clrSilver, 9, "Consolas Bold");

    CreateRect("FZP_DIV1", x+10, pY+85, 300, 1, C'30,35,40', C'30,35,40');

    int fY = pY + 95;
    CreateText("FZP_H2", x+15, fY, "ICT OTE PATTERN STATUS", clrGray, 8, "Arial Bold");
    
    CreateText("FZP_MAC_L", x+15, fY+20, "Macro Bias (H1):", clrSilver, 9);
    CreateText("FZP_MAC_V", x+150, fY+20, (macBull?"BULLISH TREND":"BEARISH TREND"), (macBull?clrDodgerBlue:clrCrimson), 9, "Consolas Bold");

    bool inOte = (inBuyOTE || inSellOTE);
    CreateText("FZP_OTE_L", x+15, fY+40, "OTE Price Zone:", clrSilver, 9);
    CreateText("FZP_OTE_V", x+150, fY+40, (inOte?"ACTIVE (50-85%)":"OUTSIDE ZONE"), (inOte?clrGold:clrSilver), 9, "Consolas Bold");

    CreateRect("FZP_DIV2", x+10, fY+65, 300, 1, C'30,35,40', C'30,35,40');

    int aY = fY + 75;
    CreateRect("FZP_BG3", x+10, aY, 300, 45, C'15,25,35', C'30,45,65'); 
    
    CreateText("FZP_ST_V", x+20, aY+10, state, stClr, 8, "Arial Bold");
    CreateText("FZP_AI_V", x+20, aY+25, aiDec, aiClr, 10, "Arial Black");

    double pnl = 0;
    for(int i = PositionsTotal()-1; i >= 0; i--) {
        if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber) pnl += PositionGetDouble(POSITION_PROFIT);
    }
    CreateText("FZP_PNL_L", x+15, aY+60, "LIVE EQUITY PNL:", clrSilver, 8, "Arial Bold");
    CreateText("FZP_PNL_V", x+15, aY+72, "$ " + DoubleToString(pnl, 2), (pnl>=0?clrLime:clrCrimson), 16, "Arial Black");

    CreateButton("FZP_BTN_PAUSE", x+160, aY+60, 150, 30, g_isPaused ? "▶ RESUME" : "⏸ PAUSE AI", g_isPaused ? clrLimeGreen : C'40,40,40', clrWhite);
    ChartRedraw(0);
}

void CreateRect(string name, int x, int y, int w, int h, color bg, color border) {
    if(ObjectFind(0, name) < 0) { ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0); ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER); }
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y); ObjectSetInteger(0, name, OBJPROP_XSIZE, w); ObjectSetInteger(0, name, OBJPROP_YSIZE, h); ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, name, OBJPROP_COLOR, border); ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT); ObjectSetInteger(0, name, OBJPROP_BACK, false);
}
void CreateText(string name, int x, int y, string text, color clr, int size=10, string font="Arial") {
    if(ObjectFind(0, name) < 0) { ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0); ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER); }
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y); ObjectSetString(0, name, OBJPROP_TEXT, text); ObjectSetInteger(0, name, OBJPROP_COLOR, clr); ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size); ObjectSetString(0, name, OBJPROP_FONT, font); ObjectSetInteger(0, name, OBJPROP_BACK, false);
}
void CreateButton(string name, int x, int y, int w, int h, string text, color bg, color fg) {
    if(ObjectFind(0, name) < 0) { ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0); ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER); }
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y); ObjectSetInteger(0, name, OBJPROP_XSIZE, w); ObjectSetInteger(0, name, OBJPROP_YSIZE, h); ObjectSetString(0, name, OBJPROP_TEXT, text); ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, name, OBJPROP_COLOR, fg); ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold"); ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9); ObjectSetInteger(0, name, OBJPROP_BACK, false);
}
