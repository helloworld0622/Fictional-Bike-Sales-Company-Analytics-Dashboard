import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

import pyodbc


def get_latest_run():
    """
    Query the latest run from dbt.Run_Audit_Log.
    Returns a dict or None if no row exists.
    """
    conn_str = (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        f"SERVER={os.environ.get('DB_SERVER')};"
        f"DATABASE={os.environ.get('DB_DATABASE')};"
        f"UID={os.environ.get('DB_USER')};"
        f"PWD={os.environ.get('DB_PASSWORD')};"
        "Encrypt=yes;"
        "TrustServerCertificate=no;"
    )

    query = """
        SELECT TOP 1
            RunId,
            RunTimestamp,
            Command,
            Status,
            TestsRun,
            TestsError,
            TestsWarn
        FROM dbt.Run_Audit_Log
        ORDER BY RunTimestamp DESC;
    """

    with pyodbc.connect(conn_str) as conn:
        with conn.cursor() as cur:
            cur.execute(query)
            row = cur.fetchone()

            if row is None:
                return None

            return {
                "RunId": row.RunId,
                "RunTimestamp": row.RunTimestamp,
                "Command": row.Command,
                "Status": row.Status,
                "TestsRun": row.TestsRun,
                "TestsError": row.TestsError,
                "TestsWarn": row.TestsWarn,
            }


def build_email_body(run_info: dict) -> str:
    """
    Build a plain-text email body from run_info.
    """
    ts = run_info["RunTimestamp"]
    if isinstance(ts, datetime):
        ts_str = ts.strftime("%Y-%m-%d %H:%M:%S")
    else:
        ts_str = str(ts)

    lines = [
        "dbt Data Quality Run Summary",
        "============================",
        f"Run ID      : {run_info['RunId']}",
        f"Timestamp   : {ts_str}",
        f"Command     : {run_info['Command']}",
        f"Status      : {run_info['Status']}",
        "",
        f"Tests Run   : {run_info['TestsRun']}",
        f"Test Errors : {run_info['TestsError']}",
        f"Test Warnings: {run_info['TestsWarn']}",
        "",
        "This email was sent automatically from the AdventureWorks RFM pipeline.",
    ]
    return "\n".join(lines)


def send_email(run_info: dict):
    """
    Send an email using SMTP. Configuration is read from environment variables.
    """
    smtp_server = os.environ.get("SMTP_SERVER")
    smtp_port = int(os.environ.get("SMTP_PORT", "587"))
    smtp_user = os.environ.get("SMTP_USER")
    smtp_password = os.environ.get("SMTP_PASSWORD")
    email_from = os.environ.get("EMAIL_FROM", smtp_user)
    email_to = os.environ.get("EMAIL_TO")

    if not all([smtp_server, smtp_user, smtp_password, email_to]):
        print("Missing SMTP configuration in environment variables.")
        return

    subject_status = run_info["Status"]
    subject_errors = run_info["TestsError"]

    subject = f"[dbt DQ] Status={subject_status}, Errors={subject_errors}"

    body_text = build_email_body(run_info)

    msg = MIMEMultipart()
    msg["From"] = email_from
    msg["To"] = email_to
    msg["Subject"] = subject
    msg.attach(MIMEText(body_text, "plain"))

    with smtplib.SMTP(smtp_server, smtp_port) as server:
        server.starttls()
        server.login(smtp_user, smtp_password)
        server.send_message(msg)

    print("Email sent to", email_to)


def main():
    """
    1. Read latest run from Run_Audit_Log
    2. If there are errors, send email; otherwise do nothing (or only for WARN/FAIL).
    """
    run_info = get_latest_run()

    if run_info is None:
        print("No rows found in dbt.Run_Audit_Log, nothing to notify.")
        return

    status = (run_info["Status"] or "").upper()
    errors = int(run_info["TestsError"] or 0)
    warns = int(run_info["TestsWarn"] or 0)

    # Simple policy:
    #   - Send email if there is any error
    #   - You can also decide to send email when there are warnings
    if errors > 0 or status in ("FAIL", "ERROR"):
        print("Run has errors, sending email alert...")
        send_email(run_info)
    elif warns > 0 or status == "WARN":
        print("Run has warnings, sending email notification...")
        send_email(run_info)
    else:
        print("Run is clean (no errors / warnings). No email sent.")


if __name__ == "__main__":
    main()