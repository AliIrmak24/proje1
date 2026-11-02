# app/core/rate_limit.py
# Tek sunucu işlemi için bellek içi deneme sınırlayıcı

import threading
import time
from collections import defaultdict, deque
from fastapi import HTTPException

class RateLimiter:
    def __init__(self, max_attempts: int, window_seconds: int):
        self.max_attempts = max_attempts
        self.window_seconds = window_seconds
        self._attempts: dict[str, deque[float]] = defaultdict(deque)
        self._lock = threading.Lock()

    def check(self, key: str):
        with self._lock:
            attempts = self._attempts[key]
            cutoff = time.monotonic() - self.window_seconds
            while attempts and attempts[0] < cutoff:
                attempts.popleft()
            if len(attempts) >= self.max_attempts:
                raise HTTPException(status_code=429, detail="Çok fazla deneme yapıldı, lütfen biraz sonra tekrar deneyin")

    def record(self, key: str):
        with self._lock:
            self._attempts[key].append(time.monotonic())

    def reset(self, key: str | None = None):
        with self._lock:
            if key is None:
                self._attempts.clear()
            else:
                self._attempts.pop(key, None)

login_limiter = RateLimiter(max_attempts=10, window_seconds=300)
register_limiter = RateLimiter(max_attempts=20, window_seconds=3600)
