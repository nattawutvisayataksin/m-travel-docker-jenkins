# 🐳 M-Travel — Docker Edition

Repo นี้คือ M-Travel ที่เตรียมไว้สำหรับ **รันบน Docker Desktop บนเครื่อง Local** และ **Deploy ผ่าน Jenkins ใน Private Cloud** ด้วยวิธีง่าย ๆ

เว็บเป็น static ล้วน (nginx) และยังเชื่อม *Supabase Cloud* เหมือนเดิมตาม `assets/js/config.js` — **ไม่ต้องรันฐานข้อมูลใน Docker**

## 🚀 รันบนเครื่อง (Docker Desktop)

1. เปิด Docker Desktop แล้วรอจนกว่า status เป็น Running
2. เปิด Terminal ที่ folder นี้ แล้วสั่ง:

```bash
docker compose up -d --build
```

3. เปิดเว็บได้ที่ **http://localhost:8080** 🎉

คำสั่งที่ใช้บ่อย:

```bash
docker compose down              # หยุด/ลบคอนเทนเนอร์
docker compose logs -f web       # ดู log
docker compose up -d --build     # แก้โค้ดแล้วรันใหม่
```

### อยากเปลี่ยนพอร์ท?

```bash
copy .env.example .env           # (Windows) หรือ cp .env.example .env
# แก้ PORT=8080 ในไฟล์ .env เป็นพอร์ทที่ต้องการ
docker compose up -d
```

## 📁 ไฟล์ที่เพิ่มจาก repo เดิม

| ไฟล์ | หน้าที่ |
|---|---|
| `Dockerfile` | สร้าง image (nginx:alpine + ไฟล์เว็บทั้งหมด) |
| `docker-compose.yml` | ประกาศ service `web` + mapping พอร์ท |
| `deploy/nginx/default.conf` | ค่า nginx (gzip + cache + routing ปกติ) |
| `.env.example` | ตัวแปร PORT / ชื่อ image — copy เป็น `.env` ได้ |
| `.dockerignore` | ตัดไฟล์ที่ไม่จำเป็นออกจาก build context |
| `Jenkinsfile` | Pipeline สำหรับ Deploy ผ่าน Jenkins |

## 🏗️ Deploy ผ่าน Jenkins (Private Cloud)

**สิ่งที่ Jenkins agent ต้องมี:**
- Docker Engine + docker compose (v2) ติดตั้งแล้ว
- (สำหรับ smoke test) `curl` — Linux agent มีโดย default อยู่แล้ว

**สร้าง Job:**
1. Jenkins → **New Item** → เลือก **Pipeline** (หรือ Multibranch Pipeline ก็ได้)
2. ในช่อง **Pipeline → Definition** เลือก *Pipeline script from SCM*
3. **SCM:** Git → Repo URL ของ repo นี้
   `https://github.com/nattawutvisayataksin/m-travel-docker-jenkins.git`
4. **Script Path:** `Jenkinsfile` → Save → **Build Now**

Pipeline จะทำ 3 stage:
`Build image` → `Deploy (docker compose up -d)` → `Smoke test (curl หน้าแรก)`

> ถ้า agent เป็น Windows ให้เปลี่ยนคำสั่ง `sh` เป็น `bat` ใน `Jenkinsfile`

### อยาก deploy หลายเครื่อง/หลายพอร์ท?

แก้ `APP_PORT` / `APP_NAME` ใน `Jenkinsfile` หรือเก็บเป็น Environment Variables ของ Jenkins ได้เลย ไม่ต้องแก้โค้ดเว็บ

---

โครงสร้างระบบเดิม + วิธีใช้เว็บ (เพิ่ม/แก้ทริป, Backup ฯลฯ) ดูได้ที่ [README.md](README.md)
