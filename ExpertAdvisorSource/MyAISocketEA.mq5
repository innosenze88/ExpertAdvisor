//+------------------------------------------------------------------+
//|                                                MyAISocketEA.mq5 |
//|                     Copyright 2025, Gemini AI Assistant |
//|                                                      
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Gemini AI Assistant"
#property link      ""
#property version   "1.00"
#property description "Expert Advisor using Socket for Real-time AI Signals"

//--- ต้องใช้ไลบรารีสำหรับฟังก์ชัน Socket
#include <stdlib.mqh> 
#include <Trade\Trade.mqh>

//--- การตั้งค่าพารามิเตอร์ภายนอกที่ปรับเปลี่ยนได้
input string AIServerIP   = "scaling-succotash-x5grr544v4jghvpqw-8888.app.github.dev";
input int    AIServerPort = 443;        // Port ของ AI Server
input double Volume       = 0.01;        // ปริมาณการซื้อขายเริ่มต้น

//--- ตัวแปรภายในสำหรับจัดการ Socket และสัญญาณ AI
int               m_socket_handle = -1; // Handle สำหรับ Socket
double            m_ai_signal     = 0.0;  // ค่าสัญญาณที่รับจาก AI (เช่น 1.0=Buy, -1.0=Sell)

CTrade m_trade;

//+------------------------------------------------------------------+
//| ฟังก์ชันเริ่มต้น (Initialization Function)                       |
//+------------------------------------------------------------------+
int OnInit()
{
   // ตั้งค่าความถี่ในการตรวจสอบ Socket
    EventSetTimer(1); // กำหนดให้ OnTimer() ทำงานทุก 1 วินาที
    
    // ตั้งค่า Magic Number ให้กับ Object การซื้อขาย (ป้องกัน Bug จาก EA ตัวอื่น)
    m_trade.SetExpertMagicNumber(12345); // <--- เพิ่มบรรทัดนี้ใน OnInit()
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| ฟังก์ชันเมื่อจบการทำงาน (Deinitialization Function)              |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer(); // ยกเลิกการเรียกใช้ OnTimer
    if (m_socket_handle > 0)
    {
        SocketClose(m_socket_handle);
        Print("Socket connection closed.");
    }
}

//+------------------------------------------------------------------+
//| ฟังก์ชันหลักที่ทำงานเมื่อมี Tick ใหม่เข้ามา (สำหรับ Trading Logic) |
//+------------------------------------------------------------------+
void OnTick()
{
    // ตรรกะการซื้อขายหลักตามสัญญาณ AI
    ExecuteTradeBasedOnSignal();
}

//+------------------------------------------------------------------+
//| ฟังก์ชันที่ทำงานตาม Timer (สำหรับเชื่อมต่อและสื่อสาร Socket)    |
//+------------------------------------------------------------------+
void OnTimer()
{
    // 1. ตรวจสอบและสร้างการเชื่อมต่อ Socket
    if (m_socket_handle < 0)
    {
        ConnectToServer(); // พยายามเชื่อมต่อใหม่ถ้าหลุด
    }
    else
    {
        // 2. ส่งข้อมูลตลาดไปยัง AI (ทำใน OnTimer เพื่อควบคุมความถี่)
        SendMarketDataToAI(); 
        
        // 3. รับสัญญาณจาก AI
        ReceiveAISignal();
    }
}

//+------------------------------------------------------------------+
//| ฟังก์ชันเชื่อมต่อไปยัง AI Server                                  |
//+------------------------------------------------------------------+
bool ConnectToServer()
{
    // A. ตรวจสอบ: ถ้ามี Handle Socket เก่าที่ยังเปิดอยู่ ให้ปิดไปก่อน
    if (m_socket_handle > 0)
    {
        SocketClose(m_socket_handle);
    }
        
    // B. สร้าง Socket ใหม่
    m_socket_handle = SocketCreate();
    
    // ตรวจสอบความผิดพลาดในการสร้าง Socket
    if (m_socket_handle < 0)
    {
        Print("ERROR: Cannot create socket. Error Code: ", GetLastError());
        return false;
    }
    
    // C. พยายามเชื่อมต่อไปยัง IP และ Port ที่กำหนด
    Print("Attempting to connect to AI Server at ", AIServerIP, ":", AIServerPort);
    
    // ตั้งค่า 5000ms (5 วินาที) เป็นค่า Timeout ในการเชื่อมต่อ
    if (SocketConnect(m_socket_handle, AIServerIP, AIServerPort, 5000) == false)
    {
        // หากเชื่อมต่อไม่สำเร็จ
        Print("ERROR: Failed to connect to AI Server. Error Code: ", GetLastError());
        
        // ปิด Socket ที่สร้างไว้และรีเซ็ต Handle เพื่อพยายามต่อใหม่ในรอบถัดไป
        SocketClose(m_socket_handle);
        m_socket_handle = -1;
        return false;
    }
    
    // D. เชื่อมต่อสำเร็จ
    Print("Successfully connected to AI Server (Handle: ", m_socket_handle, ")");
    return true;
}

//+------------------------------------------------------------------+
//| ฟังก์ชันส่งข้อมูล Market Data ไป AI Server                       |
//+------------------------------------------------------------------+
void SendMarketDataToAI()
{
    // ... (ในเวอร์ชันนี้ เราจะเติมโค้ด SendMarketDataToAI() ในขั้นตอนถัดไป)
    Print("Data sending simulation successful.");
}

//+------------------------------------------------------------------+
//| ฟังก์ชันรับสัญญาณจาก AI Server                                   |
//+------------------------------------------------------------------+
void ReceiveAISignal()
{
    // ... (ในเวอร์ชันนี้ เราจะเติมโค้ด ReceiveAISignal() ในขั้นตอนถัดไป)
    // สมมติว่าได้รับสัญญาณ 'Buy' (1.0)
    m_ai_signal = 1.0; 
    Print("AI Signal simulation received: ", m_ai_signal);
}

//+------------------------------------------------------------------+
//| ฟังก์ชันตัดสินใจซื้อขายตามสัญญาณ AI                             |
//| **สำคัญ: ต้องใส่ Logic ตรวจสอบการเปิด Position ก่อนเสมอ** |
//+------------------------------------------------------------------+
void ExecuteTradeBasedOnSignal()
{
    // ตรวจสอบว่ามี Position เปิดอยู่สำหรับคู่เงินนี้หรือไม่
    bool has_position = PositionSelect(_Symbol); // คืนค่า true หากมี position สำหรับ Symbol นี้

    if (m_ai_signal > 0.5) // สัญญาณ BUY
    {
        if (has_position)
        {
            // ตรรกะการจัดการ Position ที่มีอยู่
            long current_position_type = PositionGetInteger(POSITION_TYPE);
            if (current_position_type == POSITION_TYPE_SELL)
            {
                // สวนทาง: ปิด Sell แล้วเปิด Buy
                m_trade.PositionClose(_Symbol);
                Print("AI Signal: CLOSING SELL to PREPARE BUY.");
            }
            else { return; } // มี Buy อยู่แล้ว ไม่ทำอะไร
        }
        
        // ส่งคำสั่ง BUY
        m_trade.Buy(Volume, _Symbol, 0, 0, 0, "AI BUY Signal");
        Print("AI Signal: EXECUTE BUY Order (Volume: ", Volume, ")");
    }
    else if (m_ai_signal < -0.5) // สัญญาณ SELL
    {
        if (has_position)
        {
            // ตรรกะการจัดการ Position ที่มีอยู่
            long current_position_type = PositionGetInteger(POSITION_TYPE);
            if (current_position_type == POSITION_TYPE_BUY)
            {
                // สวนทาง: ปิด Buy แล้วเปิด Sell
                m_trade.PositionClose(_Symbol);
                Print("AI Signal: CLOSING BUY to PREPARE SELL.");
            }
            else { return; } // มี Sell อยู่แล้ว ไม่ทำอะไร
        }
        
        // ส่งคำสั่ง SELL
        m_trade.Sell(Volume, _Symbol, 0, 0, 0, "AI SELL Signal");
        Print("AI Signal: EXECUTE SELL Order (Volume: ", Volume, ")");
    }
    else // สัญญาณ NEUTRAL
    {
        // หากต้องการให้ EA ปิด Position เมื่อสัญญาณเป็นกลาง:
        // if (has_position) { m_trade.PositionClose(_Symbol); }
    }
}

//+------------------------------------------------------------------+
//| ฟังก์ชันส่งข้อมูล Market Data ไป AI Server                       |
//+------------------------------------------------------------------+
void SendMarketDataToAI()
{
    MqlTick current_tick;
    
    // A. ดึงข้อมูลราคาล่าสุด (Tick Data)
    if (!SymbolInfoTick(_Symbol, current_tick))
    {
        Print("ERROR: Failed to get current tick data. Error Code: ", GetLastError());
        return;
    }
    
    // B. ดึงค่า Indicator (RSI 14 Period)
    // นี่คือตัวอย่างข้อมูลที่จะส่งให้ AI วิเคราะห์
    double rsi_value = iRSI(_Symbol, _Period, 14, PRICE_CLOSE, 0);

    // C. จัดรูปแบบข้อมูลเป็น String (CSV Format)
    // ตัวอย่างรูปแบบ: "EURUSD,1.07550,55.45"
    string data_to_send = StringFormat("%s,%.5f,%.2f", 
                                       _Symbol,             // ชื่อคู่เงิน
                                       current_tick.bid,    // ราคาเสนอซื้อ (Bid Price)
                                       rsi_value);          // ค่า RSI
    
    // D. แปลง String เป็น Array of Bytes เพื่อส่งผ่าน Socket
    uchar data_bytes[];
    // กำหนดขนาดของ Array ให้เท่ากับความยาวของ String
    int size = StringToCharArray(data_to_send, data_bytes);
    
    if (size == 0)
    {
        Print("ERROR: Data conversion failed.");
        return;
    }

    // E. ส่งข้อมูลผ่าน Socket
    int bytes_sent = SocketSend(m_socket_handle, data_bytes, size);
    
    if (bytes_sent != size)
    {
        // F. การจัดการข้อผิดพลาดในการส่งข้อมูล (สำคัญในการไล่หาสาเหตุของ Bug)
        Print("WARNING: Failed to send all data (", bytes_sent, " of ", size, " bytes). Reconnecting...");
        
        // ปิด Socket เพื่อให้ OnTimer() ในรอบถัดไปพยายามต่อใหม่
        SocketClose(m_socket_handle); 
        m_socket_handle = -1;
    }
    else
    {
        // Print("Data sent successfully: ", data_to_send); // สามารถเปิดใช้งานเพื่อ Debug
    }
}

//+------------------------------------------------------------------+
//| ฟังก์ชันรับสัญญาณจาก AI Server                                   |
//+------------------------------------------------------------------+
void ReceiveAISignal()
{
    uchar buffer[64]; // กำหนดขนาด Buffer ที่เล็กพอสมควรสำหรับการรับค่า Signal
    
    // ตั้งค่า Timeout เพียง 100ms เพื่อไม่ให้ EA ติดค้างรอนานเกินไป
    int bytes_received = SocketRead(m_socket_handle, buffer, ArraySize(buffer), 100); 
    
    if (bytes_received > 0)
    {
        // A. แปลงข้อมูลที่ได้รับเป็น String
        string signal_string = CharArrayToString(buffer, 0, bytes_received);
        
        // B. ลบช่องว่างหรืออักขระที่ไม่จำเป็น (Trim)
        StringTrimLeft(signal_string);
        StringTrimRight(signal_string);

        // C. แปลง String เป็น Double
        double new_signal = StringToDouble(signal_string);
        
        // D. อัปเดตสัญญาณ AI
        m_ai_signal = new_signal;
        
        // Print สัญญาณที่ได้รับเพื่อ Debug และติดตามผล
        Print("AI Signal Received: ", signal_string, " -> ", m_ai_signal);
    }
    else if (bytes_received < 0)
    {
        // E. การจัดการข้อผิดพลาดในการรับข้อมูล
        // Error Code < 0 หมายถึงปัญหาเครือข่าย/การเชื่อมต่อหลุด
        Print("ERROR: Connection dropped while reading signal. Error Code: ", GetLastError());
        
        // ปิด Socket เพื่อให้ OnTimer() พยายามต่อใหม่ในรอบถัดไป
        SocketClose(m_socket_handle);
        m_socket_handle = -1;
    }
    // Note: bytes_received == 0 หมายถึงยังไม่มีข้อมูลเข้ามา (เป็นเรื่องปกติ)
}
//+------------------------------------------------------------------+