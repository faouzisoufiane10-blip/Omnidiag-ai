//+------------------------------------------------------------------+
//|                             TOP29.mq5                            |
//|       ♛  BUSINESSMAN AI | 50$ TO 180$ MICRO ACCOUNT SNIPER ♛     |
//|       Strict Risk Management | NO GRID | 1 Sniper Trade Only     |
//+------------------------------------------------------------------+
#property copyright "FAOUZI & Antigravity AI"
#property version   "1.00"
#property description "Specifically tuned for a $50 Micro Account."
#property description "Uses Sniper Entries, No Grid, Fixed 0.01 Lot, Equity Protection."

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//|   INPUTS (TUNED FOR 50$ ACCOUNT)                                 |
//+------------------------------------------------------------------+
input group "══════ 💼 50$ TO 180$ FLIPPER RULES ══════"
input double InpBaseLot          = 0.01;    // Fixed Lot (Do not increase on 50$)
input int    InpMaxTrades        = 1;       // NO GRID! 1 Trade only for safety
input double InpProfitTarget_USD = 3.0;     // Lock profit per trade ($3 is 6% of $50)
input double InpMaxLoss_USD      = 5.0;     // Emergency SL per cycle (Max 10% risk)
input int    InpMagicNumber      = 505050;

input group "══════ 🛡️ EQUITY TRAIL (LOCK PROFITS) ══════"
input bool   InpUseEquityTrail   = true;    // Secure profits before they reverse
input double InpEquityTriggerBE  = 1.5;     // At $1.50 profit, move to Break Even
input double InpEquityTrailDist  = 0.5;     // Trail by $0.50

input group "══════ 🎯 OTE & PRICE ACTION SNIPER ══════"
input int    InpOTEBars          = 50;      // Lookback for OTE zones
input bool   InpDrawZone         = true;    // Draw Transparent OTE Zone
input bool   InpRequireRejection = true;    // Must have Rejection candle
input int    InpTrendPeriod      = 50;      // M15 EMA Macro Trend

input group "══════ 📊 RSI PHYSICS ══════"
input int    InpRSIPeriod        = 7;
input int    InpBuyLevel         = 30;      // Very Strict Entry for $50
input int    InpSellLevel        = 70;      // Very Strict Entry for $50
input double InpMaxVelATR        = 4.0;     // Avoid sudden crashes

//+------------------------------------------------------------------+
//|   GLOBALS                                                        |
//+------------------------------------------------------------------+
CTrade         trade;
CPositionInfo  m_position;
CSymbolInfo    m_symbol;

int    h_rsi, h_atr, h_ema;
double rsiB[], atrB[], emaB[];
bool   g_paused = false;

double g_highestEquityAchieved = 0.0;

//+------------------------------------------------------------------+
//|   INIT                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(30);
    trade.SetTypeFilling(ORDER_FILLING_IOC);
    m_symbol.Name(_Symbol);

    h_rsi = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
    h_atr = iATR(_Symbol, _Period, 14);
    h_ema = iMA(_Symbol, PERIOD_M15, InpTrendPeriod, 0, MODE_EMA, PRICE_CLOSE);

    ArraySetAsSeries(rsiB, true);
    ArraySetAsSeries(atrB, true);
    ArraySetAsSeries(emaB, true);

    g_highestEquityAchieved = 0.0;

    DrawHUD(0, 0, 0, false, false, false, "INITIALIZING 50$ SNIPER...", "SAFE MODE ACTIVE", clrSilver, clrGold, AccountInfoDouble(ACCOUNT_BALANCE));
    Print("♛ BUSINESSMAN AI 50$ FLIPPER | ONLINE ♛");
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
    IndicatorRelease(h_rsi); IndicatorRelease(h_atr); IndicatorRelease(h_ema);
    ObjectsDeleteAll(0, "BAP_"); ObjectsDeleteAll(0, "OTE_");
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if(id == CHARTEVENT_OBJECT_CLICK && sparam == "BAP_BTN") {
        long st = ObjectGetInteger(0, "BAP_BTN", OBJPROP_STATE);
        g_paused = (st == 1);
        ObjectSetString(0, "BAP_BTN", OBJPROP_TEXT, g_paused ? " ▶ ACTIVATE 50$ SNIPER" : " ⏸ PAUSE SNIPER");
        ObjectSetInteger(0, "BAP_BTN", OBJPROP_BGCOLOR, g_paused ? C'20,120,40' : C'40,40,40');
        ChartRedraw();
    }
}

//+------------------------------------------------------------------+
//|   OTE ZONE SCANNER                                               |
//+------------------------------------------------------------------+
bool ScanOTE(bool bullish, double &zoneTop, double &zoneBot)
{
    MqlRates r[]; ArraySetAsSeries(r, true);
    if(CopyRates(_Symbol, _Period, 0, InpOTEBars, r) < InpOTEBars) return false;

    double hi = 0, lo = 999999;
    datetime tHi = 0, tLo = 0;
    for(int i = 0; i < InpOTEBars; i++) {
        if(r[i].high > hi) { hi = r[i].high; tHi = r[i].time; }
        if(r[i].low  < lo) { lo = r[i].low;  tLo = r[i].time; }
    }

    double range = hi - lo;
    if(range <= 0) return false;

    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    bool   inOTE = false;

    if(bullish) {
        zoneTop = hi - range * 0.50;  
        zoneBot = hi - range * 0.85;  
        inOTE   = (bid <= zoneTop && bid >= zoneBot);
        if(InpDrawZone) {
            DrawBox("OTE_ZONE", tLo, TimeCurrent()+PeriodSeconds()*20, zoneTop, zoneBot, C'0,40,80'); 
            DrawLabel("OTE_LBL", tHi, zoneTop, "OTE BUY ZONE", clrDodgerBlue);
        }
    } else {
        zoneTop = lo + range * 0.85;  
        zoneBot = lo + range * 0.50;  
        inOTE   = (bid >= zoneBot && bid <= zoneTop);
        if(InpDrawZone) {
            DrawBox("OTE_ZONE", tHi, TimeCurrent()+PeriodSeconds()*20, zoneTop, zoneBot, C'80,20,20');
            DrawLabel("OTE_LBL", tLo, zoneTop, "OTE SELL ZONE", clrCrimson);
        }
    }
    return inOTE;
}

void DrawBox(string nm, datetime t1, datetime t2, double p1, double p2, color bg)
{
    if(ObjectFind(0, nm) < 0) ObjectCreate(0, nm, OBJ_RECTANGLE, 0, t1, p1, t2, p2);
    else { ObjectMove(0, nm, 0, t1, p1); ObjectMove(0, nm, 1, t2, p2); }
    ObjectSetInteger(0, nm, OBJPROP_COLOR, bg); ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, bg);
    ObjectSetInteger(0, nm, OBJPROP_FILL, true); ObjectSetInteger(0, nm, OBJPROP_BACK, true);
}

void DrawLabel(string nm, datetime t, double p, string txt, color c)
{
    if(ObjectFind(0, nm) < 0) ObjectCreate(0, nm, OBJ_TEXT, 0, t, p);
    ObjectMove(0, nm, 0, t, p);
    ObjectSetString(0, nm, OBJPROP_TEXT, txt); ObjectSetInteger(0, nm, OBJPROP_COLOR, c);
    ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, 8); ObjectSetString(0, nm, OBJPROP_FONT, "Arial Bold");
}

bool IsBullishRejection(MqlRates &r[]) {
    double body = MathAbs(r[1].close - r[1].open);
    double lowerWick = MathMin(r[1].close, r[1].open) - r[1].low;
    return (r[1].close > r[1].open) && (lowerWick >= body * 1.5 || r[1].close > r[2].high);
}

bool IsBearishRejection(MqlRates &r[]) {
    double body = MathAbs(r[1].close - r[1].open);
    double upperWick = r[1].high - MathMax(r[1].close, r[1].open);
    return (r[1].close < r[1].open) && (upperWick >= body * 1.5 || r[1].close < r[2].low);
}

//+------------------------------------------------------------------+
//|   MAIN TICK                                                      |
//+------------------------------------------------------------------+
void OnTick()
{
    if(CopyBuffer(h_rsi, 0, 0, 3, rsiB) <= 0 || CopyBuffer(h_atr, 0, 0, 3, atrB) <= 0 || CopyBuffer(h_ema, 0, 0, 1, emaB) <= 0) return;

    double rsi = rsiB[0]; double atr = atrB[0]; double ema = emaB[0];
    if(atr == 0) return;

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    MqlRates bars[]; ArraySetAsSeries(bars, true);
    CopyRates(_Symbol, _Period, 0, 5, bars);

    double vel = MathAbs(bars[0].close - bars[3].close) / atr;
    bool bullish = (bid > ema); bool bearish = (bid < ema);
    double zTop = 0, zBot = 0; bool inOTE = ScanOTE(bullish, zTop, zBot);
    bool paBullish = !InpRequireRejection || IsBullishRejection(bars);
    bool paBearish = !InpRequireRejection || IsBearishRejection(bars);

    int buys = 0, sells = 0; double bPnL = 0, sPnL = 0;

    for(int i = PositionsTotal()-1; i >= 0; i--) {
        if(m_position.SelectByIndex(i) && m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber) {
            double pnl = m_position.Profit() + m_position.Swap();
            if(m_position.PositionType() == POSITION_TYPE_BUY) { buys++; bPnL += pnl; }
            else { sells++; sPnL += pnl; }
        }
    }

    double totalCyclePnL = bPnL + sPnL;
    double bal = AccountInfoDouble(ACCOUNT_BALANCE);
    
    // Safety for 50$ Account: Lock strict profits and cut strict losses
    if(buys > 0 || sells > 0) {
        if(totalCyclePnL > g_highestEquityAchieved) g_highestEquityAchieved = totalCyclePnL; 

        if(InpUseEquityTrail && g_highestEquityAchieved >= InpEquityTriggerBE) {
            double trailStopLine = g_highestEquityAchieved - InpEquityTrailDist;
            if(totalCyclePnL <= trailStopLine) { CloseAll(); g_highestEquityAchieved = 0; Print(">> EQUITY TRAIL HIT <<"); }
        }
    } else { g_highestEquityAchieved = 0; }

    if((buys > 0 && bPnL >= InpProfitTarget_USD) || (sells > 0 && sPnL >= InpProfitTarget_USD)) { CloseAll(); }
    if((buys > 0 && bPnL <= -InpMaxLoss_USD) || (sells > 0 && sPnL <= -InpMaxLoss_USD)) { CloseAll(); }

    bool fastMkt = (vel > InpMaxVelATR);
    string state = "SCANNING FOR SNIPER ENTRY"; string aiMsg = "PROTECTING 50$ BALANCE";
    color sClr = C'100,100,100'; color aClr = clrGold;

    if(buys > 0 || sells > 0)       { state="TRADE ACTIVE"; aiMsg="SNIPER PROFIT LOCK ON"; sClr=clrGold; aClr=clrLime; }
    else if(g_paused)               { state="PAUSED"; aiMsg="SYSTEM OFFLINE"; sClr=clrRed; aClr=clrGray; }
    else if(fastMkt)                { state="MARKET VOLATILE"; aiMsg="AVOIDING LOSS"; sClr=clrOrange; aClr=clrOrange; }
    else if(rsi < InpBuyLevel && bullish) {
        if(!paBullish) { state="RSI + TREND"; aiMsg="WAITING PA REJECTION"; sClr=clrAqua; aClr=clrOrange; }
        else if(inOTE) { state="SNIPER CONFLUENCE"; aiMsg="♛ EXECUTING SAFE BUY ♛"; sClr=clrLime; aClr=clrLime; }
    }
    else if(rsi > InpSellLevel && bearish) {
        if(!paBearish) { state="RSI + TREND"; aiMsg="WAITING PA REJECTION"; sClr=clrTomato; aClr=clrOrange; }
        else if(inOTE) { state="SNIPER CONFLUENCE"; aiMsg="♛ EXECUTING SAFE SELL ♛"; sClr=clrLime; aClr=clrLime; }
    }

    DrawHUD(rsi, vel, totalCyclePnL, bullish, inOTE, paBullish||paBearish, state, aiMsg, sClr, aClr, bal);

    if(g_paused || fastMkt) return;

    double lot = InpBaseLot; // STRICTLY 0.01 for 50$ account

    if(rsi < InpBuyLevel && bullish && paBullish && inOTE && buys == 0 && sells == 0) {
        trade.Buy(lot, _Symbol, ask, 0, 0, "50_SNIPER_BUY");
    }

    if(rsi > InpSellLevel && bearish && paBearish && inOTE && sells == 0 && buys == 0) {
        trade.Sell(lot, _Symbol, bid, 0, 0, "50_SNIPER_SELL");
    }
}

void CloseAll()
{
    for(int i = PositionsTotal()-1; i >= 0; i--) {
        if(m_position.SelectByIndex(i) && m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber) {
            trade.PositionClose(m_position.Ticket());
        }
    }
}

//+------------------------------------------------------------------+
//|   HUD (UI)                                                       |
//+------------------------------------------------------------------+
void DrawHUD(double rsi, double vel, double pnl, bool bull, bool ote, bool pa, string state, string aiMsg, color sClr, color aClr, double bal)
{
    int x=25, y=25;

    CR("BAP_BG", x, y, 320, 350, C'10,12,15', C'40,45,55'); 
    CR("BAP_HDR", x+5, y+5, 310, 50, C'15,20,25', C'50,200,100'); // Green Header for Safety

    CT("BAP_LOGO", x+15, y+15, "♛", C'255,200,50', 20, "Webdings");
    CT("BAP_T1", x+50, y+13, "BUSINESSMAN 50$ FLIPPER", clrWhite, 12, "Arial Black");
    CT("BAP_T2", x+50, y+35, "ULTIMATE SNIPER MODE (NO GRID)", C'100,255,150', 8, "Arial Bold");

    CR("BAP_DIV1", x+15, y+65, 290, 1, C'40,45,55', C'40,45,55');

    int mY = y+75;
    CT("BAP_L1", x+15, mY, "📊 RSI OSCILLATOR :", clrSilver, 9);
    CT("BAP_V1", x+170,mY, DoubleToString(rsi,1), (rsi>InpSellLevel||rsi<InpBuyLevel)?C'0,255,100':clrWhite, 9, "Consolas Bold");
    CT("BAP_L2", x+15, mY+25, "📈 M15 MACRO TREND :", clrSilver, 9);
    CT("BAP_V2", x+170,mY+25, bull?"BULLISH ▲":"BEARISH ▼", bull?C'0,180,255':clrCrimson, 9, "Consolas Bold");
    CT("BAP_L3", x+15, mY+50, "🎯 ICT OTE ZONE :", clrSilver, 9);
    CT("BAP_V3", x+170,mY+50, ote?"SNIPER ZONE ACTIVE":"OUTSIDE ZONE", ote?clrGold:clrGray, 9, "Consolas Bold");
    CT("BAP_L4", x+15, mY+75, "🕯️ BAR CHART P.A :", clrSilver, 9);
    CT("BAP_V4", x+170,mY+75, pa?"REJECTION DETECTED":"SCANNING...", pa?clrLime:clrOrange, 9, "Consolas Bold");

    CR("BAP_DIV2", x+15, y+180, 290, 1, C'40,45,55', C'40,45,55');

    int aY = y+190;
    CR("BAP_AI_BG", x+15, aY, 290, 50, C'20,25,30', C'60,70,80');
    CT("BAP_ST", x+25, aY+8, "» " + state, sClr, 8, "Arial Bold");
    CT("BAP_MSG", x+25, aY+25, aiMsg, aClr, 10, "Arial Black");

    int pY = aY + 65;
    CT("BAP_PLBL", x+15, pY, "LIVE EQUITY PNL:", clrSilver, 9, "Arial Bold");
    CT("BAP_PV", x+15, pY+15, "$ " + DoubleToString(pnl,2), pnl>=0?clrLime:clrCrimson, 15, "Arial Black");

    CB("BAP_BTN", x+165, pY+5, 140, 30, g_paused?"▶ RESUME SNIPER":"⏸ PAUSE SNIPER", g_paused?C'20,120,40':C'40,40,40', clrWhite);

    ChartRedraw(0);
}

void CR(string n,int x,int y,int w,int h,color bg,color bd){
    if(ObjectFind(0,n)<0) ObjectCreate(0,n,OBJ_RECTANGLE_LABEL,0,0,0);
    ObjectSetInteger(0,n,OBJPROP_CORNER,0); ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y);
    ObjectSetInteger(0,n,OBJPROP_XSIZE,w); ObjectSetInteger(0,n,OBJPROP_YSIZE,h); ObjectSetInteger(0,n,OBJPROP_BGCOLOR,bg);
    ObjectSetInteger(0,n,OBJPROP_COLOR,bd); ObjectSetInteger(0,n,OBJPROP_BORDER_TYPE,0); ObjectSetInteger(0,n,OBJPROP_BACK,false);
}
void CT(string n,int x,int y,string t,color c,int s=9,string f="Arial"){
    if(ObjectFind(0,n)<0) ObjectCreate(0,n,OBJ_LABEL,0,0,0);
    ObjectSetInteger(0,n,OBJPROP_CORNER,0); ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y);
    ObjectSetString(0,n,OBJPROP_TEXT,t); ObjectSetInteger(0,n,OBJPROP_COLOR,c); ObjectSetInteger(0,n,OBJPROP_FONTSIZE,s);
    ObjectSetString(0,n,OBJPROP_FONT,f); ObjectSetInteger(0,n,OBJPROP_BACK,false);
}
void CB(string n,int x,int y,int w,int h,string t,color bg,color fg){
    if(ObjectFind(0,n)<0) ObjectCreate(0,n,OBJ_BUTTON,0,0,0);
    ObjectSetInteger(0,n,OBJPROP_CORNER,0); ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y);
    ObjectSetInteger(0,n,OBJPROP_XSIZE,w); ObjectSetInteger(0,n,OBJPROP_YSIZE,h); ObjectSetString(0,n,OBJPROP_TEXT,t);
    ObjectSetInteger(0,n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,n,OBJPROP_COLOR,fg); ObjectSetString(0,n,OBJPROP_FONT,"Arial Bold");
    ObjectSetInteger(0,n,OBJPROP_FONTSIZE,9); ObjectSetInteger(0,n,OBJPROP_BACK,false);
}
