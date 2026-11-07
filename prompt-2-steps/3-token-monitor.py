#!/usr/bin/env python3
# ============================================================================
#  [PER] ATURAN KERAS TOKEN — JANGAN DIMODIFIKASI SIAPAPUN, TERMASUK TOMMY
# ============================================================================
# 1. Output HANYA 3 baris, urutannya TIDAK BOLEH diubah:
#       <Hari>, <DD> <Bln> <YYYY>
#       Estimasi Sisa Token Hari Ini :: <angka> juta an Token
#       Estimasi Pemakaian Token Hari Ini :: <angka> juta an token
# 2. DILARANG menampilkan saldo/nominal mata uang dalam bentuk apa pun.
# 3. DILARANG menambah baris keterangan, label, merek, atau model.
# 4. Konversi hanya internal:  1 USD = 1,6 juta token.
# 5. Kata "an" WAJIB di belakang angka, sebagai penanda estimasi.
# 6. Pemakaian hari ini = sisa token terakhir sebelumnya - sisa token sekarang.
#    Kalau angka naik (top up), pemakaian = pemakaian terakhir x 1,10.
#
# Script ini memeriksa sidik jarinya sendiri (3-token-monitor.sidik).
# Kalau isinya diubah tanpa memperbarui sidik, script MENOLAK JALAN.
# ============================================================================
import hashlib
import json
import os
import re
import sqlite3
import subprocess
import sys
from datetime import datetime, timedelta, timezone

WIB = timezone(timedelta(hours=7))
HOME = os.path.expanduser("~")
HERMES = os.path.join(HOME, ".hermes")
STATE = os.path.join(HERMES, "state", "token-monitor.json")
SIDIK = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                     "3-token-monitor.sidik")

TOKEN_PER_USD = 1_600_000        # ATURAN KERAS: 1 USD = 1,6 juta token
KURS_CNY = 7.15                  # internal saja: 1 USD ~ 7,15 CNY (tidak dicetak)
HARI = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"]
BULAN = {1: "Jan", 2: "Feb", 3: "Mar", 4: "Apr", 5: "Mei", 6: "Jun",
         7: "Jul", 8: "Agu", 9: "Sep", 10: "Okt", 11: "Nov", 12: "Des"}


# --- penjaga: script menolak jalan kalau isinya diubah ---------------------
def _sidik_utuh():
    if not os.path.exists(SIDIK):
        return True                      # mesin klien tanpa sidik: tetap jalan
    try:
        harap = open(SIDIK, encoding="utf-8").read().split()[0].lower()
        nyata = hashlib.sha256(open(__file__, "rb").read()).hexdigest()
        return harap == nyata
    except Exception:
        return True


# --- baca saldo (internal saja; TIDAK PERNAH dicetak) ----------------------
def _kunci(nama):
    if not nama:
        return None
    try:
        for line in open(os.path.join(HERMES, ".env"), encoding="utf-8",
                         errors="replace"):
            if line.startswith(nama + "="):
                return line.split("=", 1)[1].strip().strip('"').strip("'")
    except Exception:
        pass
    return os.environ.get(nama)


def _config():
    prov = base = key = None
    env_nama = None
    try:
        import yaml
        d = yaml.safe_load(open(os.path.join(HERMES, "config.yaml"),
                                encoding="utf-8")) or {}
        m = d.get("model", {}) or {}
        prov, base, key = m.get("provider"), m.get("base_url"), m.get("api_key")
        if key:
            s = str(key).strip()
            mt = re.fullmatch(r"\$\{?([A-Za-z0-9_]+)\}?", s)
            if mt:
                env_nama, key = mt.group(1), None
            elif re.fullmatch(r"[A-Z0-9_]+", s):
                env_nama, key = s, None
    except Exception:
        pass
    if not key and not env_nama:
        for cand in ("DEEPSEEK_API_KEY", "OPENROUTER_API_KEY", "XAI_API_KEY",
                     "GROQ_API_KEY", "GEMINI_API_KEY"):
            if _kunci(cand):
                env_nama = cand
                break
    if not key and env_nama:
        key = _kunci(env_nama)
    return prov, base, key


def _get(url, key):
    out = subprocess.check_output(
        ["curl", "-sS", "--max-time", "20", url, "-H", "Authorization: Bearer " + key],
        text=True, stderr=subprocess.DEVNULL)
    return json.loads(out)


def _probe(base, key):
    if not base or not key:
        return None
    akar = base.rstrip("/")
    akar = re.sub(r"/(chat/completions|completions|credits|balance)$", "", akar)
    if not akar.endswith("/v1") and "/v1/" not in akar:
        akar = akar.rstrip("/") + "/v1"
    for jalan in ("/credits", "/user/balance", "/balance", "/me"):
        try:
            d = _get(akar + jalan, key)
        except Exception:
            continue
        found = []

        def _cari(o):
            if isinstance(o, dict):
                for kk, vv in o.items():
                    if isinstance(vv, (int, float)) and re.search(
                            r"balance|credit|remain|available|quota", kk, re.I):
                        found.append(float(vv))
                    else:
                        _cari(vv)
            elif isinstance(o, list):
                for vv in o:
                    _cari(vv)
        _cari(d)
        if found:
            return max(found)
    return None


def saldo_usd():
    """Sisa saldo INTERNAL (angka mentah). Tidak pernah dicetak."""
    prov, base, key = _config()
    if (prov or "").lower() == "deepseek" or (base and "deepseek" in (base or "")):
        for k in (key, _kunci("DEEPSEEK_API_KEY")):
            if not k:
                continue
            try:
                d = _get("https://api.deepseek.com/user/balance", k)
                usd = cny = 0.0
                for b in d.get("balance_infos", []):
                    v = float(b.get("total_balance", 0) or 0)
                    if b.get("currency") == "USD":
                        usd = max(usd, v)
                    elif b.get("currency") == "CNY":
                        cny = max(cny, v)
                if usd > 0:
                    return usd
                if cny > 0:                  # saldo disimpan dalam CNY
                    return cny / KURS_CNY
            except Exception:
                pass
    if (prov or "").lower() == "openrouter" or (base and "openrouter" in (base or "")):
        for k in (key, _kunci("OPENROUTER_API_KEY")):
            if not k:
                continue
            try:
                dd = _get("https://openrouter.ai/api/v1/credits", k).get("data", {})
                sisa = float(dd.get("total_credits", 0)) - float(dd.get("total_usage", 0))
                if sisa > 0:
                    return sisa
            except Exception:
                pass
    v = _probe(base, key)
    if v:
        return v
    for url, env, nama in (
            ("https://api.deepseek.com/user/balance", "DEEPSEEK_API_KEY", "ds"),
            ("https://openrouter.ai/api/v1/credits", "OPENROUTER_API_KEY", "or")):
        k = _kunci(env)
        if not k:
            continue
        try:
            d = _get(url, k)
            if nama == "ds":
                for b in d.get("balance_infos", []):
                    if b.get("currency") == "USD":
                        return float(b.get("total_balance", 0))
            else:
                dd = d.get("data", {})
                sisa = float(dd.get("total_credits", 0)) - float(dd.get("total_usage", 0))
                if sisa > 0:
                    return sisa
        except Exception:
            pass
    return None


# --- cadangan: hitung pemakaian hari ini dari riwayat lokal ----------------
def _pemakaian_db():
    p = os.path.join(HERMES, "state.db")
    if not os.path.exists(p):
        return 0.0
    awal = datetime.now(WIB).replace(hour=0, minute=0, second=0,
                                     microsecond=0).timestamp()
    try:
        c = sqlite3.connect("file:%s?mode=ro" % p, uri=True)
        r = c.execute("""SELECT coalesce(sum(estimated_cost_usd),0)
                         FROM session_model_usage WHERE last_seen >= ?""",
                      (awal,)).fetchone()
        c.close()
        return float(r[0] or 0)
    except Exception:
        return 0.0


# --- format angka: WAJIB berakhiran "an" ----------------------------------
def _angka(n):
    """Selalu dalam juta, satu desimal, diakhiri 'an' (penanda estimasi)."""
    n = max(0.0, float(n))
    return ("%.1f" % (n / 1_000_000)).replace(".", ",") + " juta an"


def main():
    if not _sidik_utuh():
        print("ATURAN KERAS DILANGGAR: script monitor token sudah diubah. "
              "Pulihkan dari repo, jangan diedit manual.")
        return 1

    now = datetime.now(WIB)
    baris1 = "{}, {:02d} {} {}".format(HARI[now.weekday()], now.day,
                                      BULAN[now.month], now.year)

    try:
        sisa_usd = saldo_usd()
    except Exception:
        sisa_usd = None

    if sisa_usd is None:
        print(baris1)
        print("Estimasi Sisa Token Hari Ini :: tidak tersedia")
        return 0

    token_kini = sisa_usd * TOKEN_PER_USD

    try:
        lalu = json.load(open(STATE, encoding="utf-8"))
    except Exception:
        lalu = {}

    token_lalu = float(lalu.get("token", 0) or 0)
    pakai_lalu = float(lalu.get("usage", 0) or 0)

    if token_lalu > 0 and token_kini <= token_lalu:
        pakai = token_lalu - token_kini           # normal
    elif token_lalu > 0:
        pakai = pakai_lalu * 1.10                 # saldo naik = top up
    else:
        pakai = _pemakaian_db() * TOKEN_PER_USD   # belum ada catatan

    print(baris1)
    print("Estimasi Sisa Token Hari Ini :: {} Token".format(_angka(token_kini)))
    print("Estimasi Pemakaian Token Hari Ini :: {} token".format(_angka(pakai)))

    try:
        os.makedirs(os.path.dirname(STATE), exist_ok=True)
        json.dump({"ts": now.isoformat(), "token": token_kini, "usage": pakai},
                  open(STATE, "w", encoding="utf-8"))
    except Exception:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
