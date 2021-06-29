double local_min_price;//tmp　エントリーから最安値
double local_max_price;//tmp　エントリーから最高値

#ifndef OP_SELL
               #define OP_SELL ORDER_TYPE_SELL_STOP_LIMIT
               #define OP_BUY ORDER_TYPE_BUY_STOP_LIMIT
#endif //OP_SELL          

#include <Expert\Signal\SignalITF.mqh>
extern bool flagNotTrade;
               //-----------------------------------------------------------------------------------------------------------
               bool RefreshPrice(double &bid, double &ask)
               {
                  MqlTick tick;
                  if(!SymbolInfoTick(_Symbol, tick)) return(false);
                  if(tick.bid <= 0 || tick.ask <= 0) return(false);
                  bid = tick.bid;
                  ask = tick.ask;
                  return(true);
               }
               
               
               // add iwa 
               // MQL4=>MQL5 変換関数
               long OrderTicket(){
                  return(PositionGetInteger(POSITION_TICKET));
               }
               
               datetime 
               OrderOpenTime (){ return ( (datetime)PositionGetInteger(
               POSITION_TIME
               ));}
                
               double 
               OrderLots 
               (){ return ( PositionGetDouble(
               POSITION_VOLUME
               ));}
               
               // POSITION_TYPE_BUY 買い。POSITION_TYPE_SELL 売り。 
               ENUM_POSITION_TYPE   
               //ENUM_ORDER_TYPE 
               OrderType 
               (){ return ( (ENUM_POSITION_TYPE)PositionGetInteger(
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
               
               double AccountBalance(){
               //return (Balance());
               return(10000.0); // 暫定　add iwa chg temp
               }
               
               
               //!OrderClose(OrderTicket(),OrderLots(),bid,3,Violet))
               
               
bool OrderClose(
int ticket,//
double lots,//
double price,
int slippage,
color arrow_color,///---
string str_comment
){
               
               // Selectしてあることが前提
               
               
               
               //--- 結果とリクエストの宣言
                 MqlTradeRequest request;
                 MqlTradeResult  result;
                 int total=PositionsTotal(); //　保有ポジション数   
                 bool ret = true;
               //--- 全ての保有ポジションの取捨
                // for(int i=total-1; i>=0; i--)
                   {
                   //--- 注文のパラメータ
                   // ulong  position_ticket=PositionGetTicket(i);                                     // ポジションチケット
                   ulong  position_ticket = ticket;                                     // ポジションチケット
                   string position_symbol=PositionGetString(POSITION_SYMBOL);                       // シンボル 
                   int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);             // 小数点以下の桁数
                   ulong  magic=PositionGetInteger(POSITION_MAGIC);                                 // ポジションのMagicNumber
                   //double volume=PositionGetDouble(POSITION_VOLUME);                                 // ポジションボリューム
                   double volume=lots;                                 // ポジションボリューム
                   ENUM_POSITION_TYPE type1=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);   // ポジションタイプ
                   //--- ポジション情報の出力
                   PrintFormat("#%I64u %s  %s  %.2f  %s [%I64d]",
                                position_ticket,
                                position_symbol,
                               EnumToString(type1),
                                volume,
                               DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),digits),
                                magic);
                   //--- MagicNumberが一致している場合
                   if(magic==EXPERT_MAGIC)
                      {
						//string str_comment = GetStrSlowBandHigh();//★★★
                       //--- リクエストと結果の値のゼロ化
                       ZeroMemory(request);
                       ZeroMemory(result);
                       //--- 操作パラメータの設定
                       request.action   =TRADE_ACTION_DEAL;       // 取引操作タイプ
                       request.position =position_ticket;         // ポジションチケット
                       request.symbol   =position_symbol;         // シンボル 
                       request.comment = str_comment;
                       request.volume   =volume;                   // ポジションボリューム
                       request.deviation=5;                       // 価格からの許容偏差
                       request.magic    =EXPERT_MAGIC;             // ポジションのMagicNumber
                       //--- ポジションタイプによる注文タイプと価格の設定
                       if(type1==POSITION_TYPE_BUY)
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
                       PrintFormat("Close #%I64d %s %s",position_ticket,position_symbol,EnumToString(type1));
                       //--- リクエストの送信
                       
                       if(!OrderSend(request,result))
                         PrintFormat("OrderSend error %d",GetLastError()); // リクエストの送信に失敗した場合、エラーコードを出力
                       //--- 操作情報  
                       PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
                       //---
                       	         flagNotTrade = false;

                      }
                      else{ ret =false;}
                   }
                   return(ret);
                }
                
                
bool OrderSelect(int numb,int nSELECT_BY_TICKET,int nMODE_TRADES){
return(OrderSelect( numb));
}
 
 //numb = OrderSend(Symbol(),  OP_BUY,Lots,ask,3,sl_buy,tp_buy,"Reduce_risks",16384,0,Green); 
int  OrderSend
 //( string mySymbol,  int nOP_BUY,double nLots,double n_ask,double slipage, double sl_buy,double tp_buy,string scomment, ctrnnn);
(
                  string symbol1,
                  int cmd,
                  double volume,
                  double price,
                  int slippage,
                  double stoploss,
                  double takeprofit,
                  string comment=NULL,
                  int magic=0,
                  datetime expiration=0,
                  color arrow_color=clrNONE
               ){
               
                  int ret=0;
                  if( cmd == ORDER_TYPE_BUY||cmd == ORDER_TYPE_BUY_STOP_LIMIT){
                     ret = (int)MYbuyOrder(symbol1,cmd,volume,price,slippage,stoploss,takeprofit,comment,magic,expiration,arrow_color);
                  }
                  else if( cmd == ORDER_TYPE_SELL||cmd == ORDER_TYPE_SELL_STOP_LIMIT){
                     ret = (int)MYsellOrder(symbol1,cmd,volume,price,slippage,stoploss,takeprofit,comment,magic,expiration,arrow_color);
                  
                  
                  }
               
                 return(ret);
               } 
               
               

// uint MYbuyOrder(double volume) 
uint MYbuyOrder(
   string symbol1,
   int cmd,
   double volume,
   double price,
   int slippage,
   double stoploss,
   double takeprofit,
   string comment=NULL,
   int magic=0,
   datetime expiration=0,
   color arrow_color=clrNONE
)
 { 
               //--- リクエストと結果の宣言と初期化
                 //MqlTradeRequest request={0};//chg 20210624 start
                 MqlTradeRequest request;
                 //chg 20210624 end
                 MqlTradeResult  result={0};
               //--- リクエストのパラメータ
               //  request.action   =cmd;                     //　取引操作タイプ
                 request.action   =TRADE_ACTION_DEAL;                     //　取引操作タイプ
                 request.symbol   =symbol1;                             // シンボル
                 request.volume   =volume;                                   // 0.1ロットのボリューム
                 request.type     =ORDER_TYPE_BUY;                       // 注文タイプ
                 request.price    =price; // 発注価格
                 request.sl = stoploss;
                 request.tp = takeprofit;
                 request.comment = comment;
                 request.deviation=5;                                     // 価格からの許容偏差
                 request.magic    =EXPERT_MAGIC;                         // 注文のMagicNumber
                 request.type_filling = ORDER_FILLING_FOK; //add
               //--- リクエストの送信
                 if(!OrderSend(request,result))
                   PrintFormat("OrderSend error %d",GetLastError());     // リクエストの送信が失敗した場合、エラーコードを出力する
               //--- 操作に関する情報
                 PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
               //--- サーバ返答をログに書く
               	         flagNotTrade = false;
   
                 Print(__FUNCTION__,":",result.comment); 
                 if(result.retcode==10016) Print(result.bid,result.ask,result.price); 
               
                  // 
                  //mMyOrderOpenTime =TimeCurrent();
               //--- 取引サーバの返答のコードを返す 
                 return result.retcode; 
                } 
               
                // uint MYsellOrder(double volume) 
uint MYsellOrder( 
   string symbol2,
   int cmd,
   double volume,
   double price,
   int slippage,
   double stoploss,
   double takeprofit,
   string comment=NULL,
   int magic=0,
   datetime expiration=0,
   color arrow_color=clrNONE
) 
 { 
               //--- リクエストと結果の宣言と初期化
                 //MqlTradeRequest request={0};//chg 20210624 start
                 MqlTradeRequest request;
                 //chg 20210624 end
                 
                 MqlTradeResult  result={0};
               //--- リクエストのパラメータ
                 request.action   =TRADE_ACTION_DEAL;                     // 取引操作タイプ
                 request.symbol   =symbol2;                             // シンボル
                 request.volume   =volume;                                   // 0.2ロットのボリューム
                 request.type     =ORDER_TYPE_SELL;                       // 注文タイプ
                 request.price    =price; // 発注価格
                 request.sl = stoploss;
                 request.tp = takeprofit;
               	 request.comment =comment;
                 request.deviation=5;                                     // 価格からの許容偏差
                 request.type_filling = ORDER_FILLING_FOK; //add
                 request.magic    =EXPERT_MAGIC;                         // 注文のMagicNumber
               //--- リクエストの送信
                 if(!OrderSend(request,result))
                   PrintFormat("OrderSend error %d",GetLastError());     // リクエストの送信が失敗した場合、エラーコードを出力する
               //--- 操作についての情報
                 PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
               	         flagNotTrade = false;

               
               //--- サーバ返答をログに書く   
                 Print(__FUNCTION__,":",result.comment); 
                 if(result.retcode==10016) Print(result.bid,result.ask,result.price); 
                  // 
                  //mMyOrderOpenTime =TimeCurrent();
               //--- 取引サーバの返答のコードを返す 
                 return result.retcode; 
               }
#ifdef aaaaaaaaaaaaaaaaaaaaaaaaa               
               void test_buy(){
               
                   int kol,numb;
                   kol = OrdersTotal();	//現在の注文数
                   double bid;
                   double ask;
                   double sl_buy,tp_buy;
                   
                   RefreshPrice(bid, ask); 
                
                       sl_buy = NormalizeDouble((bid-StopLoss*Point()),Digits());
                       tp_buy = NormalizeDouble((ask+TakeProfit*Point()),Digits());
                       
                        numb = OrderSend(Symbol(),  OP_BUY,Lots,ask,3,sl_buy,tp_buy,"Reduce_risks",16384,0,Green); 
	         flagNotTrade = false;
               
                   kol = OrdersTotal();	//現在の注文数
                   int i;
                   for(i=0;i<kol;i++){
                     OrderSelect(i);
                     
                     
                     
                   }
                   
                  { 
                  //--- 注文プロパティから値を返す変数 
                    ulong    ticket; 
                    double   open_price; 
                    double   initial_volume; 
                    datetime time_setup; 
                    string   symbol2; 
                    string   type1; 
                    long     order_magic; 
                    long     positionID; 
                  //--- 現在の未決注文数 
                    uint     total=OrdersTotal(); 
                    int positiontotal = PositionsTotal();
                  //--- ループで注文をみる  
                    for(uint i=0;i<total;i++) 
               //     for(uint i=0;i<positiontotal;i++) 
                      { 
                      //--- リスト内の位置によって注文を返す 
                      if((ticket=OrderGetTicket(i))>0) 
                         { 
                          //--- 注文プロパティを返す 
                          open_price    =OrderGetDouble(ORDER_PRICE_OPEN); 
                          time_setup    =(datetime)OrderGetInteger(ORDER_TIME_SETUP); 
                          symbol2       =OrderGetString(ORDER_SYMBOL); 
                          order_magic   =OrderGetInteger(ORDER_MAGIC); 
                          positionID    =OrderGetInteger(ORDER_POSITION_ID); 
                          initial_volume=OrderGetDouble(ORDER_VOLUME_INITIAL); 
                          type1          =EnumToString(ENUM_ORDER_TYPE(OrderGetInteger(ORDER_TYPE))); 
                          //--- 注文についての情報を準備して表示する 
                          printf("#ticket %d %s %G %s at %G was set up at %s", 
                                 ticket,                 // 注文チケット 
                                 type1,                   // 種類 
                                 initial_volume,         // 注文のボリューム 
                                 symbol2,                 // シンボル 
                                 open_price,             // 指定された始値 
                                TimeToString(time_setup)// 注文の出された時刻 
                                 ); 
                         } 
                      }
                  //　ポジションを見る 
                    for(int i=0;i<positiontotal;i++){
                    
                     if( ticket = PositionGetTicket(i)>0){
                          open_price    =PositionGetDouble(POSITION_PRICE_OPEN); 
                          time_setup    =(datetime)PositionGetInteger(POSITION_TIME); 
                          symbol2       =PositionGetString(POSITION_SYMBOL); 
                          order_magic   =PositionGetInteger(POSITION_MAGIC); 
                          positionID    =PositionGetInteger(POSITION_IDENTIFIER); 
                          initial_volume=PositionGetDouble(POSITION_VOLUME); 
                          type1          =EnumToString(ENUM_POSITION_TYPE(PositionGetInteger(POSITION_TYPE)));  
                          
                                     printf("#ticket %d #identifier %d %s %G %s at %G was set up at %s", 
                                 ticket,                 // 注文チケット 
                                 positionID,             // ポジション識別子
                                 type1,                   // 種類 
                                 initial_volume,         // 注文のボリューム 
                                 symbol2,                 // シンボル 
                                 open_price,             // 指定された始値 
                                TimeToString(time_setup)// 注文の出された時刻 
                                 ); 
                                  
                     
                     }
                    
                    
                    }//for position 
               
               
               
               
                  
                  }       
               
               
               
}
#endif // del old code


///////////////////////////////////////////////////////////////////////////////////////////
void writestring_DEAL(string str)
{
//ファイルの最後にStrに追加　改行は\r\nでOK
	//--- ファイルを開く 
	ResetLastError();
//	int file_handle=FileOpen(InpDirectoryName+"/"+InpFileName,FILE_READ|FILE_BIN|FILE_ANSI);
//	int file_handle=FileOpen("C:\\Users\\makoto\\AppData\\Roaming\\MetaQuotes\\terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Experts\\Data\\test.txt",FILE_READ|FILE_BIN|FILE_ANSI);
//	int file_handle=FileOpen("test.txt",FILE_READ|FILE_BIN|FILE_ANSI);
//	int file_handle=FileOpen("Data\\test.txt",FILE_READ|FILE_ANSI);
//	int file_handle=FileOpen("Data\\test.txt",FILE_WRITE |FILE_BIN|FILE_ANSI);
	int file_handle=FileOpen("Data\\test_DEAL.txt",FILE_WRITE |FILE_ANSI|FILE_TXT);
	string InpFileName="Data\\test_DEAL.txt";
	if(file_handle!=INVALID_HANDLE)
    	{
	  	PrintFormat("%s file is available for reading",InpFileName);
	  	PrintFormat("File path: %s\\Files\\",TerminalInfoString(TERMINAL_DATA_PATH));
	  	//--- 追加の変数
//	  	int	  str_size;
//	  	string str;
	  	
#ifdef aaa	  	
	  	//--- ファイルからデータを読む
	  	while(!FileIsEnding(file_handle))
		{
		      	//--- 時間を書くのに使用されるシンボルの数を見つける
		        str_size=FileReadInteger(file_handle,INT_VALUE);
		      	//--- 文字列を読む
		        str=FileReadString(file_handle,str_size);
		      	//--- 文字列を出力する
		      	PrintFormat(str);
		}
#endif
//      str = (string)TimeCurrent();
//      str = str + "\t" + "test"+ "\r\ntest2";
      FileSeek(file_handle,0, SEEK_END);
      FileWrite(file_handle,str);
      FileFlush(file_handle);
		//--- ファイルを閉じる
	  	FileClose(file_handle);
	  	PrintFormat("Data is read, %s file is closed",InpFileName);
    	}
	else
  	PrintFormat("Failed to open %s file, Error code = %d",InpFileName,GetLastError());
}
///////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////
void writestring_POS(string str)
{
//ファイルの最後にStrに追加　改行は\r\nでOK
	//--- ファイルを開く 
	ResetLastError();
//	int file_handle=FileOpen(InpDirectoryName+"/"+InpFileName,FILE_READ|FILE_BIN|FILE_ANSI);
//	int file_handle=FileOpen("C:\\Users\\makoto\\AppData\\Roaming\\MetaQuotes\\terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Experts\\Data\\test.txt",FILE_READ|FILE_BIN|FILE_ANSI);
//	int file_handle=FileOpen("test.txt",FILE_READ|FILE_BIN|FILE_ANSI);
//	int file_handle=FileOpen("Data\\test.txt",FILE_READ|FILE_ANSI);
//	int file_handle=FileOpen("Data\\test.txt",FILE_WRITE |FILE_BIN|FILE_ANSI);
	int file_handle=FileOpen("Data\\test_POS.txt",FILE_WRITE |FILE_ANSI|FILE_TXT);
	string InpFileName="Data\\test_POS.txt";
	if(file_handle!=INVALID_HANDLE)
    	{
	  	PrintFormat("%s file is available for reading",InpFileName);
	  	PrintFormat("File path: %s\\Files\\",TerminalInfoString(TERMINAL_DATA_PATH));
	  	//--- 追加の変数
//	  	int	  str_size;
//	  	string str;
	  	
#ifdef aaa	  	
	  	//--- ファイルからデータを読む
	  	while(!FileIsEnding(file_handle))
		{
		      	//--- 時間を書くのに使用されるシンボルの数を見つける
		        str_size=FileReadInteger(file_handle,INT_VALUE);
		      	//--- 文字列を読む
		        str=FileReadString(file_handle,str_size);
		      	//--- 文字列を出力する
		      	PrintFormat(str);
		}
#endif
//      str = (string)TimeCurrent();
//      str = str + "\t" + "test"+ "\r\ntest2";
      FileSeek(file_handle,0, SEEK_END);
      FileWrite(file_handle,str);
      FileFlush(file_handle);
		//--- ファイルを閉じる
	  	FileClose(file_handle);
	  	PrintFormat("Data is read, %s file is closed",InpFileName);
    	}
	else
  	PrintFormat("Failed to open %s file, Error code = %d",InpFileName,GetLastError());
}
///////////////////////////////////////////////////////////////////////////////////////////


void testOrder()

 { 
//--- 注文プロパティから値を返す変数 
  ulong    ticket; 
  double   open_price; 
  double   initial_volume; 
  datetime time_setup; 
  string   symbol; 
  string   type; 
  long     order_magic; 
  long     positionID; 
//--- 現在の未決注文数 
  uint     total=OrdersTotal(); 
//--- ループで注文をみる 
  for(uint i=0;i<total;i++) 
    { 
    //--- リスト内の位置によって注文を返す 
    if((ticket=OrderGetTicket(i))>0) 
       { 
        //--- 注文プロパティを返す 
        open_price    =OrderGetDouble(ORDER_PRICE_OPEN); 
        time_setup    =(datetime)OrderGetInteger(ORDER_TIME_SETUP); 
        symbol       =OrderGetString(ORDER_SYMBOL); 
        order_magic   =OrderGetInteger(ORDER_MAGIC); 
        positionID    =OrderGetInteger(ORDER_POSITION_ID); 
        initial_volume=OrderGetDouble(ORDER_VOLUME_INITIAL); 
        type          =EnumToString(ENUM_ORDER_TYPE(OrderGetInteger(ORDER_TYPE))); 
        //--- 注文についての情報を準備して表示する 
        printf("#ticket %d %s %G %s at %G was set up at %s", 
               ticket,                 // 注文チケット 
               type,                   // 種類 
               initial_volume,         // 注文のボリューム 
               symbol,                 // シンボル 
               open_price,             // 指定された始値 
              TimeToString(time_setup)// 注文の出された時刻 
               ); 
       } 
    } 
//--- 
 }
 
 
 
bool positionTest(
int ticket,//
double lots,//
double price,
int slippage,
color arrow_color///---
){
               
               // Selectしてあることが前提
               
               
               
               //--- 結果とリクエストの宣言
                 MqlTradeRequest request;
                 MqlTradeResult  result;
                 int total=PositionsTotal(); //　保有ポジション数   
                 bool ret = true;
               //--- 全ての保有ポジションの取捨
                 for(int i=total-1; i>=0; i--)
                   {
                   //--- 注文のパラメータ
                    ulong  position_ticket=PositionGetTicket(i);                                     // ポジションチケット
                   //ulong  position_ticket = ticket;                                     // ポジションチケット
                   string position_symbol=PositionGetString(POSITION_SYMBOL);                       // シンボル 
                   int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);             // 小数点以下の桁数
                   ulong  magic=PositionGetInteger(POSITION_MAGIC);                                 // ポジションのMagicNumber
                   //double volume=PositionGetDouble(POSITION_VOLUME);                                 // ポジションボリューム
                   double volume=lots;                                 // ポジションボリューム
                   ENUM_POSITION_TYPE type1=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);   // ポジションタイプ


                   ulong  IDENTIFIER1=PositionGetInteger(POSITION_IDENTIFIER);                                 // ポジションのMagicNumber
                   ulong  magic2=PositionGetInteger(POSITION_REASON);                                 // ポジションのMagicNumber
                   ulong  magic3=PositionGetInteger(POSITION_TIME);                                 // ポジションのMagicNumber
                   ulong  magic4=PositionGetInteger(POSITION_TIME_MSC);                                 // ポジションのMagicNumber
                   ulong  magic5=PositionGetInteger(POSITION_TIME_UPDATE); 
                   
                   if( IDENTIFIER1 == 398){
                   
                        volume = lots;
                   }
                   
                                                   // ポジションのMagicNumber
                  double aaa = PositionGetDouble(POSITION_PRICE_CURRENT);
                  double aaa1 = PositionGetDouble(POSITION_PRICE_OPEN);
                  double aaa2 = PositionGetDouble(POSITION_PROFIT);
                  double aaa3 = PositionGetDouble(POSITION_SL);
                  double aaa4 = PositionGetDouble(POSITION_TP);
                  double aaa5 = PositionGetDouble(POSITION_VOLUME);
                  

                   //--- ポジション情報の出力
                   PrintFormat("#%I64u %s  %s  %.2f  %s [%I64d]",
                                position_ticket,
                                position_symbol,
                               EnumToString(type1),
                                volume,
                               DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),digits),
                                magic);
                   //--- MagicNumberが一致している場合
                   if(magic==EXPERT_MAGIC)
                      {
						string str_comment = "dummy";//GetStrSlowBandHigh();
                       //--- リクエストと結果の値のゼロ化
                       ZeroMemory(request);
                       ZeroMemory(result);
                       //--- 操作パラメータの設定
                       request.action   =TRADE_ACTION_DEAL;       // 取引操作タイプ
                       request.position =position_ticket;         // ポジションチケット
                       request.symbol   =position_symbol;         // シンボル 
                       request.comment = str_comment;
                       request.volume   =volume;                   // ポジションボリューム
                       request.deviation=5;                       // 価格からの許容偏差
                       request.magic    =EXPERT_MAGIC;             // ポジションのMagicNumber
                       //--- ポジションタイプによる注文タイプと価格の設定
                       if(type1==POSITION_TYPE_BUY)
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
                       PrintFormat("Close #%I64d %s %s",position_ticket,position_symbol,EnumToString(type1));
                       //--- リクエストの送信
                       
                   //    if(!OrderSend(request,result))
                   //      PrintFormat("OrderSend error %d",GetLastError()); // リクエストの送信に失敗した場合、エラーコードを出力
                       //--- 操作情報  
                       PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
                       //---
                   //    	         flagNotTrade = false;

                      }
                      else{ ret =false;}
                   }
                   return(ret);
                }
                
                
                
                
 //+------------------------------------------------------------------+ 
//| TradeTransaction 関数                                             | 
//+------------------------------------------------------------------+ 
void OnTradeTransaction(const MqlTradeTransaction &trans, 
                      const MqlTradeRequest &request, 
                      const MqlTradeResult &result) 
 { 
//--- 
  static int counter=0;   // OnTradeTransaction()呼び出しのカウンタ 
  static uint lasttime=0; // OnTradeTransaction()の最後の呼び出し時刻 
//--- 
  uint time=GetTickCount(); 
//--- 最後のトランザクションが1秒以上前に実行された場合 
  if(time-lasttime>1000) 
    { 
     counter=0; // これは新しい取引であり、カウンタをリセットできる 
    if(IS_DEBUG_MODE) 
        Print(" New trade operation"); 
    } 
  lasttime=time; 
  counter++; 
  Print(counter,". ",__FUNCTION__); 
//--- 取引リクエストの実行結果 
  ulong            lastOrderID   =trans.order; 
  ENUM_ORDER_TYPE  lastOrderType =trans.order_type; 
  ENUM_ORDER_STATE lastOrderState=trans.order_state; 
//--- トランザクションが実行される取引シンボルの名称 
  string trans_symbol=trans.symbol; 
//--- トランザクションの種類 
  ENUM_TRADE_TRANSACTION_TYPE  trans_type=trans.type; 
  switch(trans.type) 
    { 
    case TRADE_TRANSACTION_POSITION:   // ポジション修正 
       { 
        ulong pos_ID=trans.position; 
        PrintFormat("MqlTradeTransaction: Position  #%d %s modified: SL=%.5f TP=%.5f", 
                    pos_ID,trans_symbol,trans.price_sl,trans.price_tp); 
       } 
    break; 
    case TRADE_TRANSACTION_REQUEST:     // 取引リクエストの送信 
        PrintFormat("MqlTradeTransaction: TRADE_TRANSACTION_REQUEST"); 
        break; 
    case TRADE_TRANSACTION_DEAL_ADD:   // 取引の追加 
       { 
        ulong          lastDealID   =trans.deal; 
        ENUM_DEAL_TYPE lastDealType =trans.deal_type; 
        double        lastDealVolume=trans.volume; 
        //--- 外部システムの取引ID - 取引所で割り当てられたチケット 
        string Exchange_ticket=""; 
        if(HistoryDealSelect(lastDealID)) 
           Exchange_ticket=HistoryDealGetString(lastDealID,DEAL_EXTERNAL_ID); 
        if(Exchange_ticket!="") 
           Exchange_ticket=StringFormat("(Exchange deal=%s)",Exchange_ticket); 
  
        PrintFormat("MqlTradeTransaction: %s deal #%d %s %s %.2f lot   %s",EnumToString(trans_type), 
                    lastDealID,EnumToString(lastDealType),trans_symbol,lastDealVolume,Exchange_ticket); 
       ulong sl=HistoryDealGetInteger(lastDealID,DEAL_REASON);//DEAL_REASON_SL);            
       
       if (sl == DEAL_REASON_SL){
           sl = DEAL_REASON_SL;
       }else if(sl == DEAL_REASON_TP){
           sl = DEAL_REASON_TP;
       
       }
       ulong aa=DEAL_REASON_SL;
       ulong aa2=DEAL_REASON_TP;
       
       //ulong TP=HistoryDealGetInteger(lastDealID, DEAL_REASON_TP );            
       //ulong so=HistoryDealGetInteger(lastDealID,DEAL_REASON_SO);            
       //ulong sl=HistoryDealGetInteger(lastDealID,DEAL_REASON_SL);            
       ulong sp=HistoryDealGetInteger(lastDealID,DEAL_REASON);//DEAL_REASON_SL);            
       } 
    break; 
    case TRADE_TRANSACTION_HISTORY_ADD: // 履歴への注文の追加 
       { 
        //--- 外部システムの注文ID - 取引所で割り当てられたチケット 
        string Exchange_ticket=""; 
        if(lastOrderState==ORDER_STATE_FILLED) 
          { 
          if(HistoryOrderSelect(lastOrderID)) 
              Exchange_ticket=HistoryOrderGetString(lastOrderID,ORDER_EXTERNAL_ID); 
          if(Exchange_ticket!="") 
              Exchange_ticket=StringFormat("(Exchange ticket=%s)",Exchange_ticket); 
          } 
        PrintFormat("MqlTradeTransaction: %s order #%d %s %s %s   %s",EnumToString(trans_type), 
                    lastOrderID,EnumToString(lastOrderType),trans_symbol,EnumToString(lastOrderState),Exchange_ticket); 

       ulong sl1=HistoryDealGetInteger(lastOrderID,DEAL_REASON);//DEAL_REASON_SL);            
       
       if (sl1 == DEAL_REASON_SL){
           sl1 = DEAL_REASON_SL;
       }else if(sl1 == DEAL_REASON_TP){
           sl1 = DEAL_REASON_TP;
           ulong sl2=HistoryDealGetInteger(lastOrderID,DEAL_POSITION_ID);//DEAL_REASON_SL); 
          ulong aa=DEAL_REASON_SL;
       
       }
       ulong aa=DEAL_REASON_SL;
       ulong aa2=DEAL_REASON_TP;       

       } 
       
       
       
    break; 
    default: // 他のトランザクション 
       { 
        //--- 外部システムの注文ID - 取引所で割り当てられたチケット 
        string Exchange_ticket=""; 
        if(lastOrderState==ORDER_STATE_PLACED) 
          { 
          if(OrderSelect(lastOrderID)) 
              Exchange_ticket=OrderGetString(ORDER_EXTERNAL_ID); 
          if(Exchange_ticket!="") 
              Exchange_ticket=StringFormat("Exchange ticket=%s",Exchange_ticket); 
          } 
        PrintFormat("MqlTradeTransaction: %s order #%d %s %s   %s",EnumToString(trans_type), 
                    lastOrderID,EnumToString(lastOrderType),EnumToString(lastOrderState),Exchange_ticket); 
       } 
    break; 
    } 
//--- 注文チケット     
  ulong orderID_result=result.order; 
  string retcode_result=GetRetcodeID(result.retcode); 
  if(orderID_result!=0) 
    PrintFormat("MqlTradeResult: order #%d retcode=%s ",orderID_result,retcode_result); 
//---   

#ifndef NOT_USE_POSISION_LOG_WRITE
output_position();
output_deal();
#endif//NOT_USE_POSISION_LOG_WRITE
 } 
//+------------------------------------------------------------------+ 
//| 数値をテキスト文字列に変換する                                           | 
//+------------------------------------------------------------------+ 
string GetRetcodeID(int retcode) 
 { 
  switch(retcode) 
    { 
    case 10004: return("TRADE_RETCODE_REQUOTE");             break; 
    case 10006: return("TRADE_RETCODE_REJECT");             break; 
    case 10007: return("TRADE_RETCODE_CANCEL");             break; 
    case 10008: return("TRADE_RETCODE_PLACED");             break; 
    case 10009: return("TRADE_RETCODE_DONE");               break; 
    case 10010: return("TRADE_RETCODE_DONE_PARTIAL");       break; 
    case 10011: return("TRADE_RETCODE_ERROR");               break; 
    case 10012: return("TRADE_RETCODE_TIMEOUT");             break; 
    case 10013: return("TRADE_RETCODE_INVALID");             break; 
    case 10014: return("TRADE_RETCODE_INVALID_VOLUME");     break; 
    case 10015: return("TRADE_RETCODE_INVALID_PRICE");       break; 
    case 10016: return("TRADE_RETCODE_INVALID_STOPS");       break; 
    case 10017: return("TRADE_RETCODE_TRADE_DISABLED");     break; 
    case 10018: return("TRADE_RETCODE_MARKET_CLOSED");       break; 
    case 10019: return("TRADE_RETCODE_NO_MONEY");           break; 
    case 10020: return("TRADE_RETCODE_PRICE_CHANGED");       break; 
    case 10021: return("TRADE_RETCODE_PRICE_OFF");           break; 
    case 10022: return("TRADE_RETCODE_INVALID_EXPIRATION"); break; 
    case 10023: return("TRADE_RETCODE_ORDER_CHANGED");       break; 
    case 10024: return("TRADE_RETCODE_TOO_MANY_REQUESTS");   break; 
    case 10025: return("TRADE_RETCODE_NO_CHANGES");         break; 
    case 10026: return("TRADE_RETCODE_SERVER_DISABLES_AT"); break; 
    case 10027: return("TRADE_RETCODE_CLIENT_DISABLES_AT"); break; 
    case 10028: return("TRADE_RETCODE_LOCKED");             break; 
    case 10029: return("TRADE_RETCODE_FROZEN");             break; 
    case 10030: return("TRADE_RETCODE_INVALID_FILL");       break; 
    case 10031: return("TRADE_RETCODE_CONNECTION");         break; 
    case 10032: return("TRADE_RETCODE_ONLY_REAL");           break; 
    case 10033: return("TRADE_RETCODE_LIMIT_ORDERS");       break; 
    case 10034: return("TRADE_RETCODE_LIMIT_VOLUME");       break; 
    case 10035: return("TRADE_RETCODE_INVALID_ORDER");       break; 
    case 10036: return("TRADE_RETCODE_POSITION_CLOSED");     break; 
    default: 
        return("TRADE_RETCODE_UNKNOWN="+IntegerToString(retcode)); 
        break; 
    } 
//--- 
 }
 


bool testPositionInfoOut(
int testsq_num // testsq
){
               // Selectしてあることが前提
               // Selectしてあることが前提
               
               
               
//                 int total=PositionsTotal(); //　保有ポジション数   
                 int total=PositionsTotal(); //　保有ポジション数   
                 bool ret = true;
               //--- 全ての保有ポジションの取捨
               PrintFormat("######Position Info start### -------------------------------------------"               );
               for(int i=total-1; i>=0; i--)
                   {
                   //--- 注文のパラメータ



// long

	                  ulong  Position_ticket=PositionGetTicket(i);                                     // 取引チケット　（約定チケット）
	                  
	                  // ulong  position_ticket = ticket;                                     // ポジションチケット
	//                   string position_symbol=HistoryDealGetString(POSITION_SYMBOL);                       // シンボル 

	                   long position_id = PositionGetInteger(POSITION_IDENTIFIER);//ポジション識別子は、全ての新しくオープンしたポジションに割り当てられ、ポジションのライフタイムに一貫する固有の番号です。識別子はポジションのターンオーバによって変更されません。
//ポジション識別子は、ポジションを開く、変更する、または決済するために使用される各注文（ORDER_POSITION_ID）と約定（DEAL_POSITION_ID）で指定されています。ポジションに関連した注文や約定を検索するにはこ//のプロパティを使用します。

//ネッティングモード（単一のイン/アウト取引を使用）でポジションが反転された場合、POSITION_IDENTIFIERは変更されません。 ただし、POSITION_TICKETは、その反転につながった注文のチケットに置き換えられます。 ポジション反転はヘッジモードでは提供されません。






	                   ENUM_POSITION_TYPE type1=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);   // ポジションの種類。

	                   string position_symbol=PositionGetString(POSITION_SYMBOL);                       // シンボル 
	                   
	                   int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);             // 小数点以下の桁数


	                   ulong  magic=PositionGetInteger(POSITION_MAGIC);                                 // ポジションのMagicNumber
	                   //double volume=PositionGetDouble(POSITION_VOLUME);                                 // ポジションボリューム
	                   double volume=0.0;                                 // ポジションボリューム
//	                   ENUM_POSITION_TYPE type1=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);   // ポジションタイプ
	                   ENUM_POSITION_REASON type2=(ENUM_POSITION_REASON)PositionGetInteger(POSITION_REASON);   // ポジションタイプ
	                   string comment=PositionGetString(POSITION_COMMENT);                                 // 
	                   //--- ポジション情報の出力
//	                   PrintFormat("######PositionDeal Info ### TAB%I64u TAB##POSITION_TICKET=TAB%I64u TABPOSITION_ID=TAB%I64uTAB  ##POSITION_TYPE=TAB%sTAB POSITION_REASON=TAB%sTAB  ポジション量=TAB%.2fTAB  TAB現在の価格=TAB%sTAB [%I64d]TAB%sTABend",
	                   PrintFormat("######PositionDeal Info ### TAB%I64u TAB##POSITION_TICKET=TAB%I64u TABPOSITION_ID=TAB%I64uTAB  ##POSITION_TYPE=TAB%sTAB POSITION_REASON=TAB%sTAB  ポジション量=TAB%sTAB  TAB現在の価格=TAB%sTAB [%I64d]TAB%sTABend",
	                                 testsq_num,
	                                Position_ticket,
	                                position_id,
	                               EnumToString(type1),
	                               EnumToString(type2),
	                               
	                               DoubleToString(PositionGetDouble(POSITION_VOLUME),digits),
	                               DoubleToString(PositionGetDouble(POSITION_PRICE_CURRENT),digits),
	                                magic,comment
	                                
	                                );
	                                
                   
                   }
               PrintFormat("######Position Info end### -------------------------------------------"               );
                   return(ret);
}



bool testHistoryInfoOut(
int testsq_num // testsq
){
               
               // Selectしてあることが前提
               
HistorySelect(0,TimeCurrent());                
               
//                 int total=PositionsTotal(); //　保有ポジション数   
                 int total=HistoryDealsTotal(); //　保有ポジション数   
                 bool ret = true;
               //--- 全ての保有ポジションの取捨
               PrintFormat("######HistoryDeal Info ### start"               );
               for(int i=total-1; i>=0; i--)
                   {
                   //--- 注文のパラメータ



// long

	                  ulong  ticket=HistoryDealGetTicket(i);                                     // 取引チケット　（約定チケット）
	                   long deal_order = HistoryDealGetInteger(ticket,DEAL_ORDER);
	                  
	                  // ulong  position_ticket = ticket;                                     // ポジションチケット
	                   string position_symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);                       // シンボル 
	                   string comment=HistoryDealGetString(ticket,DEAL_COMMENT);                       // 

	                   long position_id = HistoryDealGetInteger(ticket,DEAL_POSITION_ID);//約定の開始、変更や変化が起きたポジションのポジション識別子。ポジションは、ライフタイムを通して、シンボルに実行された全ての約定に割り当てられている固有の識別子を持ちます。



	                   ENUM_DEAL_TYPE type1=(ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket,DEAL_TYPE);   // 約定の種類。

	                   ENUM_DEAL_ENTRY type2=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket,DEAL_ENTRY);   // DEAL_ENTRY	約定エントリー （エントリーイン、エントリーアウト、リバース）。ENUM_DEAL_ENTRY


	                   ENUM_DEAL_REASON type3=(ENUM_DEAL_REASON)HistoryDealGetInteger(ticket,DEAL_REASON);   // DEAL_REASON	約定実行のソースまたは理由。ENUM_DEAL_REASON
	                   
	                   int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);             // 小数点以下の桁数


	                   ulong  magic=HistoryDealGetInteger(ticket,DEAL_MAGIC);                                 // ポジションのMagicNumber
	                   //double volume=PositionGetDouble(POSITION_VOLUME);                                 // ポジションボリューム
	                   double volume=0.0;                                 // ポジションボリューム
//	                   ENUM_DEAL_ENTRY type2=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket,DEAL_ENTRY);   // 約定エントリー （エントリーイン、エントリーアウト、リバース）。
	                   
	                   //--- ポジション情報の出力
//	                   PrintFormat("######HistoryDeal Info ### TAB%I64uTAB ##DEAL_TICKET=TAB%I64uTAB  DEAL_ORDER=TAB%I64uTAB POSITION_ID=TAB%I64uTAB ##DEAL_TYPE=TAB%sTAB DEAL_ENTRY=TAB%sTAB DEAL_REASON=TAB%sTAB  TAB約定量=TAB%.2fTAB  約定の利益=TAB%sTAB TAB[%I64d]TAB%sTABend",
	                   PrintFormat("######HistoryDeal Info ### TAB%I64uTAB ##DEAL_TICKET=TAB%I64uTAB  DEAL_ORDER=TAB%I64uTAB POSITION_ID=TAB%I64uTAB ##DEAL_TYPE=TAB%sTAB DEAL_ENTRY=TAB%sTAB DEAL_REASON=TAB%sTAB  TAB約定量=TAB%sTAB  約定の利益=TAB%sTAB TAB[%I64d]TAB%sTABend",
	                                 testsq_num,
	                                ticket,
	                                deal_order,
	                                position_id,
	                               EnumToString(type1),
	                               EnumToString(type2),
	                               EnumToString(type3),
	                               DoubleToString(HistoryDealGetDouble(ticket,DEAL_VOLUME),digits),
	                               DoubleToString(HistoryDealGetDouble(ticket,DEAL_PROFIT),digits),
	                                magic,comment
	                                
	                                );
	                                
                   
                   }
               PrintFormat("######HistoryDeal Info end### -------------------------------------------"               );

                   return(ret);


#ifdef aaaaa
ENUM_DEAL_PROPERTY_INTEGER

識別子
 
説明
 
Type
 

DEAL_TICKET
 
取引チケット。各取引に割り当てられる固有の番号です。
 
long
 

DEAL_ORDER
 
約定の注文番号。
 
long
 

DEAL_TIME
 
約定時刻。
 
datetime
 

DEAL_TIME_MSC
 
01.01.1970 から経過したミリ秒数で表された 約定実行時刻。
 
long
 

DEAL_TYPE
 
約定の種類。
 
ENUM_DEAL_TYPE
 

DEAL_ENTRY
 
約定エントリー （エントリーイン、エントリーアウト、リバース）。
 
ENUM_DEAL_ENTRY
 

DEAL_MAGIC
 
約定マジックナンバー（ORDER_MAGIC を参照）。
 
long
 

DEAL_REASON
 
約定実行のソースまたは理由。
 
ENUM_DEAL_REASON
 

DEAL_POSITION_ID
 
約定の開始、変更や変化が起きたポジションのポジション識別子。ポジションは、ライフタイムを通して、シンボルに実行された全ての約定に割り当てられている固有の識別子を持ちます。
 
long
 
#endif





}



void testDatetime(){
   string str;
   
   str = TimeToString(1,TIME_DATE);
   PrintFormat(str);
   
   str = TimeToString(1,TIME_MINUTES);
   PrintFormat(str);
   
   str = TimeToString(1,TIME_SECONDS);
   PrintFormat(str);
   
   str = TimeToString(1,TIME_DATE|TIME_MINUTES);
   PrintFormat(str);
   
   str = TimeToString(1,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
   PrintFormat(str);

   PrintFormat("test");


}




// データ定義
// ポジションデータ（ポジションid）
struct struct_position_element {
   long	longPOSITION_TICKET	;	//ポジションチケット。各保有ポジションに新たに割り当てられた固有の番号。通常、その結果としてポジションを保有する、注文のチケットに対応します（サーバー上で行われた操作の結果、チケットが変更された場合を除く）。例えば、ポジションの再保有によるスワップの加算です。ポジションを保有することになった注文を見つけるには、POSITION_IDENTIFIERプロパティを使用する必要があります。//POSITION_TICKET
   			
   			//POSITION_TICKET値はMqlTradeRequest::positionと一致します。
   datetime	datetimePOSITION_TIME	;	//注文が出された時刻。//POSITION_TIME
   long	longPOSITION_TIME_MSC	;	//01.01.1970 から経ったミリ秒で表された注文が出された時刻。//POSITION_TIME_MSC
   long	longPOSITION_TIME_UPDATE	;	//01.01.1970 から経った秒数で表されたポジション変更時刻。//POSITION_TIME_UPDATE
   long	longPOSITION_TIME_UPDATE_MSC	;	//01.01.1970 から経ったミリ秒で表されたポジション変更時刻。//POSITION_TIME_UPDATE_MSC
   ENUM_POSITION_TYPE	ENUM_POSITION_TYPEPOSITION_TYPE	;	//ポジションの種類。//POSITION_TYPE
   long	longPOSITION_MAGIC	;	//ポジションマジックナンバー（ORDER_MAGICを参照）。//POSITION_MAGIC
   long	longPOSITION_IDENTIFIER	;	//ポジション識別子は、全ての新しくオープンしたポジションに割り当てられ、ポジションのライフタイムに一貫する固有の番号です。識別子はポジションのターンオーバによって変更されません。//POSITION_IDENTIFIER
   			//ポジション識別子は、ポジションを開く、変更する、または決済するために使用される各注文（ORDER_POSITION_ID）と約定（DEAL_POSITION_ID）で指定されています。ポジションに関連した注文や約定を検索するにはこのプロパティを使用します。//
   			//ネッティングモード（単一のイン/アウト取引を使用）でポジションが反転された場合、POSITION_IDENTIFIERは変更されません。 ただし、POSITION_TICKETは、その反転につながった注文のチケットに置き換えられます。 ポジション反転はヘッジモードでは提供されません。 //
   ENUM_POSITION_REASON	ENUM_POSITION_REASONPOSITION_REASON	;	//ポジションを開く理由。 //POSITION_REASON
   			
   			
   			
   double	doublePOSITION_VOLUME	;	//ポジションボリューム。//POSITION_VOLUME
   double	doublePOSITION_PRICE_OPEN	;	//ポジションの始値。//POSITION_PRICE_OPEN
   double	doublePOSITION_SL	;	//未決済ポジションの決済逆指レベル。//POSITION_SL
   double	doublePOSITION_TP	;	//未決済ポジションの決済指値。//POSITION_TP
   double	doublePOSITION_PRICE_CURRENT	;	//ポジションシンボルの現在価格。//POSITION_PRICE_CURRENT
   double	doublePOSITION_SWAP	;	//累積スワップ。//POSITION_SWAP
   double	doublePOSITION_PROFIT	;	//現在の利益。//POSITION_PROFIT
   			
   			
   			
   string	stringPOSITION_SYMBOL	;	//ポジションのシンボル。//POSITION_SYMBOL
   string	stringPOSITION_COMMENT	;	//ポジションコメント。//POSITION_COMMENT

   //データの状態
   int state_data;// 未使用0;更新中（ポジションオープン中）1；確定し履歴へ2
   
   //更新データ
   double max_price;//最大でマイナス（反対）方向にいった値　　　スタートの建値からの差分（マイナス分）
   long   max_price_subtime; // max更新時の建値からの差分の　時間（秒）
   double min_price;//最大でプラス方向にいった値　　　　スタートの建値からの差分（プラス分）
   long   min_price_subtime; // min行進時の建値からの差分の　時間（秒）

   double open_sigma_Fb;//　入ったときのσ Fb 短期
   double open_sigma_Lb;//　入ったときのσ Lb 長期
   double open_katamuki_F;//　入ったときの傾き Fk 短期
   double open_katamuki_L;//　入ったときの傾き Lk 長期
   double open_katamuki_EMA_A;//　入ったときのバンド幅±2σ L 長期
   double open_bollinger_bandwide_Fb;//　入ったときのバンド幅±2σ F 短期
   double open_bollinger_bandwide_Lb;//　入ったときのバンド幅±2σ L 長期
   double open_bollinger_bandwide_Fb_o1;
   double open_bollinger_bandwide_Fb_o2;
   double open_bollinger_bandwide_Fb_o3;
   double open_bollinger_bandwide_Fb_o4;
   double open_bollinger_bandwide_Fb_o5;
   double open_bollinger_bandwide_Lb_o1;
   double open_bollinger_bandwide_Lb_o2;
   double open_bollinger_bandwide_Lb_o3;
   double open_bollinger_bandwide_Lb_o4;
   double open_bollinger_bandwide_Lb_o5;
   double open_katamuki1_F;
   double open_katamuki2_F;
   double open_katamuki3_F;
   double open_katamuki1_L;
   double open_katamuki2_L;
   double open_katamuki3_L;
   double open_katamuki_EMA_A1;
   double open_katamuki_EMA_A2;
   double open_katamuki_EMA_B1;
   double open_katamuki_EMA_B2;
   double open_katamuki_EMA_C1;
   double open_katamuki_EMA_C2;
   int open_state_tyouki_chikou_innyou;
   int open_state_tyouki_kumo_innyou;
   int open_state_tanki__chikou_innyou;
   int open_state_tanki__kumo_innyou;
   int open_mode_span_pattern;

   double max_sigma;//最大でプラス方向にいったσ値　　　　スタートの建値からの差分（プラス分）[σ]
   double min_sigma;//最大でマイナス方向にいったσ値　　　　スタートの建値からの差分（プラス分）[σ]
   double agatte_sagarunosagaru;//トレーリングストップの時の参考値　期間中の上がってからの下がりの最大値[PIPs]
   double sagatte_agarunoagaru;//トレーリングストップの時の参考値　期間中の下がってからの上がりの最大値[PIPs]
   
   // 手法番号,名前
   int methodnum;
   string methodname;
};
struct struct_position{
   struct_position_element pos_data[];
   long  position_element_num;
   long  scan_start_indx;//オープンのデータの検索を探す際、どこを先頭にするかの情報（０からこのインデックスの前までは確定）
   
};
struct_position p_data;
//DEALデータ　約定データ
struct struct_deal_element{
   long	longDEAL_TICKET	;	//取引チケット。各取引に割り当てられる固有の番号です。//DEAL_TICKET
   long	longDEAL_ORDER	;	//約定の注文番号。//DEAL_ORDER
   datetime	datetimeDEAL_TIME	;	//約定時刻。//DEAL_TIME
   long	longDEAL_TIME_MSC	;	//01.01.1970 から経過したミリ秒数で表された 約定実行時刻。//DEAL_TIME_MSC
   ENUM_DEAL_TYPE	ENUM_DEAL_TYPEDEAL_TYPE	;	//約定の種類。//DEAL_TYPE
   ENUM_DEAL_ENTRY	ENUM_DEAL_ENTRYDEAL_ENTRY	;	//約定エントリー （エントリーイン、エントリーアウト、リバース）。//DEAL_ENTRY
   long	longDEAL_MAGIC	;	//約定マジックナンバー（ORDER_MAGIC を参照）。//DEAL_MAGIC
   ENUM_DEAL_REASON	ENUM_DEAL_REASONDEAL_REASON	;	//約定実行のソースまたは理由。//DEAL_REASON
   long	longDEAL_POSITION_ID	;	//約定の開始、変更や変化が起きたポジションのポジション識別子。ポジションは、ライフタイムを通して、シンボルに実行された全ての約定に割り当てられている固有の識別子を持ちます。//DEAL_POSITION_ID
   			
   double	doubleDEAL_VOLUME	;	//約定量。//DEAL_VOLUME
   double	doubleDEAL_PRICE	;	//約定値。//DEAL_PRICE
   double	doubleDEAL_COMMISSION	;	//約定手数料。//DEAL_COMMISSION
   double	doubleDEAL_SWAP	;	//終了時の累積スワップ。//DEAL_SWAP
   double	doubleDEAL_PROFIT	;	//約定の利益。//DEAL_PROFIT
   			
   string	stringDEAL_SYMBOL	;	//約定シンボル。//DEAL_SYMBOL
   string	stringDEAL_COMMENT	;	//約定コメント。//DEAL_COMMENT
};
struct struct_deal{
   struct_deal_element deal_data[];
   long deal_element_num;
   
};
struct_deal d_data;
//C:\Users\makoto\Documents\FX_売り買いデータ構造の定義.xls
// 初期サイズ
#define NUM_POSISION_DATA  1000
#define NUM_DEAL_DATA  10000
void init_posision_data(){
   ArrayResize(p_data.pos_data,NUM_POSISION_DATA,NUM_POSISION_DATA);
   for(int i=0 ; i<NUM_POSISION_DATA-1;i++){
      p_data.pos_data[i].state_data= 0;// 未使用0;更新中（ポジションオープン中）1；確定し履歴へ2
      p_data.pos_data[i].max_price = 0;
      p_data.pos_data[i].max_price_subtime= 0;
      p_data.pos_data[i].min_price= 0;
      p_data.pos_data[i].min_price_subtime= 0;

      p_data.pos_data[i].max_sigma= 0;
      p_data.pos_data[i].min_sigma= 0;
      p_data.pos_data[i].agatte_sagarunosagaru= 0;
      p_data.pos_data[i].sagatte_agarunoagaru= 0;

      p_data.pos_data[i].methodnum= 0;
      p_data.pos_data[i].methodname= "";
      p_data.scan_start_indx = 0;
   }
}
void init_deal_data(){
   d_data.deal_element_num = 0;
   ArrayResize(d_data.deal_data,NUM_DEAL_DATA ,NUM_DEAL_DATA);
}

bool output_deal(){
	
   //履歴データの構築	
init_deal_data(); //初期化
   HistorySelect(0,TimeCurrent());
   int total=HistoryDealsTotal(); //　保有ポジション数   
   bool ret = true;
   //--- 全ての保有ポジション構築
   //PrintFormat("######HistoryDeal Info ### start"               );
   for(int i=total-1; i>=0; i--)
   {
      ulong  ticket=HistoryDealGetTicket(i);  
   	Add_deal(ticket);
   }	
	
	string sss="";
	addstring(sss,"Deal_data");
	addstring(sss, "deal数=\t"+IntegerToString(d_data.deal_element_num));
	
	addstring(sss,"DEAL_TICKET\tDEAL_ORDER\tDEAL_TIME\tDEAL_TIME_MSC\tDEAL_TYPE\tDEAL_ENTRY\tDEAL_MAGIC\tDEAL_REASON\tDEAL_POSITION_ID\tDEAL_VOLUME\tDEAL_PRICE\tDEAL_COMMISSION\tDEAL_SWAP\tDEAL_PROFIT\tDEAL_SYMBOL\tDEAL_COMMENT");
	for(int i=0;i<d_data.deal_element_num;i++){
		
		addstring(sss,
			   IntegerToString(d_data.deal_data[i].longDEAL_TICKET)+"\t"
			   +IntegerToString(d_data.deal_data[i].longDEAL_ORDER)+"\t"
			   +TimeToString(d_data.deal_data[i].datetimeDEAL_TIME)+"\t"
			   +IntegerToString(d_data.deal_data[i].longDEAL_TIME_MSC)+"\t"
			   +EnumToString((ENUM_DEAL_TYPE)d_data.deal_data[i].ENUM_DEAL_TYPEDEAL_TYPE)+"\t"
			   +EnumToString((ENUM_DEAL_ENTRY)d_data.deal_data[i].ENUM_DEAL_ENTRYDEAL_ENTRY)+"\t"
			   +IntegerToString(d_data.deal_data[i].longDEAL_MAGIC)+"\t"
			   +EnumToString((ENUM_DEAL_REASON)d_data.deal_data[i].ENUM_DEAL_REASONDEAL_REASON)+"\t"
			   +IntegerToString(d_data.deal_data[i].longDEAL_POSITION_ID)+"\t"
			   +DoubleToString(d_data.deal_data[i].doubleDEAL_VOLUME,5)+"\t"
			   +DoubleToString(d_data.deal_data[i].doubleDEAL_PRICE,5)+"\t"
			   +DoubleToString(d_data.deal_data[i].doubleDEAL_COMMISSION,5)+"\t"
			   +DoubleToString(d_data.deal_data[i].doubleDEAL_SWAP,5)+"\t"
			   +DoubleToString(d_data.deal_data[i].doubleDEAL_PROFIT,5)+"\t"
			   +d_data.deal_data[i].stringDEAL_SYMBOL+"\t"
			   +d_data.deal_data[i].stringDEAL_COMMENT
		);
	}
	writestring_DEAL(sss);
	return true;
}

bool output_position(){
	string sss="";
    addstring(sss,"Position_data");
	addstring(sss, "Position数=\t"+IntegerToString(p_data.position_element_num));
	
	addstring(sss,"POSITION_TICKET\tPOSITION_TIME\tPOSITION_TIME_MSC\tPOSITION_TIME_UPDATE\tPOSITION_TIME_UPDATE_MSC\tPOSITION_TYPE\tPOSITION_MAGIC\tPOSITION_IDENTIFIER\tPOSITION_REASON\tPOSITION_VOLUME\tPOSITION_PRICE_OPEN\tPOSITION_SL\tPOSITION_TP\tPOSITION_PRICE_CURRENT\tPOSITION_SWAP\tPOSITION_PROFIT\tPOSITION_COMMENT\tstatus\tmax_price\tmax_subtime\tmin_price\tmin_time\topen_sigma_Fb\topen_sigmaLb\topen_bollinger_bandwide_Fb\topen_bollinger_bandwide_Fb_o1\topen_bollinger_bandwide_Fb_o2\topen_bollinger_bandwide_Fb_o3\topen_bollinger_bandwide_Fb_o4\topen_bollinger_bandwide_Fb_o5\topen_bollinger_bandwide_Lb\topen_bollinger_bandwide_Lb_o1\topen_bollinger_bandwide_Lb_o2\topen_bollinger_bandwide_Lb_o3\topen_bollinger_bandwide_Lb_o4\topen_bollinger_bandwide_Lb_o5\topen_katamuki_F\topen_katamuki1_F\topen_katamuki2_F\topen_katamuki3_F\topen_katamuki_L\topen_katamuki1_L\topen_katamuki2_L\topen_katamuki3_L\topen_katamuki_EMA_A\topen_katamuki_EMA_A1\topen_katamuki_EMA_A2\topen_katamuki_EMA_B1\topen_katamuki_EMA_B2\topen_katamuki_EMA_C1\topen_katamuki_EMA_C2\topen_state_tyouki_chikou_innyou\topen_state_tyouki_kumo_innyou\topen_state_tanki__chikou_innyou\topen_state_tanki__kumo_innyou\topen_mode_span_pattern\tmax_sigma\tmin_sigma\tagatte_sagaru\tsagatte_agaru");
	for(int i=0;i<p_data.position_element_num;i++){
		
		addstring(sss,
			IntegerToString(		p_data.pos_data[i].longPOSITION_TICKET				)+"\t"
			+TimeToString(		p_data.pos_data[i].datetimePOSITION_TIME				)+"\t"
			+IntegerToString(		p_data.pos_data[i].longPOSITION_TIME_MSC				)+"\t"
			+IntegerToString(		p_data.pos_data[i].longPOSITION_TIME_UPDATE				)+"\t"
			+IntegerToString(		p_data.pos_data[i].longPOSITION_TIME_UPDATE_MSC				)+"\t"
			+EnumToString((ENUM_POSITION_TYPE)		p_data.pos_data[i].ENUM_POSITION_TYPEPOSITION_TYPE				)+"\t"
			+IntegerToString(		p_data.pos_data[i].longPOSITION_MAGIC				)+"\t"
			+IntegerToString(		p_data.pos_data[i].longPOSITION_IDENTIFIER				)+"\t"
			+EnumToString((ENUM_POSITION_REASON)		p_data.pos_data[i].ENUM_POSITION_REASONPOSITION_REASON				)+"\t"
			+DoubleToString(		p_data.pos_data[i].doublePOSITION_VOLUME				,5)+"\t"
			+DoubleToString(		p_data.pos_data[i].doublePOSITION_PRICE_OPEN				,5)+"\t"
			+DoubleToString(		p_data.pos_data[i].doublePOSITION_SL				,5)+"\t"
			+DoubleToString(		p_data.pos_data[i].doublePOSITION_TP				,5)+"\t"
			+DoubleToString(		p_data.pos_data[i].doublePOSITION_PRICE_CURRENT				,5)+"\t"
			+DoubleToString(		p_data.pos_data[i].doublePOSITION_SWAP				,5)+"\t"
			+DoubleToString(		p_data.pos_data[i].doublePOSITION_PROFIT				,5)+"\t"
			+		p_data.pos_data[i].stringPOSITION_COMMENT				+"\t"
			+IntegerToString(		p_data.pos_data[i].state_data				)+"\t"// chg add tab 20190626
			+DoubleToString(p_data.pos_data[i].max_price/(Point()*10))+"\t"
			+IntegerToString(p_data.pos_data[i].max_price_subtime)+"\t"
			+DoubleToString(p_data.pos_data[i].min_price/(Point()*10))+"\t"
			+IntegerToString(p_data.pos_data[i].min_price_subtime)+"\t"


			+DoubleToString(p_data.pos_data[i].open_sigma_Fb)+"\t"
			+DoubleToString(p_data.pos_data[i].open_sigma_Lb)+"\t"


			+DoubleToString(p_data.pos_data[i].open_bollinger_bandwide_Fb/(Point()*10))+"\t"

			+DoubleToString(p_data.pos_data[i].open_bollinger_bandwide_Fb_o1/(Point()*10))+"\t"
			+DoubleToString(p_data.pos_data[i].open_bollinger_bandwide_Fb_o2/(Point()*10))+"\t"
			+DoubleToString(p_data.pos_data[i].open_bollinger_bandwide_Fb_o3/(Point()*10))+"\t"
			+DoubleToString(p_data.pos_data[i].open_bollinger_bandwide_Fb_o4/(Point()*10))+"\t"
			+DoubleToString(p_data.pos_data[i].open_bollinger_bandwide_Fb_o5/(Point()*10))+"\t"


			+DoubleToString(p_data.pos_data[i].open_bollinger_bandwide_Lb/(Point()*10))+"\t"
			+DoubleToString(p_data.pos_data[i].open_bollinger_bandwide_Lb_o1/(Point()*10))+"\t"
			+DoubleToString(p_data.pos_data[i].open_bollinger_bandwide_Lb_o2/(Point()*10))+"\t"
			+DoubleToString(p_data.pos_data[i].open_bollinger_bandwide_Lb_o3/(Point()*10))+"\t"
			+DoubleToString(p_data.pos_data[i].open_bollinger_bandwide_Lb_o4/(Point()*10))+"\t"
			+DoubleToString(p_data.pos_data[i].open_bollinger_bandwide_Lb_o5/(Point()*10))+"\t"



			+DoubleToString(p_data.pos_data[i].open_katamuki_F)+"\t"
			+DoubleToString(p_data.pos_data[i].open_katamuki1_F)+"\t"
			+DoubleToString(p_data.pos_data[i].open_katamuki2_F)+"\t"
			+DoubleToString(p_data.pos_data[i].open_katamuki3_F)+"\t"


			+DoubleToString(p_data.pos_data[i].open_katamuki_L)+"\t"
			+DoubleToString(p_data.pos_data[i].open_katamuki1_L)+"\t"
			+DoubleToString(p_data.pos_data[i].open_katamuki2_L)+"\t"
			+DoubleToString(p_data.pos_data[i].open_katamuki3_L)+"\t"
			+DoubleToString(p_data.pos_data[i].open_katamuki_EMA_A)+"\t"

			+DoubleToString(p_data.pos_data[i].open_katamuki_EMA_A1)+"\t"
			+DoubleToString(p_data.pos_data[i].open_katamuki_EMA_A2)+"\t"
			+DoubleToString(p_data.pos_data[i].open_katamuki_EMA_B1)+"\t"
			+DoubleToString(p_data.pos_data[i].open_katamuki_EMA_B2)+"\t"
			+DoubleToString(p_data.pos_data[i].open_katamuki_EMA_C1)+"\t"
			+DoubleToString(p_data.pos_data[i].open_katamuki_EMA_C2)+"\t"

			+IntegerToString(p_data.pos_data[i].open_state_tyouki_chikou_innyou)+"\t"
			+IntegerToString(p_data.pos_data[i].open_state_tyouki_kumo_innyou)+"\t"
			+IntegerToString(p_data.pos_data[i].open_state_tanki__chikou_innyou)+"\t"
			+IntegerToString(p_data.pos_data[i].open_state_tanki__kumo_innyou)+"\t"
			+IntegerToString(p_data.pos_data[i].open_mode_span_pattern)+"\t"


			+DoubleToString(p_data.pos_data[i].max_sigma)+"\t"
			+DoubleToString(p_data.pos_data[i].min_sigma)+"\t"

			+DoubleToString(p_data.pos_data[i].agatte_sagarunosagaru/(Point()*10))+"\t"
			+DoubleToString(p_data.pos_data[i].sagatte_agarunoagaru/(Point()*10))



		);
	}
	writestring_POS(sss);
	return true;
}


bool Add_deal(long ticket)
{
   // 履歴データを追加
   //前提として、呼び出し前にSELECTしてあること
   bool ret=false;
   int i;
   i = (int)d_data.deal_element_num;
   ArrayResize(d_data.deal_data,i+1 ,NUM_DEAL_DATA);
   
   d_data.deal_data[i].longDEAL_TICKET=HistoryDealGetInteger(ticket,DEAL_TICKET);
   d_data.deal_data[i].longDEAL_ORDER=HistoryDealGetInteger(ticket,DEAL_ORDER);
   d_data.deal_data[i].datetimeDEAL_TIME=(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
   d_data.deal_data[i].longDEAL_TIME_MSC=HistoryDealGetInteger(ticket,DEAL_TIME_MSC);
   d_data.deal_data[i].ENUM_DEAL_TYPEDEAL_TYPE=(ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket,DEAL_TYPE);
   d_data.deal_data[i].ENUM_DEAL_ENTRYDEAL_ENTRY=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket,DEAL_ENTRY);
   d_data.deal_data[i].longDEAL_MAGIC=HistoryDealGetInteger(ticket,DEAL_MAGIC);
   d_data.deal_data[i].ENUM_DEAL_REASONDEAL_REASON=(ENUM_DEAL_REASON)HistoryDealGetInteger(ticket,DEAL_REASON);
   d_data.deal_data[i].longDEAL_POSITION_ID=HistoryDealGetInteger(ticket,DEAL_POSITION_ID);
   
   
   
   d_data.deal_data[i].doubleDEAL_VOLUME=HistoryDealGetDouble(ticket,DEAL_VOLUME);
   d_data.deal_data[i].doubleDEAL_PRICE=HistoryDealGetDouble(ticket,DEAL_PRICE);
   d_data.deal_data[i].doubleDEAL_COMMISSION=HistoryDealGetDouble(ticket,DEAL_COMMISSION);
   d_data.deal_data[i].doubleDEAL_SWAP=HistoryDealGetDouble(ticket,DEAL_SWAP);
   d_data.deal_data[i].doubleDEAL_PROFIT=HistoryDealGetDouble(ticket,DEAL_PROFIT);
   
   d_data.deal_data[i].stringDEAL_SYMBOL=HistoryDealGetString(ticket,DEAL_SYMBOL);
   d_data.deal_data[i].stringDEAL_COMMENT=HistoryDealGetString(ticket,DEAL_COMMENT);

   d_data.deal_element_num++;

   return(ret);
}
void check_ADD_position_data(){
   int total=PositionsTotal(); //　保有ポジション数   
   bool flag_chg = false;
   for(int i=total-1; i>=0; i--)
   {
      ulong  Position_ticket=PositionGetTicket(i);
      long position_id = PositionGetInteger(POSITION_IDENTIFIER);
      bool flagfinded = false;
//      for(int j = p_data.scan_start_indx;j< p_data.position_element_num-1;j++){
      for(int j = (int)p_data.scan_start_indx;j< p_data.position_element_num;j++){
         if(p_data.pos_data[j].state_data == 1){
            if(p_data.pos_data[j].longPOSITION_IDENTIFIER == position_id){ 
               // OK
               flagfinded = true;
               break;
            }else{
               // 
            }
            
            
         }else{
            //if( p_data.scan_start_indx < i){
            //   p_data.scan_start_indx = i;
            //}
         }
      
      }
      if(flagfinded){
      }else{
         // Add 
         Add_posision(Position_ticket);
         flag_chg =true;
      }
 
   }
//   if(flag_chg){
//      PrintFormat("View p_data.pos_data start");
//      ArrayPrint( p_data.pos_data);
//      PrintFormat("View p_data.pos_data end");

//   }  
}

bool update_open_position(// 呼ぶところの想定：　tick時（、足が変わったとき？）
double crrent_price,
long crrent_time  //datetimeのlong型　秒
){  
   //Open中のデータを更新
   //
   bool ret=false;
   int i;
//   for(i = p_data.scan_start_indx;i<p_data.position_element_num-1;i++){
   for(i = (int)p_data.scan_start_indx;i<p_data.position_element_num;i++){// chg 20190625 fuguai
      //Open中？
      if(p_data.pos_data[i].state_data == 1){
         //Openがクローズとなったかの確認→ポジション中にあるかを確認
            ret = PositionSelectByTicket( p_data.pos_data[i].longPOSITION_TICKET);      
            if(ret){
               if(p_data.pos_data[i].doublePOSITION_PRICE_OPEN<crrent_price){ // 現価格がOpen価格より大きいとき
                  //過去の記録より大きいときに更新　
                  if( crrent_price-p_data.pos_data[i].doublePOSITION_PRICE_OPEN > p_data.pos_data[i].max_price){
//                  if(p_data.pos_data[i].max_price ==0 ){
                     p_data.pos_data[i].max_price = crrent_price-p_data.pos_data[i].doublePOSITION_PRICE_OPEN;// ＯＰＥＮ価格から上方向にどれだけ行ったかの差分（正の数字のみ）
                     p_data.pos_data[i].max_price_subtime = crrent_time - (long)p_data.pos_data[i].datetimePOSITION_TIME;
                  }else{
                     
                  }
               }else{// 現価格がOpen価格より小さい
                  if( p_data.pos_data[i].doublePOSITION_PRICE_OPEN-crrent_price > p_data.pos_data[i].min_price){
//                  if(p_data.pos_data[i].min_price ==0 ){
                     p_data.pos_data[i].min_price = p_data.pos_data[i].doublePOSITION_PRICE_OPEN-crrent_price;
                     p_data.pos_data[i].min_price_subtime = crrent_time - (long)p_data.pos_data[i].datetimePOSITION_TIME;
                  }else{
                     
                  }
                  
               }
               
               //double max_price;//最大でマイナス（反対）方向にいった値　　　スタートの建値からの差分（マイナス分）
               //long   max_price_subtime; // max更新時の建値からの差分の　時間（秒）
               //double min_price;//最大でプラス方向にいった値　　　　スタートの建値からの差分（プラス分）
               //long   min_price_subtime; // min行進時の建値からの差分の　時間（秒）


#ifdef USE_span_sigma_Bolinger

				// max_sigma//min_sigma//
				if(p_data.pos_data[i].open_sigma_Fb < sigma){
                  //過去の記録より大きいときに更新　
                	if( p_data.pos_data[i].max_sigma < sigma){
						p_data.pos_data[i].max_sigma = sigma;
					}
				}else{
                	if( p_data.pos_data[i].min_sigma > sigma){
						p_data.pos_data[i].min_sigma = sigma;
					}
				}
#endif// USE_span_sigma_Bolinger
				
				//agatte_sagarunosagaru 
				//sagatte_agarunoagaru
#ifdef delll
				トレーリング幅調査
                    高値更新時に、ローカル安値をリセット、高値記憶
                    記憶高値と現在値の差の大きいものを、上がって下がるの下がる部分とする。
				
				ローカル高値、安値　確認しあったら更新
				if( local_max_price < crrent_price){
				    local_max_price = crrent_price;
				    local_min_price = crrent_price
				}
				if(local_min_price > crrent_price){
				    local_max_price = crrent_price;
				    local_min_price = crrent_price
				}
				現在値と比較して、agatte_sagarunosagaru、sagatte_agarunoagaru　の大きいものを格納する
#endif //delll				
				if(local_min_price > crrent_price){
					local_min_price = crrent_price;
				}
				if(local_max_price < crrent_price){
					local_max_price = crrent_price;
				}
				if( local_max_price-crrent_price >p_data.pos_data[i].agatte_sagarunosagaru){
					p_data.pos_data[i].agatte_sagarunosagaru = local_max_price-crrent_price;
				}
				if( crrent_price -local_min_price >p_data.pos_data[i].sagatte_agarunoagaru){
					p_data.pos_data[i].sagatte_agarunoagaru = crrent_price -local_min_price;
				}
				


                p_data.pos_data[i].doublePOSITION_PROFIT = PositionGetDouble(POSITION_PROFIT);
               
               ret = true;
            }else{
               // position中になくなったら、ステータスの変更が必要
               p_data.pos_data[i].state_data = 2;
               PrintFormat("###### 通常ありえない：   position中になくなったら、ステータスの変更が必要);");
            }      
      
      
      }// state_data == 1
   
   
   }
   

   return(ret);

}
bool Add_posision(long Position_ticket
)
{
   //データの最後に書き込む.どこまであるかはdeal_element_numで確認。
   bool ret=false;
   int i;
   i = (int)p_data.position_element_num;//次に書き込むidx
   ret=PositionSelectByTicket(Position_ticket);
   if(ret){
      ArrayResize(p_data.pos_data,i+1,NUM_POSISION_DATA);

      p_data.pos_data[i].longPOSITION_TICKET = PositionGetInteger(POSITION_TICKET);
      
      
      p_data.pos_data[i].datetimePOSITION_TIME = (datetime)PositionGetInteger(POSITION_TIME);
      p_data.pos_data[i].longPOSITION_TIME_MSC = PositionGetInteger(POSITION_TIME_MSC);
      p_data.pos_data[i].longPOSITION_TIME_UPDATE = PositionGetInteger(POSITION_TIME_UPDATE);
      p_data.pos_data[i].longPOSITION_TIME_UPDATE_MSC = PositionGetInteger(POSITION_TIME_UPDATE_MSC);
      p_data.pos_data[i].ENUM_POSITION_TYPEPOSITION_TYPE = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      p_data.pos_data[i].longPOSITION_MAGIC = PositionGetInteger(POSITION_MAGIC);
      p_data.pos_data[i].longPOSITION_IDENTIFIER = PositionGetInteger(POSITION_IDENTIFIER);
      
      
      p_data.pos_data[i].ENUM_POSITION_REASONPOSITION_REASON = (ENUM_POSITION_REASON)PositionGetInteger(POSITION_REASON);
      
      
      
      p_data.pos_data[i].doublePOSITION_VOLUME = PositionGetDouble(POSITION_VOLUME);
      p_data.pos_data[i].doublePOSITION_PRICE_OPEN = PositionGetDouble(POSITION_PRICE_OPEN);
      p_data.pos_data[i].doublePOSITION_SL = PositionGetDouble(POSITION_SL);
      p_data.pos_data[i].doublePOSITION_TP = PositionGetDouble(POSITION_TP);
      p_data.pos_data[i].doublePOSITION_PRICE_CURRENT = PositionGetDouble(POSITION_PRICE_CURRENT);
      p_data.pos_data[i].doublePOSITION_SWAP = PositionGetDouble(POSITION_SWAP);
      p_data.pos_data[i].doublePOSITION_PROFIT = PositionGetDouble(POSITION_PROFIT);

      p_data.pos_data[i].stringPOSITION_COMMENT = PositionGetString(POSITION_COMMENT);
      
#ifdef USE_span_sigma_Bolinger
      //add 
      p_data.pos_data[i].open_sigma_Fb = sigma;
      p_data.pos_data[i].open_sigma_Lb = sigma_H1;
      
      p_data.pos_data[i].open_bollinger_bandwide_Fb = sigma_1*4;// ±2σ幅のPIPS
      p_data.pos_data[i].open_bollinger_bandwide_Fb_o1 = (Bolinger_bufferUpper1[1]-Bolinger_bufferMiddle1[1])*4;//
      p_data.pos_data[i].open_bollinger_bandwide_Fb_o2 = (Bolinger_bufferUpper1[2]-Bolinger_bufferMiddle1[2])*4;//
      p_data.pos_data[i].open_bollinger_bandwide_Fb_o3 = (Bolinger_bufferUpper1[3]-Bolinger_bufferMiddle1[3])*4;//
      p_data.pos_data[i].open_bollinger_bandwide_Fb_o4 = (Bolinger_bufferUpper1[4]-Bolinger_bufferMiddle1[4])*4;//
      p_data.pos_data[i].open_bollinger_bandwide_Fb_o5 = (Bolinger_bufferUpper1[5]-Bolinger_bufferMiddle1[5])*4;//
      p_data.pos_data[i].open_bollinger_bandwide_Lb = sigma_1_H1*4;// ±2σ幅のPIPS
      p_data.pos_data[i].open_bollinger_bandwide_Lb_o1 = (Bolinger_bufferUpper1_H1[1]-Bolinger_bufferMiddle1_H1[1])*4;//
      p_data.pos_data[i].open_bollinger_bandwide_Lb_o2 = (Bolinger_bufferUpper1_H1[2]-Bolinger_bufferMiddle1_H1[2])*4;//
      p_data.pos_data[i].open_bollinger_bandwide_Lb_o3 = (Bolinger_bufferUpper1_H1[3]-Bolinger_bufferMiddle1_H1[3])*4;//
      p_data.pos_data[i].open_bollinger_bandwide_Lb_o4 = (Bolinger_bufferUpper1_H1[4]-Bolinger_bufferMiddle1_H1[4])*4;//
      p_data.pos_data[i].open_bollinger_bandwide_Lb_o5 = (Bolinger_bufferUpper1_H1[5]-Bolinger_bufferMiddle1_H1[5])*4;//
      
      
      
      p_data.pos_data[i].open_katamuki_F = ((Bolinger_bufferMiddle1[0]-Bolinger_bufferMiddle1[4])/5)/(Point()*10);
      p_data.pos_data[i].open_katamuki1_F = ((Bolinger_bufferMiddle1[0]-Bolinger_bufferMiddle1[1])/1)/(Point()*10);//
      p_data.pos_data[i].open_katamuki2_F = ((Bolinger_bufferMiddle1[1]-Bolinger_bufferMiddle1[2])/2)/(Point()*10);//
      p_data.pos_data[i].open_katamuki3_F = ((Bolinger_bufferMiddle1[1]-Bolinger_bufferMiddle1[3])/3)/(Point()*10);//
      p_data.pos_data[i].open_katamuki_L = ((Bolinger_bufferMiddle1_H1[0]-Bolinger_bufferMiddle1_H1[4])/5)/(Point()*10);
      p_data.pos_data[i].open_katamuki1_L = ((Bolinger_bufferMiddle1_H1[0]-Bolinger_bufferMiddle1_H1[1])/1)/(Point()*10);//
      p_data.pos_data[i].open_katamuki2_L = ((Bolinger_bufferMiddle1_H1[1]-Bolinger_bufferMiddle1_H1[2])/2)/(Point()*10);//
      p_data.pos_data[i].open_katamuki3_L = ((Bolinger_bufferMiddle1_H1[1]-Bolinger_bufferMiddle1_H1[3])/3)/(Point()*10);//
      p_data.pos_data[i].open_katamuki_EMA_A = ((bufferEMA_A[0]-bufferEMA_A[4])/5)/(Point()*10);
      p_data.pos_data[i].open_katamuki_EMA_A1 = ((bufferEMA_A[0]-bufferEMA_A[1])/1)/(Point()*10);//
      p_data.pos_data[i].open_katamuki_EMA_A2 = ((bufferEMA_A[1]-bufferEMA_A[2])/2)/(Point()*10);//
      p_data.pos_data[i].open_katamuki_EMA_B1 = ((bufferEMA_B[0]-bufferEMA_B[1])/1)/(Point()*10);//
      p_data.pos_data[i].open_katamuki_EMA_B2 = ((bufferEMA_B[1]-bufferEMA_B[2])/2)/(Point()*10);//
      p_data.pos_data[i].open_katamuki_EMA_C1 = ((bufferEMA_C[0]-bufferEMA_C[1])/1)/(Point()*10);//
      p_data.pos_data[i].open_katamuki_EMA_C2 = ((bufferEMA_C[1]-bufferEMA_C[2])/2)/(Point()*10);//
      p_data.pos_data[i].open_state_tyouki_chikou_innyou = state_tyouki_chikou_innyou;//
      p_data.pos_data[i].open_state_tyouki_kumo_innyou = state_tyouki_kumo_innyou;//
      p_data.pos_data[i].open_state_tanki__chikou_innyou = state_tanki__chikou_innyou;//
      p_data.pos_data[i].open_state_tanki__kumo_innyou = state_tanki__kumo_innyou;//
      p_data.pos_data[i].open_mode_span_pattern = mode_span_pattern;//
#endif// USE_span_sigma_Bolinger

	   // init
	   local_min_price=p_data.pos_data[i].doublePOSITION_PRICE_OPEN;
	   local_max_price=local_min_price;


      p_data.pos_data[i].state_data = 1;// 追加

      p_data.position_element_num++;
   }
   
   
   
   return(ret);
}

string to_split="_life_is_good_"; // 部分文字列に分ける文字列 


//GetMethodNo_Name_Comment(to_split);

bool GetMethodNo_Name_Comment(string& s,int& m_no,string& m_name,string& comment){
  string sep="#";               // 区切り文字 
  ushort u_sep;                 // 区切り文字のコード 
  string result[];               // 文字列を受け取る配列 
  //--- 区切り文字のコードを取得する 
  u_sep=StringGetCharacter(sep,0); 
  //--- 文字列を部分文字列に分ける 
  int k=StringSplit(s,u_sep,result); 
  //--- コメントを表示する 
  PrintFormat("Strings obtained: %d. Used separator '%s' with the code %d",k,sep,u_sep); 
  //--- 取得された文字列を全て出力する 
  if(k>0) 
    { 
    for(int i=0;i<k;i++) 
       { 
        PrintFormat("result[%d]=\"%s\"",i,result[i]); 
       } 
    }
  if(k>3) {
     //s = result[0]; 
     m_no = (int)StringToInteger( result[1]); 
     m_name = result[2]; 
     comment = result[3]; 
     return (true);

  }
  return(false);
}
string MakeMethodNo_Name_Comment(int m_no,string m_name,string comment){
  string sep="#";               // 区切り文字 
  //ushort u_sep;                 // 区切り文字のコード 
  string result=sep+ IntegerToString( m_no)+sep+m_name+sep+comment;               // 文字列を受け取る配列 
  PrintFormat("result[]=\"%s\"",result); 
  return(result);   
}


void testtt(){
	
	string s1,mn,c;
	string mn2,c2;
	int i,i2;
	s1 = "a";
	mn="method_name";
	c="comment +++";
	i = 30;
	to_split=MakeMethodNo_Name_Comment(i,mn,c);
	PrintFormat("result1=%s",to_split); 
	
	GetMethodNo_Name_Comment(to_split,i2,mn2,c2);
	
	PrintFormat("result2=%s %d %s %s",i2,mn2,c2); 
}

#define method_kind_num 1
int GetMethodNum(){
   return(method_kind_num);
}
//____________________________________________________________________________________________________

// 時間フィルタ　filterTimeFrame
CSignalITF *filterTimeFrame;

int OnInitCSignalITF(){
   filterTimeFrame=new CSignalITF;
   if(filterTimeFrame==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter0");
      //ExtExpert.Deinit();
      return(INIT_FAILED);
     }

	//chg int -> bit
//	bad_minutes_of_hour_bit =1<<bad_minutes_of_hour;
//	bad_hours_of_day_bit =1<<bad_days_of_week;
//	bad_days_of_week_bit =1<<bad_days_of_week;


     
   filterTimeFrame.GoodMinuteOfHour( 	good_minute_of_hour		);
   filterTimeFrame.BadMinutesOfHour( 	bad_minutes_of_hour		);
   filterTimeFrame.GoodHourOfDay(	  good_hour_of_day			);
   filterTimeFrame.BadHoursOfDay(	  bad_hours_of_day			);
   filterTimeFrame.GoodDayOfWeek(	  good_day_of_week			);
   filterTimeFrame.BadDaysOfWeek(	  bad_days_of_week			);
     
   return 0;  
}

//CSignalITF Timefilter;

bool IsTimeFillter(){//　true エントリーOK、false エントリーNG

	double tmp;
	bool ret;
	tmp =filterTimeFrame.Direction();
	
	if(tmp == 0.0){
		ret = true;
	}else{
		ret = false;
	}
	return ret;
}



input	   int               good_minute_of_hour=-1;	//分（ 0~59）値が -1 の場合、シグナルは通して有効
input	   long              bad_minutes_of_hour=0;	//ビットフィールド。このフィールドの各ビットが分に対応します。（ 0 ビット - 0 分、... 59 ビット - 59分）。ビット値が 0 の場合、売買シグナルは対応する時間で有効にされます。ビット値が 1 の場合、売買シグナルは対応する時間で無効にされます。
input	   int               good_hour_of_day=-1;	//一日で売買シグナルが有効になる時間（ 0~23）値が -1 の場合、シグナルは一日を通して有効です。
input	   int               bad_hours_of_day=0;	//ビットフィールド。このフィールドの各ビットが時間に対応します。（ 0 ビット - 0 時、... 23 ビット - 23 時）。ビット値が 0 の場合、売買シグナルは対応する時間で有効にされます。ビット値が 1 の場合、売買シグナルは対応する時間で無効にされます。

input	   int               good_day_of_week=-1;	//売買シグナルが有効な曜日（ 0~6 で6が日曜日）。値が -1 の場合、シグナルは一週間を通して有効です。
input	   int               bad_days_of_week=0;	//ビットフィールド。このフィールドの各ビットが曜日に対応します。（ 0 ビット - 日曜、... 23 ビット - 土曜）。ビット値が 0 の場合、売買シグナルは対応する曜日で有効にされます。ビット値が 1 の場合、売買シグナルは対応する曜日で無効にされます。指定された数は、2進数として表されるビットマスクとして使用されます。無効にされた曜日は有効なものよりも高い優先度を持っています。


long bad_minutes_of_hour_bit;
int bad_hours_of_day_bit;
int bad_days_of_week_bit;



int GetAfter_bar(){
                    datetime Time_cur = TimeCurrent();
		         int after_bar_count=0; // オーダーからのバーの本数 
		         after_bar_count = 0; 
		         if(Time_cur > OrderOpenTime() && OrderOpenTime() > 0)                          //if the current time is farther than the entry Point()...
		         { after_bar_count = (int)NormalizeDouble( ((Time_cur - OrderOpenTime() ) /60), 0 ); }    //define the distance in tfM1 mybars up to the entry Point()
	return (after_bar_count);
}
int GetAfter_bar_candle(){
                    datetime Time_cur = TimeCurrent();
		         int after_bar_count=0; // オーダーからのバーの本数 
		         after_bar_count = 0; 
		         if(Time_cur > OrderOpenTime() && OrderOpenTime() > 0)                          //if the current time is farther than the entry Point()...
		         { after_bar_count = (int)NormalizeDouble( ((Time_cur - OrderOpenTime() ) /PeriodSeconds()), 0 ); }    //define the distance in tfM1 mybars up to the entry Point()
	return (after_bar_count);
}

//double chgPips2price(double d){return(d*Point()*10);}
//double chgPrice2Pips(double d){return(d/(Point()*10));}



