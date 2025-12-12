//+------------------------------------------------------------------+
//|                                                 MyAISocketEA.mq5 |
//|                             Copyright 2025, Gemini AI Assistant |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Gemini AI Assistant"
#property link      ""
#property version   "1.04" // Version with Decimal Fix and Log Debug
#property description "Expert Advisor using Local Socket for Real-time AI Signals with SL/TP"

#include <Trade\Trade.mqh>

//--- Parameters
input string AIServerIP   = "127.0.0.1";
input int    AIServerPort = 8888;
input double Volume       = 0.01;

//--- Internal Variables
int      m_socket_handle      = -1;
double   m_ai_signal          = 0.0;
double   m_stop_loss_level    = 0.0;
double   m_take_profit_level  = 0.0;
string   log_message          = ""; // <--- FIX: ตัวแปรที่หายไป

CTrade m_trade;

//+------------------------------------------------------------------+
//| OnInit()                                                         |
//+------------------------------------------------------------------+
int OnInit()
{
    EventSetTimer(1); 
    m_trade.SetExpertMagicNumber(12345);
    Print("EA Started. Waiting for Socket connection...");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| OnDeinit()                                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer(); 
    if (m_socket_handle > 0)
    {
        SocketClose(m_socket_handle);
        Print("Socket connection closed.");
    }
}

//+------------------------------------------------------------------+
//| OnTick()                                                         |
//+------------------------------------------------------------------+
void OnTick()
{
    ExecuteTradeBasedOnSignal();
}

//+------------------------------------------------------------------+
//| OnTimer()                                                        |
//+------------------------------------------------------------------+
void OnTimer()
{
    if (m_socket_handle < 0)
    {
        ConnectToServer();
    }
    else
    {
        SendMarketDataToAI(); 
        ReceiveAISignal();
    }
}

//+------------------------------------------------------------------+
//| ConnectToServer()                                                |
//+------------------------------------------------------------------+
bool ConnectToServer()
{
    ResetLastError();
    m_socket_handle = SocketCreate();
    
    if (m_socket_handle == INVALID_HANDLE)
    {
        Print("ERROR: Cannot create socket. Error Code: ", GetLastError());
        return false;
    }
    
    if (!SocketConnect(m_socket_handle, AIServerIP, AIServerPort, 1000))
    {
        SocketClose(m_socket_handle);
        m_socket_handle = -1;
        return false;
    }
    
    Print("Successfully connected to AI Server (Handle: ", m_socket_handle, ")");
    return true;
}

//+------------------------------------------------------------------+
//| ExecuteTradeBasedOnSignal()                                      |
//+------------------------------------------------------------------+
void ExecuteTradeBasedOnSignal()
{
    bool has_position = PositionSelect(_Symbol); 

    if (m_ai_signal > 0.5) // BUY
    {
        if (has_position)
        {
            long current_position_type = PositionGetInteger(POSITION_TYPE);
            if (current_position_type == POSITION_TYPE_SELL)
            {
                m_trade.PositionClose(_Symbol);
                Print("AI Signal: CLOSING SELL to PREPARE BUY.");
            }
            else { return; }
        }
        
        m_trade.Buy(Volume, _Symbol, 0, m_stop_loss_level, m_take_profit_level, "AI BUY Signal");
        log_message = StringFormat("AI Signal: EXECUTE BUY Order. SL=%.5f, TP=%.5f", m_stop_loss_level, m_take_profit_level);
        Print(log_message);
        m_ai_signal = 0.0; 
    }
    else if (m_ai_signal < -0.5) // SELL
    {
        if (has_position)
        {
            long current_position_type = PositionGetInteger(POSITION_TYPE);
            if (current_position_type == POSITION_TYPE_BUY)
            {
                m_trade.PositionClose(_Symbol);
                Print("AI Signal: CLOSING BUY to PREPARE SELL.");
            }
            else { return; }
        }
        
        m_trade.Sell(Volume, _Symbol, 0, m_stop_loss_level, m_take_profit_level, "AI SELL Signal");
        log_message = StringFormat("AI Signal: EXECUTE SELL Order. SL=%.5f, TP=%.5f", m_stop_loss_level, m_take_profit_level);
        Print(log_message);
        m_ai_signal = 0.0;
    }
}

//+------------------------------------------------------------------+
//| SendMarketDataToAI()                                             |
//+------------------------------------------------------------------+
void SendMarketDataToAI()
{
    MqlTick current_tick;
    if (!SymbolInfoTick(_Symbol, current_tick)) return;
    
    double rsi_value = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
    
    // FIX: ใช้ DoubleToString เพื่อบังคับให้ใช้จุดทศนิยม (.) เสมอ
    string price_str = DoubleToString(current_tick.bid, 5);
    string rsi_str   = DoubleToString(rsi_value, 2);
    
    string data_to_send = _Symbol + "," + price_str + "," + rsi_str;
    
    // DEBUG: Log ข้อมูลที่ส่งออกไป
    Print("DEBUG: Data sent to AI: ", data_to_send); 
    
    uchar data_bytes[];
    int size = StringToCharArray(data_to_send, data_bytes, 0, WHOLE_ARRAY, CP_UTF8);
    
    if(size > 0) size--; // ตัด Null Terminator ออก

    ResetLastError();
    int bytes_sent = SocketSend(m_socket_handle, data_bytes, size);
    
    if (bytes_sent <= 0)
    {
        Print("Socket Send Failed. Error: ", GetLastError());
        SocketClose(m_socket_handle);
        m_socket_handle = -1;
    }
}

//+------------------------------------------------------------------+
//| ReceiveAISignal()                                                |
//+------------------------------------------------------------------+
void ReceiveAISignal()
{
    if (m_socket_handle == -1) return;

    uchar buffer[512]; 
    ResetLastError();
    // **เพิ่ม Timeout เป็น 200ms** เพื่อให้ Server มีเวลาส่งข้อมูลกลับมา
    int bytes_received = SocketRead(m_socket_handle, buffer, ArraySize(buffer), 200); 

    if (bytes_received > 0)
    {
        string full_signal_string = CharArrayToString(buffer, 0, bytes_received, CP_UTF8); 
        
        StringTrimLeft(full_signal_string);
        StringTrimRight(full_signal_string);

        string result[];
        if (StringSplit(full_signal_string, ',', result) >= 3)
        {
             m_ai_signal = StringToDouble(result[0]);
             m_stop_loss_level = StringToDouble(result[1]);
             m_take_profit_level = StringToDouble(result[2]);
             
             if(m_ai_signal != 0.0) {
                 PrintFormat("AI Signal Received: S=%.1f, SL=%.5f, TP=%.5f", m_ai_signal, m_stop_loss_level, m_take_profit_level);
             }
        }
    }
    else
    {
        int err = GetLastError();
        // 56003 = ERR_NET_SOCKET_TIMEOUT (Timeout)
        // 5273 = ERR_NET_SOCKET_NO_DATA (No Data - เราจะถือว่าเป็น Timeout ได้)
        
        // **เงื่อนไขใหม่:** ปิด Socket เฉพาะเมื่อเป็น Critical Error (ไม่ใช่ 0, 56003, หรือ 5273)
        if (err != 0 && err != 56003 && err != 5273) 
        {
             Print("CRITICAL Socket Read Error: ", err, ". Disconnecting.");
             SocketClose(m_socket_handle);
             m_socket_handle = -1;
        }
        // ถ้าเป็น 5273 หรือ 56003 จะไม่ทำอะไรในรอบนี้ และรอรอบถัดไปเพื่อส่ง/รับใหม่
    }
}
//+------------------------------------------------------------------+