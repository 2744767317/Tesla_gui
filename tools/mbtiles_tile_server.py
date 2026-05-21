#!/usr/bin/env python3
"""Serve an MBTiles file as XYZ tiles for the Qt Location OSM plugin.

Usage:
    python3 tools/mbtiles_tile_server.py /path/to/map.mbtiles --port 8765

Then start the dashboard with:
    TESLA_MAP_TILE_HOST="http://127.0.0.1:8765" ./Tesla_Dashboard_UI
"""

from __future__ import annotations

import argparse
import mimetypes
import sqlite3
import threading
from collections import OrderedDict
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse


def detect_content_type(tile_data: bytes) -> str:
    if tile_data.startswith(b"\x89PNG\r\n\x1a\n"):
        return "image/png"
    if tile_data.startswith(b"\xff\xd8"):
        return "image/jpeg"
    if tile_data.startswith(b"RIFF") and b"WEBP" in tile_data[:16]:
        return "image/webp"
    return "application/octet-stream"


class MBTilesServer(BaseHTTPRequestHandler):
    db_path: Path
    flip_y: bool
    cache_limit: int = 4096
    tile_cache: OrderedDict[tuple[int, int, int], bytes] = OrderedDict()
    cache_lock = threading.Lock()
    thread_local = threading.local()

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        parts = [part for part in parsed.path.strip("/").split("/") if part]
        if len(parts) != 3:
            self.send_error(404, "Expected /z/x/y.png")
            return

        try:
            zoom = int(parts[0])
            tile_x = int(parts[1])
            tile_y = int(Path(parts[2]).stem)
        except ValueError:
            self.send_error(400, "Invalid tile coordinate")
            return

        mbtiles_y = (1 << zoom) - 1 - tile_y if self.flip_y else tile_y
        tile_data = self.lookup_tile(zoom, tile_x, mbtiles_y)
        if tile_data is None:
            self.send_error(404, "Tile not found")
            return

        self.send_response(200)
        self.send_header("Content-Type", detect_content_type(tile_data))
        self.send_header("Cache-Control", "public, max-age=31536000, immutable")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(tile_data)))
        self.end_headers()
        self.wfile.write(tile_data)

    def log_message(self, fmt: str, *args: object) -> None:
        return

    @classmethod
    def lookup_tile(cls, zoom: int, tile_x: int, tile_y: int) -> bytes | None:
        cache_key = (zoom, tile_x, tile_y)
        with cls.cache_lock:
            cached_tile = cls.tile_cache.get(cache_key)
            if cached_tile is not None:
                cls.tile_cache.move_to_end(cache_key)
                return cached_tile

        connection = cls.connection()
        cursor = connection.execute(
            """
            SELECT tile_data
            FROM tiles
            WHERE zoom_level = ? AND tile_column = ? AND tile_row = ?
            LIMIT 1
            """,
            cache_key,
        )
        row = cursor.fetchone()
        if not row:
            return None

        tile_data = row[0]
        with cls.cache_lock:
            cls.tile_cache[cache_key] = tile_data
            cls.tile_cache.move_to_end(cache_key)
            while len(cls.tile_cache) > cls.cache_limit:
                cls.tile_cache.popitem(last=False)

        return tile_data

    @classmethod
    def connection(cls) -> sqlite3.Connection:
        connection = getattr(cls.thread_local, "connection", None)
        if connection is None:
            connection = sqlite3.connect(f"file:{cls.db_path}?mode=ro", uri=True)
            connection.execute("PRAGMA query_only = ON")
            connection.execute("PRAGMA temp_store = MEMORY")
            connection.execute("PRAGMA mmap_size = 268435456")
            cls.thread_local.connection = connection
        return connection


def read_scheme(db_path: Path) -> str:
    try:
        with sqlite3.connect(f"file:{db_path}?mode=ro", uri=True) as connection:
            cursor = connection.execute(
                "SELECT value FROM metadata WHERE name = 'scheme' LIMIT 1"
            )
            row = cursor.fetchone()
            return str(row[0]).lower() if row else "tms"
    except sqlite3.Error:
        return "tms"


def main() -> int:
    parser = argparse.ArgumentParser(description="Serve MBTiles as XYZ tiles.")
    parser.add_argument("mbtiles", type=Path, help="Path to .mbtiles file")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument(
        "--xyz",
        action="store_true",
        help="Use XYZ tile_row without TMS Y flipping.",
    )
    parser.add_argument(
        "--cache-tiles",
        type=int,
        default=4096,
        help="Number of recently requested tiles to keep in memory.",
    )
    args = parser.parse_args()

    if not args.mbtiles.exists():
        raise SystemExit(f"MBTiles file not found: {args.mbtiles}")

    mimetypes.add_type("image/webp", ".webp")
    scheme = read_scheme(args.mbtiles)
    MBTilesServer.db_path = args.mbtiles.resolve()
    MBTilesServer.flip_y = not args.xyz and scheme != "xyz"
    MBTilesServer.cache_limit = max(0, args.cache_tiles)

    server = ThreadingHTTPServer((args.host, args.port), MBTilesServer)
    print(f"Serving {args.mbtiles} on http://{args.host}:{args.port}")
    print("Qt Location will request /z/x/y.png automatically from that base URL.")
    print(f"Tile scheme: {'TMS' if MBTilesServer.flip_y else 'XYZ'}, memory cache: {MBTilesServer.cache_limit} tiles")
    print("Press Ctrl+C to stop.")
    server.serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
