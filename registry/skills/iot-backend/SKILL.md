---
name: iot-backend
description: Patrones especializados para backends IoT en Raspberry Pi con GPIO, FastAPI, MongoDB async y WebSockets. Usar cuando se trabaje con hardware, limit switches, scoring de bowling, o cualquier integración edge-device.
argument-hint: --component gpio|scoring|websocket
tools: [Read, Write, Edit, Bash]
tier: extended
---

# IoT Backend Best Practices

## Contexto
Backend del boliche semiautomático en Raspberry Pi. Stack: FastAPI + MongoDB async + RPi.GPIO + WebSocket.

## GPIO: Debounce (50ms estándar)
```python
async def handle_limit_switch(pin_number: int):
    initial_state = GPIO.read(pin_number)
    await asyncio.sleep(0.05)  # 50ms debounce
    if GPIO.read(pin_number) == initial_state:
        await process_switch_event(pin_number, initial_state)
```

## MongoDB async (motor)
```python
from motor.motor_asyncio import AsyncIOMotorClient

client = AsyncIOMotorClient(os.getenv("MONGODB_URL"))
db = client.bowling

async def save_frame(frame: dict):
    await db.frames.insert_one(frame)
```

## FastAPI + WebSocket real-time
```python
@app.websocket("/ws/game/{game_id}")
async def game_socket(websocket: WebSocket, game_id: str):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_json()
            await manager.broadcast(game_id, data)
    except WebSocketDisconnect:
        manager.disconnect(websocket)
```

## Testing en Pi vs mocks
- Tests unitarios: mockear GPIO con `unittest.mock`
- Tests de integración: correr en Pi real con hardware conectado
- Nunca mockear MongoDB en tests de integración

## Reglas críticas
- GPIO cleanup en finally/signal handlers
- Timeout en operaciones de hardware (nunca esperar indefinidamente)
- Logs estructurados para debugging remoto
