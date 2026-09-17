-- ============================================================================
-- SQL Server — RBAC & Least Privilege (generic, no real data)
-- ============================================================================
-- Tujuan    : Menegakkan least privilege + separation of duties untuk user &
--             service account (docs/04 §5 dan docs/05 §2). Contoh AppDB.
-- Prinsip   : JANGAN pernah berikan db_owner/sysadmin ke service account
--             aplikasi. Aplikasi cukup dapat DML pada skema yang relevan.
-- ============================================================================
SET NOCOUNT ON;

-- ----------------------------------------------------------------------------
-- 1. Server & database role yang baku
-- ----------------------------------------------------------------------------
-- Login service account menuju AppDB (via AD domain user / managed identity)
CREATE LOGIN [DOMAIN\svc_app_api] FROM WINDOWS;   -- app API backend
CREATE LOGIN [DOMAIN\svc_app_report] FROM WINDOWS;-- reporting app

USE AppDB;
CREATE USER [svc_app_api]    FOR LOGIN [DOMAIN\svc_app_api];
CREATE USER [svc_app_report] FOR LOGIN [DOMAIN\svc_app_report];

GO
-- ----------------------------------------------------------------------------
-- 2. Database roles minimal — bukan db_owner
-- ----------------------------------------------------------------------------
EXEC sp_addrole N'app_rw', 'owner';
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO app_rw;

EXEC sp_addrole N'app_read', 'owner';
GRANT SELECT ON SCHEMA::dbo TO app_read;

-- Gabungkan ke user
EXEC sp_addrolemember N'app_rw',  N'svc_app_api';
EXEC sp_addrolemember N'app_read', N'svc_app_report';

-- SERVICE ACCOUNT SQL Agent (jalankan job operasional) — user terisolasi
-- CREATE USER [svc_sqlagent] FOR LOGIN [DOMAIN\svc_sqlagent];
-- EXEC sp_addrolemember N'SQLAgentOperatorRole', N'svc_sqlagent';

-- ----------------------------------------------------------------------------
-- 3. Contoh kebalikan yang HARUS dihindari (anti-pattern)
-- ----------------------------------------------------------------------------
-- EXEC sp_addrolemember N'db_owner', N'svc_app_api';     -- X salah
-- EXEC sp_addrolemember N'sysadmin', N'DOMAIN\developer';-- X salah

-- ----------------------------------------------------------------------------
-- 4. Verifikasi hak yang sebenarnya dimiliki user
-- ----------------------------------------------------------------------------
-- SELECT * FROM sys.fn_my_permissions(NULL, 'DATABASE');
-- EXECUTE AS LOGIN = N'DOMAIN\svc_app_api';
--     SELECT IS_ROLEMEMBER('app_rw')   AS is_app_rw,
--            IS_SRVROLEMEMBER('sysadmin') AS is_sysadmin;   -- harus 0
-- REVERT;

-- ----------------------------------------------------------------------------
-- 5. Access review pack (untuk recertification berkala, docs/04 §5)
-- ----------------------------------------------------------------------------
-- Semua user yang masih hidup di database
SELECT dp.name AS principal, r.name AS membership
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members rm ON rm.member_principal_id = dp.principal_id
LEFT JOIN sys.database_principals r     ON r.principal_id = rm.role_principal_id
WHERE dp.type IN ('S','U','G');   -- SQL user, Windows user, group

-- Deteksi login dengan akses sysadmin
SELECT sp.name FROM sys.server_role_members srm
JOIN sys.server_principals sp ON sp.principal_id = srm.member_principal_id
WHERE srm.role_principal_id = SUSER_ID('sysadmin');

-- Deteksi login SQL Auth yang password policy-nya nonaktif
SELECT name FROM sys.sql_logins
WHERE is_policy_checked = 0 OR is_expiration_checked = 0;