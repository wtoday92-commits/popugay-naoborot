"""Прогресс за серию забегов: python tools/progression.py <забегов> [серий]. Попугай учится и качается,
игрок (средний бот) открывает исследования за перья. Пишет таблицу по забегам."""
import json, subprocess, sys, os
from concurrent.futures import ThreadPoolExecutor

GODOT = r"C:\godot\Godot_v4.7.1-stable_win64_console.exe"
SAVE_DIR = os.path.expandvars(r"%APPDATA%\Godot\app_userdata\Попугай наоборот")


def series(idx, n):
    name = f"prog_{idx}.json"
    path = os.path.join(SAVE_DIR, name)
    if os.path.exists(path):
        os.remove(path)
    rows = []
    for i in range(n):
        cmd = [GODOT, "--headless", "--path", ".", "--fixed-fps", "20", "--", "--sim", "--learn", "--prog", "--save=" + name]
        out = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=600).stdout
        for line in out.splitlines():
            if line.startswith("ДАННЫЕ "):
                rows.append(json.loads(line[7:]))
    return rows


if __name__ == "__main__":
    n = int(sys.argv[1])
    k = int(sys.argv[2]) if len(sys.argv) > 2 else 4
    with ThreadPoolExecutor(max_workers=k) as ex:
        all_series = list(ex.map(lambda i: series(i, n), range(k)))
    print(f"Серий: {k}, забегов в серии: {n}")
    print("забег | побед попугая | ур. в конце | открыто у игрока | прокачка попугая (сумма ур.) | разные умения-планы")
    for i in range(n):
        rs = [s[i] for s in all_series if len(s) > i]
        wins = sum(1 for r in rs if r["boss"])
        lvl = sum(r["level"] for r in rs) / len(rs)
        unl = sum(len(r["unlocked"]) for r in rs) / len(rs)
        up = sum(sum(r["up"].values()) for r in rs) / len(rs)
        plans = sorted(set(p for r in rs for p in r["plan"]))
        print(f"{i + 1:5d} | {wins}/{len(rs)} | {lvl:.1f} | {unl:.1f}/10 | {up:.1f} | {', '.join(plans)}")
    skills = {}
    for s in all_series:
        for r in s:
            for sk in r["skills"]:
                skills[sk] = skills.get(sk, 0) + 1
    tot = sum(skills.values())
    for i, s in enumerate(all_series):
        print(f"серия {i + 1}: планы " + " ".join(r["plan"][0][:4] if r["plan"] else "-" for r in s))
    print("Доля умений за все забеги: " + ", ".join(f"{k} {100 * v // tot}%" for k, v in sorted(skills.items(), key=lambda x: -x[1])))
