import socket
import threading
import time

# --- Configuration ---
HOST = '127.0.0.1'
PORT = 8888


def get_ai_signal(market_data: str) -> str:
    """
    Simulate AI Logic.
    Input: "Symbol,Bid,RSI"
    Output: "Signal,SL,TP"
    """
    try:
        # Debug Log (สำคัญ)
        print(f"Received Raw Data: '{market_data}'", flush=True)

        parts = market_data.split(',')
        if len(parts) < 3:
            print("Error: Not enough data parts", flush=True)
            return "0.0,0.0,0.0"

        symbol = parts[0]
        # FIX: ใช้ replace เพื่อรับได้ทั้ง . และ , เป็นทศนิยม
        try:
            bid_price = float(parts[1].replace(',', '.'))
            rsi_value = float(parts[2].replace(',', '.'))
        except ValueError:
            print(f"ValueError: Cannot convert price/RSI. Data: {market_data}", flush=True)
            return "0.0,0.0,0.0"

        # --- Simple Logic (RSI) ---
        signal = 0.0
        if rsi_value < 30.0:
            signal = 1.0  # Buy
        elif rsi_value > 70.0:
            signal = -1.0  # Sell

        # --- SL/TP Calculation ---
        point = 0.00100
        sl = 0.0
        tp = 0.0

        if signal == 1.0:
            sl = bid_price - point
            tp = bid_price + point
        elif signal == -1.0:
            sl = bid_price + point
            tp = bid_price - point

        response = f"{signal:.1f},{sl:.5f},{tp:.5f}"

        if signal != 0.0:
            print(f"[{symbol}] RSI:{rsi_value:.2f} -> SIGNAL: {response}", flush=True)

        return response

    except Exception as e:
        print(f"Logic Error in get_ai_signal: {e} | Data was: {market_data}", flush=True)
        return "0.0,0.0,0.0"


def handle_client(conn, addr):
    # FIX: บังคับให้เป็น Non-blocking mode
    conn.setblocking(False)
    print(f"[CONNECTED] Client {addr} linked.", flush=True)

    try:
        while True:
            # ใช้ try-except ครอบการรับข้อมูลทั้งหมด
            try:
                # ลองรับข้อมูลแบบ non-blocking
                data = conn.recv(1024)

                if not data:
                    # ถ้าไม่มีข้อมูลแต่ไม่มี Error และ socket ไม่ได้ถูก block แสดงว่า Client ปิดการเชื่อมต่อ
                    print(f"[INFO] Client {addr} disconnected.", flush=True)
                    break

                    # --- ส่วน Decode และ Process Data ---
                msg = data.decode('utf-8', errors='ignore').strip()

                if not msg:
                    time.sleep(0.001)
                    continue

                # Process AI และส่งกลับ
                response = get_ai_signal(msg)
                conn.sendall(response.encode('utf-8'))

            except socket.error as e:
                # ตรวจจับ BlockingIOError ที่เกิดจาก setblocking(False)
                if e.errno == 10035:  # Windows specific BlockingIOError
                    time.sleep(0.001)
                    continue

                if e.errno == 10054:  # ConnectionResetError/Forceful disconnect
                    print(f"[INFO] Client {addr} reset connection (Error 10054).", flush=True)
                    break

                # Other socket errors
                print(f"[SOCKET ERROR] Client {addr}: {e}", flush=True)
                break

            except ConnectionResetError:
                print(f"[INFO] Client {addr} reset connection.", flush=True)
                break
            except Exception as e:
                print(f"[CRITICAL ERROR] Thread Exception: {e}", flush=True)
                break

    finally:
        conn.close()
        print(f"[DISCONNECTED] {addr} closed.", flush=True)


def start_server():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    # FIX: การย่อหน้า (Indentation) และเพิ่ม flush=True
    try:
        server.bind((HOST, PORT))
        server.listen(5)
        print(f"=== AI Server Ready at {HOST}:{PORT} ===", flush=True)
        print("Waiting for MT5 connection...", flush=True)

        while True:
            conn, addr = server.accept()
            thread = threading.Thread(target=handle_client, args=(conn, addr))
            thread.daemon = True
            thread.start()

    except Exception as e:
        print(f"Server Start Error: {e}", flush=True)
    finally:
        server.close()


if __name__ == '__main__':
    start_server()