//+------------------------------------------------------------------+
//| Simple Moving Average                                            |
//+------------------------------------------------------------------+
double MODE_SMA(const int position,const int period,const double &price[])
  {
//---
   double result=0.0;
//--- check position
   if(position>=period-1 && period>0)
     {
      //--- calculate value
      for(int i=0;i<period;i++) result+=price[position-i];
      result/=period;
     }
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Exponential Moving Average                                       |
//+------------------------------------------------------------------+
double MODE_EMA(const int position,const int period,const double prev_value,const double &price[])
  {
//---
   double result=0.0;
//--- calculate value
   if(period>0)
     {
      double pr=2.0/(period+1.0);
      result=price[position]*pr+prev_value*(1-pr);
     }
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Linear Weighted Moving Average                                   |
//+------------------------------------------------------------------+
double MODE_LWMA(const int position,const int period,const double &price[])
  {
//---
   double result=0.0,sum=0.0;
   int    i,wsum=0;
//--- calculate value
   if(position>=period-1 && period>0)
     {
      for(i=period;i>0;i--)
        {
         wsum+=i;
         sum+=price[position-i+1]*(period-i+1);
        }
      result=sum/wsum;
     }
//---
   return(result);
  }