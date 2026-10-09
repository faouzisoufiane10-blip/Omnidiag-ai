//+------------------------------------------------------------------+
//|                 BUSINESSMAN_AI_ULTIMATE_90_PRO.mq5               |
//|       ♛  BUSINESSMAN AI PRO | THE ULTIMATE 90%+ WIN RATE ENGINE  |
//|       Merged: OTE + RSI + PRICE ACTION + EQUITY TRAIL PROTECTION |
//+------------------------------------------------------------------+
#property copyright "FAOUZI & Antigravity AI"
#property version   "90.00"
#property description "BUSINESSMAN AI PRO | Ultimate 90%+ Win Rate Engine"
#property description "Features: OTE Pattern, Bar Chart Rejection, Equity Trail"
#property description "Resources/Images:"
#property description "- businessman_ai_pro_logo.jpg (Logo)"
#property description "- promo_slide_1.jpg, promo_slide_2.jpg (Promo)"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//|   INPUTS                                                         |
//+------------------------------------------------------------------+
input group "══════ 💼 BUSINESSMAN MONEY MANAGEMENT ══════"
input bool   InpUseAutoLot       = true;    // Auto Compounding Lot
input double InpRiskPercent      = 1.0;     // Risk % per trade
input double InpBaseLot          = 0.01;    // Manual lot
input int    InpMagicNumber      = 909090;
input int    InpMaxTrades        = 3;       // Max grid trades
input double InpProfitTarget_USD = 5.0;     // Fast cycle profit target

input group "══════ 🛡️ EQUITY PROTECTION & TRAILING ══════"
input double InpMaxLoss_USD      = 50.0;    // Hard Equity Stop Loss
input bool   InpUseEquityTrail   = true;    // Use Equity Trailing
input double InpEquityTriggerBE  = 7.0;     // USD Profit to trigger Break Even
input double InpEquityTrailDist  = 2.5;     // USD Trailing Distance

