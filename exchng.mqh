//+------------------------------------------------------------------+
//|                                                       exchng.mqh |
//|                                           Copyright ｩ 2009, alsu |
//|                                                 alsufx@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright ｩ 2009, alsu"
#property link      "alsufx@gmail.com"

#import "exchng.ex5"
   void              RegisterBuffer(double &Buffer[], string name, int mode);
   void              RegisterBuffer2(double &Buffer[], string name, int mode,int period, string symbol);
   void              UnregisterBuffer(double &Buffer[]);
   int               FindBuffers(string name, int mode, string symbol, int period, string &buffers[]);
   double            GetIndicatorValue(string descriptor, int shift);
   bool              SetIndicatorValue(string descriptor, int shift, double value);
#import

