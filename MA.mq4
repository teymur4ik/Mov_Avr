#property version   "1.00"
#property strict
#property description "Советник открывает и закрывает позиции на пересечении двух индикаторов  Moving Average " 

#include "mov_avr.mq4"
#include "moving.mq4"

//+------------------------------------------------------------------+
extern string  LMA="";     
extern int     period_1             = 35,    //Период усреднения для вычисления первой MA. 
               ma_shift_1           = 0;     //Сдвиг индикатора относительно ценового графика. 
input ENUM_MA_METHOD ma_method_1=MODE_LWMA; 
input ENUM_APPLIED_PRICE applied_price_1 = PRICE_OPEN;  //Используемая цена. 
input ENUM_TIMEFRAMES timeframe_1   = 0;           //Период. 

extern string  ____ = "--------------------------"; 

extern string  EMA="";     
extern int     period_2             = 20,          //Период усреднения для вычисления второй MA. 
               ma_shift_2           = 0;           //Сдвиг индикатора относительно ценового графика. 
input ENUM_MA_METHOD ma_method_2    = MODE_EMA;    //Метод усреднения. 
input ENUM_APPLIED_PRICE applied_price_2 = PRICE_OPEN;  //Используемая цена. 
input ENUM_TIMEFRAMES timeframe_2   = 0;           //Период. 

extern int     barOpen              = 1;           //бар на котором ждем сигнал (0- текущий  1 - прошлый) 
extern string  _____ = "--------------------------"; 

extern double  Lot                  = 0.01;        //лот 

extern int     Stoploss             = 0;           //стоплосс (0-отключен) 
extern int     Takeprofit           = 0;           //тейкпрофит (0-отключен) 

extern int     slippage             = 20;         // проскальзывание 
extern int     Magic                = 0;           
//-------------------------------------------------------------------- 
double STOPLEVEL; 
string val; 
//-------------------------------------------------------------------- 
int OnInit() 
{ 
   val = " "+AccountCurrency(); 
   return(INIT_SUCCEEDED); 
} 
//------------------------------------------------------------------- 
void OnTick() 
{ 
   if (!IsTradeAllowed()) 
   { 
      DrawLABEL("IsTradeAllowed","Торговля запрещена",5,15,Red); 
      return; 
   } 
   else DrawLABEL("IsTradeAllowed","Торговля разрешена",5,15,Lime); 

   //--- 

   STOPLEVEL=MarketInfo(Symbol(),MODE_STOPLEVEL); 
   double OSL,OTP,OOP,StLo=0,SL=0,TP=0,Profit=0,ProfitB=0,ProfitS=0; 
   int i,b=0,s=0,tip; 
   for (i=0; i<OrdersTotal(); i++) 
   {     
      if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) 
      { 
         if (OrderSymbol()==Symbol() && Magic==OrderMagicNumber()) 
         { 
            tip = OrderType(); 
            OSL = NormalizeDouble(OrderStopLoss(),Digits); 
            OTP = NormalizeDouble(OrderTakeProfit(),Digits); 
            OOP = NormalizeDouble(OrderOpenPrice(),Digits); 
            SL=OSL;TP=OTP; 
            if (tip==OP_BUY)             
            {   
               ProfitB+=OrderProfit()+OrderSwap()+OrderCommission(); 
               b++; 
               if (OSL==0 && Stoploss>=STOPLEVEL && Stoploss!=0) 
               { 
                  SL = NormalizeDouble(OOP - Stoploss   * Point,Digits); 
               } 
               if (OTP==0 && Takeprofit>=STOPLEVEL && Takeprofit!=0) 
               { 
                  TP = NormalizeDouble(OOP + Takeprofit * Point,Digits); 
               } 
               if (SL != OSL || TP != OTP) 
               {   
                  if (!OrderModify(OrderTicket(),OOP,SL,TP,0,clrNONE)) Print("Error OrderModify <<",Error(GetLastError()),">> "); 
               } 
            }                                         
            if (tip==OP_SELL)         
            { 
               ProfitS+=OrderProfit()+OrderSwap()+OrderCommission(); 
               s++; 
               if (OSL==0 && Stoploss>=STOPLEVEL && Stoploss!=0) 
               { 
                  SL = NormalizeDouble(OOP + Stoploss   * Point,Digits); 
               } 
               if (OTP==0 && Takeprofit>=STOPLEVEL && Takeprofit!=0) 
               { 
                  TP = NormalizeDouble(OOP - Takeprofit * Point,Digits); 
               } 
               if (SL != OSL || TP != OTP) 
               {   
                  if (!OrderModify(OrderTicket(),OOP,SL,TP,0,clrNONE)) Print("Error OrderModify <<",Error(GetLastError()),">> "); 
               } 
            } 
         } 
      } 
   } 
   Profit = ProfitB + ProfitS; 
   DrawLABEL("Balance",StringConcatenate("Balance ",DoubleToStr(AccountBalance(),2),val),5,35,clrGray); 
   DrawLABEL("Equity",StringConcatenate("Equity ",DoubleToStr(AccountEquity(),2),val),5,55,clrGray); 
   DrawLABEL("FreeMargin",StringConcatenate("FreeMargin ",DoubleToStr(AccountFreeMargin(),2),val),5,75,clrGray); 
   DrawLABEL("Profit",StringConcatenate("Profit ",DoubleToStr(Profit,2),val),5,95,Color(Profit<0,Red,Lime)); 
   //---------------------------------------------------------------- 

   double MA10 = iMA(NULL,timeframe_1,period_1,ma_shift_1,ma_method_1,applied_price_1,barOpen); 
   double MA20 = iMA(NULL,timeframe_2,period_2,ma_shift_2,ma_method_2,applied_price_2,barOpen); 
   double MA11 = iMA(NULL,timeframe_1,period_1,ma_shift_1,ma_method_1,applied_price_1,barOpen+1); 
   double MA21 = iMA(NULL,timeframe_2,period_2,ma_shift_2,ma_method_2,applied_price_2,barOpen+1); 

   //----------------------------------------------------------------------- 
   if (MA10>=MA20 && MA11<MA21) 
   { 
      if (s>0) CLOSEORDER(OP_SELL); 
      if (b==0) 
      { 
         SendOrder(OP_BUY, Lot, NormalizeDouble(Ask,Digits)); 
      } 
   } 
   if (MA10<=MA20 && MA11>MA21) 
   { 
      if (b>0) CLOSEORDER(OP_BUY); 
      if (s==0) 
      { 
         SendOrder(OP_SELL, Lot, NormalizeDouble(Bid,Digits)); 
      } 
   } 
} 
//-------------------------------------------------------------------- 
bool SendOrder(int tip, double lots, double price, double sl=0, double tp=0) 
{ 
   if(!IsNewOrderAllowed()) return(false); 
   lots=CheckVolumeValue(lots); 
   if (tip<2) 
   { 
      if (AccountFreeMarginCheck(Symbol(),tip,lots)<0) 
      { 
         return(false); 
      } 
   } 
   for (int i=0; i<10; i++) 
   {     
      if (OrderSend(Symbol(),tip, lots,price,slippage,sl,tp,NULL,Magic,0,clrNONE)!=-1) return(true); 
      Sleep(500); 
      RefreshRates(); 
      if (IsStopped()) return(false); 
   } 
   return(false); 
} 
//------------------------------------------------------------------ 
string Strtip(int tip) 
{ 
   switch(tip) 
   { 
   case OP_BUY:      return("BUY"); 
   case OP_SELL:     return("SELL"); 
   case OP_BUYSTOP:  return("BUYSTOP"); 
   case OP_SELLSTOP: return("SELLSTOP"); 
   case OP_BUYLIMIT: return("BUYLIMIT"); 
   case OP_SELLLIMIT:return("SELLLIMIT"); 
   } 
   return("error"); 
} 
//------------------------------------------------------------------ 
bool CLOSEORDER(int ord=-1) 
{ 
   bool error=true; 
   int j,err,nn=0,OT,OMN; 
   while (true) 
   { 
      for (j = OrdersTotal()-1; j >= 0; j--) 
      { 
         if (OrderSelect(j, SELECT_BY_POS)) 
         { 
            OMN = OrderMagicNumber(); 
            if (OrderSymbol() == Symbol() && OMN == Magic) 
            { 
               OT = OrderType(); 
               if (ord != OT && ord !=-1) continue; 
               if (OT==OP_BUY) 
               { 
                  error=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Bid,Digits),slippage,Blue); 
               } 
               if (OT==OP_SELL) 
               { 
                  error=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Ask,Digits),slippage,Red); 
               } 
               if (!error) 
               { 
                  err = GetLastError(); 
                  if (err<2) continue; 
                  if (err==129) 
                  {   
                     RefreshRates(); 
                     continue; 
                  } 
                  if (err==146) 
                  { 
                     if (IsTradeContextBusy()) Sleep(2000); 
                     continue; 
                  } 
                  Comment("Error <<",Error(err),">> ",TimeToStr(TimeCurrent(),TIME_SECONDS)); 
               } 
            } 
         } 
      } 
      int n=0; 
      for (j = 0; j < OrdersTotal(); j++) 
      { 
         if (OrderSelect(j, SELECT_BY_POS)) 
         { 
            OMN = OrderMagicNumber(); 
            if (OrderSymbol() == Symbol() && OMN == Magic) 
            { 
               OT = OrderType(); 
               if (ord != OT && ord !=-1) continue; 
               n++; 
            } 
         }   
      } 
      if (n==0) return(true); 
      nn++; 
      if (nn>10) {return(false);} 
      Sleep(1000); 
      RefreshRates(); 
   } 
   return(true); 
} 
//------------------------------------------------------------------ 
color Color(bool P,color a,color b) 
{ 
   if (P) return(a); 
   else return(b); 
} 
//------------------------------------------------------------------ 
void DrawLABEL(string name, string Name, int X, int Y, color clr) 
{ 
   if (ObjectFind(name)==-1) 
   { 
      ObjectCreate(name, OBJ_LABEL, 0, 0, 0); 
      ObjectSet(name, OBJPROP_CORNER, 1); 
      ObjectSet(name, OBJPROP_XDISTANCE, X); 
      ObjectSet(name, OBJPROP_YDISTANCE, Y); 
   } 
   ObjectSetText(name,Name,12,"Arial",clr); 
} 
//-------------------------------------------------------------------- 
string Error(int code) 
{ 
   switch(code) 
   { 
      case 0:   return("Нет ошибок"); 
      case 1:   return("Нет ошибки, но результат неизвестен");                             
      case 2:   return("Общая ошибка");                                                   
      case 3:   return("Неправильные параметры");                                         
      case 4:   return("Торговый сервер занят");                                           
      case 5:   return("Старая версия клиентского терминала");                             
      case 6:   return("Нет связи с торговым сервером");                                   
      case 7:   return("Недостаточно прав");                                               
      case 8:   return("Слишком частые запросы");                                         
      case 9:   return("Недопустимая операция нарушающая функционирование сервера");       
      case 64:  return("Счет заблокирован");                                               
      case 65:  return("Неправильный номер счета");                                       
      case 128: return("Истек срок ожидания совершения сделки");                           
      case 129: return("Неправильная цена");                                               
      case 130: return("Неправильные стопы");                                             
      case 131: return("Неправильный объем");                                             
      case 132: return("Рынок закрыт");                                                   
      case 133: return("Торговля запрещена");                                               
      case 134: return("Недостаточно денег для совершения операции");                     
      case 135: return("Цена изменилась");                                                 
      case 136: return("Нет цен");                                                         
      case 137: return("Брокер занят");                                                   
      case 138: return("Новые цены");                                                     
      case 139: return("Ордер заблокирован и уже обрабатывается");                         
      case 140: return("Разрешена только покупка");                                       
      case 141: return("Слишком много запросов");                                         
      case 145: return("Модификация запрещена, так как ордер слишком близок к рынку");     
      case 146: return("Подсистема торговли занята");                                     
      case 147: return("Использование даты истечения ордера запрещено брокером");         
      case 148: return("Количество открытых и отложенных ордеров достигло предела, установленного брокером."); 
      case 4000: return("Нет ошибки");                                                       
      case 4001: return("Неправильный указатель функции");                                   
      case 4002: return("Индекс массива - вне диапазона");                                   
      case 4003: return("Нет памяти для стека функций");                                     
      case 4004: return("Переполнение стека после рекурсивного вызова");                     
      case 4005: return("На стеке нет памяти для передачи параметров");                     
      case 4006: return("Нет памяти для строкового параметра");                             
      case 4007: return("Нет памяти для временной строки");                                 
      case 4008: return("Неинициализированная строка");                                     
      case 4009: return("Неинициализированная строка в массиве");                           
      case 4010: return("Нет памяти для строкового массива");                               
      case 4011: return("Слишком длинная строка");                                           
      case 4012: return("Остаток от деления на ноль");                                       
      case 4013: return("Деление на ноль");                                                 
      case 4014: return("Неизвестная команда");                                             
      case 4015: return("Неправильный переход");                                             
      case 4016: return("Неинициализированный массив");                                     
      case 4017: return("Вызовы DLL не разрешены");                                         
      case 4018: return("Невозможно загрузить библиотеку");                                 
      case 4019: return("Невозможно вызвать функцию");                                       
      case 4020: return("Вызовы внешних библиотечных функций не разрешены");                 
      case 4021: return("Недостаточно памяти для строки, возвращаемой из функции");         
      case 4022: return("Система занята");                                                   
      case 4050: return("Неправильное количество параметров функции");                       
      case 4051: return("Недопустимое значение параметра функции");                         
      case 4052: return("Внутренняя ошибка строковой функции");                             
      case 4053: return("Ошибка массива");                                                   
      case 4054: return("Неправильное использование массива-таймсерии");                     
      case 4055: return("Ошибка пользовательского индикатора");                             
      case 4056: return("Массивы несовместимы");                                             
      case 4057: return("Ошибка обработки глобальныех переменных");                         
      case 4058: return("Глобальная переменная не обнаружена");                             
      case 4059: return("Функция не разрешена в тестовом режиме");                           
      case 4060: return("Функция не разрешена");                                             
      case 4061: return("Ошибка отправки почты");                                           
      case 4062: return("Ожидается параметр типа string");                                   
      case 4063: return("Ожидается параметр типа integer");                                 
      case 4064: return("Ожидается параметр типа double");                                   
      case 4065: return("В качестве параметра ожидается массив");                           
      case 4066: return("Запрошенные исторические данные в состоянии обновления");           
      case 4067: return("Ошибка при выполнении торговой операции");                         
      case 4099: return("Конец файла");                                                     
      case 4100: return("Ошибка при работе с файлом");                                       
      case 4101: return("Неправильное имя файла");                                           
      case 4102: return("Слишком много открытых файлов");                                   
      case 4103: return("Невозможно открыть файл");                                         
      case 4104: return("Несовместимый режим доступа к файлу");                             
      case 4105: return("Ни один ордер не выбран");                                         
      case 4106: return("Неизвестный символ");                                               
      case 4107: return("Неправильный параметр цены для торговой функции");                 
      case 4108: return("Неверный номер тикета");                                           
      case 4109: return("Торговля не разрешена. Необходимо включить опцию Разрешить советнику торговать в свойствах эксперта.");             
      case 4110: return("Длинные позиции не разрешены. Необходимо проверить свойства эксперта.");           
      case 4111: return("Короткие позиции не разрешены. Необходимо проверить свойства эксперта.");           
      case 4200: return("Объект уже существует");                                           
      case 4201: return("Запрошено неизвестное свойство объекта");                           
      case 4202: return("Объект не существует");                                             
      case 4203: return("Неизвестный тип объекта");                                         
      case 4204: return("Нет имени объекта");                                               
      case 4205: return("Ошибка координат объекта");                                         
      case 4206: return("Не найдено указанное подокно");                                     
      default:   return("Ошибка неизвестна "); 
   } 
} 
//-------------------------------------------------------------------- 

void OnDeinit(const int reason) 
{ 
   if (!IsTesting()) ObjectsDeleteAll(); 
   Comment(""); 
} 
//+------------------------------------------------------------------+ 
void DrawArrow(int win, string name, double price, color colr,int arr=6) 
{ 
   ObjectDelete(name); 
   ObjectCreate(name,OBJ_ARROW,win,Time[0],price,0,0,0,0);                     
   ObjectSet   (name,OBJPROP_ARROWCODE,arr); 
   ObjectSet   (name,OBJPROP_COLOR, colr); 
   return; 
} 
//+------------------------------------------------------------------+ 
// TextCreate(0,"Text",0,time,price,"Text"); 
bool TextCreate(const long              chart_ID=0,               // ID графика 
                const string            name="Text",              // имя объекта 
                const int               sub_window=0,             // номер подокна 
                datetime                time=0,                   // время точки привязки 
                double                  price=0,                  // цена точки привязки 
                const string            text="Text",              // сам текст 
                const string            font="Arial",             // шрифт 
                const int               font_size=10,             // размер шрифта 
                const color             clr=clrRed,               // цвет 
                const double            angle=0.0,                // наклон текста 
                const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // способ привязки 
                const bool              back=false,               // на заднем плане 
                const bool              selection=false,          // выделить для перемещений 
                const bool              hidden=true,              // скрыт в списке объектов 
                const long              z_order=0)                // приоритет на нажатие мышью 
  { 
   if(ObjectFind(chart_ID,name)!=-1) ObjectDelete(chart_ID,name); 
   if(!ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,time,price)) 
     { 
      return(false); 
     } 
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font); 
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size); 
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle); 
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor); 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text); 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
bool EditCreate(const long             chart_ID=0,               // ID графика 
                const string           name="Edit",              // имя объекта 
                const int              sub_window=0,             // номер подокна 
                const long              x=0,                      // координата по оси X 
                const long              y=0,                      // координата по оси Y 
                const int              width=50,                 // ширина 
                const int              height=18,                // высота 
                const string           text="Text",              // текст 
                const string           font="Arial",             // шрифт 
                const int              font_size=8,             // размер шрифта 
                const ENUM_ALIGN_MODE  align=ALIGN_RIGHT,       // способ выравнивания 
                const bool             read_only=true,// возможность редактировать 
                const ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER,// угол графика для привязки 
                const color            clr=clrBlack,             // цвет текста 
                const color            back_clr=clrWhite,        // цвет фона 
                const color            border_clr=clrNONE,       // цвет границы 
                const bool             back=false,               // на заднем плане 
                const bool             selection=false,          // выделить для перемещений 
                const bool             hidden=true,              // скрыт в списке объектов 
                const long             z_order=0)                // приоритет на нажатие мышью 
  { 
   ResetLastError(); 
   if(ObjectFind(chart_ID,name)==-1) 
   { 
      if(!ObjectCreate(chart_ID,name,OBJ_EDIT,sub_window,0,0)) 
      { 
         return(false); 
      } 
      ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width); 
      ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height); 
      ObjectSetString(chart_ID,name,OBJPROP_TEXT,text); 
      ObjectSetString(chart_ID,name,OBJPROP_FONT,font); 
      ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size); 
      ObjectSetInteger(chart_ID,name,OBJPROP_ALIGN,align); 
      ObjectSetInteger(chart_ID,name,OBJPROP_READONLY,read_only); 
      ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner); 
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
      ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr); 
      ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr); 
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
   } 
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x); 
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y); 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
// ButtonCreate(0,"Button",0,x,y,width,height,text,"Arial",8,clrBlack,clrLightGray,clrNONE,false,CORNER_LEFT_UPPER); 
bool ButtonCreate(const long              chart_ID=0,               // ID графика 
                  const string            name="Button",            // имя кнопки 
                  const int               sub_window=0,             // номер подокна 
                  const long               x=0,                      // координата по оси X 
                  const long               y=0,                      // координата по оси Y 
                  const int               width=50,                 // ширина кнопки 
                  const int               height=18,                // высота кнопки 
                  const string            text="Button",            // текст 
                  const string            font="Arial",             // шрифт 
                  const int               font_size=8,// размер шрифта 
                  const color             clr=clrBlack,// цвет текста 
                  const color             clrfon=clrLightGray,// цвет фона 
                  const color             border_clr=clrNONE,// цвет границы 
                  const bool              state=false,       // 
                  const ENUM_BASE_CORNER  CORNER=CORNER_LEFT_UPPER) 
  { 
   if(ObjectFind(chart_ID,name)==-1) 
     { 
      ObjectCreate(chart_ID,name,OBJ_BUTTON,sub_window,0,0); 
      ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width); 
      ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height); 
      ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,CORNER); 
      ObjectSetString(chart_ID,name,OBJPROP_FONT,font); 
      ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size); 
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,0); 
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,0); 
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,0); 
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,1); 
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,1); 
      ObjectSetInteger(chart_ID,name,OBJPROP_STATE,state); 
     } 
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr); 
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,clrfon); 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text); 
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x); 
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y); 
   return(true); 
  } 
//-------------------------------------------------------------------- 
bool RectLabelCreate(const long             chart_ID=0,               // ID графика 
                     const string           name="RectLabel",         // имя метки 
                     const int              sub_window=0,             // номер подокна 
                     const long              x=0,                     // координата по оси X 
                     const long              y=0,                     // координата по оси y 
                     const int              width=50,                 // ширина 
                     const int              height=18,                // высота 
                     const color            back_clr=clrWhite,        // цвет фона 
                     const color            clr=clrBlack,             // цвет плоской границы (Flat) 
                     const ENUM_LINE_STYLE  style=STYLE_SOLID,        // стиль плоской границы 
                     const int              line_width=1,             // толщина плоской границы 
                     const bool             back=false,               // на заднем плане 
                     const bool             selection=true,           // выделить для перемещений 
                     const bool             hidden=true,              // скрыт в списке объектов 
                     const long             z_order=1)                // приоритет на нажатие мышью 
  { 
   ResetLastError(); 
   if(ObjectFind(chart_ID,name)==-1) 
     { 
      ObjectCreate(chart_ID,name,OBJ_RECTANGLE_LABEL,sub_window,0,0); 
      ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_TYPE,BORDER_FLAT); 
      ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,CORNER_LEFT_UPPER); 
      ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
      ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,line_width); 
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
      //ObjectSetInteger(chart_ID,name,OBJPROP_ALIGN,ALIGN_RIGHT); 
      ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr); 
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
      ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width); 
      ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height); 
     } 
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x); 
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y); 
   return(true); 
  } 
//-------------------------------------------------------------------- 
//TrendCreate(0,"TrendLine",0,t1,p1,t2,p2,clrRed); 
bool TrendCreate(const long            chart_ID=0,        // ID графика 
                 const string          name="TrendLine",  // имя линии 
                 const int             sub_window=0,      // номер подокна 
                 datetime              time1=0,           // время первой точки 
                 double                price1=0,          // цена первой точки 
                 datetime              time2=0,           // время второй точки 
                 double                price2=0,          // цена второй точки 
                 const color           clr=clrRed,        // цвет линии 
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // стиль линии 
                 const int             width=1,           // толщина линии 
                 const bool            back=false,        // на заднем плане 
                 const bool            selection=true,    // выделить для перемещений 
                 const bool            ray_right=false,   // продолжение линии вправо 
                 const bool            hidden=true,       // скрыт в списке объектов 
                 const long            z_order=0)         // приоритет на нажатие мышью 
  { 
   if(ObjectFind(chart_ID,name)!=-1) 
      ObjectDelete(name); 
   if(!ObjectCreate(chart_ID,name,OBJ_TREND,sub_window,time1,price1,time2,price2)) 
     { 
      return(false); 
     } 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width); 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_RIGHT,ray_right); 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
bool IsNewOrderAllowed() 
{ 
   int max_allowed_orders=(int)AccountInfoInteger(ACCOUNT_LIMIT_ORDERS); 
   if(max_allowed_orders==0) return(true); 
   if(OrdersTotal()<max_allowed_orders) return(true); 
   return(false); 
} 
//+------------------------------------------------------------------+ 
double CheckVolumeValue(double volume) 
{ 
   double min_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN); 
   if(volume<min_volume) return(min_volume); 
   double max_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX); 
   if(volume>max_volume) return(max_volume); 
   double volume_step=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);//--- градация объема 
   int ratio=(int)MathRound(volume/volume_step); 
   if(MathAbs(ratio*volume_step-volume)>0.0000001) return(ratio*volume_step); 
   return(volume); 
} 
//+------------------------------------------------------------------+ 
//RectangleCreate(0,"Rectangle",0,time1,price1,time2,price2,clrRed); 

bool RectangleCreate(const long            chart_ID=0,        // ID графика 
                     const string          name="Rectangle",  // имя прямоугольника 
                     const int             sub_window=0,      // номер подокна   
                     datetime              time1=0,           // время первой точки 
                     double                price1=0,          // цена первой точки 
                     datetime              time2=0,           // время второй точки 
                     double                price2=0,          // цена второй точки 
                     const color           clr=clrRed,        // цвет прямоугольника 
                     const ENUM_LINE_STYLE style=STYLE_SOLID, // стиль линий прямоугольника 
                     const int             width=1,           // толщина линий прямоугольника 
                     const bool            fill=false,        // заливка прямоугольника цветом 
                     const bool            back=false,        // на заднем плане 
                     const bool            selection=true,    // выделить для перемещений 
                     const bool            hidden=true,       // скрыт в списке объектов 
                     const long            z_order=0)         // приоритет на нажатие мышью 
  { 
   if(ObjectFind(chart_ID,name)==-1) 
   { 
      if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE,sub_window,time1,price1,time2,price2)) 
      { 
         return(false); 
      } 
   } 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width); 
   ObjectSetInteger(chart_ID,name,OBJPROP_FILL,fill); 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
string StrTF(int t=0) 
{ 
   if (t==0) t=Period(); 
   switch(t) 
   { 
      case PERIOD_M1:         return("M1"); 
      case PERIOD_M2:         return("M2"); 
      case PERIOD_M3:         return("M3"); 
      case PERIOD_M4:         return("M4"); 
      case PERIOD_M5:         return("M5"); 
      case PERIOD_M6:         return("M6"); 
      case PERIOD_M10:        return("M10"); 
      case PERIOD_M15:        return("M15"); 
      case PERIOD_M30:        return("M30"); 
      case PERIOD_H1:         return("H1"); 
      case PERIOD_H4:         return("H4"); 
      case PERIOD_D1:         return("D1"); 
      default: 
         return(IntegerToString(t)); 
   } 
} 
//-------------------------------------------------------------------- 