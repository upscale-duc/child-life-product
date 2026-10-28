"""Copy for preparing configured Premium prices before choosing a plan."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1] / "lib/l10n"
copy = {
    "pv2LoadingPrices": ("Đang tải giá Premium…", "Loading Premium prices…", "Preparation before showing plan choices; no price is guessed."),
    "pv2PriceLoadFailedBody": ("Kiểm tra kết nối rồi thử lại.", "Check your connection and try again.", "Recovery instruction when no valid Premium display prices are available."),
    "pv2PriceLoadFailed": ("Chưa tải được giá Premium", "Couldn’t load Premium prices", "Retry state before plan choices when no recent configured price is available."),
}
for locale, index in [("vi", 0), ("en", 1)]:
    path = root / f"app_{locale}.arb"
    data = json.loads(path.read_text())
    for key, values in copy.items():
        data[key] = values[index]
        data[f"@{key}"] = {"description": values[2]}
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
