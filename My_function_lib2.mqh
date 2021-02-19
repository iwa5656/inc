#ifndef My_function_lib2
#define  My_function_lib2 1
void addstring(string& s,string ss){ //改行付き
	s=s+ss+"\r\n";
}
void addstring_nochgline(string& s,string ss){ //
	s=s+ss;
}


double chgPips2price(double d){return(d*Point()*10.0);}
double chgPrice2Pips(double d){return(d/(Point()*10.0));}


void test_writestring_file(string filename,string str,bool add)  //  表示文字列、　true　既存の文字のあとに追加、false　上書き（数が足りないと過去のものが残る）
{
//ファイルの最後にStrに追加　改行は\r\nでOK
	//--- ファイルを開く 
	ResetLastError();
//	int file_handle=FileOpen(InpDirectoryName+"/"+InpFileName,FILE_READ|FILE_BIN|FILE_ANSI);
//	int file_handle=FileOpen("C:\\Users\\makoto\\AppData\\Roaming\\MetaQuotes\\terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Experts\\Data\\test.txt",FILE_READ|FILE_BIN|FILE_ANSI);
//	int file_handle=FileOpen("test.txt",FILE_READ|FILE_BIN|FILE_ANSI);
//	int file_handle=FileOpen("Data\\test.txt",FILE_READ|FILE_ANSI);
//	int file_handle=FileOpen("Data\\test.txt",FILE_WRITE |FILE_BIN|FILE_ANSI);
	int file_handle=FileOpen("Data\\"+filename,FILE_READ|FILE_WRITE |FILE_ANSI|FILE_TXT);
	if(file_handle!=INVALID_HANDLE)
    	{
//debug	  	PrintFormat("%s file is available for reading",filename);
//debug	  	PrintFormat("File path: %s\\Files\\",TerminalInfoString(TERMINAL_DATA_PATH));
	  	//--- 追加の変数
//	  	int	  str_size;
//	  	string str;
         string tmp;

if ( add== true){	  	
	  	//--- ファイルからデータを読む
	  	while(!FileIsEnding(file_handle))
		{
		        tmp=FileReadString(file_handle);

#ifdef aaa	  	
		      	//--- 時間を書くのに使用されるシンボルの数を見つける
		        str_size=FileReadInteger(file_handle,INT_VALUE);
		      	//--- 文字列を読む
		        str=FileReadString(file_handle,str_size);
		      	//--- 文字列を出力する
		      	PrintFormat(str);
#endif
		}
}		
//      str = (string)TimeCurrent();
//      str = str + "\t" + "test"+ "\r\ntest2";
//      FileSeek(file_handle,0, SEEK_END);
      FileWrite(file_handle,str);
      FileFlush(file_handle);
		//--- ファイルを閉じる
	  	FileClose(file_handle);
//debug	  	PrintFormat("Data is read, %s file is closed",filename);
    	}
	else
  	PrintFormat("Failed to open %s file, Error code = %d",filename,GetLastError());
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string PeriodToString(ENUM_TIMEFRAMES l_period)
  {
   switch(l_period)
     {
      case PERIOD_M1: return("M1");
      case PERIOD_M2: return("M2");
      case PERIOD_M3: return("M3");
      case PERIOD_M4: return("M4");
      case PERIOD_M5: return("M5");
      case PERIOD_M6: return("M6");
      case PERIOD_M10: return("M10");
      case PERIOD_M12: return("M12");
      case PERIOD_M15: return("M15");
      case PERIOD_M20: return("M20");
      case PERIOD_M30: return("M30");
      case PERIOD_H1: return("H1");
      case PERIOD_H2: return("H2");
      case PERIOD_H3: return("H3");
      case PERIOD_H4: return("H4");
      case PERIOD_H6: return("H6");
      case PERIOD_H8: return("H8");
      case PERIOD_H12: return("H12");
      case PERIOD_D1: return("D1");
      case PERIOD_W1: return("W1");
      case PERIOD_MN1: return("MN1");
     }
   return(NULL);
  };
  double PeriodToIndex(ENUM_TIMEFRAMES l_period)
  {
   switch(l_period)
     {
      case PERIOD_M1: return(1);
      case PERIOD_M2: return(2);
      case PERIOD_M3: return(3);
      case PERIOD_M4: return(4);
      case PERIOD_M5: return(5);
      case PERIOD_M6: return(6);
      case PERIOD_M10: return(7);
      case PERIOD_M12: return(8);
      case PERIOD_M15: return(9);
      case PERIOD_M20: return(10);
      case PERIOD_M30: return(11);
      case PERIOD_H1: return(12);
      case PERIOD_H2: return(13);
      case PERIOD_H3: return(14);
      case PERIOD_H4: return(15);
      case PERIOD_H6: return(16);
      case PERIOD_H8: return(17);
      case PERIOD_H12: return(18);
      case PERIOD_D1: return(19);
      case PERIOD_W1: return(20);
      case PERIOD_MN1: return(21);
     }
   return(NULL);
  };
  double get_peri_direct_pos_offset(double pips,ENUM_TIMEFRAMES l_period,int dir){
	  double sub_v=chgPips2price(pips);
	  sub_v=sub_v*PeriodToIndex(l_period)*((double)dir);
	  return sub_v;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//メモリサイズ確保	共通関数
//引数　＆配列名[]（一次元）、必要な総数、＆予備　→   ret true　メモリを増やした。false　true以外。エラーはエラー表示でみる。
bool mem_kakuho_1div_double(double &buf[],int n,int &yobi,int &yobisize){
	bool ret=false;
	int intret;
	if(n+2>yobi){
		intret=ArrayResize(buf,yobi+yobisize,yobisize);   
//		printf("intret="+intret);//20200107
		if(intret == -1){
			//mem取れない　どうしようもない
			printf("error mem取れない　どうしようもない double");
			return false;
		}
		//yobi = yobi+yobisize;
		ret = true;
	}
		
	return ret;
}
//引数　＆配列名[]（一次元）、必要な総数、＆予備　→
bool mem_kakuho_1div_datetime(datetime &buf[],int n,int &yobi,int &yobisize){
	bool ret=false;
	int intret;
	if(n+2>yobi){
		intret=ArrayResize(buf,yobi+yobisize,yobisize);   
		if(intret == -1){
			//mem取れない　どうしようもない
			printf("error mem取れない　どうしようもない datetime");
			return false;
		}
		//yobi = yobi+yobisize;
		ret = true;
	}
	return ret;
}
//引数　＆配列名[]（一次元）、必要な総数、＆予備　→
bool mem_kakuho_1div_int(int &buf[],int n,int &yobi,int &yobisize){
	bool ret=false;
	int intret;
	if(n+2>yobi){
		intret=ArrayResize(buf,yobi+yobisize,yobisize);   
		if(intret == -1){
			//mem取れない　どうしようもない
			return false;
		}
		//yobi = yobi+yobisize;
		ret = true;
	}
	return ret;
}
//引数　＆配列名[]（一次元）、必要な総数、＆予備　→
bool mem_kakuho_1div_bool(bool &buf[],int n,int &yobi,int &yobisize){
	bool ret=false;
	int intret;
	if(n+2>yobi){
		intret=ArrayResize(buf,yobi+yobisize,yobisize);   
		if(intret == -1){
			//mem取れない　どうしようもない
			return false;
		}
		//yobi = yobi+yobisize;
		ret = true;
	}
	return ret;
}
//引数　＆配列名[]（一次元）、必要な総数、＆予備　→
bool mem_kakuho_1div_uint(uint &buf[],int n,int &yobi,int &yobisize){
	bool ret=false;
	int intret;
	if(n+2>yobi){
		intret=ArrayResize(buf,yobi+yobisize,yobisize);   
		if(intret == -1){
			//mem取れない　どうしようもない
			return false;
		}
		//yobi = yobi+yobisize;
		ret = true;
	}
	return ret;
}


//名前がprefix含むものを削除
void all_del_prefix_object(string prefix){
   string objname;
   for(int i=ObjectsTotal(0,0,-1)-1;i>=0;i--)
     {
      objname=ObjectName(0,i);
      if(StringFind(objname,prefix)==-1)
         continue;
      else
         ObjectDelete(0,objname);
     }
}

int GetTimeColor(ENUM_TIMEFRAMES p){
    int cl = clrWhite;
	switch(p)
	{
        case PERIOD_CURRENT:
            cl = GetTimeColor(_Period);
            break;
		case PERIOD_M1:
		    //cl = clrWhite;
			cl = 0xFFFFFF;//	　	white
		    break;
		case PERIOD_M5:
		    //cl = clrYellow;
			cl = 0xFFFF00;//	　	yellow
		    break;
		case PERIOD_M15:
			cl = 0x0000FF;//	　	blue
		
		    break;
		case PERIOD_M30:
			cl = 0x00FF00;//	　	lime
		    break;
		case PERIOD_H1:
	    	//cl = clrYellow;
			cl = 0x00FFFF;//	　	aqua
		    break;
		case PERIOD_H4:
			cl = 0xFF0000;//	　	red
		    break;
		case PERIOD_D1:
			cl = 0xFF00FF;//	　	fuchsia
		    break;		    
		case PERIOD_W1:
		    cl = clrLavenderBlush;
		    break;
		default:
		    break;

	}
    return cl;		    
}
#endif//My_function_lib2

//新規バーのチェック
bool isNewBar(string symbol, ENUM_TIMEFRAMES tf)
{
   static datetime bartime = 0;
   static long ticktime = 0;
   MqlTick tick;
   SymbolInfoTick(symbol, tick);
   if(iTime(symbol, tf, 0) != bartime)
   {
      bartime = iTime(symbol, tf, 0);
      ticktime = tick.time_msc;
      return true;
   }
   else if(ticktime == tick.time_msc) return true;
   return false;
}

//新規バーのチェック Tickの違いまで見る
bool isNewBar_tick(string symbol, ENUM_TIMEFRAMES tf)
{
   static datetime bartime = 0;
   static long ticktime = 0;
   MqlTick tick;
   SymbolInfoTick(symbol, tick);
   if(iTime(symbol, tf, 0) != bartime)
   {
      bartime = iTime(symbol, tf, 0);
      ticktime = tick.time_msc;
      return true;
   }
   else if(ticktime == tick.time_msc) return true;
   return false;
}