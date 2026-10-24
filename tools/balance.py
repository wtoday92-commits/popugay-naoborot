"""Прогоны баланса без графики: python tools/balance.py <режим> <число забегов> [доп. флаги].
Режимы: nobot (без игрока), mid (средний игрок: рогатка и таран), full (сильный игрок со всеми исследованиями)."""
import json, subprocess, sys, statistics
from concurrent.futures import ThreadPoolExecutor

GODOT = r"C:\godot\Godot_v4.7.1-stable_win64_console.exe"
FLAGS = {"nobot": ["--nobot"], "mid": ["--nobot", "--midbot"], "full": ["--fullbot"]}


def run(extra):
    cmd = [GODOT, "--headless", "--path", ".", "--fixed-fps", "20", "--", "--sim"] + extra
    out = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=600).stdout
    for line in out.splitlines():
        if line.startswith("ДАННЫЕ "):
            return json.loads(line[7:])
    return None


def summarize(rows, title):
    rows = [r for r in rows if r]
    wins = [r for r in rows if r["boss"]]
    deaths = [r for r in rows if not r["boss"]]
    lvl_boss = [r["level"] for r in rows]
    print(f"== {title}: забегов {len(rows)}")
    print(f"попугай сломал пылесос: {len(wins)}/{len(rows)} ({100 * len(wins) // max(1, len(rows))}%)")
    if wins:
        print(f"  время победы: медиана {statistics.median([r['time'] for r in wins]):.0f} c")
    if deaths:
        print(f"  гибель: медиана {statistics.median([r['time'] for r in deaths]):.0f} c, до пылесоса {sum(1 for r in deaths if r['time'] < 240)}; у пылесоса осталось хп в среднем {100 * statistics.mean([r['boss_hp'] for r in deaths if r['time'] >= 240] or [0]):.0f}%")
    print(f"  уровень в конце: медиана {statistics.median(lvl_boss):.0f} (мин {min(lvl_boss)}, макс {max(lvl_boss)})")
    sk = {}
    for r in rows:
        for k in r["skills"]:
            sk[k] = sk.get(k, 0) + 1
    print(f"  умения: {dict(sorted(sk.items(), key=lambda x: -x[1]))}")
    taken = {}
    for r in rows:
        tot = sum(r["taken"].values()) or 1
        for k, v in r["taken"].items():
            taken[k] = taken.get(k, 0) + v / tot / len(rows)
    print("  урон по герою (доли): " + ", ".join(f"{k} {100 * v:.0f}%" for k, v in sorted(taken.items(), key=lambda x: -x[1])[:6]))
    print(f"  ивенты пройдено в среднем: {statistics.mean([r['events'] for r in rows]):.1f} из {rows[0]['events_total']}")
    return rows


if __name__ == "__main__":
    mode, n = sys.argv[1], int(sys.argv[2])
    extra = FLAGS[mode] + sys.argv[3:]
    with ThreadPoolExecutor(max_workers=8) as ex:
        rows = list(ex.map(lambda _: run(extra), range(n)))
    summarize(rows, mode)
