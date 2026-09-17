# Cloud & Kubernetes — Contoh Artefak

Bukti kompetensi **database di platform cloud-native** tanpa mengorbankan keamanan/data residency — melengkapi [docs/10-CLOUD-KUBERNETES.md](../../docs/10-CLOUD-KUBERNETES.md).

| Path | Platform | Isi |
|---|---|---|
| [`k8s/postgres-statefulset.yaml`](./k8s/postgres-statefulset.yaml) | Kubernetes | Postgres tanpa operator (dev/test): StatefulSet + PVC (Retain) + NetworkPolicy default-deny |

## Poin yang Ditonjolkan

- **StatefulSet + PVC**, bukan Deployment — identitas & storage pod stabil.
- **ReclaimPolicy: Retain** — volume tidak terhapus saat PVC dihapus.
- **NetworkPolicy default-deny** + akses hanya dari namespace aplikasi.
- **Anti-affinity** antar pod replica (tidak satu node fisik).
- Credential via **Secrets/External Secrets** di production (tidak di Git).

> Context: pola privat/hybrid cloud untuk regulasi perbankan — melihat docs/10 §1 & §6.
> Untuk provisioning managed DB di cloud (Azure SQL) lihat [`../automation-iac/terraform/`](../automation-iac/terraform/).