-- ============================================================================
-- Oracle — RBAC, Least Privilege & Data Redaction (generic, no real data)
-- ============================================================================
-- Tujuan    : Menegakkan least privilege & separation of duties pada database
--             keyakinan internal (docs/04 §5 + docs/05 §2).
-- Catatan   : Contoh role/objek fiktif. Sesuaikan dengan naming convention
--             org (docs/04 §1).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Role aplikasi — minimal privilege
-- ----------------------------------------------------------------------------
CREATE ROLE app_read;      -- SELECT pada skema yang dibutuhkan
GRANT SELECT ON app.customer TO app_read;
GRANT SELECT ON app.transaction TO app_read;

CREATE ROLE app_rw;        -- DML terbatas pada tabel bisnis
GRANT SELECT, INSERT, UPDATE, DELETE ON app.customer TO app_rw;
GRANT EXECUTE ON app.pkg_customer TO app_rw;

CREATE ROLE security_auditor;   -- read-only view untuk bukti audit
GRANT SELECT ON sys.audit_unified_enabled_policies TO security_auditor;
GRANT SELECT ON unified_audit_trail TO security_auditor;

-- Developer tidak punya akses production; service account pakai role di atas.

-- ----------------------------------------------------------------------------
-- 2. User service account (app) — hanya role minimal, bukan DBA
-- ----------------------------------------------------------------------------
CREATE USER app_service IDENTIFIED BY "<vault-credential>"
    DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;
GRANT app_rw TO app_service;
REVOKE CONNECT, RESOURCE FROM app_service;      -- bila diberikan sebelumnya

-- ----------------------------------------------------------------------------
-- 3. Separation of Duties — pisahkan deploy vs data-owner (docs/04 §5)
--    - DBA ops tidak boleh memiliki akses langsung ke data business.
--    - Oracle Database Vault menegakkan pemisahan ini secara teknis.
-- ----------------------------------------------------------------------------
-- Konfigurasi Database Vault (langganan resmi admin DV):
--   BEGIN
--       DBMS_MACADM.CREATE_REALM('DATA_CUSTOMER', TRUE, 0);
--       DBMS_MACADM.ADD_OBJECT_TO_REALM('DATA_CUSTOMER','APP','CUSTOMER',NULL,
--                                       'OWNER');
--   END;
--   /   -- hanya app_service yang boleh akses langsung.

-- ----------------------------------------------------------------------------
-- 4. Pemantauan perolehan privilege (privilege analysis)
-- ----------------------------------------------------------------------------
-- Jalankan di dev/UAT utk menemukan privilege yang sebenarnya dipakai
BEGIN
   DBMS_PRIVILEGE_CAPTURE.CREATE_CAPTURE(pname      => 'cap_dev_app',
                                         type       => DBMS_PRIVILEGE_CAPTURE.G_DATABASE);
   DBMS_PRIVILEGE_CAPTURE.ENABLE_CAPTURE('cap_dev_app');
   -- jalankan workload app selama 1 minggu, lalu:
   --   DBMS_PRIVILEGE_CAPTURE.DISABLE_CAPTURE('cap_dev_app');
   --   DBMS_PRIVILEGE_CAPTURE.GENERATE_RESULT('cap_dev_app');
END;
/
-- Hasil: cek DBA_PRIV_CAPTURE / DBA_USED_PRIVS utk mencabut privilege berlebih.