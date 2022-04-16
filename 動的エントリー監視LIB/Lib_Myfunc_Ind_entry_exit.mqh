//int Lots;

#ifndef EXPERT_MAGIC
#define EXPERT_MAGIC 123
#endif
            
#include <_inc\\My_function_lib2.mqh>
#define NOT_USE_POSISION_LOG_WRITE
#include "Lib_MyFunc_Trade.mqh"

#ifndef CTRADE
#define CTRADE
#include <Trade\\trade.mqh>
CTrade ctrade;
#endif//CTRADE

//Option
#define USE_debug_view_entry_after
//#define USE_IND_TO_EA_FOR_OPTIMUM_TESTER
//Ind側で描画用bufferを用意して、パラメータを設定すること
// at oninit
//    SetIndexBuffer(n,buffer)      nの番号は直値でEAがわの　バッファ番号とする。
//   //　時系列データへ（０が最新）
//         ArraySetAsSeries(buffEMA,true)
// at tick(cal)
//   bufferの先頭から順にパラメータを入れる
//          set_Ind_to_EA_para(double &p[])

//EA側で　指定バッファのCopybufferしてparaに格納する前提：　　

#ifdef commentttt
Ind側
エントリー指示（売り買い、TPSL、現在価格、時間、依頼番号、手法番号）
Exit指示

EA側

　即時動的監視エントリー
	　指定したエントリーを、TPSL]の価格を動的に監視してクローズする。
	　エントリー時に、動的監視エントリーとして、TPSLを渡して、EA側でポーリングして制御する。エントリー名（番号、手法番号、通貨）とともに渡す。
　即時動的監視エントリーのTPSLの変更
　即時動的監視エントリーのトレーリング設定有無

　ある価格を超えたら、エントリーする。
	エントリー条件はＴpLSを指定する。または、動的に監視して実施する指定

即時動的監視エントリーの監視部分について
	監視対象のデータを保持：「動的エントリー」下記を持つ
		依頼番号、指定エントリー名（番号、手法、シンボル）の文字列
		tpSL
	監視はTickで監視する。
		動的エントリーデータで有効なものを順番に超えてないかを確認する。
			売りのエントリー
				Tp、SL　Askの価格を見る
			買いのエントリ
Tp.Sl　BIDの価格を見る




受信側ポーリング
	受信→登録、処理へ
		エントリー
		
Tick動作部分
	監視部分
		Exit監視
		トレイリング更新
#endif //commenttt
//初期化
void init_entry_exit_ctr_forEA(void){// (★EA)
   ctrade.SetExpertMagicNumber(EXPERT_MAGIC);
	entry_exit_ctr_count = 0;
	entry_exit_ctr_start_idx=0;

    Ind_EntryNo=-1;
    Ind_hyoukaNo=-1;

    Ind_hyoukaSyuhouNo=-1;
    Ind_EntryPrice=-1;
    Ind_Tp_Price=-1;
    Ind_Sl_Price=-1;
   
	Ind_command=-1;
	Ind_EntryTime=-1;
	Ind_EntryDirect=-1;
	Ind_trailing_step_pips=-1;
	Ind_trailing_start_pips=-1;
	Ind_trailing_stop_pips=-1;
	Ind_send_count=-1;
	
    
    
    Ind_EntryTime = 0;
    Ind_command = -1;
    
    IndReciveData();
    pre_Ind_EntryNo=Ind_EntryNo;
	pre_Ind_send_count=Ind_send_count;
		
}
//データ定義
int entry_exit_ctr_start_idx;

int  entry_exit_ctr_count;
struct struct_entry_exit_ctr{
	int status;////0;無効、１：監視中(エントリー前)、２：エントリー後の監視中
	int	EntryNo;// entryno
	int	hyoukaNo;//
	int	hyoukaSyuhouNo;//hyoukaSyuhouNo
	int	command;// 動的監視有無: 0:なし、１：動的TPSLあり、２：動的TPSLありかつ　Trailing_stop
				//  10  即時売り買い（TPSL指定なし）
				//  20  指定決済	（指定：Ind_EntryNo,Ind_hyoukaNo,Ind_hyoukaSyuhouNo）
				//　99　全Exit　
	int EntryDirect;//-1:sell, 1:buy
	string key;
	double Tp_Price;
	double Sl_Price;
	double EntryPrice;
	datetime EntryTime;
	
	//開始利益
	double trailing_step_pips;//利益出たら次のステップに移動させる幅
	//刻みh場
	double trailing_start_pips;//0はすぐにトレーリングする。
	//トータルの利益が最大どこでSTOPにするか？
	double trailing_stop_pips;//トレーリングでの離隔。
	double lots;
	
	int testflag;
};
#define ENTRY_EXIT_CTR_OF_NUM 20000
struct_entry_exit_ctr	entry_exit_ctr[ENTRY_EXIT_CTR_OF_NUM];
void add_entry_exit_ctr(void){
	int i=entry_exit_ctr_count;
	
	entry_exit_ctr[i].EntryNo=Ind_EntryNo;
	entry_exit_ctr[i].hyoukaNo=Ind_hyoukaNo;// entryno
	entry_exit_ctr[i].hyoukaSyuhouNo=Ind_hyoukaSyuhouNo;//hyoukaSyuhouNo
	entry_exit_ctr[i].command=Ind_command;// 動的監視有無: 0:即時Entry、１：動的TPSLあり、２：動的TPSLありかつ　Trailing_stop
	entry_exit_ctr[i].EntryDirect=Ind_EntryDirect;//-1:sell, 1:buy
	entry_exit_ctr[i].key=MakeKeyName_Comment((int)Ind_EntryNo,Ind_hyoukaNo,Ind_hyoukaSyuhouNo);
	entry_exit_ctr[i].Tp_Price=Ind_Tp_Price;
	entry_exit_ctr[i].Sl_Price=Ind_Sl_Price;
	entry_exit_ctr[i].EntryPrice=Ind_EntryPrice;
	entry_exit_ctr[i].EntryTime=Ind_EntryTime;
	//開始利益
	entry_exit_ctr[i].trailing_step_pips=Ind_trailing_step_pips;//利益出たら次のステップに移動させる幅
	//刻みh場
	entry_exit_ctr[i].trailing_start_pips=Ind_trailing_start_pips;//0はすぐにトレーリングする。
	//トータルの利益が最大どこでSTOPにするか？
	entry_exit_ctr[i].trailing_stop_pips=Ind_trailing_stop_pips;//トレーリングでの離隔。
	entry_exit_ctr[i].lots = Ind_lots;
	entry_exit_ctr[i].status = 1;//0;無効、１：監視中

#ifdef USE_debug_view_entry_after	
	datetime nowtime=TimeCurrent();
    entry_exit_ctr[i].EntryTime=nowtime;
    entry_exit_ctr[i].testflag=0;// 0未処理　１処理した
#endif //USE_debug_view_entry_after    
    
    entry_exit_ctr_count++;
}

//監視部分（★EA Tick部分へ)
void entry_exit_ctr_tick_exe(double now_price_ask,double now_price_bid){
    datetime nowtime=TimeCurrent();
	//受信処理
    IndReciveData();
	if(IndChkChgData()==true){
		if(Ind_EntryNo>130){ printf("★★★★chgRecive");}//debug ★★★
        //登録処理
        add_entry_exit_ctr();
	   
	}
	//データ受信完了フラグ送信
	reciveed_senddata();
	//監視処理
	int first_find_idx=0;
	for(int i=entry_exit_ctr_start_idx;i<entry_exit_ctr_count;i++){
		if(entry_exit_ctr[i].status >= 1){//監視対象あり　　エントリー処理・監視
			
			if(first_find_idx == 0){
				first_find_idx = i;
			}
				
			if(entry_exit_ctr[i].command == 0){//即時Entry
			    if(entry_exit_ctr[i].status == 1){
			        OrderExecute_EntryNo(i);
			        
			    }
			}else if(entry_exit_ctr[i].command == 10){//即時エントリー
			    if(entry_exit_ctr[i].status == 1){
					OrderExecute_EntryNo_for_sokuji(i);
					entry_exit_ctr[i].status = 2;
				}
			}else if(entry_exit_ctr[i].command == 20){//特定Exit
			    if(entry_exit_ctr[i].status != 0){
					exit_idx(i);
					entry_exit_ctr[i].status = 0;
				}


			}else if(entry_exit_ctr[i].command == 99){//全Exit
				exit_all();
				for(i=entry_exit_ctr_start_idx;i<entry_exit_ctr_count;i++){
					if(entry_exit_ctr[i].status >= 1){//監視対象あり　　エントリー処理・監視
						entry_exit_ctr[i].status = 0;//無効へ
					}
				}

			}else if(entry_exit_ctr[i].command == 1){//　監視　　動的TPSLあり
			    //Entry 処理
			    if(entry_exit_ctr[i].status == 1){
			        OrderExecute_EntryNo(i);
			    }
			    //監視処理
				bool flag_exit = false;
				//超えたか
				if(entry_exit_ctr[i].EntryDirect == 1){
					//buy
					if(now_price_bid >= entry_exit_ctr[i].Tp_Price){
						//exit処理
						flag_exit = true;
					}else if(now_price_bid <= entry_exit_ctr[i].Sl_Price){
						//exit処理
						flag_exit = true;
					}
				}else{
					//sell
					if(now_price_ask <= entry_exit_ctr[i].Tp_Price){
						//exit処理
						flag_exit = true;
					}else if(now_price_ask >= entry_exit_ctr[i].Sl_Price){
						//exit処理
						flag_exit = true;
					}
				}
				if(flag_exit == true){
					//exit処理 を実行
					exit_entry_exit_ctr(entry_exit_ctr[i].key);
					entry_exit_ctr[i].status= 0; //監視なしへ
				}
			}else if(entry_exit_ctr[i].command == 2){//　Trailing
				//Trailing
			}
		
		}else {
#ifdef USE_debug_view_entry_after	
        	//datetime nowtime=TimeCurrent();
            if(entry_exit_ctr[i].testflag==0 &&  entry_exit_ctr[i].EntryTime + PeriodSeconds()*  30 < nowtime){
                entry_exit_ctr[i].testflag=1;// 0未処理　１処理した
            }
#endif //USE_debug_view_entry_after    
 	    }
	
	}
	//読み取りのはじめのidxの更新
	if(first_find_idx > entry_exit_ctr_start_idx){
		entry_exit_ctr_start_idx = first_find_idx;
	}
	
}
void exit_all(void){
	ctrade.PositionClose(_Symbol);
}
void exit_idx(int i){
	string key = MakeKeyName_Comment(entry_exit_ctr[i].EntryNo,entry_exit_ctr[i].hyoukaNo,entry_exit_ctr[i].hyoukaSyuhouNo);
	exit_entry_exit_ctr(key);
}
void exit_entry_exit_ctr(string &key){// key  売り買い情報
	PositionSelect(Symbol());
	int total=PositionsTotal(); //　保有ポジション数	
	bool flagfinded = false;
	long  Position_ticket=0;

	double lots;//
	//double price,
	//nt slippage,
	//color arrow_color,///---
	
    for(int i=total-1; i>=0; i--)
	{
		string sret = PositionGetSymbol(i);
		if(sret !=""){
			Position_ticket=(long)PositionGetTicket(i);//ポジションの選択
			string comment = PositionGetString(POSITION_COMMENT);
			
			if(comment == key){
				flagfinded = true;
				lots=PositionGetDouble(POSITION_VOLUME);
				break;
			}
		}
	}
	if(flagfinded == true){
		bool bret = OrderClose_ticket((int)Position_ticket,key);
		if( bret == false){
			printf("error "+__FUNCTION__);
		}
	}
}

bool OrderClose_ticket(
int ticket,//
string str_comment
){
			   
			   // Selectしてあることが前提
			   
			   
			   
			   //--- 結果とリクエストの宣言
				 MqlTradeRequest request;
				 MqlTradeResult  result;
				 //int total=PositionsTotal(); //　保有ポジション数   
				 bool ret = true;
				double lots=PositionGetDouble(POSITION_VOLUME);
			   //--- 全ての保有ポジションの取捨
				// for(int i=total-1; i>=0; i--)
				   {
				   //--- 注文のパラメータ
				   // ulong  position_ticket=PositionGetTicket(i);									   // ポジションチケット
				   ulong  position_ticket = ticket; 									// ポジションチケット
				   string position_symbol=PositionGetString(POSITION_SYMBOL);						// シンボル 
				   int	  digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS); 			// 小数点以下の桁数
				   ulong  magic=PositionGetInteger(POSITION_MAGIC); 								// ポジションのMagicNumber
				   //double volume=PositionGetDouble(POSITION_VOLUME);								   // ポジションボリューム
				   double volume=lots;								   // ポジションボリューム
				   ENUM_POSITION_TYPE type1=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);	 // ポジションタイプ
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
					   request.action	=TRADE_ACTION_DEAL; 	  // 取引操作タイプ
					   request.position =position_ticket;		  // ポジションチケット
					   request.symbol	=position_symbol;		  // シンボル 
					   request.comment = str_comment;
					   request.volume	=volume;				   // ポジションボリューム
					   request.deviation=5; 					  // 価格からの許容偏差
					   request.magic	=EXPERT_MAGIC;			   // ポジションのMagicNumber
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
					   			 //flagNotTrade = false;

					  }
					  else{ ret =false;}
				   }
				   return(ret);
                }


///受信部分　EA部分
string Ind_paras[]={
"Ind_EntryNo",
"Ind_hyoukaNo",
"Ind_hyoukaSyuhouNo",
"Ind_EntryPrice",
"Ind_Tp_Price",
"Ind_Sl_Price"
"Ind_command",
"Ind_EntryTime",
"Ind_EntryDirect",
"Ind_trailing_step_pips",
"Ind_trailing_start_pips",
"Ind_trailing_stop_pips"
};

int Ind_EntryNo,pre_Ind_EntryNo;
int Ind_EntryDirect;
int Ind_hyoukaNo,pre_Ind_hyoukaNo;
int Ind_hyoukaSyuhouNo,pre_Ind_hyoukaSyuhouNo;
double Ind_EntryPrice,pre_Ind_EntryPrice;
double Ind_Tp_Price,pre_Ind_Tp_Price;
double Ind_Sl_Price,pre_Ind_Sl_Price;
int Ind_command;
datetime Ind_EntryTime;
double Ind_trailing_step_pips;
double Ind_trailing_start_pips;
double Ind_trailing_stop_pips;
double Ind_lots;
int Ind_send_count,pre_Ind_send_count;//送信データをセット後、前回値より１あげることで、データを変化したと通知する。
int Ind_send_flag;// 0の時に送信可能。送信データ設定後、フラグを１にする。
//void IndOninit(void){
//    Ind_EntryNo=-1;
//    Ind_hyoukaNo=-1;
//
//    Ind_hyoukaSyuhouNo=-1;
//    Ind_EntryPrice=-1;
//    Ind_Tp_Price=-1;
//    Ind_Sl_Price=-1;
//   
//	Ind_command=-1;
//	Ind_EntryTime=-1;
//	Ind_EntryDirect=-1;
//	Ind_trailing_step_pips=-1;
//	Ind_trailing_start_pips=-1;
//	Ind_trailing_stop_pips=-1;
//    
//    
//    Ind_EntryTime = 0;
//    Ind_command = -1;
//    
//    IndReciveData();
//    pre_Ind_EntryNo=Ind_EntryNo;
//    
//    //
//    ENUM_TIMEFRAMES period = Period();
//    int handle = iCustom(Symbol(),Period(),"MyMASignal\\パターン\\_20200509_current_レンジパターン\\TestZigzagPattern_current",period);
//    
//}
//void IndOnTick_Entry(void){
//    IndReciveData();
//	if(IndChkChgData()==true){
//        //Entry
//	    OrderExecute();
//	}
//}
bool IndChkChgData(void){



    return ( Ind_EntryNo!=-1 && (
         //Ind_EntryNo != pre_Ind_EntryNo || 
	      Ind_send_count != pre_Ind_send_count
	  ));
}
extern double para[];
void IndReciveData(void){
    pre_Ind_EntryNo=Ind_EntryNo;
	pre_Ind_send_count = Ind_send_count;
    
    double re;
    bool ret;
	ret = GlobalVariableGet("Ind_EntryNo",re);
	if(ret==true){
		Ind_EntryNo = (int)re;
	}

	ret = GlobalVariableGet("Ind_EntryDirect",re);
	if(ret==true){
		 Ind_EntryDirect= (int)re;
	}

	ret = GlobalVariableGet("Ind_hyoukaNo",re);
	if(ret==true){
		 Ind_hyoukaNo= (int)re;
	}
	ret = GlobalVariableGet("Ind_hyoukaSyuhouNo",re);
	if(ret==true){
		 Ind_hyoukaSyuhouNo= (int)re;
	}
	ret = GlobalVariableGet("Ind_EntryPrice",re);
	if(ret==true){
		Ind_EntryPrice = re;
	}
	ret = GlobalVariableGet("Ind_Tp_Price",re);
	if(ret==true){
		Ind_Tp_Price = re;
	}
	ret = GlobalVariableGet("Ind_Sl_Price",re);
	if(ret==true){
		Ind_Sl_Price =re;
	}


	ret = GlobalVariableGet("Ind_command",re);
	if(ret==true){
		Ind_command =(int)re;
	}
	ret = GlobalVariableGet("Ind_EntryTime",re);
	if(ret==true){
		Ind_EntryTime =(datetime)re;
	}
	ret = GlobalVariableGet("Ind_EntryDirect",re);
	if(ret==true){
		Ind_EntryDirect =(int)re;
	}
	ret = GlobalVariableGet("Ind_trailing_step_pips",re);
	if(ret==true){
		Ind_trailing_step_pips =re;
	}
	ret = GlobalVariableGet("Ind_trailing_start_pips",re);
	if(ret==true){
		Ind_trailing_start_pips =re;
	}
	ret = GlobalVariableGet("Ind_trailing_stop_pips",re);
	if(ret==true){
		Ind_trailing_stop_pips =re;
	}

	ret = GlobalVariableGet("Ind_lots",re);
	if(ret==true){
		Ind_lots =re;
	}
	ret = GlobalVariableGet("Ind_send_count",re);
	if(ret==true){
		Ind_send_count =re;
	}
#define debug_recive	
#ifdef debug_recive
	if(Ind_EntryNo>130){
		printf("★★★Recive data"
			+"entryNo:"+IntegerToString(Ind_EntryNo)
			+"EntryPrice:"+DoubleToString(Ind_EntryPrice,5)
			+"Tp_Price:"+IntegerToString(Ind_command)
			+"Sl_Price:"+IntegerToString((int)Ind_send_count)
			
			);
	}
#endif



#ifdef USE_IND_TO_EA_FOR_OPTIMUM_TESTER
//最適化時にグローバル変数が使えないっぽいので、無理やり指標にパラメータを詰め込んで使用する。
		int i=0;
		Ind_EntryNo = (int)para[i++];
		Ind_EntryDirect= (int)para[i++];
		Ind_hyoukaNo= (int)para[i++];
		Ind_hyoukaSyuhouNo= (int)para[i++];
		Ind_EntryPrice = para[i++];
		Ind_Tp_Price = para[i++];
		Ind_Sl_Price = para[i++];
		Ind_command = (int)para[i++];
		Ind_EntryTime = (datetime)para[i++];
		Ind_EntryDirect = (int)para[i++];
		Ind_trailing_step_pips = para[i++];
		Ind_trailing_start_pips = para[i++];
		Ind_trailing_stop_pips = para[i++];
		Ind_lots = para[i++];
		Ind_send_count = para[i++];
#endif//USE_IND_TO_EA_FOR_OPTIMUM_TESTER







//debug
//testtt2();
}
//即時Order実行
void OrderExecute_EntryNo_for_sokuji(int i){
	string str_comment = MakeKeyName_Comment(entry_exit_ctr[i].EntryNo,entry_exit_ctr[i].hyoukaNo,entry_exit_ctr[i].hyoukaSyuhouNo);
	double bid,ask;
    RefreshPrice(bid, ask);
	double lots = entry_exit_ctr[i].lots;
	if(entry_exit_ctr[i].EntryDirect==1){
		ctrade.Buy(lots,_Symbol,ask,0.0,0.0,str_comment);
	}else if(entry_exit_ctr[i].EntryDirect==-1){
		ctrade.Sell(lots,_Symbol,bid,0.0,0.0,str_comment);
	}
	

}
//Order実行
void OrderExecute_EntryNo(int i){
	double bid, ask;
	double sl,tp;
	bool ret=false;
	int flag_canNotTPSL = false;//小さすぎたら即時で実施
	//add 2019/08/03 時間フィルタを追加
	string str_comment = MakeKeyName_Comment(entry_exit_ctr[i].EntryNo,entry_exit_ctr[i].hyoukaNo,entry_exit_ctr[i].hyoukaSyuhouNo);
    RefreshPrice(bid, ask);
	double lots = entry_exit_ctr[i].lots;
//    sl = NormalizeDouble(Ind_Sl_Price,Digits());
//    tp = NormalizeDouble(Ind_Tp_Price,Digits());
    
    sl = MathAbs(entry_exit_ctr[i].EntryPrice-entry_exit_ctr[i].Sl_Price);
    int pp=55;
    if( sl < pp*Point()){
        sl=pp*Point();
        flag_canNotTPSL = true;
    }
    tp = MathAbs(entry_exit_ctr[i].Tp_Price-entry_exit_ctr[i].EntryPrice);
    if( tp < pp*Point()){
        tp=pp*Point();
        flag_canNotTPSL = true;
    }
    if(entry_exit_ctr[i].EntryDirect==-1){
        sl = NormalizeDouble(ask+sl,Digits());
        tp = NormalizeDouble(bid-tp,Digits());
        ret=OrderSend(Symbol(),  OP_SELL,lots,bid,3,sl,tp,str_comment,16384,0,Red); 
//    }else if(Ind_EntryDirect==1){	// chg 20210820 参照不具合　正しい変数を参照する
    }else if(entry_exit_ctr[i].EntryDirect==1){	//　chg 20210820 参照不具合　正しい変数を参照する
        sl = NormalizeDouble(bid-sl,Digits());
        tp = NormalizeDouble(ask+tp,Digits());
        ret = OrderSend(Symbol(),  OP_BUY,lots,ask,3,sl,tp,str_comment,16384,0,Green); 
    }
    if(ret == false){
		printf("error entry at :"+ __FUNCTION__);
	}


    if( flag_canNotTPSL == false){
		entry_exit_ctr[i].status = 0;// 即時としてEntry完了したので、監視しないようにする。
	}else{
		entry_exit_ctr[i].command = 1;//：動的TPSLあり　に変更し、監視対象とする。
		entry_exit_ctr[i].status=2;
	}
}

//void OrderExecute(double Lots,int Ind_EntryNo,int Ind_hyoukaNo,int Ind_hyoukaSyuhouNo){//string m_name,int hyoukaSyuhouNo,string c){
//	double bid, ask;
//	double sl,tp;
//	//add 2019/08/03 時間フィルタを追加
////	if(IsTimeFillter()==false){
////		return;
////	}
////string MakeKeyName_Comment(int no,int hyoukaSyuhouNo,int EntryDirect){
//	string str_comment = MakeKeyName_Comment((int)Ind_EntryNo,Ind_hyoukaNo,Ind_hyoukaSyuhouNo);
//    RefreshPrice(bid, ask);
//
////    sl = NormalizeDouble(Ind_Sl_Price,Digits());
////    tp = NormalizeDouble(Ind_Tp_Price,Digits());
//    
//    sl = MathAbs(Ind_EntryPrice-Ind_Sl_Price);
//    int pp=55;
//    if( sl < pp*Point()){
//        sl=pp*Point();
//    }
//    tp = MathAbs(Ind_Tp_Price-Ind_EntryPrice);
//    if( tp < pp*Point()){
//        tp=pp*Point();
//    }
//    
//    if(Ind_EntryDirect==-1){
//        sl = NormalizeDouble(ask+sl,Digits());
//        tp = NormalizeDouble(bid-tp,Digits());
//        OrderSend(Symbol(),  OP_SELL,Lots,bid,3,sl,tp,str_comment,16384,0,Red); 
//    }else if(Ind_EntryDirect==1){
//        sl = NormalizeDouble(bid-sl,Digits());
//        tp = NormalizeDouble(ask+tp,Digits());
//        OrderSend(Symbol(),  OP_BUY,Lots,ask,3,sl,tp,str_comment,16384,0,Green); 
//    }
//}
void testtt2(void){
    //sl tp
    printf("0.0001*10,0.001");
    test_order(0.0001*10,0.01);



    printf("0.0001,0.001");
    test_order(0.0001,0.001);

    printf("0.0003,0.001");
    test_order(0.0003,0.001);

    printf("0.0005,0.001");
    test_order(0.0005,0.001);

    printf("0.001,0.001");
    test_order(0.0005,0.001);

}

void test_order(double s,double t){
	double bid, ask;
	double sl,tp;
	//add 2019/08/03 時間フィルタを追加
	if(IsTimeFillter()==false){
		return;
	}
	string str_comment = MakeKeyName_Comment((int)Ind_EntryNo,Ind_hyoukaNo,Ind_hyoukaSyuhouNo);
    RefreshPrice(bid, ask);
    int ddd = Digits();

 //                       sl_sell = NormalizeDouble((ask+StopLoss*Point()),Digits());
//                        tp_sell = NormalizeDouble((bid-TakeProfit*Point()),Digits());

//     sl = NormalizeDouble(bid+s,Digits());
    s=50*Point();//5PIPS NG
    
    s=70*Point();//5PIPS OK
    s=60*Point();//9PIPS OK
    s=55*Point();//9PIPS OK
    s=52*Point();//9PIPS OK
    s=51*Point();//9PIPS NG
     sl = NormalizeDouble(ask+s,Digits());
    tp = NormalizeDouble(bid-t,Digits());
    
    
    OrderSend(Symbol(),  OP_SELL,0.1,bid,3,sl,tp,str_comment,16384,0,Red); 
}


string MakeKeyName_Comment(int no,int hyoukaSyuhouNo,int EntryDirect){
  string sep="#";               // 区切り文字 
  //ushort u_sep;                 // 区切り文字のコード 
  string result=sep+ IntegerToString( no)
  				+sep+ IntegerToString( hyoukaSyuhouNo)
  				+sep+ IntegerToString( EntryDirect)
  				;               // 文字列を受け取る配列 
  
  
  // debug 20200222
  //result = "123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#123456789#";
  //###       32byte分しかコメントには欠けない　　　123456789#123456789#123456789#1
  //Deal_Comment用リンク番号を先頭に付与
  return(result);   
}


//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
// for Ind
//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////


void init_entry_exit_ctr_forInd(void){//　for　Ind使用★　Initへ追加
	Ind_EntryNo = 0;
	Ind_send_count = 0;
	Ind_send_flag=0;
	// queue
   entry_exit_send_queue_num=0;
   queue_head =0; queue_num = 0;
}

//各処理　　//　for　Ind使用★　Entry時に追加

//通常のTPSLの発注
void SetSendData_forEntry_tpsl(int EntryDirect,int hyoukaNo,int hyoukaSyuhouNo,double EntryPrice,double Tp_Price,double Sl_Price,double lots){
	int command = 0;
	Ind_EntryNo = Ind_EntryNo+1;
	int a = Ind_EntryNo;
	#ifdef dellll
	GlobalVariableSet("Ind_command",command);// 動的監視有無: 0:なし、１：動的TPSLあり、２：動的TPSLありかつ　Trailing_stop
	GlobalVariableSet("Ind_EntryNo",a);
	GlobalVariableSet("Ind_EntryDirect",EntryDirect);
	GlobalVariableSet("Ind_hyoukaNo",hyoukaNo);
	GlobalVariableSet("Ind_hyoukaSyuhouNo",hyoukaSyuhouNo);
	GlobalVariableSet("Ind_EntryPrice",EntryPrice);
	GlobalVariableSet("Ind_Tp_Price",Tp_Price);
	GlobalVariableSet("Ind_Sl_Price",Sl_Price);
	GlobalVariableSet("Ind_lots",lots);
	GlobalVariableSet("Ind_send_count",++Ind_send_count);
	#endif //dellll
	struct_entry_exit_send_queue ss;
	ss.Ind_command=command;
	ss.Ind_EntryNo=a;
	ss.Ind_EntryDirect=EntryDirect;
	ss.Ind_hyoukaNo=hyoukaNo;
	ss.Ind_hyoukaSyuhouNo=hyoukaSyuhouNo;
	ss.Ind_EntryPrice=EntryPrice;
	ss.Ind_Tp_Price=Tp_Price;
	ss.Ind_Sl_Price=Sl_Price;
	ss.Ind_lots=lots;
	ss.Ind_send_count=++Ind_send_count;

	send_add_queue_entry_exit_send(ss);
	
}
 //動的監視でTPSLを実現
void SetSendData_forEntry_tpsl_direct_ctrl(int EntryDirect,int hyoukaNo,int hyoukaSyuhouNo,double EntryPrice,double Tp_Price,double Sl_Price,double lots){
	int command = 1;
	Ind_EntryNo = Ind_EntryNo+1;
	int a=Ind_EntryNo;
	struct_entry_exit_send_queue ss;
	ss.Ind_command=command;// 動的監視有無: 0:なし、１：動的TPSLあり、２：動的TPSLありかつ　Trailing_stop
	ss.Ind_EntryNo=a;
	ss.Ind_EntryDirect=EntryDirect;
	ss.Ind_hyoukaNo=hyoukaNo;
	ss.Ind_hyoukaSyuhouNo=hyoukaSyuhouNo;
	ss.Ind_EntryPrice=EntryPrice;
	ss.Ind_Tp_Price=Tp_Price;
	ss.Ind_Sl_Price=Sl_Price;
	ss.Ind_lots=lots;
	ss.Ind_send_count=++Ind_send_count;


	send_add_queue_entry_exit_send(ss);



	printf("SetSendData_forEntry_tpsl_direct_ctrl"
	    +"entryNo:"+IntegerToString(a)
	    +"Dir:"+IntegerToString(EntryDirect)
	    +"Ind_hyoukaNo:"+IntegerToString(hyoukaNo)
	    +"EntryPrice:"+DoubleToString(EntryPrice,5)
	    +"Tp_Price:"+DoubleToString(Tp_Price,5)
	    +"Sl_Price:"+DoubleToString(Sl_Price,5)
	    
	    );
}

//即時エントリー
void SetSendData_forEntry_sokuji(int EntryDirect,int hyoukaNo,int hyoukaSyuhouNo,double EntryPrice,double Tp_Price,double Sl_Price,double lots){
	int command = 10;
	Ind_EntryNo = Ind_EntryNo+1;
	int a=Ind_EntryNo;
	struct_entry_exit_send_queue ss;
	ss.Ind_command=command;// 動的監視有無: 0:なし、１：動的TPSLあり、２：動的TPSLありかつ　Trailing_stop
	ss.Ind_EntryNo=a;
	ss.Ind_EntryDirect=EntryDirect;
	ss.Ind_hyoukaNo=hyoukaNo;
	ss.Ind_hyoukaSyuhouNo=hyoukaSyuhouNo;
	ss.Ind_EntryPrice=EntryPrice;
	ss.Ind_Tp_Price=Tp_Price;
	ss.Ind_Sl_Price=Sl_Price;
	ss.Ind_lots=lots;
	ss.Ind_send_count=++Ind_send_count;
	send_add_queue_entry_exit_send(ss);
	
	printf("★★★SetSendData_forEntry_sokuji"
	    +"entryNo:"+IntegerToString(a)
	    +"Dir:"+IntegerToString(EntryDirect)
	    +"Ind_hyoukaNo:"+IntegerToString(hyoukaNo)
	    +"EntryPrice:"+DoubleToString(EntryPrice,5)
	    +"Tp_Price:"+DoubleToString(Tp_Price,5)
	    +"Sl_Price:"+DoubleToString(Sl_Price,5)
	    
	    );
}
//ExitAll
void SetSendData_forExitAll(void){
	int command = 99;
	Ind_EntryNo = Ind_EntryNo+1;
	int a=Ind_EntryNo;
	struct_entry_exit_send_queue ss;
	ss.Ind_command=command;// 動的監視有無: 0:なし、１：動的TPSLあり、２：動的TPSLありかつ　Trailing_stop
	ss.Ind_EntryNo=a;
	ss.Ind_send_count=++Ind_send_count;
	send_add_queue_entry_exit_send(ss);

	
	printf("★★★★SetSendData_forExitAll"
	    +"entryNo:"+IntegerToString(a)
	    
	    );
}
//Exit
void SetSendData_forExit(int entry_no){// 指定のentry_noをExitさせる
	int command = 20;
	int a=entry_no;
	struct_entry_exit_send_queue ss;
	ss.Ind_command=command;// 動的監視有無: 0:なし、１：動的TPSLあり、２：動的TPSLありかつ　Trailing_stop
	ss.Ind_EntryNo=a;
	ss.Ind_hyoukaNo=0;				//将来拡張用（区別したいなら、引く数に追加して使用すること）
	ss.Ind_hyoukaSyuhouNo=0;		//将来拡張用（区別したいなら、引く数に追加して使用すること）
	ss.Ind_send_count=++Ind_send_count;

	send_add_queue_entry_exit_send(ss);

	printf("★★★★SetSendData_forExit"
	    +"entryNo:"+IntegerToString(a)
	    
	    );
}

void set_Ind_to_EA_para(double &p[]){
#ifdef USE_IND_TO_EA_FOR_OPTIMUM_TESTER
	int i=0;
//    if(p==NULL){return;}
	p[i++]=Ind_EntryNo;
	p[i++]=Ind_EntryDirect;
	p[i++]=Ind_hyoukaNo;
	p[i++]=Ind_hyoukaSyuhouNo;
	p[i++]=Ind_EntryPrice;
	p[i++]=Ind_Tp_Price;
	p[i++]=Ind_Sl_Price;
	p[i++]=Ind_command;
	p[i++]=(double)Ind_EntryTime;
	p[i++]=Ind_EntryDirect;
	p[i++]=Ind_trailing_step_pips;
	p[i++]=Ind_trailing_start_pips;
	p[i++]=Ind_trailing_stop_pips;
	p[i++]=Ind_lots;
	p[i++]=Ind_send_count;
	
#endif//USE_IND_TO_EA_FOR_OPTIMUM_TESTER
    
} 

//int enqueue(data_t enq_data) の仕様
//enq_data を待ち行列 queue_data に追加し（entry_exit_send_queue_num を１つ増やし），
//戻り値 SUCCESS を返す。ただし，待ち行列が満杯であるときには，追加せず FAILURE を返す。
struct struct_entry_exit_send_queue{
   int Ind_EntryNo,pre_Ind_EntryNo;
   int Ind_EntryDirect;
   int Ind_hyoukaNo,pre_Ind_hyoukaNo;
   int Ind_hyoukaSyuhouNo,pre_Ind_hyoukaSyuhouNo;
   double Ind_EntryPrice,pre_Ind_EntryPrice;
   double Ind_Tp_Price,pre_Ind_Tp_Price;
   double Ind_Sl_Price,pre_Ind_Sl_Price;
   int Ind_command;
   datetime Ind_EntryTime;
   double Ind_trailing_step_pips;
   double Ind_trailing_start_pips;
   double Ind_trailing_stop_pips;
   double Ind_lots;
   int Ind_send_flag;
   int Ind_send_count;

	
};
int entry_exit_send_queue_num;
int queue_head ,queue_num;
#define QUEUE_SIZE 12
#define SUCCESS 1
#define FAILURE 2
struct_entry_exit_send_queue entry_exit_send_queue[QUEUE_SIZE];

int enqueue(struct_entry_exit_send_queue &enq_data)
{
    if (entry_exit_send_queue_num < QUEUE_SIZE) {
        entry_exit_send_queue[(queue_head + entry_exit_send_queue_num) % QUEUE_SIZE] = enq_data;
        entry_exit_send_queue_num ++;
        return SUCCESS;
    } else {
        return FAILURE;
    }
}
//int dequeue(data_t *deq_data) の仕様
//待ち行列が空でなければ、それからデータを一つ取り出し，その値を *deq_data に代入し、entry_exit_send_queue_num は１減じ， 
//queue_head は１つ進めて、SUCCESS を戻り値として返す。ただし，待ち行列が空のときは，戻り値として FAILURE を返す他は、何もしない。

int dequeue(struct_entry_exit_send_queue &deq_data)
{
    if (entry_exit_send_queue_num > 0) {
        deq_data = entry_exit_send_queue[queue_head];
        queue_head = (queue_head + 1) % QUEUE_SIZE;
        entry_exit_send_queue_num --;
        return SUCCESS;
    } else {
        return FAILURE;
    }
}
void send_add_queue_entry_exit_send(struct_entry_exit_send_queue &enq_data){
	enqueue(enq_data);
	send_syori_entry_exit_send();
}

void send_syori_entry_exit_send(void){//送信可能（受信側が受けっとったあとなら、送信する）
   int ret=FAILURE;
	if(entry_exit_send_queue_num>0){
		recive_data_for_Ind();
		if(Ind_send_flag==0){
			//送信処理
			struct_entry_exit_send_queue ss;
			ret = dequeue(ss);
			if(ret == SUCCESS){
				GlobalVariableSet("Ind_command",ss.Ind_command);
				GlobalVariableSet("Ind_EntryNo",ss.Ind_EntryNo);
				GlobalVariableSet("Ind_EntryDirect",ss.Ind_EntryDirect);
				GlobalVariableSet("Ind_hyoukaNo",ss.Ind_hyoukaNo);
				GlobalVariableSet("Ind_hyoukaSyuhouNo",ss.Ind_hyoukaSyuhouNo);
				GlobalVariableSet("Ind_EntryPrice",ss.Ind_EntryPrice);
				GlobalVariableSet("Ind_Tp_Price",ss.Ind_Tp_Price);
				GlobalVariableSet("Ind_Sl_Price",ss.Ind_Sl_Price);
				GlobalVariableSet("Ind_lots",ss.Ind_lots);				
				
				Ind_send_flag=1;
				GlobalVariableSet("Ind_send_flag",Ind_send_flag);
				GlobalVariableSet("Ind_send_count",++Ind_send_count);
			}
		}
	}
}
//★Ind　動的監視Tick　IndのTickに定義
void send_ctr_tick_exe(void){
	send_syori_entry_exit_send();
}

void reciveed_senddata(void){	//データ受信後、受信したことを送信側に通知　1→０へ
	GlobalVariableSet("Ind_send_flag",0);
}

void recive_data_for_Ind(void){
	double re;
	bool ret=false;
	ret = GlobalVariableGet("Ind_send_flag",re);
	if(ret==true){
		Ind_send_flag =(int)re;
	}
}