import os
import datetime

def logger(sid, msg):
    if os.getenv('HANDSOFF_DEBUG', '0').lower() in ['0', 'false', 'off', 'disable']:
        return
    os.makedirs('.tmp', exist_ok=True)
    with open('.tmp/hook-debug.log', 'a') as log_file:
        time = datetime.datetime.now().isoformat()
        log_file.write(f"[{time}] [{sid}] {msg}\n")

def log_tool_decision(session, context, tool, target, decision):
    # Determine target based on tool and its input
    if os.getenv('HANDSOFF_DEBUG', '0').lower() in ['0', 'false', 'off', 'disable']:
        return
    os.makedirs('.tmp', exist_ok=True)
    os.makedirs('.tmp/hooked-sessions', exist_ok=True)
    time = datetime.datetime.now().isoformat()
    with open('.tmp/hooked-sessions/{time}-decision.txt', 'w') as f:
        f.write(f'[{time}] [{session}] {tool} | {target} => {decision}\n')
        f.write(f'Context:\n{context}\n')