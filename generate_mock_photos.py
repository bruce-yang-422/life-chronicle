"""產生附件壓力測資；合成圖不代表真實相機畫質或指定檔案大小。"""
import argparse
import hashlib
import json
from pathlib import Path
import secrets

import numpy as np
import piexif
from PIL import Image, ImageDraw, ImageFont, ImageOps

PROFILES = [
    ("phone12", 4032, 3024, "JPEG", 92, 100),
    ("phone48", 8192, 6144, "JPEG", 95, 20),
    ("screenshot", 1290, 2796, "PNG", None, 50),
    ("camera24", 6000, 4000, "JPEG", 95, 50),
]
# 儲存時套用反向變換，EXIF 顯示校正後應回到可讀的 TOP／四角標記。
INVERSE = {
    2: Image.Transpose.FLIP_LEFT_RIGHT,
    3: Image.Transpose.ROTATE_180,
    4: Image.Transpose.FLIP_TOP_BOTTOM,
    5: Image.Transpose.TRANSPOSE,
    6: Image.Transpose.ROTATE_90,
    7: Image.Transpose.TRANSVERSE,
    8: Image.Transpose.ROTATE_270,
}


def new_run_directory(root, prefix):
    # 一般 mkdir 沿用專案資料夾權限，讓 IDE／使用者也能開啟圖片。
    for _ in range(10):
        target = root / (prefix + secrets.token_hex(4))
        try:
            target.mkdir()
            return target
        except FileExistsError:
            continue
    raise FileExistsError("無法建立新的產圖資料夾")


def generate_realistic_noise_image(width, height, rng):
    # 按列區塊建圖，避免同時配置多個 48MP 浮點陣列。
    rgb = np.empty((height, width, 3), dtype=np.uint8)
    base = np.linspace(50, 200, width, dtype=np.float32)
    for start in range(0, height, 128):
        end = min(start + 128, height)
        noise = rng.integers(0, 50, (end - start, width, 3), dtype=np.uint8)
        for channel, gradient in enumerate((base, base * .8, 255 - base * .5)):
            rgb[start:end, :, channel] = np.clip(
                gradient + noise[:, :, channel], 0, 255
            ).astype(np.uint8)
    image = Image.fromarray(rgb)
    draw = ImageDraw.Draw(image)
    font = ImageFont.load_default(size=max(12, min(width, height) // 24))
    margin = max(6, min(width, height) // 32)
    for text, xy, anchor, color in [
        ("TL", (margin, margin), "lt", "red"),
        ("TR", (width-margin, margin), "rt", "green"),
        ("BL", (margin, height-margin), "lb", "blue"),
        ("BR", (width-margin, height-margin), "rb", "yellow"),
        ("TOP ^", (width//2, margin), "mt", "white"),
    ]:
        draw.text(xy, text, font=font, anchor=anchor, fill=color,
                  stroke_width=2, stroke_fill="black")
    return image


def metadata(mode, orientation):
    if mode == "none":
        return None
    data = {
        "0th": {piexif.ImageIFD.Make: b"Synthetic",
                piexif.ImageIFD.Model: b"MockCamera",
                piexif.ImageIFD.Orientation: orientation},
        "Exif": {piexif.ExifIFD.DateTimeOriginal: b"2020:06:15 14:30:00",
                 piexif.ExifIFD.OffsetTimeOriginal: b"+08:00"},
        "GPS": {},
    }
    if mode == "gps":
        # 明確的合成測試座標，非圖片真實拍攝地點。
        data["GPS"] = {
            piexif.GPSIFD.GPSVersionID: (2, 3, 0, 0),
            piexif.GPSIFD.GPSLatitudeRef: b"N",
            piexif.GPSIFD.GPSLatitude: ((25, 1), (2, 1), (0, 1)),
            piexif.GPSIFD.GPSLongitudeRef: b"E",
            piexif.GPSIFD.GPSLongitude: ((121, 1), (33, 1), (0, 1)),
            piexif.GPSIFD.GPSAltitudeRef: 0,
            piexif.GPSIFD.GPSAltitude: (10, 1),
        }
    return piexif.dump(data)



def build_demo_bundle(snapshot, output_root, per_event, seed):
    """針對已備份的 50 筆 demo，逐篇產生約 20 MB 內的新照片集合。"""
    proof = json.loads(snapshot.read_text(encoding="utf-8"))
    data = proof["data"]
    events = data["events"]
    if len(events) != 50 or any(not e["title"].startswith("【模擬・") for e in events):
        raise ValueError("只允許 50 筆已標示模擬的 demo 事件")
    blobs = {b["blob_id"]: b for b in data["blobs"]}
    output_root.mkdir(parents=True, exist_ok=True)
    output = new_run_directory(output_root, f"demo50_{seed}_")
    bundle = {"synthetic": True, "seed": seed, "subject_id": events[0]["subject_id"],
              "limit_bytes": 25000000, "photos_per_event": per_event, "events": []}
    rng = np.random.default_rng(seed)
    alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
    for event_index, event in enumerate(events):
        prior = [a for a in data["attachments"] if a["event_id"] == event["event_id"]]
        used = sum(blobs[a["blob_id"]]["byte_size"] for a in prior)
        budget = (20000000 - used) // per_event
        if budget < 100000:
            raise ValueError("事件既有附件過多，停止產圖")
        item = {"event_id": event["event_id"], "title": event["title"],
                "existing_ids": sorted(a["attachment_id"] for a in prior),
                "existing_bytes": used, "photos": []}
        for slot in range(per_event):
            number = event_index * per_event + slot
            case = number % 10
            mode = "none" if case == 0 else "time" if case == 1 else "gps"
            orientation = case - 1 if case >= 2 else 1
            image = generate_realistic_noise_image(4032, 3024, rng)
            if orientation in INVERSE:
                transformed = image.transpose(INVERSE[orientation])
                image.close()
                image = transformed
            filename = f"event{event_index+1:02d}_{slot+1:02d}_{mode}_o{orientation}.jpg"
            target = output / filename
            exif = metadata(mode, orientation)
            options = {"exif": exif} if exif else {}
            try:
                for quality in range(90, 49, -2):
                    image.save(target, format="JPEG", quality=quality, optimize=True, **options)
                    if target.stat().st_size <= budget:
                        break
                else:
                    raise ValueError("無法在目標額度內產圖")
            finally:
                image.close()
            with Image.open(target) as saved:
                saved.load()
                assert saved.getexif().get(274, 1) == orientation
                assert bool(saved.getexif()) == (mode != "none")
                normalized = ImageOps.exif_transpose(saved)
                assert normalized.size == (4032, 3024)
                normalized.close()
            digest = hashlib.sha256(target.read_bytes()).hexdigest()
            # 每份集合採固定引用 ID，重跑裝置匯入時不會重複增加引用。
            value = int.from_bytes(hashlib.sha256(
                f"{seed}:{event['event_id']}:{slot}:{digest}".encode()).digest()[:16], "big")
            encoded = ""
            for _ in range(26):
                encoded = alphabet[value & 31] + encoded
                value >>= 5
            item["photos"].append({"file": filename, "bytes": target.stat().st_size,
                                   "sha256": digest, "reference_id": encoded,
                                   "quality": quality, "exif": mode, "orientation": orientation})
        item["total_bytes"] = used + sum(f["bytes"] for f in item["photos"])
        assert item["total_bytes"] <= 20000000 < 25000000
        bundle["events"].append(item)
        (output / "demo_bundle.json").write_text(json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"事件 {event_index+1}/50：新增 {per_event} 張，含既有附件共 {item['total_bytes']/1000000:.2f} MB", flush=True)
    print(f"完成：{output}", flush=True)
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path,
                        default=Path(__file__).resolve().parent / "mock_camera_photos")
    parser.add_argument("--count", type=int, help="每種尺寸的張數；省略時合計 220 張")
    parser.add_argument("--max-edge", type=int, help="限制長邊供小量驗證；省略時使用原尺寸")
    parser.add_argument("--seed", type=int, default=20261021)
    parser.add_argument("--demo-snapshot", type=Path, help="50 筆 demo 的 snapshot.json，依既有容量配置照片")
    parser.add_argument("--photos-per-event", type=int, default=5)
    args = parser.parse_args()
    if args.photos_per_event < 1 or args.photos_per_event > 20:
        parser.error("--photos-per-event 須為 1～20")
    if args.demo_snapshot:
        build_demo_bundle(args.demo_snapshot, args.output, args.photos_per_event, args.seed)
        return
    if args.count is not None and args.count < 1:
        parser.error("--count 必須至少為 1")
    if args.max_edge is not None and args.max_edge < 128:
        parser.error("--max-edge 必須至少為 128")
    args.output.mkdir(parents=True, exist_ok=True)
    output = new_run_directory(args.output, f"run_{args.seed}_")
    rng = np.random.default_rng(args.seed)
    total = 0
    print(f"輸出資料夾：{output}", flush=True)
    with (output / "manifest.jsonl").open("w", encoding="utf-8") as manifest:
        for name, width, height, fmt, quality, default_count in PROFILES:
            if args.max_edge:
                ratio = min(1, args.max_edge / max(width, height))
                width, height = max(1, round(width*ratio)), max(1, round(height*ratio))
            for index in range(args.count or default_count):
                # JPEG 每十張：無 EXIF、僅時間、GPS＋方向 1～8。
                case = index % 10
                mode = "none" if case == 0 or fmt == "PNG" else "time" if case == 1 else "gps"
                orientation = case - 1 if case >= 2 and fmt == "JPEG" else 1
                image = generate_realistic_noise_image(width, height, rng)
                # PNG 每隔一張提供真正半透明像素，供透明壓縮路徑測試。
                transparent = fmt == "PNG" and index % 2 == 1
                if transparent:
                    image = image.convert("RGBA")
                    image.putalpha(128)
                if orientation in INVERSE:
                    transformed = image.transpose(INVERSE[orientation])
                    image.close()
                    image = transformed
                path = output / f"{name}_{index+1:03d}_{mode}_o{orientation}.{ 'jpg' if fmt == 'JPEG' else 'png'}"
                exif = metadata(mode, orientation)
                options = {"quality": quality, "optimize": True} if fmt == "JPEG" else {}
                if exif:
                    options["exif"] = exif
                try:
                    image.save(path, format=fmt, **options)
                finally:
                    image.close()
                # 回讀實際編碼結果，避免清單只記預期值。
                with Image.open(path) as saved:
                    saved.load()
                    actual_exif = saved.getexif()
                    assert actual_exif.get(274, 1) == orientation
                    assert bool(actual_exif) == (mode != "none")
                    if mode != "none":
                        readback = piexif.load(saved.info["exif"])
                        assert readback["Exif"][piexif.ExifIFD.DateTimeOriginal] == b"2020:06:15 14:30:00"
                        assert bool(readback["GPS"]) == (mode == "gps")
                    corrected = ImageOps.exif_transpose(saved)
                    assert corrected.size == (width, height)
                    corrected.close()
                    stored_size = saved.size
                size = path.stat().st_size
                record = dict(file=path.name, bytes=size, decimal_mb=round(size/1000000, 4),
                              stored_size=stored_size, display_size=[width, height],
                              exif=mode, orientation=orientation, transparent=transparent,
                              seed=args.seed, synthetic=True,
                              sha256=hashlib.sha256(path.read_bytes()).hexdigest())
                manifest.write(json.dumps(record, ensure_ascii=False) + "\n")
                manifest.flush()
                total += size
                print(f"{path.name}: {size/1000000:.2f} MB", flush=True)
    print(f"完成，合計 {total/1000000:.2f} MB；清單：{output / 'manifest.jsonl'}")


if __name__ == "__main__":
    main()
