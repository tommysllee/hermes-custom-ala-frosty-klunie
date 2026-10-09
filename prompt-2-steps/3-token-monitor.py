#!/usr/bin/env python3
# ============================================================================
#  [PER] b.6 — MONITOR ESTIMASI SISA TOKEN  (lihat bagian (B) b.6 di
#  prompt-2-steps/2-user-allOS-in-hermeschat.md)
#
#  Dipakai sebagai script cron `no_agent` (tanpa LLM): stdout dikirim apa
#  adanya ke chat. Dijadwalkan tiap 6 jam.
#
#  ATURAN KERAS b.6 — JANGAN DIUBAH SIAPA PUN:
#    1. Output WAJIB dalam ESTIMASI TOKEN.
#    2. WAJIB TIDAK dalam saldo/nominal mata uang apa pun.
#    3. JANGAN sebut nama merk/model (mis. DeepSeek, OpenAI, Anthropic...).
#    4. SATU bubble chat, satu baris, TANPA keterangan tambahan apa pun.
#    5. Bentuk: "Tanggal <tgl> <bln> <thn>, jam <HH.MM>, Estimasi Sisa Token <angka>"
#
#  Kalau butuh mengubah cara hitung: SILAKAN ubah logika internal (fungsi
#  di bawah), TAPI format & aturan output di atas TIDAK BOLEH disentuh.
# ============================================================================
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

# --- parameter estimasi (boleh disesuaikan, tapi lihat aturan b.6) ----------
HARI_RIWAYAT = 7          # pakai riwayat N hari terakhir utk kalibrasi
HARI_RIWAYAT_PANJANG = 30 # cadangan kalau N hari terlalu sedikit
MIN_TOKEN_RIWAYAT = 1000  # di bawah ini dianggap data belum cukup
# Kalibrasi HANYA memakai baris yang benar2 berbiaya (estimated_cost_usd > 0),
# supaya token GRATIS tidak mencemari rasio harga (biar estimasi nggak meledak).
# Token dihitung input+output saja (TANPA cache-read) -> estimasi sederhana
# yang konservatif dan gampang dibayangkan pemakai.

# Cadangan kalau belum ada riwayat sama sekali (perkiraan kasar, USD/1jt token).
# Dipakai HANYA untuk membagi sisa saldo -> token, tidak pernah ditampilkan.
HARGA_CADANGAN_PER_JUTA = 0.40

# Harga per 1 juta token, DIKALIBRASI dari rasio pemakaian nyata:
#   masuk 78% x $0,15 + keluar 22% x $0,60 = $0,249 per 1 juta token.
# Dipakai HANYA internal utk membagi saldo -> token; nama penyedia TIDAK
# PERNAH muncul di output (aturan b.6).
HARGA_PER_JUTA = 0.249

# Pemakaian GRATIS tetap DIHITUNG BERBIAYA memakai harga perkiraan ini
# (per 1 juta token), kira-kira setara harga model yang sama di OpenRouter —
# karena "gratis" itu tidak abadi dan tidak boleh diperlakukan $0 saat
# mengkalibrasi sisa saldo (kalau $0, estimasi meledak ngawur).
HARGA_GRATIS_PER_JUTA = 0.40

BULAN = {1: "Jan", 2: "Feb", 3: "Mar", 4: "Apr", 5: "Mei", 6: "Jun",
         7: "Jul", 8: "Agu", 9: "Sep", 10: "Okt", 11: "Nov", 12: "Des"}


# ---------------------------------------------------------------------------
# 1) Ambil saldo/kuota dari penyedia (URL & kunci dibaca otomatis)
# ---------------------------------------------------------------------------
def _kunci_dari_env(nama):
    """Baca nilai kunci dari ~/.hermes/.env berdasarkan NAMA variabel."""
    if not nama:
        return None
    p = os.path.join(HERMES, ".env")
    try:
        with open(p, encoding="utf-8", errors="replace") as f:
            for line in f:
                if line.startswith(nama + "="):
                    return line.split("=", 1)[1].strip().strip('"').strip("'")
    except Exception:
        pass
    return os.environ.get(nama)


def _baca_config():
    """Kembalikan (provider, base_url, api_key) dari config.yaml."""
    prov = base = key = None
    env_nama = None
    p = os.path.join(HERMES, "config.yaml")
    try:
        import yaml
        d = yaml.safe_load(open(p, encoding="utf-8")) or {}
        m = d.get("model", {}) or {}
        prov = m.get("provider")
        base = m.get("base_url")
        key = m.get("api_key")
        # config bisa menulis nama variabel env, dgn atau tanpa ${...}
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
        # tebak dari kunci yang ada di .env (yang didukung lebih dulu)
        for cand in ("DEEPSEEK_API_KEY", "OPENROUTER_API_KEY", "XAI_API_KEY",
                     "GROQ_API_KEY", "GEMINI_API_KEY"):
            if _kunci_dari_env(cand):
                env_nama = cand
                break
    if not key and env_nama:
        key = _kunci_dari_env(env_nama)
    return prov, base, key


def _curl(url, key):
    """GET JSON. Pesan galat ditahan supaya TIDAK mengotori stdout chat."""
    out = subprocess.check_output(
        ["curl", "-sS", "--max-time", "20", url,
         "-H", "Authorization: Bearer " + key],
        text=True, stderr=subprocess.DEVNULL)
    return json.loads(out)


def _probe_generik(base, key):
    """Coba endpoint saldo yang lazim pada penyedia kompatibel-OpenAI."""
    if not base or not key:
        return None
    akar = base.rstrip("/")
    akar = re.sub(r"/(chat/completions|completions|credits|balance)$", "", akar)
    if not akar.endswith("/v1") and "/v1/" not in akar:
        akar = akar.rstrip("/") + "/v1"
    for jalan in ("/credits", "/user/balance", "/balance", "/me"):
        try:
            d = _curl(akar + jalan, key)
        except Exception:
            continue
        ditemukan = []

        def _cari(o):
            if isinstance(o, dict):
                for kk, vv in o.items():
                    if isinstance(vv, (int, float)) and re.search(
                            r"balance|credit|remain|available|quota", kk, re.I):
                        ditemukan.append(float(vv))
                    else:
                        _cari(vv)
            elif isinstance(o, list):
                for vv in o:
                    _cari(vv)
        _cari(d)
        if ditemukan:
            return max(ditemukan)
    return None


def saldo_usd():
    """Kembalikan (nilai, mata_uang) sisa saldo.

    Urutan: penyedia yang sedang dipakai (dari config.yaml) lebih dulu, lalu
    penyedia lain yang punya kunci di .env. Mata uang hanya dipakai internal
    untuk konversi -> TIDAK PERNAH ditampilkan (aturan b.6).
    """
    prov, base, key = _baca_config()

    # 1) penyedia yang sedang aktif
    if (prov or "").lower() == "deepseek" or (base and "deepseek" in (base or "")):
        for k in (key, _kunci_dari_env("DEEPSEEK_API_KEY")):
            if not k:
                continue
            try:
                d = _curl("https://api.deepseek.com/user/balance", k)
                for b in d.get("balance_infos", []):
                    if b.get("currency") == "USD":
                        return float(b.get("total_balance", 0)), "USD"
            except Exception:
                pass
    if (prov or "").lower() == "openrouter" or (base and "openrouter" in (base or "")):
        for k in (key, _kunci_dari_env("OPENROUTER_API_KEY")):
            if not k:
                continue
            try:
                dd = _curl("https://openrouter.ai/api/v1/credits", k).get("data", {})
                sisa = float(dd.get("total_credits", 0)) - float(dd.get("total_usage", 0))
                if sisa > 0:
                    return sisa, "USD"
            except Exception:
                pass
    v = _probe_generik(base, key)
    if v:
        return v, "USD"

    # 2) cadangan: penyedia lain yang kuncinya ada
    for nm, url, env in (
        ("deepseek", "https://api.deepseek.com/user/balance", "DEEPSEEK_API_KEY"),
        ("openrouter", "https://openrouter.ai/api/v1/credits", "OPENROUTER_API_KEY"),
    ):
        k = _kunci_dari_env(env)
        if not k:
            continue
        try:
            d = _curl(url, k)
            if nm == "deepseek":
                for b in d.get("balance_infos", []):
                    if b.get("currency") == "USD":
                        return float(b.get("total_balance", 0)), "USD"
            else:
                dd = d.get("data", {})
                sisa = float(dd.get("total_credits", 0)) - float(dd.get("total_usage", 0))
                if sisa > 0:
                    return sisa, "USD"
        except Exception:
            pass

    # 3) penyedia custom lain (mis. router) — probe endpoint saldo
    try:
        import yaml
        d = yaml.safe_load(open(os.path.join(HERMES, "config.yaml"),
                                encoding="utf-8")) or {}
        for cp in (d.get("custom_providers") or []):
            v = _probe_generik(cp.get("base_url"), _kunci_dari_env(cp.get("key_env")))
            if v:
                return v, "USD"
    except Exception:
        pass

    raise RuntimeError("sumber saldo tidak terbaca")


# ---------------------------------------------------------------------------
# 2) Hitung pemakaian nyata dari state.db (kalibrasi mandiri, tanpa vendor)
# ---------------------------------------------------------------------------
def _pemakaian(sejak):
    """Kembalikan (biaya_efektif_usd, jumlah_token) dari riwayat lokal.

    Baris berbiaya memakai biaya aslinya; baris GRATIS tetap dinilai memakai
    HARGA_GRATIS_PER_JUTA (kira2 setara harga model sama di OpenRouter) —
    gratis tidak boleh diperlakukan $0, nanti estimasi meledak ngawur.
    Token dihitung input+output.
    """
    p = os.path.join(HERMES, "state.db")
    if not os.path.exists(p):
        return 0.0, 0
    try:
        c = sqlite3.connect("file:%s?mode=ro" % p, uri=True)
        rows = c.execute("""
            SELECT coalesce(estimated_cost_usd, 0),
                   coalesce(input_tokens, 0) + coalesce(output_tokens, 0)
            FROM session_model_usage
            WHERE last_seen >= ?
        """, (sejak,)).fetchall()
        c.close()
    except Exception:
        return 0.0, 0

    biaya = 0.0
    token = 0
    for b, t in rows:
        b = float(b or 0)
        t = int(t or 0)
        if b <= 0 and t > 0:
            b = t * (HARGA_GRATIS_PER_JUTA / 1_000_000)
        biaya += b
        token += t
    return biaya, token


def estimasi_token(sisa):
    """Sisa saldo -> perkiraan jumlah token yang masih bisa dipakai.

    Caranya menyesuaikan diri dengan pola pemakaian nyata mesin ini:
        sisa_token = sisa_saldo x (token_terpakai / biaya_terpakai)
    Jadi TIDAK perlu tahu merek/model atau daftar harga siapa pun.
    """
    now = datetime.now(WIB).timestamp()
    for hari in (HARI_RIWAYAT, HARI_RIWAYAT_PANJANG):
        biaya, token = _pemakaian(now - hari * 86400)
        if token >= MIN_TOKEN_RIWAYAT and biaya > 0:
            return sisa * (token / biaya)

    # Belum ada riwayat (mesin baru) -> pakai harga hasil kalibrasi
    return sisa / (HARGA_PER_JUTA / 1_000_000)


def ribuan(n):
    """14236836 -> '14.236.836' (pemisah ribuan gaya Indonesia)."""
    return "{:,.0f}".format(n).replace(",", ".")


# ---------------------------------------------------------------------------
# 3) Output — bentuk WAJIB, TIDAK BOLEH DIUBAH (aturan b.6)
# ---------------------------------------------------------------------------
def main():
    now = datetime.now(WIB)
    stempel = "Tanggal {} {} {}, jam {}.{:02d}".format(
        now.day, BULAN[now.month], now.year, now.hour, now.minute)
    try:
        sisa, _mata_uang = saldo_usd()
        token = estimasi_token(sisa)
        baris = "{}, Estimasi Sisa Token {}".format(stempel, ribuan(token))
    except Exception:
        # Gagal baca saldo -> tetap kirim stempel + penanda, tanpa mata uang
        baris = "{}, Estimasi Sisa Token tidak tersedia".format(stempel)
    print(baris)
    return 0


if __name__ == "__main__":
    sys.exit(main())
