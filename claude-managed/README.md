# claude-managed

Quy tắc "cứng" cho Claude Code: **chỉ cho đọc** DB, Viindoo và `appsettings.Production.json`.

Thư mục này chỉ là **bản lưu trữ**. **Không stow / symlink**: file thật phải là bản chép, thuộc quyền root
ở `/etc/claude-code/`. Nếu symlink về `~/dotfyles`, Claude vẫn sửa được nên quy tắc mất tác dụng.

| File | Chép tới | Tác dụng |
|---|---|---|
| `managed-settings.json` | `/etc/claude-code/managed-settings.json` | rule `deny` + gắn hook, ưu tiên cao nhất, không ghi đè được |
| `guard.py` | `/etc/claude-code/hooks/guard.py` | hook PreToolUse đọc nội dung lệnh, chặn lệnh ghi |

(macOS: `/Library/Application Support/ClaudeCode/`, sửa đường dẫn hook trong `managed-settings.json` cho khớp.)

## Cài / cập nhật (Linux, WSL)

```fish
sudo install -d -o root -g root -m 755 /etc/claude-code/hooks
sudo install -o root -g root -m 644 ~/dotfyles/claude-managed/managed-settings.json /etc/claude-code/managed-settings.json
sudo install -o root -g root -m 755 ~/dotfyles/claude-managed/guard.py /etc/claude-code/hooks/guard.py
```

Khởi động lại Claude Code, gõ `/status` hoặc `/permissions` để thấy rule managed. Trước khi cập nhật, xem lại thay đổi
(`git diff`), vì Claude có thể sửa bản trong `~/dotfyles`, chỉ không sửa được bản trong `/etc`.

So bản đang chạy với bản lưu trữ: `diff -r ~/dotfyles/claude-managed /etc/claude-code` (bỏ qua README).

Gỡ: `sudo rm -r /etc/claude-code`.

## Chặn gì

- **DB**: `sqlite3` phải có `-readonly`, không `.output` / `.import` / `.backup`…; `sqlcmd`, `mysql`, `psql`… chỉ câu SELECT,
  không `-i <file>`; chặn `bcp`, `sqlpackage`, `dotnet ef database …`; không sửa file `*.db`, `*.sqlite`, `*.mdf`, `*.ldf`, `*.bak`.
- **Viindoo** (lệnh gọi mạng `curl` / `wget` / `python -c` / `node -e`… tới `sigmaworldwide`, `/web/dataset`, `call_kw`,
  `/xmlrpc`, `/jsonrpc`): chặn `write`, `create`, `unlink`, `copy`, `button_*`, `action_*`, `message_post`…; method khác danh sách
  đọc (`search_read`, `read`, `fields_get`, `search_count`…) cũng chặn. `grep` / đọc code trong repo không bị ảnh hưởng.
- **appsettings.Production.json**: đọc được (Read, `cat`, `grep`, `head`); chặn Edit / Write, `sed -i`, `>`, `tee`, `rm`, `mv`, `cp`…
- **/etc/claude-code**: không cho sửa (dù sao cũng cần sudo).
- **git push / gh pr merge**: `ask`, mỗi lần Claude chạy đều hiện hộp hỏi, phải bấm đồng ý.
- `disableBypassPermissionsMode`: không bật được chế độ bỏ qua quyền.

## Giới hạn

Hook đọc **nội dung câu lệnh**, nên không thấy bên trong file script (`python tool.py`, `dotnet run` của app tự gọi Viindoo / DB).
Chặn chắc chắn nhất vẫn là **tài khoản DB / Viindoo chỉ có quyền đọc** trên máy dev.
