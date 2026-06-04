# 🔌 SKILL: IoT Backend Best Practices

**Para:** `~/.claude/skills/IoT-Backend-Best-Practices.md`

---

## 📋 CUÁNDO USAR ESTA SKILL

✅ Escribiendo código del boliche (Raspberry Pi)
✅ Manejo de GPIO / limit switches
✅ WebSockets en tiempo real
✅ MongoDB + FastAPI + async
✅ Scoring logic especializado en bowling
✅ Testing en hardware (Pi) vs mocks

---

## 🎯 PATRONES CORE

### 1. GPIO Management

#### Debounce (50ms estándar)
```python
import asyncio
from datetime import datetime

async def handle_limit_switch(pin_number):
    """Handle limit switch with debounce"""
    # Read initial state
    initial_state = GPIO.read(pin_number)
    
    # Wait 50ms (debounce window)
    await asyncio.sleep(0.05)
    
    # Read again to confirm (no noise)
    confirmed_state = GPIO.read(pin_number)
    
    if initial_state == confirmed_state:
        # Valid state change, process
        await process_pin_event(pin_number, confirmed_state)
    else:
        # Noise, ignore
        logger.debug(f"Debounce ignored on pin {pin_number}")
```

#### Never Block Event Loop
```python
# ❌ WRONG: Blocks the loop
def read_all_pins():
    for pin in [1, 2, 3, 4]:
        time.sleep(0.1)  # BLOCKS!
        state = GPIO.read(pin)
        process(state)

# ✅ CORRECT: Async, non-blocking
async def read_all_pins():
    tasks = []
    for pin in [1, 2, 3, 4]:
        tasks.append(handle_pin_async(pin))
    await asyncio.gather(*tasks)
```

#### Async/Await Always
```python
# Queue events for async processing
class PinEventQueue:
    def __init__(self):
        self.queue = asyncio.Queue()
    
    async def add_event(self, pin, state):
        """Add pin change to async queue"""
        await self.queue.put({
            'pin': pin,
            'state': state,
            'timestamp': datetime.now(),
            'source': 'gpio'
        })
    
    async def process_queue(self):
        """Continuously process queued events"""
        while True:
            event = await self.queue.get()
            await handle_event(event)
            self.queue.task_done()
```

---

### 2. Raspberry Pi Constraints

#### Memory Management
```python
import psutil

async def monitor_memory():
    """Monitor and cleanup if needed"""
    while True:
        memory_percent = psutil.virtual_memory().percent
        
        if memory_percent > 85:
            # Cleanup: clear caches, close unused connections
            logger.warning(f"Memory high: {memory_percent}%")
            await cleanup_memory()
            # Force garbage collection
            import gc
            gc.collect()
        
        await asyncio.sleep(30)  # Check every 30s

async def cleanup_memory():
    """Release unnecessary memory"""
    # Close idle DB connections
    await db.cleanup_idle_connections()
    
    # Clear event buffers
    if len(event_buffer) > 1000:
        # Archive old events to disk
        await archive_old_events()
        event_buffer.clear()
```

#### CPU Throttling (Keep < 80°C)
```python
import os

async def monitor_cpu_temp():
    """Monitor CPU temperature on Pi"""
    while True:
        # Read CPU temp from /sys/class/thermal/thermal_zone0/temp
        try:
            with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
                temp_millidegrees = int(f.read().strip())
                temp_celsius = temp_millidegrees / 1000
            
            logger.info(f"CPU Temp: {temp_celsius}°C")
            
            if temp_celsius > 80:
                logger.critical(f"CPU overheating: {temp_celsius}°C")
                # Throttle operations
                await throttle_operations()
        except:
            pass
        
        await asyncio.sleep(60)

async def throttle_operations():
    """Reduce load when CPU hot"""
    # Reduce logging frequency
    # Pause non-critical tasks
    # Increase polling intervals
    pass
```

#### SD Card Reliability
```python
# ✅ Use SSD via USB if possible (not MicroSD)
# ✅ Enable journaling on filesystem
# ✅ Configure log rotation (not unlimited growth)

# In systemd service:
# StandardOutput=journal
# StandardError=journal
# SyslogIdentifier=boliche

# In Python:
import logging
from logging.handlers import RotatingFileHandler

handler = RotatingFileHandler(
    'boliche.log',
    maxBytes=10_000_000,  # 10MB
    backupCount=5         # Keep 5 backups
)
```

---

### 3. WebSocket Reliability

#### Ping/Pong (30s interval)
```python
import asyncio
from fastapi import WebSocket

class WebSocketManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []
        self.ping_interval = 30  # seconds
    
    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
        # Start ping/pong for this connection
        asyncio.create_task(self.ping_client(websocket))
    
    async def ping_client(self, websocket: WebSocket):
        """Send ping every 30s, expect pong response"""
        while websocket in self.active_connections:
            try:
                await websocket.send_json({
                    'type': 'ping',
                    'timestamp': datetime.now().isoformat()
                })
                # Expect pong within 10s
                await asyncio.wait_for(
                    self.wait_for_pong(websocket),
                    timeout=10
                )
                await asyncio.sleep(self.ping_interval)
            except asyncio.TimeoutError:
                logger.warning(f"Pong timeout for {websocket}")
                await self.disconnect(websocket)
            except:
                break
```

#### Reconnect with Exponential Backoff
```javascript
// Client-side (JavaScript)
class GameClient {
    constructor() {
        this.ws = null;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 10;
        this.baseReconnectDelay = 1000; // 1s
    }
    
    async connect(url) {
        try {
            this.ws = new WebSocket(url);
            this.ws.onopen = () => this.onConnect();
            this.ws.onmessage = (e) => this.onMessage(e);
            this.ws.onerror = () => this.onError();
            this.ws.onclose = () => this.onClose();
        } catch (error) {
            this.reconnect();
        }
    }
    
    async reconnect() {
        if (this.reconnectAttempts >= this.maxReconnectAttempts) {
            console.error('Max reconnect attempts reached');
            return;
        }
        
        // Exponential backoff: 1s, 2s, 4s, 8s...
        const delay = this.baseReconnectDelay * Math.pow(2, this.reconnectAttempts);
        this.reconnectAttempts++;
        
        console.log(`Reconnecting in ${delay}ms...`);
        await new Promise(resolve => setTimeout(resolve, delay));
        
        this.connect(this.url);
    }
    
    onConnect() {
        console.log('Connected');
        this.reconnectAttempts = 0; // Reset on success
    }
    
    onClose() {
        console.log('Disconnected');
        this.reconnect();
    }
}
```

#### Message Queue for Offline Clients
```python
# Server-side: Queue messages while client offline
class OfflineMessageQueue:
    def __init__(self, max_queue_size=1000):
        self.queues: dict[str, asyncio.Queue] = {}
        self.max_queue_size = max_queue_size
    
    async def queue_message(self, client_id: str, message: dict):
        """Queue message if client offline"""
        if client_id not in self.queues:
            self.queues[client_id] = asyncio.Queue()
        
        queue = self.queues[client_id]
        if queue.qsize() < self.max_queue_size:
            await queue.put(message)
        else:
            logger.warning(f"Queue full for {client_id}, dropping old messages")
            # Drop oldest message to make room
            try:
                queue.get_nowait()
            except:
                pass
            await queue.put(message)
    
    async def get_queued_messages(self, client_id: str) -> list:
        """Return all queued messages for client"""
        if client_id not in self.queues:
            return []
        
        messages = []
        queue = self.queues[client_id]
        
        while not queue.empty():
            try:
                messages.append(queue.get_nowait())
            except:
                break
        
        # Delete empty queue
        if queue.empty():
            del self.queues[client_id]
        
        return messages
```

---

### 4. MongoDB Async Patterns

#### Motor (Async MongoDB Driver)
```python
from motor.motor_asyncio import AsyncClient

async def init_db():
    """Initialize Motor client"""
    client = AsyncClient("mongodb://localhost:27017")
    db = client.boliche
    return db

async def record_game_score(db, game_id: str, frames: list, total: int):
    """Async insert game score"""
    result = await db.games.insert_one({
        '_id': game_id,
        'frames': frames,
        'total_score': total,
        'timestamp': datetime.now(),
        'version': 1
    })
    return result.inserted_id

async def get_game_stats(db, game_id: str):
    """Async query with aggregation"""
    pipeline = [
        {'$match': {'_id': game_id}},
        {'$project': {
            'avg_pin_knockdown': {
                '$avg': '$frames.pins_knocked'
            },
            'strikes': {
                '$size': {
                    '$filter': {
                        'input': '$frames',
                        'as': 'frame',
                        'cond': {'$eq': ['$$frame.pins_knocked', 10]}
                    }
                }
            }
        }}
    ]
    
    result = await db.games.aggregate(pipeline).to_list(1)
    return result[0] if result else None
```

#### Index Optimization
```python
async def create_indexes(db):
    """Create indexes for performance"""
    # Index on game_id (query performance)
    await db.games.create_index('_id')
    
    # Index on timestamp (for range queries)
    await db.games.create_index('timestamp')
    
    # Compound index for common queries
    await db.games.create_index([
        ('player_id', 1),
        ('timestamp', -1)
    ])
    
    # TTL index (auto-delete old data after 30 days)
    await db.game_sessions.create_index(
        'timestamp',
        expireAfterSeconds=30*24*60*60
    )
```

---

### 5. Bowling Scoring Logic (Atomic)

```python
class BowlingScorer:
    """Handle bowling scoring with validation"""
    
    def calculate_frame_score(self, frame_pins: list) -> dict:
        """Calculate score for one frame"""
        if len(frame_pins) > 3:
            raise ValueError("Frame cannot have more than 3 rolls")
        
        total = sum(frame_pins)
        
        if total > 10 and len(frame_pins) == 2:
            raise ValueError("Cannot knock down more than 10 pins in 2 rolls")
        
        # Strike (10 on first roll)
        if len(frame_pins) >= 1 and frame_pins[0] == 10:
            return {
                'type': 'strike',
                'pins': 10,
                'bonus_frames': 2
            }
        
        # Spare (10 on first two rolls)
        if len(frame_pins) >= 2 and sum(frame_pins[:2]) == 10:
            return {
                'type': 'spare',
                'pins': 10,
                'bonus_frames': 1
            }
        
        # Open frame
        return {
            'type': 'open',
            'pins': total,
            'bonus_frames': 0
        }
    
    def calculate_total_score(self, all_frames: list) -> int:
        """Calculate final score with bonuses"""
        score = 0
        
        for i, frame in enumerate(all_frames):
            frame_score = sum(frame)
            
            if frame_score == 10:
                # Strike or spare - add bonus
                bonus = sum(all_frames[i+1][:2]) if i+1 < len(all_frames) else 0
                score += 10 + bonus
            else:
                score += frame_score
        
        return score
```

---

## 🧪 TESTING PATTERNS

### Unit Tests (Mock GPIO)
```python
import pytest
from unittest.mock import Mock, patch

@pytest.mark.asyncio
async def test_debounce_ignores_noise():
    """Test debounce filters out noise"""
    with patch('GPIO.read') as mock_read:
        # First read: HIGH
        # Wait 50ms
        # Second read: LOW (noise)
        mock_read.side_effect = [1, 0]
        
        result = await handle_limit_switch(pin=1)
        
        # Should be ignored (no state change)
        assert result is None

@pytest.mark.asyncio
async def test_debounce_confirms_valid_state():
    """Test debounce confirms consistent state"""
    with patch('GPIO.read') as mock_read:
        # First read: HIGH
        # Wait 50ms
        # Second read: HIGH (valid)
        mock_read.side_effect = [1, 1]
        
        result = await handle_limit_switch(pin=1)
        
        # Should process
        assert result == {'pin': 1, 'state': 1}
```

### Integration Tests (Real GPIO on Pi)
```python
@pytest.mark.asyncio
@pytest.mark.pi_hardware  # Only run on actual Pi
async def test_limit_switch_on_real_hardware():
    """Test with actual limit switch"""
    # Requires: Limit switch physically connected to GPIO pin 17
    
    events = []
    
    async def event_handler(event):
        events.append(event)
    
    # Monitor pin 17
    monitor = PinMonitor(pin=17, callback=event_handler)
    
    # Manually press limit switch
    # (or use test rig with servo to press it)
    await asyncio.sleep(1)
    
    # Should have recorded exactly 1 event (debounce)
    assert len(events) == 1
    assert events[0]['pin'] == 17
```

### Stress Tests
```python
@pytest.mark.asyncio
async def test_100_presses_per_second():
    """Stress test: 100 pin presses/sec"""
    events = []
    
    async def event_handler(event):
        events.append(event)
    
    # Simulate 100 presses/sec for 10 seconds
    for _ in range(1000):
        await handle_limit_switch(pin=17)
        # Should debounce properly
        await asyncio.sleep(0.001)
    
    # Memory should not grow unbounded
    import gc
    gc.collect()
    memory_usage = psutil.Process().memory_info().rss / 1024 / 1024
    
    assert memory_usage < 100  # < 100MB
```

---

## ⚠️ GOTCHAS & ANTI-PATTERNS

❌ **Blocking I/O in async code:**
```python
# WRONG
async def bad_example():
    time.sleep(1)  # BLOCKS ENTIRE EVENT LOOP!

# CORRECT
async def good_example():
    await asyncio.sleep(1)  # Non-blocking
```

❌ **Forgetting await:**
```python
# WRONG
async def bad():
    task = some_async_function()  # Task not awaited!

# CORRECT
async def good():
    await some_async_function()
    # or
    task = asyncio.create_task(some_async_function())
```

❌ **Hardcoding Pi-specific paths:**
```python
# WRONG
temp_file = "/sys/class/thermal/thermal_zone0/temp"

# CORRECT
import platform
if platform.machine() == 'armv7l':  # Pi
    temp_file = "/sys/class/thermal/thermal_zone0/temp"
else:  # Development machine
    temp_file = None  # Skip on non-Pi
```

---

## ✅ CHECKLIST ANTES DE COMMIT

- [ ] No `time.sleep()` (use `await asyncio.sleep()`)
- [ ] No GPIO operations in main thread (use async queue)
- [ ] Debounce applied to all limit switches (50ms)
- [ ] WebSocket ping/pong every 30s
- [ ] Message queue for offline clients
- [ ] Tests mock GPIO (no real hardware in CI)
- [ ] Stress test: 100+ presses/sec
- [ ] Memory monitoring enabled
- [ ] CPU temp monitoring enabled
- [ ] Logging configured with rotation
- [ ] Error handling for all async operations
- [ ] Graceful shutdown on KeyboardInterrupt

---

**Última actualización:** 2026-06-04
**Aplicable a:** Boliche Raspberry Pi + FastAPI + MongoDB
