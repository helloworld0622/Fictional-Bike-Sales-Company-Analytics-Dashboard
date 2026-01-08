import subprocess
import datetime
import pyodbc

#connect to sql server
conn = pyodbc.connect(
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "SERVER=adventureworks-sqlsrv.database.windows.net,1433;"
    "DATABASE=AdventureWorks2022;"
    "UID=sqladmin;"
    "PWD=Password123!;"
    "Encrypt=yes;TrustServerCertificate=no;"
)

def log_run(run_type, status, error_count=0, warning_count=0, notes=None):
    with conn.cursor() as cur:
        cur.execute("""
            insert into dbt.Run_Audit_Log (
                RunTimestamp, RunType, Status,
                ErrorCount, WarningCount, TriggerSource, Notes
            )
            values (?, ?, ?, ?, ?, ?, ?)
        """, (
            datetime.datetime.utcnow(),
            run_type,
            status,
            error_count,
            warning_count,
            'manual',
            notes
        ))
        conn.commit()

def run_cmd(cmd):
    """运行命令并返回 (return_code, stdout+stderr 文本)"""
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )
    output_lines = []
    for line in proc.stdout:
        print(line, end="")  
        output_lines.append(line)
    proc.wait()
    return proc.returncode, "".join(output_lines)

if __name__ == "__main__":
#dbt run
    rc_run, out_run = run_cmd(["dbt", "run"])
    status_run = "success" if rc_run == 0 else "fail"
    log_run("run", status_run, error_count=0, warning_count=0,
            notes="dbt run completed with return code {}".format(rc_run))

#dbt test
    rc_test, out_test = run_cmd(["dbt", "test"])

    error_count = out_test.count("ERROR")
    warning_count = out_test.count("WARN")

    status_test = "success" if rc_test == 0 else "fail"

    log_run("test", status_test,
            error_count=error_count,
            warning_count=warning_count,
            notes="dbt test completed with rc={}, errors={}, warns={}".format(
                rc_test, error_count, warning_count
            ))