import os
import smtplib
import ssl
import subprocess
from email.message import EmailMessage
from email.utils import make_msgid
from datetime import datetime, timezone
import time

# --- Configurable flags ---

USE_THREADING = os.environ.get("USE_THREADING", "TRUE").upper() == "TRUE"

MAIL_SMTP_VARIABLES = os.environ.get('MAIL_SMTP_VARIABLES', '')
MAIL_DEBUG = os.environ.get("MAIL_DEBUG", "FALSE").upper() == "TRUE"

MAIL_SUBJECT = os.environ.get('MAIL_SUBJECT', 'Vaultwarden Backup')
MAIL_FROM = os.environ.get('MAIL_FROM', 'backup@vaultwarden.com'')
MAIL_TO = os.environ.get('MAIL_TO')

now = datetime.now(timezone.utc)  
epoch = int(now.timestamp())      
formatted_date = datetime.fromtimestamp(epoch, timezone.utc).strftime('%Y%m%d')  
iso_time = now.isoformat() + "Z"

MAIL_BODY = os.environ.get('MAIL_BODY') or f"""
📦 Vaultwarden Backup Report

🕒 Timestamp (UTC):       {iso_time}
⏱️ UNIX Epoch Seconds:    {epoch}
📚 Log Entry ID:          backup-{formatted_date}
🔧 Status:                ✅ Backup completed successfully
📁 Backup Job Trigger:    CRON / automated run
🧠 Intelligence Level:    Autonomously initiated by container node

✨ End of transmission. Signing off...

""".strip()

PARENT_ID_FILE = "/app/parent_message_id.txt"
smtp_server = os.environ.get("SMTP_SERVER", "smtp.gmail.com")
smtp_port = int(os.environ.get("SMTP_PORT", "587"))
smtp_user = os.environ.get("SMTP_USER")
smtp_password = os.environ.get("SMTP_PASSWORD")

# --- Modern threaded SMTP mail ---
def send_mail_smtp():
    # Threading: first-time or continuing thread?
    if USE_THREADING:
        if not os.path.exists(PARENT_ID_FILE):
            parent_msgid = make_msgid(domain="vaultwarden.com")
            with open(PARENT_ID_FILE, "w") as f:
                f.write(parent_msgid)
        else:
            with open(PARENT_ID_FILE, "r") as f:
                parent_msgid = f.read().strip()
    else:
        parent_msgid = None

    current_msgid = make_msgid(domain="vaultwarden.com")

    msg = EmailMessage()
    msg['Subject'] = MAIL_SUBJECT
    msg['From'] = MAIL_FROM
    msg['To'] = MAIL_TO
    msg['Message-ID'] = current_msgid
    msg.set_content(MAIL_BODY)

    if USE_THREADING and parent_msgid:
        msg['In-Reply-To'] = parent_msgid
        msg['References'] = parent_msgid

    if MAIL_DEBUG:
        print("Message headers:\n", msg)

    context = ssl.create_default_context()
    try:
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls(context=context)
            server.login(smtp_user, smtp_password)
            server.send_message(msg)
        print("\033[94m[INFO] Email sent with Message-ID:", current_msgid, "\033[0m")
    except Exception as e:
        print("\033[91m[ERROR] Failed to send email:", e, "\033[0m")

# --- Entrypoint ---
if __name__ == "__main__":
    send_mail_smtp()
