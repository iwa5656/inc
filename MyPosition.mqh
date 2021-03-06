// MyPosition.mqh
#property copyright "Copyright (c) 2013, Toyolab FX"
#property link      "http://forex.toyolab.com/"
#property version   "131.009"

// order type extension
#define ORDER_TYPE_NONE -1
#define OP_NONE ORDER_TYPE_NONE
#define OP_BUY ORDER_TYPE_BUY
#define OP_SELL ORDER_TYPE_SELL
#define OP_BUYLIMIT ORDER_TYPE_BUY_LIMIT
#define OP_SELLLIMIT ORDER_TYPE_SELL_LIMIT
#define OP_BUYSTOP ORDER_TYPE_BUY_STOP
#define OP_SELLSTOP ORDER_TYPE_SELL_STOP

// color constant 
#define clrBuy C'3,95,172'
#define clrSell C'225,68,29'

// structure for MyPosition
struct MyPosition
{
   ulong ticket;        // deal ticket
   ulong order_stop;    // stop order ticket
   ulong order_limit;   // limit order ticket
   double lots;         // open lots
   double price;        // open price
   datetime time;       // open time
} MyPos[POSITIONS];

// magic numbers
long MAGIC_B[POSITIONS], MAGIC_S[POSITIONS];

// order comment
string Gvar[POSITIONS];

// pips adjustment
double PipPoint = _Point;

// slippage
input double SlippagePips = 2;
ulong Slippage = 2;

// start date of history
input datetime StartHistory = 0;

// retrieve position from history pool
input bool RetrieveHistory = true;

// refresh Bid/Ask
bool RefreshPrice(double &bid, double &ask)
{
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick)) return(false);
   if(tick.bid <= 0 || tick.ask <= 0) return(false);
   bid = tick.bid;
   ask = tick.ask;
   return(true);
}

// init MyPosition to be called in OnInit()
void MyInitPosition(long magic)
{
   // pips adjustment
   if(_Digits == 3 || _Digits == 5)
   {
      Slippage = (ulong)(SlippagePips * 10);
      PipPoint = _Point * 10;
   }
   else
   {
      Slippage = (ulong)SlippagePips;
      PipPoint = _Point;
   }
   // position settings
   for(int i=0; i<POSITIONS; i++)
   {
      // magic number setting
      MAGIC_B[i] = magic+2*i;
      MAGIC_S[i] = MAGIC_B[i]+1;
      // init order line object
      Gvar[i] = _Symbol+IntegerToString(MAGIC_B[i]);
      ObjectCreate(0, Gvar[i]+"H", OBJ_HLINE, 0, 0, 0);
      ObjectSetInteger(0, Gvar[i]+"H", OBJPROP_STYLE,
                       STYLE_DASHDOT);
      // reset position
      ZeroMemory(MyPos[i]);
      // retrieve position and order
      if(!RetrieveHistory) continue;
      RetrieveOpenPosition(i);
      RetrieveOrder(i);
   }
   ShowPositionLine();
}

// retrieve open position from deal history pool
bool RetrieveOpenPosition(int i)
{
   HistorySelect(StartHistory, TimeCurrent()+60);
   for(int k=HistoryDealsTotal()-1; k>=0; k--)
   {
      ulong ticket = HistoryDealGetTicket(k);
      if(HistoryDealGetString(ticket, DEAL_SYMBOL)
         != _Symbol) continue;
      long dmagic = HistoryDealGetInteger(ticket,
                    DEAL_MAGIC);
      ENUM_DEAL_TYPE dtype = (ENUM_DEAL_TYPE)
         HistoryDealGetInteger(ticket, DEAL_TYPE);
      // position is closed
      if((dtype == DEAL_TYPE_SELL
          && dmagic == MAGIC_B[i]) || 
         (dtype == DEAL_TYPE_BUY
          && dmagic == MAGIC_S[i])) break;
      // position is open
      if((dtype == DEAL_TYPE_BUY
          && dmagic == MAGIC_B[i]) || 
         (dtype == DEAL_TYPE_SELL
          && dmagic == MAGIC_S[i]))
      {
         MyPos[i].ticket = ticket;
         MyPos[i].lots = HistoryDealGetDouble(ticket,
                         DEAL_VOLUME);
         if(dtype == DEAL_TYPE_SELL)
            MyPos[i].lots = -MyPos[i].lots;
         MyPos[i].price = HistoryDealGetDouble(ticket,
                          DEAL_PRICE);
         MyPos[i].time = (datetime)
            HistoryDealGetInteger(ticket, DEAL_TIME);
         return(true);
      }
   }
   return(false);
}

// retrieve closed position from deal history pool
bool RetrieveClosePosition(int i, MyPosition &pos)
{
   HistorySelect(StartHistory, TimeCurrent()+60);
   for(int k=HistoryDealsTotal()-1; k>=0; k--)
   {
      ulong ticket = HistoryDealGetTicket(k);
      if(HistoryDealGetString(ticket, DEAL_SYMBOL)
         != _Symbol) continue;
      long dmagic = HistoryDealGetInteger(ticket,
                    DEAL_MAGIC);
      ENUM_DEAL_TYPE dtype = (ENUM_DEAL_TYPE)
         HistoryDealGetInteger(ticket, DEAL_TYPE);
      // position is open
      if((dtype == DEAL_TYPE_BUY
          && dmagic == MAGIC_B[i]) || 
         (dtype == DEAL_TYPE_SELL
          && dmagic == MAGIC_S[i])) break;
      // position is closed
      if((dtype == DEAL_TYPE_SELL
          && dmagic == MAGIC_B[i]) || 
         (dtype == DEAL_TYPE_BUY
          && dmagic == MAGIC_S[i]))
      {
         pos.ticket = ticket;
         pos.price = HistoryDealGetDouble(ticket,
                     DEAL_PRICE);
         pos.time = (datetime)
            HistoryDealGetInteger(ticket, DEAL_TIME);
         return(true);
      }
   }
   return(false);
}

// retrieve orders from current order pool
bool RetrieveOrder(int i)
{
   bool stop_flag = false, limit_flag = false;
   for(int k=OrdersTotal()-1; k>=0; k--)
   {
      ulong order = OrderGetTicket(k);
      if(!OrderSelect(order)) continue;
      if(OrderGetString(ORDER_SYMBOL)
         != _Symbol) continue;
      long omagic = OrderGetInteger(ORDER_MAGIC);
      ENUM_ORDER_TYPE otype = (ENUM_ORDER_TYPE)
         OrderGetInteger(ORDER_TYPE);
      if(omagic != MAGIC_B[i] && omagic != MAGIC_S[i])
         continue;
      if(otype == ORDER_TYPE_BUY_STOP ||
         otype == ORDER_TYPE_SELL_STOP)
      {
         if(stop_flag) return(true);
         else stop_flag = true;
         MyPos[i].order_stop = order;
      }
      if(otype == ORDER_TYPE_BUY_LIMIT ||
         otype == ORDER_TYPE_SELL_LIMIT)
      {
         if(limit_flag) return(true);
         else limit_flag = true;
         MyPos[i].order_limit = order;
      }
   }
   return(stop_flag || limit_flag);
}

// deinit MyPosition to be called in OnDeinit()
void MyDeinitPosition()
{
   for(int i=0; i<POSITIONS; i++)
      ObjectDelete(0, Gvar[i]+"H");
}

// check MyPosition to be called in OnTrade()
void MyCheckPosition()
{
   HistorySelect(StartHistory, TimeCurrent());
   for(int i=0; i<POSITIONS; i++)
   {
      // stop order is filled
      if(SubCheckPosition(i, MyPos[i].order_stop))
      {
         SubOrderDelete(MyPos[i].order_limit);
         MyPos[i].order_stop = 0;
         MyPos[i].order_limit = 0;
      }
      // limit order is filled
      if(SubCheckPosition(i, MyPos[i].order_limit))
      {
         SubOrderDelete(MyPos[i].order_stop);
         MyPos[i].order_stop = 0;
         MyPos[i].order_limit = 0;
      }
      // for open positions
      if(MyPos[i].ticket > 0) 
      {
         // send SL and TP orders
         double sl = GlobalVariableGet(Gvar[i]+"SL");
         double tp = GlobalVariableGet(Gvar[i]+"TP");
         if(sl > 0 && OrderModifyPending(i, sl, "SL"))
            GlobalVariableDel(Gvar[i]+"SL");
         if(tp > 0 && OrderModifyPending(i, tp, "TP"))
            GlobalVariableDel(Gvar[i]+"TP");
      }
   }
   ShowPositionLine();
}

// check position sub-function
bool SubCheckPosition(int i, ulong order)
{
   // filled order check from order history pool
   if(!HistoryOrderSelect(order) || 
      HistoryOrderGetInteger(order, ORDER_STATE)
      != ORDER_STATE_FILLED) return(false);
   for(int k=HistoryDealsTotal()-1; k>=0; k--)
   {
      ulong ticket = HistoryDealGetTicket(k);
      if(HistoryDealGetString(ticket, DEAL_SYMBOL)
         != _Symbol) continue;
      long dmagic = HistoryDealGetInteger(ticket,
                    DEAL_MAGIC);
      datetime dtime = (datetime)
         HistoryDealGetInteger(ticket, DEAL_TIME);
      double dprice = HistoryDealGetDouble(ticket,
                      DEAL_PRICE);
      double dlots = HistoryDealGetDouble(ticket,
                     DEAL_VOLUME);
      ENUM_DEAL_TYPE dtype = (ENUM_DEAL_TYPE)
         HistoryDealGetInteger(ticket, DEAL_TYPE);
      ENUM_ORDER_TYPE otype = ORDER_TYPE_BUY;
      if(dtype == DEAL_TYPE_SELL)
         otype = ORDER_TYPE_SELL;
      // position closed
      if((dtype == DEAL_TYPE_SELL && 
          dmagic == MAGIC_B[i]) ||
         (dtype == DEAL_TYPE_BUY &&
          dmagic == MAGIC_S[i]))
      {
         // show closed position
         MyPosition pos;
         pos.ticket = ticket;
         pos.price = dprice;
         pos.time = dtime;
         ShowClosePosition(otype, MyPos[i], pos);
         // reset position
         MyPos[i].ticket = 0;
         MyPos[i].lots = 0;
         MyPos[i].price = 0;
         MyPos[i].time = 0;
         break;
      }
      // position opened
      if((dtype == DEAL_TYPE_BUY &&
          dmagic == MAGIC_B[i]) ||
         (dtype == DEAL_TYPE_SELL &&
          dmagic == MAGIC_S[i]))
      {
         MyPos[i].ticket = ticket;
         MyPos[i].lots = dlots;
         if(dtype == DEAL_TYPE_SELL)
            MyPos[i].lots = -MyPos[i].lots;
         MyPos[i].price = dprice;
         MyPos[i].time = dtime;
         ShowOpenPosition(otype, MyPos[i]);
         break;
      }
   }
   return(true);
}

// show open position
void ShowOpenPosition(ENUM_ORDER_TYPE type,
                      MyPosition &pos)
{
   // buy position is opened
   if(type == ORDER_TYPE_BUY)
   {
      string oname = "#"+IntegerToString(pos.ticket)+
         " buy "+DoubleToString(MathAbs(pos.lots),2)+
         " "+_Symbol+" at "+
         DoubleToString(pos.price, _Digits);
      if(ObjectFind(0, oname) < 0)
         ObjectCreate(0, oname, OBJ_ARROW_BUY, 0,
                      pos.time, pos.price);
   }
   // sell position is opened
   if(type == ORDER_TYPE_SELL)
   {
      string oname = "#"+IntegerToString(pos.ticket)+
         " sell "+DoubleToString(MathAbs(pos.lots),2)+
         " "+_Symbol+" at "+
         DoubleToString(pos.price, _Digits);
      if(ObjectFind(0, oname) < 0)
         ObjectCreate(0, oname, OBJ_ARROW_SELL, 0,
                      pos.time, pos.price);
   }
}

// show closed position
void ShowClosePosition(ENUM_ORDER_TYPE type,
                       MyPosition &openpos,
                       MyPosition &pos)
{
   color ocolor = clrNONE;
   // buy position is closed
   if(type == ORDER_TYPE_SELL)
   {
      string oname = "#"+IntegerToString(pos.ticket)+
         " sell "+DoubleToString(MathAbs(pos.lots),2)+
         " "+_Symbol+" at "+
         DoubleToString(pos.price, _Digits);
      if(ObjectFind(0, oname) < 0)
         ObjectCreate(0, oname, OBJ_ARROW_SELL, 0,
                      pos.time, pos.price);
      ocolor = clrBuy;
   }
   // sell position is closed
   if(type == ORDER_TYPE_BUY)
   {
      string oname = "#"+IntegerToString(pos.ticket)+
         " buy "+DoubleToString(MathAbs(pos.lots),2)+
         " "+_Symbol+" at "+
         DoubleToString(pos.price, _Digits);
      if(ObjectFind(0, oname) < 0)
         ObjectCreate(0, oname, OBJ_ARROW_BUY, 0,
                      pos.time, pos.price);
      ocolor = clrSell;
   }
   // show line from open to close
   string oname = "#"+IntegerToString(openpos.ticket)+
      " -> #" + IntegerToString(pos.ticket);   
   if(ObjectFind(0, oname) < 0)
   {
      ObjectCreate(0, oname, OBJ_TREND, 0, openpos.time,
                   openpos.price, pos.time, pos.price); 
      ObjectSetInteger(0, oname, OBJPROP_COLOR, ocolor);
      ObjectSetInteger(0, oname, OBJPROP_STYLE, STYLE_DOT);
   }
}

// show position line
void ShowPositionLine()
{
   for(int i=0; i<POSITIONS; i++)
   {
      // for open positions
      if(MyPos[i].ticket > 0) 
      {
         color cline = clrBuy;
         if(MyPos[i].lots < 0) cline = clrSell;
         ObjectSetInteger(0, Gvar[i]+"H",
            OBJPROP_COLOR, cline);
         ObjectSetDouble(0, Gvar[i]+"H",
            OBJPROP_PRICE, MyPos[i].price);
         ObjectSetInteger(0, Gvar[i]+"H",
            OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
      }
      // hide position line for closed positions
      else ObjectSetInteger(0, Gvar[i]+"H",
              OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS); 
   }


   ChartRedraw(0);
}

// get filling mode
ENUM_ORDER_TYPE_FILLING OrderFilling()
{
   long filling_mode = SymbolInfoInteger(_Symbol,
                       SYMBOL_FILLING_MODE);
   if(filling_mode%2 != 0) return(ORDER_FILLING_FOK);
   else if(filling_mode%4 != 0) return(ORDER_FILLING_IOC);
   return(ORDER_FILLING_RETURN);
}

// send order to open position
bool MyOrderSend(int pos_id, ENUM_ORDER_TYPE type,
                 double lots, double price, double sl,
                 double tp, string comment="")
{
   price = NormalizeDouble(price, _Digits);
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);
   if(comment == "") comment = Gvar[pos_id];
   bool ret = false;
   switch(type)
   {
      case ORDER_TYPE_BUY:
      case ORDER_TYPE_SELL:
         ret = OrderSendMarket(pos_id, type, lots, sl,
                               tp, comment);
         break;
      case ORDER_TYPE_BUY_STOP:
      case ORDER_TYPE_BUY_LIMIT:
      case ORDER_TYPE_SELL_STOP:
      case ORDER_TYPE_SELL_LIMIT:
         ret = OrderSendPending(pos_id, type, lots, price,
                                sl, tp, comment);
         break;
      default:
         Print("MyOrderSend : Unsupported type");
         break;
   }
   return(ret);
}

// send market order to open position
bool OrderSendMarket(int i, ENUM_ORDER_TYPE type,
                     double lots, double sl,
                     double tp, string comment)
{
   if(MyOrderType(i) != ORDER_TYPE_NONE) return(true);
   // for no position or order
   MqlTradeRequest request={0};
   MqlTradeResult result={0}; 
   // refresh rate
   double bid, ask;
   RefreshPrice(bid, ask);
   // order request
   if(type == ORDER_TYPE_BUY)
   {
      request.price = ask;
      request.magic = MAGIC_B[i];
   }
   else if(type == ORDER_TYPE_SELL)
   {
      request.price = bid;
      request.magic = MAGIC_S[i];
   }
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lots;
   request.deviation = Slippage;
   request.type = type;
   request.type_filling = OrderFilling();
   request.comment = comment;
   OrderSend(request,result);
   // order completed
   if(result.retcode == TRADE_RETCODE_DONE)
   {
      MyPos[i].ticket = result.deal;
      MyPos[i].lots = result.volume;
      MyPos[i].price = result.price;
      MyPos[i].time = TimeCurrent();
      if(type == ORDER_TYPE_SELL)
         MyPos[i].lots = -MyPos[i].lots;
   }
   // order placed
   else if(result.retcode == TRADE_RETCODE_PLACED)
   {
      int m;
      for(m=0; m<10; m++)
      {
         Sleep(1000);
         if(RetrieveOpenPosition(i)) break;
      }
      if(m==10) Print("MyOrderSendMarket : No open"+
                      " positions exist");
   }
   // order error
   else
   {
      Print("MyOrderSendMarket : ", result.retcode, " ",
            RetcodeDescription(result.retcode));
      return(false);
   }
   // show open position
   ShowOpenPosition(type, MyPos[i]);
   // send SL and TP orders
   if(sl > 0 && !OrderModifyPending(i, sl, "SL"))
      GlobalVariableSet(Gvar[i]+"SL", sl);
   if(tp > 0 && !OrderModifyPending(i, tp, "TP"))
      GlobalVariableSet(Gvar[i]+"TP", tp);
   return(true);
}

// send pending order to open position
bool OrderSendPending(int i, ENUM_ORDER_TYPE type,
                      double lots, double price, double sl,
                      double tp, string comment)
{
   if(MyPos[i].ticket > 0) return(true);
   // for no open position
   if(MyPos[i].order_limit > 0 &&
     (type == ORDER_TYPE_BUY_LIMIT ||
      type == ORDER_TYPE_SELL_LIMIT)) return(true);
   if(MyPos[i].order_stop > 0 &&
     (type == ORDER_TYPE_BUY_STOP ||
      type == ORDER_TYPE_SELL_STOP)) return(true);
   // for non-existing pending order 
   MqlTradeRequest request={0};
   MqlTradeResult result={0}; 
   // order request
   if(type == ORDER_TYPE_BUY_LIMIT ||
      type == ORDER_TYPE_BUY_STOP)
      request.magic = MAGIC_B[i];
   else if(type == ORDER_TYPE_SELL_LIMIT ||
           type == ORDER_TYPE_SELL_STOP)
           request.magic = MAGIC_S[i];
   request.action = TRADE_ACTION_PENDING;
   request.symbol = _Symbol;
   request.volume = lots;
   request.type = type;
   request.price = price;
   request.type_filling = OrderFilling();
   request.type_time = ORDER_TIME_GTC;
   request.comment = comment;
   OrderSend(request,result);
   // order completed
   if(result.retcode == TRADE_RETCODE_DONE)
   {
      if(type == ORDER_TYPE_BUY_STOP ||
         type == ORDER_TYPE_SELL_STOP)
         MyPos[i].order_stop = result.order;
      if(type == ORDER_TYPE_BUY_LIMIT ||
         type == ORDER_TYPE_SELL_LIMIT)
         MyPos[i].order_limit = result.order;
   }
   // order placed
   else if(result.retcode == TRADE_RETCODE_PLACED)
   {
      int m;
      for(m=0; m<10; m++)
      {
         Sleep(1000);
         if(RetrieveOrder(i)) break;
      }
      if(m==10) Print("MyOrderSendPending : No orders"+
                      " exist");
   }
   // order error
   else
   {
      Print("MyOrderSendPending : ", result.retcode, " ",
            RetcodeDescription(result.retcode));
      return(false);
   }
   // save SL and TP orders
   if(sl > 0) GlobalVariableSet(Gvar[i]+"SL", sl);
   if(tp > 0) GlobalVariableSet(Gvar[i]+"TP", tp);
   return(true);
}

// send close order
bool MyOrderClose(int pos_id)
{
   if(MyPos[pos_id].ticket == 0) return(true);
   // for open position
   MqlTradeRequest request={0};
   MqlTradeResult result={0}; 
   MyPosition pos;
   // refresh rate
   double bid, ask;
   RefreshPrice(bid, ask);
   // order request
   double lots = MyPos[pos_id].lots;
   if(lots > 0)
   {
      request.type = ORDER_TYPE_SELL;
      request.magic = MAGIC_B[pos_id];
      request.price = bid;
   }
   else if(lots < 0)
   {
      request.type = ORDER_TYPE_BUY;
      request.magic = MAGIC_S[pos_id];
      request.price = ask;
   }
   else return(true);
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.deviation = Slippage;
   request.volume = MathAbs(lots);
   request.comment                                  // debug del
      = HistoryDealGetString(MyPos[pos_id].ticket,
                             DEAL_COMMENT);
   if(request.comment == "")
      request.comment = Gvar[pos_id];    // debug del
   request.type_filling = OrderFilling();
   
   Print("================pre close");
   MyOrderPrint(pos_id);
   Print("↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑pre close");
   bool success=OrderSend(request,result);
   Print("================aft close");
   MyOrderPrint(pos_id);
   Print("↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑aft close");
    TMyOrderSend(request,result,success) ;   //debug
   // order completed
   if(result.retcode == TRADE_RETCODE_DONE)
   {
      pos.ticket = result.deal;
      pos.price = result.price;
      pos.time = TimeCurrent();
   }
   // order placed
   else if(result.retcode == TRADE_RETCODE_PLACED)
   {
      int m;
      for(m=0; m<10; m++)
      {
         Sleep(1000);
         if(RetrieveClosePosition(pos_id, pos)) break;
      }
      if(m==10) Print("MyOrderClose : No closed orders"+
                      " exist");
   }
   // order error
   else
   {
      Print("MyOrderClose : ", result.retcode, " ",
            RetcodeDescription(result.retcode));
      return(false);
   }
   // show closed position
   ShowClosePosition(request.type, MyPos[pos_id], pos);
   // delete SL and TP orders
   if(MyPos[pos_id].order_stop > 0)
      SubOrderDelete(MyPos[pos_id].order_stop);
   if(MyPos[pos_id].order_limit > 0)
      SubOrderDelete(MyPos[pos_id].order_limit);
   ZeroMemory(MyPos[pos_id]);
   return(true);
}

// delete pending order
bool MyOrderDelete(int pos_id)
{
   if(MyPos[pos_id].ticket > 0) return(true);
   // for pending order
   bool ret = true;
   if(MyPos[pos_id].order_stop > 0 &&
     (ret=SubOrderDelete(MyPos[pos_id].order_stop)))
      MyPos[pos_id].order_stop = 0;
   if(MyPos[pos_id].order_limit > 0 &&
     (ret=SubOrderDelete(MyPos[pos_id].order_limit)))
      MyPos[pos_id].order_limit = 0;
   if(ret && GlobalVariableCheck(Gvar[pos_id]+"SL"))
      GlobalVariableDel(Gvar[pos_id]+"SL");
   if(ret && GlobalVariableCheck(Gvar[pos_id]+"TP"))
      GlobalVariableDel(Gvar[pos_id]+"TP");
   return(ret);
}

// delete pending order sub-function
bool SubOrderDelete(ulong order)
{
   if(order == 0) return(true);
   // for pending order
   MqlTradeRequest request={0};
   MqlTradeResult result={0}; 
   // order request
   request.action = TRADE_ACTION_REMOVE;
   request.order = order;
   OrderSend(request,result);
   // order completed
   if(result.retcode == TRADE_RETCODE_DONE) return(true);
   // order placed
   else if(result.retcode == TRADE_RETCODE_PLACED)
   {
      Sleep(1000);
      return(true);
   }
   // order error
   else
   {
      Print("MyOrderDelete : ", result.retcode, " ",
            RetcodeDescription(result.retcode));
      return(false);
   }
}

// modify order
bool MyOrderModify(int pos_id, double price, double sl,
                   double tp)
{
   bool ret = true;
   price = NormalizeDouble(price, _Digits);
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);
   // for open position
   if(MyPos[pos_id].ticket > 0)
   {
      if(sl > 0) ret = OrderModifyPending(pos_id, sl, "SL");
      if(tp > 0) ret = OrderModifyPending(pos_id, tp, "TP");
   }
   // for stop order
   else if(MyPos[pos_id].order_stop > 0)
   {
      if(price > 0)
         ret = SubOrderModify(MyPos[pos_id].order_stop,
                              price);
      if(sl > 0) GlobalVariableSet(Gvar[pos_id]+"SL", sl);
      if(tp > 0) GlobalVariableSet(Gvar[pos_id]+"TP", tp);
   }
   // for limit order
   else if(MyPos[pos_id].order_limit > 0)
   {
      if(price > 0)
         ret = SubOrderModify(MyPos[pos_id].order_limit,
                              price);
      if(sl > 0) GlobalVariableSet(Gvar[pos_id]+"SL", sl);
      if(tp > 0) GlobalVariableSet(Gvar[pos_id]+"TP", tp);
   }
   return(ret);
}

// order modify sub-function(new SL/TP)
bool OrderModifyPending(int i, double price, string comment)
{
   if(MyPos[i].ticket == 0 || price == 0) return(true);
   // for open position
   MqlTradeRequest request={0};
   MqlTradeResult result={0}; 
   // refresh rate
   double bid, ask;
   RefreshPrice(bid, ask);
   // order request
   double lots = MyPos[i].lots;
   if(lots > 0)
   {
      request.magic = MAGIC_B[i];
      if(comment == "SL")
         request.type = ORDER_TYPE_SELL_STOP;
      if(comment == "TP")
         request.type = ORDER_TYPE_SELL_LIMIT;
   }
   else if(lots < 0)
   {
      request.magic = MAGIC_S[i];
      if(comment == "SL")
         request.type = ORDER_TYPE_BUY_STOP;
      if(comment == "TP")
         request.type = ORDER_TYPE_BUY_LIMIT;
   }
   else return(true);
   // for existing SL order
   if(MyPos[i].order_stop > 0 &&
     (request.type == ORDER_TYPE_BUY_STOP ||
      request.type == ORDER_TYPE_SELL_STOP))
   {
      SubOrderModify(MyPos[i].order_stop, price);
      return(true);
   }
   // for existing TP order
   if(MyPos[i].order_limit > 0 &&
     (request.type == ORDER_TYPE_BUY_LIMIT ||
      request.type == ORDER_TYPE_SELL_LIMIT))
   {
      SubOrderModify(MyPos[i].order_limit, price);
      return(true);
   }
   request.action = TRADE_ACTION_PENDING;
   request.symbol = _Symbol;
   request.volume = MathAbs(lots);
   request.price = price;
   request.type_filling = OrderFilling();
   request.type_time = ORDER_TIME_GTC;
   request.comment = HistoryDealGetString(MyPos[i].ticket,
                                          DEAL_COMMENT);
   if(request.comment == "") request.comment = Gvar[i];
   request.comment = request.comment + comment;
   OrderSend(request,result);
   // order completed
   if(result.retcode == TRADE_RETCODE_DONE)
   {
      if(request.type == ORDER_TYPE_BUY_STOP ||
         request.type == ORDER_TYPE_SELL_STOP)
         MyPos[i].order_stop = result.order;
      if(request.type == ORDER_TYPE_BUY_LIMIT ||
         request.type == ORDER_TYPE_SELL_LIMIT)
         MyPos[i].order_limit = result.order;
   }
   // order placed
   else if(result.retcode == TRADE_RETCODE_PLACED)
   {
      int m;
      for(m=0; m<10; m++)
      {
         Sleep(1000);
         if(RetrieveOrder(i)) break;
      }
      if(m==10) Print("MyOrderModifyPending : No orders"+
                      " exist");
   }
   // order error
   else
   {
      Print("MyOrderModifyPending : ", result.retcode,
            " ", RetcodeDescription(result.retcode));
      return(false);
   }
   return(true);
}

// modify order sub-function(modify SL/TP)
bool SubOrderModify(ulong order, double price)
{
   if(order == 0 || price == 0) return(true);
   if(OrderSelect(order) &&
      OrderGetDouble(ORDER_PRICE_OPEN) == price)
      return(true);
   // for pending order with SL/TP
   MqlTradeRequest request={0};
   MqlTradeResult result={0}; 
   // order request
   request.action = TRADE_ACTION_MODIFY;
   request.order = order;
   request.price = price;
   request.type_time = ORDER_TIME_GTC;
   OrderSend(request,result);
   // order completed
   if(result.retcode == TRADE_RETCODE_DONE) return(true);
   // order placed
   else if(result.retcode == TRADE_RETCODE_PLACED)
   {
      Sleep(1000);
      return(true);
   }
   // order error
   else
   {
      Print("MyOrderModify : ", result.retcode, " ",
            RetcodeDescription(result.retcode));
      return(false);
   }
}

// get order type
ENUM_ORDER_TYPE MyOrderType(int pos_id)
{
   ENUM_ORDER_TYPE type = ORDER_TYPE_NONE;
   if(MyPos[pos_id].ticket > 0)
   {
      if(MyPos[pos_id].lots > 0) type = ORDER_TYPE_BUY;
      if(MyPos[pos_id].lots < 0) type = ORDER_TYPE_SELL;
   }
   else if(OrderSelect(MyPos[pos_id].order_stop))
      type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
   else if(OrderSelect(MyPos[pos_id].order_limit))
      type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
   return(type);
}

// get order lots
double MyOrderLots(int pos_id)
{
   double lots = 0;
   if(MyPos[pos_id].ticket > 0)
      lots = MathAbs(MyPos[pos_id].lots);
   else if(OrderSelect(MyPos[pos_id].order_stop))
      lots = OrderGetDouble(ORDER_VOLUME_CURRENT);
   else if(OrderSelect(MyPos[pos_id].order_limit))
      lots = OrderGetDouble(ORDER_VOLUME_CURRENT);
   return(lots);   
}

// get signed lots of open position
double MyOrderOpenLots(int pos_id)
{
   double lots = 0;
   if(MyPos[pos_id].ticket > 0) lots = MyPos[pos_id].lots;
   return(lots);   
}

// get order open price
double MyOrderOpenPrice(int pos_id)
{
   double price = 0;
   if(MyPos[pos_id].ticket > 0)
      price = MyPos[pos_id].price;
   else if(OrderSelect(MyPos[pos_id].order_stop))
      price = OrderGetDouble(ORDER_PRICE_OPEN);
   else if(OrderSelect(MyPos[pos_id].order_limit))
      price = OrderGetDouble(ORDER_PRICE_OPEN);
   return(price);   
}

// get order open time
datetime MyOrderOpenTime(int pos_id)
{
   datetime opentime = 0;
   if(MyPos[pos_id].ticket > 0)
      opentime = MyPos[pos_id].time;
   else if(OrderSelect(MyPos[pos_id].order_stop))
      opentime = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
   else if(OrderSelect(MyPos[pos_id].order_limit))
      opentime = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
   return(opentime);
}

// get order stop loss
double MyOrderStopLoss(int pos_id)
{
   double sl = 0;
   if(MyPos[pos_id].ticket > 0)
   {
      if(OrderSelect(MyPos[pos_id].order_stop))
         sl = OrderGetDouble(ORDER_PRICE_OPEN);
   }
   else if(OrderSelect(MyPos[pos_id].order_stop))
      sl = GlobalVariableGet(Gvar[pos_id]+"SL");
   else if(OrderSelect(MyPos[pos_id].order_limit))
      sl = GlobalVariableGet(Gvar[pos_id]+"SL");
   return(sl);
}

// get order take profit
double MyOrderTakeProfit(int pos_id)
{
   double tp = 0;
   if(MyPos[pos_id].ticket > 0)
   {
      if(OrderSelect(MyPos[pos_id].order_limit))
         tp = OrderGetDouble(ORDER_PRICE_OPEN);
   }
   else if(OrderSelect(MyPos[pos_id].order_stop))
      tp = GlobalVariableGet(Gvar[pos_id]+"TP");
   else if(OrderSelect(MyPos[pos_id].order_limit))
      tp = GlobalVariableGet(Gvar[pos_id]+"TP");
   return(tp);
}

// get close price of open position
double MyOrderClosePrice(int pos_id)
{
   double bid, ask;
   RefreshPrice(bid, ask);
   double price = 0;
   if(MyPos[pos_id].lots > 0) price = bid;
   if(MyPos[pos_id].lots < 0) price = ask;
   return(price);
}

// get profit of open position
double MyOrderProfit(int pos_id)
{
   return(MyOrderProfitPips(pos_id)
      *SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE)
      *SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE)
      *MyOrderLots(pos_id)*0.0001);
}

// get profit of open position in pips
double MyOrderProfitPips(int pos_id)
{
   double profit = 0;
   if(MyPos[pos_id].lots > 0)
      profit = MyOrderClosePrice(pos_id)-MyPos[pos_id].price;
   if(MyPos[pos_id].lots < 0)
      profit = MyPos[pos_id].price-MyOrderClosePrice(pos_id);
   return(profit/PipPoint);
}

// print order information
void MyOrderPrint(int pos_id)
{
   double minlots = SymbolInfoDouble(_Symbol,
                                     SYMBOL_VOLUME_MIN);
   int lots_digits = (int)(MathLog10(1.0/minlots));
   string stype[] = {"buy", "sell", "buy limit",
                     "sell limit", "buy stop", "sell stop"};
   string s = "MyPos[" + IntegerToString(pos_id) + "] ";
   if(MyOrderType(pos_id) == OP_NONE) s = s + "No position";
   else
   {
      s = s + "#";
      if(MyPos[pos_id].ticket > 0)
         s = s + IntegerToString(MyPos[pos_id].ticket);
      else if(MyPos[pos_id].order_limit > 0)
         s = s + IntegerToString(MyPos[pos_id].order_limit);
      else if(MyPos[pos_id].order_stop > 0)
         s = s + IntegerToString(MyPos[pos_id].order_stop);
      s = s + " ["
            + TimeToString(MyOrderOpenTime(pos_id))
            + "] "
            + stype[MyOrderType(pos_id)]
            + " "
            + DoubleToString(MyOrderLots(pos_id),
                             lots_digits)
            + " "
            + Symbol()
            + " at " 
            + DoubleToString(MyOrderOpenPrice(pos_id),
                             _Digits);
      if(MyOrderStopLoss(pos_id) != 0)
         s = s + " sl " 
               + DoubleToString(MyOrderStopLoss(pos_id),
                                _Digits);
      if(MyOrderTakeProfit(pos_id) != 0)
         s = s + " tp "
               + DoubleToString(MyOrderTakeProfit(pos_id),
                                _Digits);
      s = s + " magic ";
      if(MyOrderType(pos_id) % 2 == 0)
         s = s + IntegerToString( MAGIC_B[pos_id]);
      else s = s + IntegerToString(MAGIC_S[pos_id]);
   }
   Print(s);
}

// OrderSend retcode description
string RetcodeDescription(int retcode)
{
   switch(retcode)
   {
      case TRADE_RETCODE_REQUOTE:
           return("Requote");
      case TRADE_RETCODE_REJECT:
           return("Request rejected");
      case TRADE_RETCODE_CANCEL:
           return("Request canceled by trader");
      case TRADE_RETCODE_PLACED:
           return("Order placed");
      case TRADE_RETCODE_DONE:
           return("Request completed");
      case TRADE_RETCODE_DONE_PARTIAL:
           return("Only part of the request was"+
                  " completed");
      case TRADE_RETCODE_ERROR:
           return("Request processing error");
      case TRADE_RETCODE_TIMEOUT:
           return("Request canceled by timeout");
      case TRADE_RETCODE_INVALID:
           return("Invalid request");
      case TRADE_RETCODE_INVALID_VOLUME:
           return("Invalid volume in the request");
      case TRADE_RETCODE_INVALID_PRICE:
           return("Invalid price in the request");
      case TRADE_RETCODE_INVALID_STOPS:
           return("Invalid stops in the request");
      case TRADE_RETCODE_TRADE_DISABLED:
           return("Trade is disabled");
      case TRADE_RETCODE_MARKET_CLOSED:
           return("Market is closed");
      case TRADE_RETCODE_NO_MONEY:
           return("There is not enough money to"+
                  " complete the request");
      case TRADE_RETCODE_PRICE_CHANGED:
           return("Prices changed");
      case TRADE_RETCODE_PRICE_OFF:
           return("There are no quotes to process the"+
                  " request");
      case TRADE_RETCODE_INVALID_EXPIRATION:
           return("Invalid order expiration date in"+
                  " the request");
      case TRADE_RETCODE_ORDER_CHANGED:
           return("Order state changed");
      case TRADE_RETCODE_TOO_MANY_REQUESTS:
           return("Too frequent requests");
      case TRADE_RETCODE_NO_CHANGES:
           return("No changes in request");
      case TRADE_RETCODE_SERVER_DISABLES_AT:
           return("Autotrading disabled by server");
      case TRADE_RETCODE_CLIENT_DISABLES_AT:
           return("Autotrading disabled by client"+
                  " terminal");
      case TRADE_RETCODE_LOCKED:
           return("Request locked for processing");
      case TRADE_RETCODE_FROZEN:
           return("Order or position frozen");
      case TRADE_RETCODE_INVALID_FILL:
           return("Invalid order filling type");
      case TRADE_RETCODE_CONNECTION:
           return("No connection with the trade"+
                  " server");
      case TRADE_RETCODE_ONLY_REAL:
           return("Operation is allowed only for live"+
                  " accounts");
      case TRADE_RETCODE_LIMIT_ORDERS:
           return("The number of pending orders has"+
                  " reached the limit");
      case TRADE_RETCODE_LIMIT_VOLUME:
           return("The volume of orders and positions"+
                  " has reached the limit");
   }
   return(IntegerToString(retcode) +
          " Unknown Retcode");
}
//+------------------------------------------------------------------+ 
//| 結果処理と取引リクエストを送信する                                        | 
//+------------------------------------------------------------------+ 
bool TMyOrderSend(MqlTradeRequest &request,MqlTradeResult &result,bool success) 
 { 
//--- 最後のエラーコードをゼロにリセットする 
  //ResetLastError(); 
//--- リクエストを送信する 
  //bool success=OrderSend(request,result); 
//--- 失敗したら、理由を見つける 
  if(!success) 
    { 
    int answer=result.retcode; 
    Print("TradeLog: Trade request failed. Error = ",GetLastError()); 
    switch(answer) 
       { 
        //--- リクオート 
        case 10004: 
          { 
          Print("TRADE_RETCODE_REQUOTE"); 
          Print("request.price = ",request.price,"   result.ask = ", 
                 result.ask," result.bid = ",result.bid); 
          break; 
          } 
        //--- 注文がサーバに受け入れられない 
        case 10006: 
          { 
          Print("TRADE_RETCODE_REJECT"); 
          Print("request.price = ",request.price,"   result.ask = ", 
                 result.ask," result.bid = ",result.bid); 
          break; 
          } 
        //--- 無効な価格 
        case 10015: 
          { 
          Print("TRADE_RETCODE_INVALID_PRICE"); 
          Print("request.price = ",request.price,"   result.ask = ", 
                 result.ask," result.bid = ",result.bid); 
          break; 
          } 
        //--- 無効な SL 及び/または TP 
        case 10016: 
          { 
          Print("TRADE_RETCODE_INVALID_STOPS"); 
          Print("request.sl = ",request.sl," request.tp = ",request.tp); 
          Print("result.ask = ",result.ask," result.bid = ",result.bid); 
          break; 
          } 
        //--- 無効なボリューム 
        case 10014: 
          { 
          Print("TRADE_RETCODE_INVALID_VOLUME"); 
          Print("request.volume = ",request.volume,"   result.volume = ", 
                 result.volume); 
          break; 
          } 
        //--- 取引操作に不充分なメモリ 
        case 10019: 
          { 
          Print("TRADE_RETCODE_NO_MONEY"); 
          Print("request.volume = ",request.volume,"   result.volume = ", 
                 result.volume,"   result.comment = ",result.comment); 
          break; 
          } 
        //--- 他の理由。サーバ応答コードを出力する 
        default: 
          { 
          Print("Other answer = ",answer); 
          } 
       } 
    //--- false を返して、取引リクエストの失敗結果を通知する 
    return(false); 
    } 
//--- OrderSend() が true を返す。- 答えを繰り返す。 
  return(true); 
 }
 
 
 
 
 //+------------------------------------------------------------------+
//| 全てのポジションを決済                                                  |
//+------------------------------------------------------------------+

ulong OrderTicket(int i){
   return(PositionGetTicket(i));
}

datetime 
OrderOpenTime 
(){ return ( PositionGetInteger(
POSITION_TIME
));}
 
double 
OrderLots 
(){ return ( PositionGetDouble(
POSITION_VOLUME
));}

ENUM_POSITION_TYPE    
// POSITION_TYPE_BUY 買い。POSITION_TYPE_SELL 売り。 
OrderType 
(){ return ( PositionGetInteger(
POSITION_TYPE
));}


string 
OrderSymbol 
(){ return ( PositionGetString(
POSITION_SYMBOL
));}


double 
OrderOpenPrice 
(){ return ( PositionGetDouble(
POSITION_PRICE_OPEN
));}



#define EXPERT_MAGIC 123456   // エキスパートアドバイザのMagicNumber
void DelPosition()
 {
//--- 結果とリクエストの宣言
  MqlTradeRequest request;
  MqlTradeResult  result;
  int total=PositionsTotal(); //　保有ポジション数   
//--- 全ての保有ポジションの取捨
  for(int i=total-1; i>=0; i--)
    {
    //--- 注文のパラメータ
    ulong  position_ticket=PositionGetTicket(i);                                     // ポジションチケット
    string position_symbol=PositionGetString(POSITION_SYMBOL);                       // シンボル 
    int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);             // 小数点以下の桁数
    ulong  magic=PositionGetInteger(POSITION_MAGIC);                                 // ポジションのMagicNumber
    double volume=PositionGetDouble(POSITION_VOLUME);                                 // ポジションボリューム
    ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);   // ポジションタイプ
    //--- ポジション情報の出力
    PrintFormat("#%I64u %s  %s  %.2f  %s [%I64d]",
                 position_ticket,
                 position_symbol,
                EnumToString(type),
                 volume,
                DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),digits),
                 magic);
    //--- MagicNumberが一致している場合
    if(magic==EXPERT_MAGIC)
       {
        //--- リクエストと結果の値のゼロ化
        ZeroMemory(request);
        ZeroMemory(result);
        //--- 操作パラメータの設定
        request.action   =TRADE_ACTION_DEAL;       // 取引操作タイプ
        request.position =position_ticket;         // ポジションチケット
        request.symbol   =position_symbol;         // シンボル 
        request.volume   =volume;                   // ポジションボリューム
        request.deviation=5;                       // 価格からの許容偏差
        request.magic    =EXPERT_MAGIC;             // ポジションのMagicNumber
        //--- ポジションタイプによる注文タイプと価格の設定
        if(type==POSITION_TYPE_BUY)
          {
           request.price=SymbolInfoDouble(position_symbol,SYMBOL_BID);
           request.type =ORDER_TYPE_SELL;
          }
        else
          {
           request.price=SymbolInfoDouble(position_symbol,SYMBOL_ASK);
           request.type =ORDER_TYPE_BUY;
          }
        //--- 決済情報の出力
        PrintFormat("Close #%I64d %s %s",position_ticket,position_symbol,EnumToString(type));
        //--- リクエストの送信
        if(!OrderSend(request,result))
          PrintFormat("OrderSend error %d",GetLastError()); // リクエストの送信に失敗した場合、エラーコードを出力
        //--- 操作情報  
        PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
        //---
       }
    }
 }