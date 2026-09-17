-- ============================================================================
-- Oracle DBMS_SCHEDULER — generic, no real data
-- Tujuan   : Mendefinisikan job scheduler Oracle (backup, health check,
--            maintenance window) yang di-replikasi via Git/CI/CD.
--            Melengkapi docs/06 §4 (patching rolling) dan docs/09 SOP 1-4.
--            Skrip batch yang dijalankan: examples/performance-monitoring/
--            oracle/oracle_health_check.sql dan examples/backup-recovery/
--            oracle/rman_backup_strategy.sql .
-- Cara pakai : Jalankan sebagai user dengan privilege CREATE JOB.
-- Catatan   : credential_info / destination_name menggunakan file credential
--              yang dibuat terpisah (DBMS_CREDENTIAL.CREATE_CREDENTIAL).
-- ============================================================================

-- ============================================================
-- 0. Credential (contoh) — password tidak disimpan di script ini
-- ============================================================
-- EXEC DBMS_CREDENTIAL.CREATE_CREDENTIAL(
--     credential_name => 'OPS_HOST_CRED',
--     username        => 'opc',
--     password        => '<from secret store>',
--     database_role   => NULL
-- );

-- ============================================================
-- 1. Program: jalankan health check script via SQL*Plus
-- ============================================================
BEGIN
    DBMS_SCHEDULER.drop_program(program_name => 'DBA_PROG_HEALTHCHECK', force => TRUE);
EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN
    DBMS_SCHEDULER.create_program(
        program_name   => 'DBA_PROG_HEALTHCHECK',
        program_type   => 'PLSQL_BLOCK',
        program_action => q'[
            -- Jalankan script health check (lihat examples/performance-monitoring/oracle/oracle_health_check.sql)
            @/opt/oracle/scripts/oracle_health_check.sql
        ]',
        enabled        => TRUE,
        comments       => 'Harian: instance, tablespace, archivelog, Data Guard (docs/09 SOP 1)'
    );
END;
/

-- ============================================================
-- 2. Schedule: harian jam 06:30
-- ============================================================
BEGIN
    DBMS_SCHEDULER.drop_schedule(schedule_name => 'DAILY_0630', force => TRUE);
EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN
    DBMS_SCHEDULER.create_schedule(
        schedule_name   => 'DAILY_0630',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY;BYHOUR=6;BYMINUTE=30',
        comments        => 'Harian 06:30'
    );
END;
/

-- ============================================================
-- 3. Job: gabungkan program + schedule
-- ============================================================
BEGIN
    DBMS_SCHEDULER.drop_job(job_name => 'DBA_JOB_HEALTHCHECK', force => TRUE);
EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN
    DBMS_SCHEDULER.create_job(
        job_name        => 'DBA_JOB_HEALTHCHECK',
        program_name    => 'DBA_PROG_HEALTHCHECK',
        schedule_name   => 'DAILY_0630',
        enabled         => FALSE,                     -- enable manual setelah review
        auto_drop       => FALSE,
        job_class       => 'DEFAULT_JOB_CLASS',
        comments        => 'Health check harian'
    );
END;
/

-- ============================================================
-- 4. Window: maintenance window mingguan (untuk patching rolling,
--    index rebuild, stats gather). Docs/06 §4.
-- ============================================================
BEGIN
    DBMS_SCHEDULER.drop_window(window_name => 'WEEKEND_MAINT_WINDOW', force => TRUE);
EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN
    DBMS_SCHEDULER.create_window(
        window_name     => 'WEEKEND_MAINT_WINDOW',
        resource_plan   => 'DEFAULT_MAINTENANCE_PLAN',
        start_date      => SYSTIMESTAMP,
        duration        => INTERVAL '4' HOUR,
        repeat_interval => 'FREQ=WEEKLY;BYDAY=SAT;BYHOUR=2;BYMINUTE=0',
        enabled         => FALSE,
        comments        => 'Window maintenance Sabtu 02:00-06:00'
    );
END;
/

-- ============================================================
-- 5. Job: RMAN backup harian (di dalam maintenance window)
-- ============================================================
BEGIN
    DBMS_SCHEDULER.drop_program(program_name => 'DBA_PROG_RMAN_BACKUP', force => TRUE);
EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN
    DBMS_SCHEDULER.create_program(
        program_name   => 'DBA_PROG_RMAN_BACKUP',
        program_type   => 'PLSQL_BLOCK',
        program_action => q'[
            -- Skrip RMAN dijalankan via host command (perlu credential host)
            -- Disarankan: simpan RMAN command di file, panggil via scheduler.
            BEGIN
                DBMS_SCHEDULER.create_job(
                    job_name        => 'DBA_JOB_RMAN_INNER',
                    job_type        => 'EXECUTABLE',
                    job_action      => '/opt/oracle/scripts/rman_backup.sh',
                    enabled         => TRUE,
                    auto_drop       => FALSE
                );
            END;
        ]',
        enabled        => TRUE,
        comments       => 'Wrapper untuk RMAN backup script'
    );
END;
/

BEGIN
    DBMS_SCHEDULER.drop_schedule(schedule_name => 'DAILY_0200', force => TRUE);
EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN
    DBMS_SCHEDULER.create_schedule(
        schedule_name   => 'DAILY_0200',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY;BYHOUR=2;BYMINUTE=7',
        comments        => 'Harian 02:07 (di dalam window maintenance)'
    );
END;
/

BEGIN
    DBMS_SCHEDULER.drop_job(job_name => 'DBA_JOB_RMAN_BACKUP', force => TRUE);
EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN
    DBMS_SCHEDULER.create_job(
        job_name        => 'DBA_JOB_RMAN_BACKUP',
        program_name    => 'DBA_PROG_RMAN_BACKUP',
        schedule_name   => 'DAILY_0200',
        enabled         => FALSE,
        auto_drop       => FALSE,
        comments        => 'RMAN backup harian (docs/06 §2)'
    );
END;
/

-- ============================================================
-- 6. Verifikasi
-- ============================================================
PROMPT === Job & schedule yang baru dibuat ===
SELECT owner, job_name, enabled, program_name, schedule_name, last_start_date, next_run_date
FROM   dba_scheduler_jobs
WHERE  owner = USER
ORDER  BY job_name;
