// MyDateTime.mqh
#property copyright "Copyright (c) 2012, Toyolab FX"
#property link      "http://forex.toyolab.com/"

int Year()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   return(dt.year);
}

int Month()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   return(dt.mon);
}

int Day()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   return(dt.day);
}

int Hour()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   return(dt.hour);
}

int Minute()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   return(dt.min);
}

int Seconds()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   return(dt.sec);
}

int DayOfWeek()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   return(dt.day_of_week);
}

int DayOfYear()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   return(dt.day_of_year);
}

int TimeYear(datetime val)
{
   MqlDateTime dt;
   TimeToStruct(val, dt);
   return(dt.year);
}

int TimeMonth(datetime val)
{
   MqlDateTime dt;
   TimeToStruct(val, dt);
   return(dt.mon);
}

int TimeDay(datetime val)
{
   MqlDateTime dt;
   TimeToStruct(val, dt);
   return(dt.day);
}

int TimeHour(datetime val)
{
   MqlDateTime dt;
   TimeToStruct(val, dt);
   return(dt.hour);
}

int TimeMinute(datetime val)
{
   MqlDateTime dt;
   TimeToStruct(val, dt);
   return(dt.min);
}

int TimeSeconds(datetime val)
{
   MqlDateTime dt;
   TimeToStruct(val, dt);
   return(dt.sec);
}

int TimeDayOfWeek(datetime val)
{
   MqlDateTime dt;
   TimeToStruct(val, dt);
   return(dt.day_of_week);
}

int TimeDayOfYear(datetime val)
{
   MqlDateTime dt;
   TimeToStruct(val, dt);
   return(dt.day_of_year);
}
