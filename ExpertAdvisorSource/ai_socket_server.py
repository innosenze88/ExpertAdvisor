import socket
import threading
import time
# ถ้ามีการใช้ Machine Learning Model จริง จะต้อง import พวก TensorFlow/PyTorch ด้วย
# import your_ml_model 

HOST = '127.0.0.1'  # IP เดียวกับที่ตั้งใน MQL5 (AIServerIP)
PORT = 8888         # Port เดียวกันกับที่ตั้งใน MQL5 (AIServerPort)

# --- 1. ฟังก์ชันจำลองการตัดสินใจของ AI ---
def get_ai_signal(market_data: str) -> str:
    """
    ฟังก์ชันนี้จำลองการประมวลผลของ AI 
    โดยปกติจะนำ market_data ไปเข้าโมเดล ML เพื่อได้สัญญาณออกมา
    """
    try:
        # market_data จะเป็นรูปแบบ CSV: "SYMBOL,PRICE,RSI_VALUE"
        symbol, price_str, rsi_str = market_data.split(',')
        price = float(price_str)
        rsi = float(rsi_str)
        
        # --- ตรรกะการจำลองสัญญาณ AI (คุณสามารถแทนที่ด้วยโมเดล ML จริง) ---
        # สัญญาณ Buy: ถ้า RSI ต่ำกว่า 30 (Oversold)
        if rsi < 30.0:
            signal = 1.0  # Buy
        # สัญญาณ Sell: ถ้า RSI สูงกว่า 70 (Overbought)
        elif rsi > 70.0:
            signal = -1.0 # Sell
        # สัญญาณ Neutral: ถ้าอยู่ระหว่าง 30 ถึง 70
        else:
            signal = 0.0  # Neutral
        
        print(f"[{symbol} @ {price}] RSI={rsi:.2f} -> Signal: {signal:.1f}")
        return f"{signal:.2f}" # ส่งกลับเป็น String ที่มีทศนิยม 2 ตำแหน่ง
        
    except Exception as e:
        print(f"Error processing data: {e}. Data: {market_data}")
        return "0.0" # ส่งสัญญาณ Neutral ถ้ามีข้อผิดพลาด

# --- 2. ฟังก์ชันจัดการการเชื่อมต่อแต่ละ Client (EA) ---
def handle_client(conn, addr):
    print(f"Connection established from {addr}")
    
    # กำหนด Timeout สำหรับ Socket
    conn.settimeout(5.0) 
    
    while True:
        try:
            # รับข้อมูลจาก MT5 EA (Buffer 1024 bytes)
            data = conn.recv(1024)
            if not data:
                break # ถ้าไม่มีข้อมูล แสดงว่า Client ปิดการเชื่อมต่อ
                
            # ถอดรหัสข้อมูลที่ได้รับจาก bytes เป็น String
            market_data = data.decode('utf-8').strip()
            
            # 1. ประมวลผลสัญญาณ AI
            ai_signal = get_ai_signal(market_data)
            
            # 2. ส่งสัญญาณ AI กลับไปยัง MT5 EA
            conn.sendall(ai_signal.encode('utf-8'))
            
        except socket.timeout:
            # นี่คือเรื่องปกติ ถ้า EA ไม่ได้ส่งข้อมูลทุก Tick
            pass 
        except ConnectionResetError:
            # ปัญหาที่ Client (MT5 EA) ปิดการเชื่อมต่อ
            print(f"Client {addr} forcefully closed the connection.")
            break
        except Exception as e:
            # การจัดการข้อผิดพลาดอื่นๆ (สำคัญใน DevOps)
            print(f"Unexpected error with client {addr}: {e}")
            break

    print(f"Connection with {addr} closed.")
    conn.close()

# --- 3. ฟังก์ชันหลักสำหรับรัน Socket Server ---
def start_server():
    # สร้าง Socket Object
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    
    # ตั้งค่าให้สามารถนำ Address/Port กลับมาใช้ใหม่ได้ทันที
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1) 
    
    try:
        # ผูก Socket เข้ากับ Host และ Port
        server_socket.bind((HOST, PORT))
        
        # เริ่มรอรับการเชื่อมต่อ (คิวได้ 5 ตัว)
        server_socket.listen(5)
        print(f"AI Socket Server is listening on {HOST}:{PORT}")
        
        while True:
            # รอรับการเชื่อมต่อจาก Client ใหม่
            conn, addr = server_socket.accept()
            
            # สร้าง Thread ใหม่เพื่อจัดการ Client แต่ละตัว (ทำให้รองรับหลาย EA ได้)
            client_thread = threading.Thread(target=handle_client, args=(conn, addr))
            client_thread.start()
            
    except Exception as e:
        print(f"FATAL ERROR during server startup: {e}")
    finally:
        server_socket.close()

if __name__ == "__main__":
    start_server()