"""
One-off tool: downloads a representative, openly-licensed image for every
subcategory listed in the "services" sheet of xlsx/data.xlsx, via the
Openverse API (openly licensed / CC images, no API key required).

Images + an attribution manifest are stored under assets/services/.
This is source material for future UI work, not final production art —
review relevance/quality before shipping any of it.
"""

import csv
import json
import re
import time
from pathlib import Path
from urllib.parse import quote

import openpyxl
import requests

ROOT = Path(__file__).resolve().parent.parent
XLSX_PATH = ROOT / "xlsx" / "data.xlsx"
OUT_DIR = ROOT / "assets" / "services"
MANIFEST_PATH = OUT_DIR / "ATTRIBUTIONS.csv"
FAILED_PATH = OUT_DIR / "_not_found.txt"

OPENVERSE_URL = "https://api.openverse.org/v1/images/"
HEADERS = {"User-Agent": "PakkaHomes-AssetFetcher/1.0 (contact: aestheticphysiox@gmail.com)"}


def slugify(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[/&]", " ", text)
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return text.strip("-")


def load_items():
    wb = openpyxl.load_workbook(XLSX_PATH, data_only=True)
    ws = wb["services"]
    items = []
    for row in ws.iter_rows(min_row=2, values_only=True):
        category = row[0]
        if not category:
            continue
        for cell in row[1:]:
            if cell:
                items.append((category.strip(), cell.strip()))
    return items


def search_openverse(query: str):
    params = {
        "q": query,
        "page_size": 5,
        "license_type": "commercial,modification",
        "mature": "false",
    }
    resp = requests.get(OPENVERSE_URL, params=params, headers=HEADERS, timeout=20)
    resp.raise_for_status()
    return resp.json()


def clean_query(text: str) -> str:
    text = re.sub(r"[/&]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def find_result(category: str, subcategory: str):
    queries = [
        f"{clean_query(subcategory)} {category}",
        clean_query(subcategory),
        f"{category} service",
    ]
    for q in queries:
        try:
            data = search_openverse(q)
        except requests.RequestException as exc:
            print(f"  ! search failed for {q!r}: {exc}")
            time.sleep(2)
            continue
        results = data.get("results") or []
        for r in results:
            if r.get("url"):
                return r, q
        time.sleep(0.6)
    return None, None


def guess_ext(url: str, content_type: str) -> str:
    for ext in (".jpg", ".jpeg", ".png", ".webp"):
        if url.lower().split("?")[0].endswith(ext):
            return ".jpg" if ext == ".jpeg" else ext
    if content_type:
        if "png" in content_type:
            return ".png"
        if "webp" in content_type:
            return ".webp"
    return ".jpg"


def download_image(url: str, dest: Path) -> bool:
    try:
        resp = requests.get(url, headers=HEADERS, timeout=25, stream=True)
        resp.raise_for_status()
    except requests.RequestException as exc:
        print(f"  ! download failed: {exc}")
        return False
    ext = guess_ext(url, resp.headers.get("Content-Type", ""))
    dest = dest.with_suffix(ext)
    with open(dest, "wb") as f:
        for chunk in resp.iter_content(8192):
            f.write(chunk)
    return dest.exists() and dest.stat().st_size > 2000


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    items = load_items()
    print(f"Loaded {len(items)} subcategory items from services sheet")

    manifest_rows = []
    failed = []

    for i, (category, subcategory) in enumerate(items, 1):
        cat_slug = slugify(category)
        sub_slug = slugify(subcategory)
        cat_dir = OUT_DIR / cat_slug
        cat_dir.mkdir(parents=True, exist_ok=True)
        dest_stub = cat_dir / sub_slug

        print(f"[{i}/{len(items)}] {category} / {subcategory}")
        result, used_query = find_result(category, subcategory)
        if not result:
            print("  no result found")
            failed.append(f"{category} / {subcategory}")
            time.sleep(0.6)
            continue

        ok = download_image(result["url"], dest_stub)
        if not ok:
            failed.append(f"{category} / {subcategory} (download failed)")
            time.sleep(0.6)
            continue

        saved_path = None
        for ext in (".jpg", ".png", ".webp"):
            p = dest_stub.with_suffix(ext)
            if p.exists():
                saved_path = p
                break

        manifest_rows.append({
            "category": category,
            "subcategory": subcategory,
            "file": str(saved_path.relative_to(ROOT)) if saved_path else "",
            "query_used": used_query,
            "title": result.get("title"),
            "creator": result.get("creator"),
            "creator_url": result.get("creator_url"),
            "license": result.get("license"),
            "license_version": result.get("license_version"),
            "license_url": result.get("license_url"),
            "source_page": result.get("foreign_landing_url"),
            "image_url": result.get("url"),
            "provider": result.get("provider"),
        })
        time.sleep(0.6)

    with open(MANIFEST_PATH, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(manifest_rows[0].keys()) if manifest_rows else [
            "category", "subcategory", "file", "query_used", "title", "creator",
            "creator_url", "license", "license_version", "license_url",
            "source_page", "image_url", "provider",
        ])
        writer.writeheader()
        writer.writerows(manifest_rows)

    with open(FAILED_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(failed))

    print(f"\nDone. {len(manifest_rows)} downloaded, {len(failed)} failed.")
    print(f"Manifest: {MANIFEST_PATH}")
    if failed:
        print(f"Failed list: {FAILED_PATH}")


if __name__ == "__main__":
    main()
