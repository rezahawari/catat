# Catat — Aplikasi Manajemen Keuangan Personal & Bisnis

Catat adalah aplikasi pencatatan dan pengelolaan keuangan modern untuk kebutuhan personal dan bisnis UMKM/freelancer dalam satu ekosistem terpadu.

---

## 📱 Arsitektur & Tech Stack

```
finflow/
├── docker-compose.yml          # PostgreSQL & Backend API container
├── apps/
│   ├── backend/                # Go (Golang) + Fiber REST API
│   │   ├── cmd/api/main.go     # Server entry point
│   │   ├── internal/           # Auth, Spaces, Accounts, Categories, Transactions, Invoices, Debts, Reports
│   │   ├── db/migrations/      # PostgreSQL Schema Migrations
│   │   └── Dockerfile          # Multi-stage optimized Docker build
│   └── mobile/                 # Flutter Application (Android & iOS ready)
│       ├── lib/
│       │   ├── core/theme/     # Design Tokens (AppColors, AppTypography Plus Jakarta Sans)
│       │   ├── core/network/   # Dio Client with automatic JWT silent refresh
│       │   ├── core/local_db/  # Drift SQLite offline-first database
│       │   ├── features/       # Modular feature slices (Dashboard, Transactions, Invoices, Debts, Reports)
│       │   └── shared/widgets/ # Reusable GlassCard, QuickActionButton, AmountKeypadSheet
│       └── pubspec.yaml
```

---

## 🚀 Panduan Menjalankan

### 1. Backend Service (Go + PostgreSQL)

Menggunakan Docker Compose:
```bash
# Menjalankan PostgreSQL & Backend API
docker compose up -d

# Cek status kesehatan backend
curl http://localhost:8080/health
```

Atau menjalankan lokal secara manual:
```bash
cd apps/backend
go run cmd/api/main.go
```

### 2. Mobile App (Flutter)

```bash
cd apps/mobile

# Mengunduh dependensi
flutter pub get

# Menjalankan di emulator / perangkat fisik
flutter run
```

---

## 🎨 Karakteristik Desain (Modern & Elegan)
- **Palette**: Deep Teal (`#0F5C55`) sebagai warna aksen utama, didukung Warm Amber (`#B8860B`) untuk Ruang Bisnis, serta Terracotta (`#B3543F`) untuk Pengeluaran.
- **Typography**: Google Fonts **Plus Jakarta Sans** dengan hierarki angka nominal yang besar dan jelas.
- **Micro-Interactions**: Bottom sheet keypad numerik cepat (<30 detik untuk mencatat transaksi baru), Glassmorphism borders tanpa shadow tebal.
- **Dual Space Mode**: Switcher instan antara *Ruang Personal* dan *Ruang Bisnis*.
