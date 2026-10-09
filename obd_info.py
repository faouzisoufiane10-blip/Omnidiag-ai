#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
  أداة تشخيص أعطال السيارات — Outil Diagnostic Auto 2026
  Version: 2.0  |  Encodage: UTF-8
=============================================================================
  Usage: python obd_info.py
=============================================================================
"""

import os
import re
import sys
import textwrap

# ──────────────────────────────────────────────────────────────────────────────
# COLOURS
# ──────────────────────────────────────────────────────────────────────────────
try:
    import colorama
    colorama.init(autoreset=True)
    CY   = colorama.Fore.CYAN
    GR   = colorama.Fore.GREEN
    YE   = colorama.Fore.YELLOW
    RE   = colorama.Fore.RED
    MA   = colorama.Fore.MAGENTA
    WH   = colorama.Fore.WHITE
    DIM  = colorama.Style.DIM
    BLD  = colorama.Style.BRIGHT
    RST  = colorama.Style.RESET_ALL
except ImportError:
    CY = GR = YE = RE = MA = WH = DIM = BLD = RST = ""

# ──────────────────────────────────────────────────────────────────────────────
# DATA
# ──────────────────────────────────────────────────────────────────────────────

INTRO = """\
ما هي أداة تشخيص أعطال السيارات وما هي استخداماتها؟

أداة تشخيص أعطال السيارات هي جهاز إلكتروني يتصل بوحدات التحكم الإلكترونية
(ECUs) عبر بروتوكول OBD-II الموحد (ISO 15765).

* إلزامي في أوروبا: بنزين منذ 2001 | ديزل منذ 2004
* يقرأ رموز الأعطال (DTCs)
* يراقب معايير الحساسات في الوقت الفعلي
* يُجري إعادة ضبط الصيانة وتعيير المكونات
* يُعيد برمجة وحدات التحكم (في الطرازات المتقدمة)

الأنظمة المغطاة: ABS | ESP | Airbags | Boite auto | ADAS | BMU (هجين/كهربائي)

السوق العالمي: متوقع 47 مليار دولار بحلول 2026
"""

CATEGORIES = [
    {
        "id": "1",
        "nom": "أجهزة OBD2 لاسلكية  (BT / Wi-Fi)",
        "exemples": "Vgate iCar Pro 2.0 | OBDLink MX+",
        "prix": "80 - 150 EUR",
        "ecrans": "-- (تطبيق iOS/Android)",
        "systemes": "~5 ECU (محرك فقط)",
        "vehicules": "~2 000 طراز",
        "public": "هواة / أداة ثانوية",
        "detail": (
            "أجهزة صغيرة تتصل بتطبيق على الهاتف.\n"
            "تقتصر على قراءة رموز المحرك ومعايير الحساسات القياسية.\n"
            "لا تدعم DoIP ولا SGW."
        ),
    },
    {
        "id": "2",
        "nom": "ماسحات محمولة — مبتدئون",
        "exemples": "Launch CRP129E | Autel AL629",
        "prix": "150 - 350 EUR",
        "ecrans": "3.5 بوصة",
        "systemes": "5 ECU رئيسية",
        "vehicules": "~2 000 طراز",
        "public": "مبتدئ / ورشة صغيرة",
        "detail": (
            "شاشة مدمجة 3.5 بوصة.\n"
            "بطارية داخلية تدوم 8 ساعات.\n"
            "تدعم ABS, Airbags, Engine, Transmission, SRS.\n"
            "لا تدعم DoIP ولا بروتوكولات ما بعد 2022."
        ),
    },
    {
        "id": "3",
        "nom": "أجهزة احترافية متوسطة المدى",
        "exemples": "Launch X431 V+ | Autel MK906 Pro | Bosch KTS 560",
        "prix": "450 - 1 899 EUR",
        "ecrans": "7 - 8 بوصة",
        "systemes": ">15 ECU",
        "vehicules": ">8 000 طراز",
        "public": "ورش مستقلة محترفة",
        "detail": (
            "الفئة الأكثر شيوعاً في الورش الفرنسية المستقلة.\n"
            "دعم DoIP (مركبات ما بعد 2022).\n"
            "دعم CAN FD.\n"
            "بعض الطرازات تدعم SGW Stellantis (اشتراك إضافي).\n"
            "شاشة لمس 7-8 بوصة, Wi-Fi 5G, Bluetooth 5."
        ),
    },
    {
        "id": "4",
        "nom": "منصات تشخيص متطورة",
        "exemples": "Launch X431 PAD VII | Autel MaxiSYS Ultra EV | Snap-on ZEUS+",
        "prix": "2 899 - 4 500 EUR",
        "ecrans": "10.1 - 12.3 بوصة",
        "systemes": ">20 ECU",
        "vehicules": ">20 000 طراز",
        "public": "ورش كبرى / مراكز تقنية",
        "detail": (
            "راسم إشارة مدمج (2-4 قنوات).\n"
            "وصول SGW كامل لمركبات FCA/Stellantis.\n"
            "وحدات ADAS كاملة + كاميرا حرارية.\n"
            "معالج ثماني النواة, RAM 8 GB.\n"
            "دعم Automotive Ethernet (DoIP كامل)."
        ),
    },
    {
        "id": "5",
        "nom": "أنظمة سطح العمل المعيارية",
        "exemples": "Delphi DS150E | Texa Navigator TXT Multihub",
        "prix": "4 000 - 9 000 EUR",
        "ecrans": "محطة عمل PC",
        "systemes": "Tous systemes",
        "vehicules": ">25 000 طراز",
        "public": "ورش منظمة / محطات متعددة",
        "detail": (
            "اتصال إيثرنت (Ethernet).\n"
            "دعم عن بُعد + تحديثات تلقائية عبر السحابة.\n"
            "تكامل مع برامج إدارة ورش العمل.\n"
            "مناسبة لمحطات عمل متعددة في نفس الوقت."
        ),
    },
]

DEVICES = [
    {
        "nom":          "Launch X431 V+  (2026)",
        "prix":         "1 450 EUR",
        "garantie":     "2 ans",
        "maj":          "A vie",
        "ecran":        "7\"",
        "vehicules":    "8 500+",
        "ecu":          "16",
        "doip":         "OUI",
        "sgw":          "120EUR/an",
        "oscilloscope": "NON",
        "note":         "Meilleur rapport qualite/prix — France 2026",
    },
    {
        "nom":          "Autel MK906 Pro",
        "prix":         "1 650 EUR",
        "garantie":     "2 ans",
        "maj":          "5 ans",
        "ecran":        "7\" IPS",
        "vehicules":    "7 800+",
        "ecu":          "14",
        "doip":         "OUI",
        "sgw":          "NON",
        "oscilloscope": "NON",
        "note":         "Excellent sur vehicules asiatiques (Toyota/Hyundai)",
    },
    {
        "nom":          "Bosch KTS 560",
        "prix":         "1 899 EUR",
        "garantie":     "3 ans",
        "maj":          "Cloud",
        "ecran":        "8\"",
        "vehicules":    "9 200+",
        "ecu":          "18",
        "doip":         "OUI",
        "sgw":          "Partiel",
        "oscilloscope": "NON",
        "note":         "Qualite allemande — SAV 24h/24",
    },
    {
        "nom":          "Launch X431 PAD VII",
        "prix":         "2 899 EUR",
        "garantie":     "2 ans",
        "maj":          "A vie",
        "ecran":        "10.1\"",
        "vehicules":    "20 000+",
        "ecu":          "20+",
        "doip":         "OUI",
        "sgw":          "OUI",
        "oscilloscope": "OUI 4ch",
        "note":         "Solution pro complete — grandes structures",
    },
    {
        "nom":          "Autel MaxiSYS Ultra EV",
        "prix":         "3 200 EUR",
        "garantie":     "2 ans",
        "maj":          "A vie",
        "ecran":        "12.9\"",
        "vehicules":    "20 000+",
        "ecu":          "20+",
        "doip":         "OUI",
        "sgw":          "Partiel",
        "oscilloscope": "OUI 4ch",
        "note":         "Specialise VE / Hybride",
    },
    {
        "nom":          "Snap-on ZEUS+",
        "prix":         "4 500 EUR",
        "garantie":     "3 ans",
        "maj":          "A vie",
        "ecran":        "10.5\"",
        "vehicules":    "22 000+",
        "ecu":          "20+",
        "doip":         "OUI",
        "sgw":          "OUI",
        "oscilloscope": "OUI 2ch",
        "note":         "Haut de gamme — reseau concessionnaire",
    },
]

FAKES_WARNING = """\
نسخ X431 Workshop 2026 المقلدة — لماذا يجب عليك تجنبها؟

السعر المغري: 200-400 EUR مقابل +1500 EUR للأصلية.

المشاكل التقنية:
* قواعد بيانات DTC قديمة (2020-2021) — لا تحديثات
* لا تدعم DoIP  ->  فشل مع BMW G60 / Mercedes EQE / VW ID.7
* لا وصول SGW   ->  عاجزة مع فيات/ألفا/جيب منذ 2019
* بروتوكولات CAN FD غير مدعومة

النتيجة:
الجهاز المقلد سيفشل مع أكثر من 40% من المركبات بحلول 2026.
الاستثمار في الأصلي هو القرار الاقتصادي السليم على المدى المتوسط.
"""

# ──────────────────────────────────────────────────────────────────────────────
# BOX-DRAWING ENGINE
# ──────────────────────────────────────────────────────────────────────────────

IW = 74      # inner width (between ║ borders)
_ANSI = re.compile(r"\x1b\[[0-9;]*m")


def _vis(s: str) -> int:
    """Visible (non-ANSI) length."""
    return len(_ANSI.sub("", s))


def _pad(s: str, width: int, align: str = "left") -> str:
    diff = width - _vis(s)
    if diff < 0:
        diff = 0
    if align == "center":
        lp = diff // 2
        return " " * lp + s + " " * (diff - lp)
    return s + " " * diff


def box_top():
    print(CY + "╔" + "═" * IW + "╗" + RST)

def box_sep():
    print(CY + "╠" + "═" * IW + "╣" + RST)

def box_mid():
    print(CY + "╟" + "─" * IW + "╢" + RST)

def box_bot():
    print(CY + "╚" + "═" * IW + "╝" + RST)

def box_blank():
    print(CY + "║" + " " * IW + "║" + RST)

def box_row(text: str = "", color: str = "", align: str = "left"):
    padded = _pad(text, IW, align)
    print(CY + "║" + RST + color + padded + RST + CY + "║" + RST)


# ──────────────────────────────────────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────────────────────────────────────

def clear():
    os.system("cls" if os.name == "nt" else "clear")


def header(title: str):
    clear()
    box_top()
    box_row("  " + title, color=BLD + YE, align="center")
    box_sep()
    box_blank()


def pause():
    box_blank()
    box_bot()
    print()
    input(DIM + "    ◄  اضغط Enter للرجوع...  " + RST)


def wrap_box(text: str, indent: int = 2, width: int = IW - 4):
    prefix = " " * indent
    for line in text.splitlines():
        if line.strip() == "":
            box_blank()
        else:
            for chunk in textwrap.wrap(line, width):
                box_row(prefix + chunk, color=WH)


# ──────────────────────────────────────────────────────────────────────────────
# SCREENS
# ──────────────────────────────────────────────────────────────────────────────

def show_intro():
    header("ما هي أداة OBD2 وكيف تعمل؟")
    wrap_box(INTRO)
    pause()


def show_categories():
    header("أنواع أجهزة التشخيص — 5 فئات")
    for c in CATEGORIES:
        box_mid()
        box_row("  [" + c["id"] + "]  " + c["nom"], color=BLD + YE)
        box_mid()
        pairs = [
            ("Exemple ", c["exemples"]),
            ("Prix    ", c["prix"]),
            ("Ecran   ", c["ecrans"]),
            ("Systemes", c["systemes"]),
            ("Modeles ", c["vehicules"]),
            ("Public  ", c["public"]),
        ]
        for lbl, val in pairs:
            box_row("    " + GR + lbl + RST + " : " + WH + val)
    box_blank()
    box_bot()
    print()
    sub = input(BLD + "  ► رقم الفئة للتفاصيل  (Enter للرجوع): " + RST).strip()
    for c in CATEGORIES:
        if c["id"] == sub:
            header(c["nom"])
            wrap_box(c["detail"])
            pause()
            return


def show_comparison():
    header("مقارنة أفضل 6 أجهزة — 2026")

    # (label, key, col-width)
    COLS = [
        ("Appareil",  "nom",          21),
        ("Prix",      "prix",          9),
        ("Garnt.",    "garantie",      6),
        ("MAJ",       "maj",           6),
        ("Ecran",     "ecran",         6),
        ("Modeles",   "vehicules",     7),
        ("ECU",       "ecu",           4),
        ("DoIP",      "doip",          4),
        ("SGW",       "sgw",           9),
        ("Oscillo",   "oscilloscope",  7),
    ]
    # total inner width of table = sum of (cw+2) + separators
    # fits inside IW=74 box

    def tbl_line(hc="─", cc="┼", lc="╟", rc="╢"):
        inner = (cc + hc).join(hc * (cw + 2) for _, _, cw in COLS)
        print(CY + lc + inner + rc + RST)

    def tbl_row(vals, color="", is_header=False):
        sc = CY + BLD if is_header else CY + DIM
        line = ""
        for (_, _, cw), v in zip(COLS, vals):
            v = str(v)
            if len(v) > cw:
                v = v[: cw - 1] + "."
            cell = " {:<{}} ".format(v, cw)
            line += sc + "│" + RST + color + cell + RST
        print(CY + "║" + RST + line + CY + "║" + RST)

    tbl_line("─", "┬", "╟", "╢")
    tbl_row([h for h, _, _ in COLS], color=BLD + CY, is_header=True)
    tbl_line("═", "╪", "╠", "╣")
    for d in DEVICES:
        vals = [d[k] for _, k, _ in COLS]
        tbl_row(vals, color=WH)
        box_row("  " + DIM + d["note"] + RST)
        tbl_line("─", "┼", "╟", "╢")

    box_blank()
    box_bot()
    print()
    input(DIM + "    ◄  اضغط Enter للرجوع...  " + RST)


def show_fakes():
    header("! تحذير : النسخ المقلدة X431 !")
    wrap_box(FAKES_WARNING)
    pause()


def search_device():
    header("بحث عن جهاز")
    box_bot()
    print()
    query = input(BLD + "  ► اسم الجهاز أو العلامة: " + RST).strip().lower()
    found = [d for d in DEVICES if query in d["nom"].lower()]

    clear()
    box_top()
    box_row("  نتائج البحث : « " + query + " »", color=BLD + YE, align="center")
    box_sep()

    if not found:
        box_blank()
        box_row("     لم يُعثر على نتائج.", color=RE)
        box_blank()
    else:
        labels = {
            "prix": "Prix", "garantie": "Garantie", "maj": "MAJ",
            "ecran": "Ecran", "vehicules": "Modeles", "ecu": "ECU",
            "doip": "DoIP", "sgw": "SGW", "oscilloscope": "Oscillo",
            "note": "Note",
        }
        for d in found:
            box_blank()
            box_row("  >> " + d["nom"], color=BLD + YE)
            box_mid()
            for k, v in d.items():
                if k == "nom":
                    continue
                lbl = labels.get(k, k)
                box_row("    " + GR + "{:<12}".format(lbl) + RST + ": " + WH + v)
            box_blank()

    box_bot()
    print()
    input(DIM + "    ◄  اضغط Enter للرجوع...  " + RST)


# ──────────────────────────────────────────────────────────────────────────────
# MAIN MENU
# ──────────────────────────────────────────────────────────────────────────────

MENU = [
    ("1", "مقدمة — ما هي OBD2 وكيف تعمل؟",       show_intro),
    ("2", "الأنواع الخمسة لأجهزة التشخيص",         show_categories),
    ("3", "مقارنة أفضل 6 أجهزة  (جدول كامل)",      show_comparison),
    ("4", "تحذير : النسخ المقلدة X431 Workshop",    show_fakes),
    ("5", "بحث عن جهاز بالاسم",                    search_device),
    ("0", "خروج",                                  None),
]

ICONS = {
    "1": ">  Intro",
    "2": ">  Types",
    "3": ">  Tableau",
    "4": ">  Faux",
    "5": ">  Recherche",
    "0": ">  Quitter",
}


def main():
    if os.name == "nt":
        os.system("")   # enable VT100 in old CMD

    while True:
        clear()

        # ── Header ────────────────────────────────────────────────────────
        box_top()
        box_blank()
        box_row(
            "  OBD2  --  Diagnostic Automobile  --  2026  ",
            color=BLD + CY, align="center",
        )
        box_row(
            "  Guide Complet des Outils de Diagnostic Auto  ",
            color=MA, align="center",
        )
        box_blank()
        box_sep()
        box_blank()

        # ── Menu items ────────────────────────────────────────────────────
        for key, label, _ in MENU:
            if key == "0":
                num_c = RE + BLD
                lbl_c = RE
            else:
                num_c = BLD + CY
                lbl_c = WH
            entry = (
                "    "
                + num_c + "[" + key + "]" + RST
                + "  "
                + DIM + ICONS.get(key, "") + RST
                + "  "
                + lbl_c + label + RST
            )
            box_row(entry)

        box_blank()
        box_sep()
        box_bot()
        print()
        choice = input(BLD + CY + "  ► اختيارك : " + RST).strip()

        for key, _, action in MENU:
            if choice == key:
                if action is None:
                    clear()
                    box_top()
                    box_blank()
                    box_row(
                        "  مع السلامة !   A bientot  ",
                        color=BLD + GR, align="center",
                    )
                    box_blank()
                    box_bot()
                    print()
                    sys.exit(0)
                action()
                break


if __name__ == "__main__":
    main()
