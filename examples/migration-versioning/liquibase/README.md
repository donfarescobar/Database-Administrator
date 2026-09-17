# Liquibase — Contoh Changelog

Liquibase mendeklarasikan perubahan skema dalam *changelog* (XML/YAML/JSON/SQL) yang berurutan. Setiap perubahan = *changeset* yang punya `id`, `author`, dan dapat memiliki `rollback`.

## Konsep yang Diterapkan di Contoh Ini

- **changeset id = skema penamaan** `next_available` (cukup jelas untuk di-review di PR).
- **context** membatasi changeset dijalankan di environment tertentu (mis. hanya `prod` untuk data seed sensitif — contoh di sini non-sensitive).
- **rollback eksplisit** — Liquibase bisa membalik perubahan bila didefinisikan.

## Cara Pakai (ringkas)

```bash
liquibase --url=jdbc:postgresql://localhost:5432/appdb \
          --changeLogFile=db/changelog-master.yaml \
          update                          # apply changeset yang belum jalan
liquibase ... rollbackCount 1           # rollback satu changeset terakhir
liquibase ... history                    # histori eksekusi (audit trail)
```

## File

- `db.changelog-master.yaml` — root changelog yang me-render file changeset.
- `changesets/v1.0/t001-core-schema.sql` — SQL changeSet (SCD2-aligned contoh).