-- ============================================================================
-- SQL Server Agent Jobs — generic, no real data
-- Tujuan   : Definisi job operasional via T-SQL (msdb) sehingga bisa
--            di-replikasi lewat Git/CI/CD. Melengkapi docs/09 SOP 1, 2, 4.
-- Cara pakai :
--   - Jalankan sekali di instance target; agent akan pickup schedule.
--   - Untuk multi-instance, parameterkan nama server/job.
-- Catatan  : job dibuat disabled by default; enable setelah review.
-- ============================================================================

USE [msdb];
GO

-- ============================================================
-- JOB 1: Daily health check
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'DBA - Daily Health Check')
BEGIN
    EXEC msdb.dbo.sp_add_job
        @job_name           = N'DBA - Daily Health Check',
        @enabled            = 0,                 -- enable manual setelah review
        @description        = N'Harian: instance, backup, disk, AG (docs/09 SOP 1)',
        @category_name      = N'Database Maintenance',
        @owner_login_name   = N'sa';

    EXEC msdb.dbo.sp_add_jobstep
        @job_name           = N'DBA - Daily Health Check',
        @step_name          = N'Run health check script',
        @subsystem          = N'TSQL',
        @command            = N'-- Path disesuaikan dengan lokasi script di server
                               :r C:\DBA\scripts\sqlserver_health_check.sql',
        @database_name      = N'master',
        @retry_attempts     = 1,
        @retry_interval     = 5;

    EXEC msdb.dbo.sp_add_jobschedule
        @job_name           = N'DBA - Daily Health Check',
        @name               = N'Daily 06:30',
        @freq_type          = 4,                 -- daily
        @freq_interval      = 1,
        @active_start_time  = 063000;            -- 06:30

    EXEC msdb.dbo.sp_attach_schedule
        @job_name           = N'DBA - Daily Health Check',
        @schedule_name      = N'Daily 06:30';

    EXEC msdb.dbo.sp_add_jobserver
        @job_name           = N'DBA - Daily Health Check',
        @server_name        = @@SERVERNAME;
END
GO

-- ============================================================
-- JOB 2: Backup harian + log every 15 min
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'DBA - Backup Full Daily')
BEGIN
    EXEC msdb.dbo.sp_add_job
        @job_name           = N'DBA - Backup Full Daily',
        @enabled            = 0,
        @description        = N'Full backup harian (docs/06 §2)',
        @category_name      = N'Database Maintenance',
        @owner_login_name   = N'sa';

    EXEC msdb.dbo.sp_add_jobstep
        @job_name           = N'DBA - Backup Full Daily',
        @step_name          = N'Full backup user DBs',
        @subsystem          = N'TSQL',
        @command            = N'-- Generate backup semua user database
DECLARE @name sysname, @sql nvarchar(max);
DECLARE c CURSOR LOCAL FOR SELECT name FROM sys.databases
                            WHERE database_id > 4 AND state = 0 AND source_database_id IS NULL;
OPEN c; FETCH NEXT FROM c INTO @name;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N''BACKUP DATABASE [''+@name+N''] TO DISK = N''''E:\Backup\''+@name+N''_''+
               CONVERT(varchar(8),GETDATE(),112)+N''.bak'''' WITH COMPRESSION, CHECKSUM, INIT;'';
    EXEC (@sql);
    FETCH NEXT FROM c INTO @name;
END
CLOSE c; DEALLOCATE c;',
        @database_name      = N'master';

    EXEC msdb.dbo.sp_add_jobschedule
        @job_name           = N'DBA - Backup Full Daily',
        @name               = N'Daily 02:00',
        @freq_type          = 4,
        @freq_interval      = 1,
        @active_start_time  = 020000;

    EXEC msdb.dbo.sp_add_jobserver
        @job_name           = N'DBA - Backup Full Daily',
        @server_name        = @@SERVERNAME;
END
GO

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'DBA - Backup Log Every 15min')
BEGIN
    EXEC msdb.dbo.sp_add_job
        @job_name           = N'DBA - Backup Log Every 15min',
        @enabled            = 0,
        @description        = N'Log backup 15 menit (PITR support, docs/06 §2)',
        @category_name      = N'Database Maintenance',
        @owner_login_name   = N'sa';

    EXEC msdb.dbo.sp_add_jobstep
        @job_name           = N'DBA - Backup Log Every 15min',
        @step_name          = N'Log backup user DBs',
        @subsystem          = N'TSQL',
        @command            = N'DECLARE @name sysname, @sql nvarchar(max);
DECLARE c CURSOR LOCAL FOR SELECT name FROM sys.databases
                            WHERE recovery_model = 1 AND database_id > 4;
OPEN c; FETCH NEXT FROM c INTO @name;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N''BACKUP LOG [''+@name+N''] TO DISK = N''''E:\Backup\''+@name+N''_log_''+
               CONVERT(varchar(20),GETDATE(),120)+N''.trn'''' WITH COMPRESSION, CHECKSUM;'';
    EXEC (@sql);
    FETCH NEXT FROM c INTO @name;
END
CLOSE c; DEALLOCATE c;',
        @database_name      = N'master';

    EXEC msdb.dbo.sp_add_jobschedule
        @job_name           = N'DBA - Backup Log Every 15min',
        @name               = N'Every 15 minutes',
        @freq_type          = 4,
        @freq_interval      = 1,
        @freq_subday_type   = 4,                 -- minutes
        @freq_subday_interval = 15;

    EXEC msdb.dbo.sp_add_jobserver
        @job_name           = N'DBA - Backup Log Every 15min',
        @server_name        = @@SERVERNAME;
END
GO

-- ============================================================
-- JOB 3: Index maintenance mingguan
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'DBA - Index Maintenance Weekly')
BEGIN
    EXEC msdb.dbo.sp_add_job
        @job_name           = N'DBA - Index Maintenance Weekly',
        @enabled            = 0,
        @description        = N'Rebuild/reorganize sesuai fragmentasi (docs/07 §6)',
        @category_name      = N'Database Maintenance',
        @owner_login_name   = N'sa';

    EXEC msdb.dbo.sp_add_jobstep
        @job_name           = N'DBA - Index Maintenance Weekly',
        @step_name          = N'Run index maintenance',
        @subsystem          = N'TSQL',
        @command            = N':r C:\DBA\scripts\sqlserver_index_maintenance.sql',
        @database_name      = N'master';

    EXEC msdb.dbo.sp_add_jobschedule
        @job_name           = N'DBA - Index Maintenance Weekly',
        @name               = N'Sunday 03:30',
        @freq_type          = 8,                 -- weekly
        @freq_interval      = 1,                 -- Sunday
        @active_start_time  = 033000;

    EXEC msdb.dbo.sp_add_jobserver
        @job_name           = N'DBA - Index Maintenance Weekly',
        @server_name        = @@SERVERNAME;
END
GO
