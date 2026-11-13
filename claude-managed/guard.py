#!/usr/bin/env python3
# Hook PreToolUse cho Claude Code (managed settings, file của root ở /etc/claude-code/hooks/guard.py).
# Chặn GHI vào DB, Viindoo và appsettings.Production.json; ĐỌC vẫn cho phép.
# Thoát mã 2 = chặn lệnh, nội dung stderr gửi lại cho Claude. Lỗi đọc input thì cho qua (không làm hỏng Claude Code).
# Đây là lớp chặn theo nội dung lệnh (heuristic): lệnh chạy file script riêng thì hook không thấy được bên trong.
# Chặn chắc chắn nhất vẫn là tài khoản DB / Viindoo chỉ có quyền đọc.
import json
import os
import re
import sys


def block(reason):
    print("[managed guard] Bị chặn: " + reason, file=sys.stderr)
    sys.exit(2)


try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

tool = data.get("tool_name", "")
inp = data.get("tool_input") or {}

# ---------- Sửa / ghi file bằng công cụ Edit, Write... ----------
DB_FILE = re.compile(r"\.(db|sqlite|sqlite3|mdf|ldf|bak)(-wal|-shm|-journal)?$|\.db\.bak-", re.I)

if tool in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
    path = inp.get("file_path") or inp.get("notebook_path") or ""
    name = os.path.basename(path).lower()
    if name == "appsettings.production.json":
        block("appsettings.Production.json chỉ được đọc, không được sửa.")
    if DB_FILE.search(name):
        block("file DB chỉ được đọc, không được sửa: " + path)
    if os.path.abspath(path).startswith("/etc/claude-code"):
        block("không được sửa cấu hình /etc/claude-code.")
    sys.exit(0)

if tool != "Bash":
    sys.exit(0)

cmd = inp.get("command") or ""
low = cmd.lower()

# ---------- DB ----------
SQL_WRITE = re.compile(
    r"\b(insert|update|delete|merge|drop|alter|create|truncate|replace|exec|execute|grant|revoke|deny|"
    r"backup|restore|attach|detach|vacuum|reindex|into)\b|\bsp_\w+|\bxp_\w+", re.I)

# sqlite3: chỉ cho chạy với -readonly (sqlite tự từ chối mọi lệnh ghi)
if re.search(r"(^|[\s;&|(/])sqlite3(\s|$)", low):
    if "-readonly" not in low:
        block("sqlite3 chỉ được chạy với -readonly (chỉ đọc).")
    if re.search(r"\.(import|restore|save|backup|clone|output|once)\b", low):
        block("lệnh sqlite3 ghi file không được phép.")

# SQL Server và các CLI khác: chỉ cho câu SELECT, không chạy file script (-i)
if re.search(r"(^|[\s;&|(/])(sqlcmd|mssql-cli|usql|isql|osql|mysql|psql|bcp|sqlpackage|invoke-sqlcmd)(\s|$)", low):
    if re.search(r"(^|\s)-i(\s|$)", low) or re.search(r"\b(bcp|sqlpackage)\b", low):
        block("không được chạy script SQL / bcp / sqlpackage.")
    if SQL_WRITE.search(cmd):
        block("chỉ được chạy câu SELECT trên DB.")

# EF Core: không đụng DB thật
if re.search(r"dotnet[- ]ef\s+database\b", low) or re.search(r"dotnet-ef\s+database\b", low):
    block("dotnet ef database ... ghi vào DB, không được phép.")

# ---------- Viindoo (Odoo JSON-RPC / XML-RPC) ----------
# Chỉ xét lệnh gọi mạng / chạy code tại chỗ có địa chỉ Viindoo hoặc RPC Odoo (grep / đọc code trong repo không bị chặn)
VIINDOO_TARGET = re.compile(r"sigmaworldwide|/web/dataset|/web/session|call_kw|execute_kw|/xmlrpc|/jsonrpc", re.I)
NETWORK = re.compile(r"(^|[\s;&|(/])(curl|wget|http|https|xh|httpie|python3?\s+-c|node\s+-e|dotnet\s+fsi|pwsh|powershell)(\s|$)", re.I)

ODOO_READ = {"search_read", "read", "fields_get", "search_count", "search", "name_search", "name_get",
             "read_group", "default_get", "check_access_rights", "authenticate", "login", "version",
             "get_views", "load_views", "web_search_read", "web_read"}
ODOO_WRITE = re.compile(
    r"[\"'/](write|create|unlink|copy|name_create|toggle_active|action_archive|action_unarchive|"
    r"message_post|button_\w+|action_\w+|_action_\w+|do_unreserve|process)(?:[\"'/?\s]|$)", re.I)

if NETWORK.search(cmd) and VIINDOO_TARGET.search(cmd):
    if ODOO_WRITE.search(cmd):
        block("Viindoo chỉ được đọc (search_read / read / fields_get), không được write / create / button_...")
    # mọi tên method ghi rõ ra mà không nằm trong danh sách đọc cũng chặn
    for m in re.findall(r"[\"']method[\"']\s*:\s*[\"'](\w+)[\"']", cmd):
        if m.lower() not in ODOO_READ and m.lower() not in ("call", "call_kw", "execute_kw"):
            block("method Viindoo '" + m + "' không nằm trong danh sách chỉ đọc.")

# ---------- appsettings.Production.json ----------
if "appsettings.production" in low:
    if re.search(r">>?\s*[\"']?[^\s\"']*appsettings\.production", low):
        block("không được ghi đè appsettings.Production.json (chỉ đọc).")
    if re.search(r"(^|[\s;&|(])(sed\s+[^|;&]*-i|perl\s+[^|;&]*-i|tee|rm|mv|cp|truncate|dd|ln|chmod|chown|install|rsync|"
                 r"python3?|node|dotnet\s+user-secrets)(\s|$)", low):
        block("appsettings.Production.json chỉ được đọc (cat / grep / head / less).")

# ---------- Bảo vệ chính cấu hình này ----------
if "/etc/claude-code" in low and (
        re.search(r"(^|[\s;&|(])(sudo|rm|mv|cp|tee|chmod|chown|ln|install|truncate)(\s|$)|sed\s+[^|;&]*-i", low)
        or re.search(r">>?\s*[\"']?/etc/claude-code", low)):
    block("không được sửa /etc/claude-code.")

sys.exit(0)
