# 📓 สรุปผลงานและคู่มือ — M-Travel Docker Edition

> โปรเจกต์: `m-travel-docker-jenkins` · อัปเดต: 26 ต.ค. 2026 (รอบ 2 — cert/Vault/AWX ดู Section 8)
> ไฟล์นี้รวม: สรุปผลงาน, สถาปัตยกรรม, โครงสร้างไฟล์, คู่มือคำสั่ง Docker, และแผน step ถัดไป (Jenkins)

---

## 1) สรุปสั้นสุด

| หัวข้อ | สิ่งที่ควรรู้ |
|---|---|
| ระบบเดิม M-Travel | เว็บ static ทำจาก HTML / CSS / JavaScript ใช้ข้อมูลจาก Supabase Cloud ผ่าน `assets/js/config.js` — ไม่ต้อง build |
| สิ่งที่ทำในโปรเจกต์นี้ | Clone ระบบมาเป็น repo แยก + เพิ่มไฟล์ Docker + ทดลองรันบน Docker Desktop แล้วผ่านทั้งหมด |
| สถานะปัจจุบัน | เว็บกำลังรันอยู่ที่ `http://localhost:8080` ผ่าน container `m-travel-web` |
| สิ่งที่พร้อมใช้ต่อ | Jenkinsfile ถูกเตรียมไว้แล้ว เพื่อนำไปตั้ง Job ใน Jenkins ในอนาคต |
| git | commit `42d2776` push ขึ้น GitHub repo `m-travel-docker-jenkins` เรียบร้อย |

### ทางเลือกที่ตัดสินใจไปแล้ว (กันลืม: ตัวเลือกที่ถามผู้ใช้ตอนเริ่ม)

- เชื่อม **Supabase Cloud** แบบเดิม (ไม่รันฐานข้อมูลใน Docker) ← เหตุผล: ง่ายที่สุด สภาพแวดล้อมเหมือน production
- ทำ **Jenkinsfile** ให้ทันที ← เหตุผล: ให้เข้าใจระบบไว้ก่อน จะไปทำต่อทีเดียวได้สบาย
- ชื่อ folder คือ **m-travel-docker-jenkins** ← ชัดเจนว่าแยกจาก repo เดิม

---

## 2) สถาปัตยกรรม

### ภาพรวมระบบ

```
┌───────────────── เครื่องที่ติดตั้ง Docker Desktop ─────────────────┐
│                                                                   │
│   Browser                                                         │
│      │    http://localhost:8080                                   │
│      ▼                                                            │
│   ┌────────────────────┐                                          │
│   │ Container          │    ไฟล์เว็บถูก copy ลง image ตอน build       │
│   │ m-travel-web       │                                          │
│   │ nginx port 80      │──► /usr/share/nginx/html                 │
│   └────────────────────┘       ├─ index.html trip.html about.html admin.html │
│        ▲      ▲                └─ assets/ (css js img)            │
│        │      │      แมพพอร์ทของ Docker: 8080 → 80                │
│   docker compose                                                 │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
                    │   JavaScript ของเว็บ (ที่รันใน browser) ยิงคำขอไปที่...
                    ▼
     ┌────────────────────────────────────┐
     │  Supabase Cloud  (นอก container)   │
     │  • Postgres: ตาราง trips, settings │
     │  • Auth: บัญชีผู้ดูแลระบบ            │
     │  • Storage: เก็บรูปทริป              │
     └────────────────────────────────────┘
```

### ประเด็นสำคัญ 3 ข้อ (จำไว้ใช้ตอนอ่านโค้ด)

1. **มี container เดียว** ทำหน้าที่เสิร์ฟไฟล์ static เท่านั้น — ไม่มี Database หรือ backend function ใน container
2. **ข้อมูลทริป / รูปอยู่กับ Supabase ทั้งหมด** → สั่ง `docker compose down` หรือลบ container กี่ครั้ง ข้อมูลจริงจะไม่หาย
3. **โค้ดถูก copy ลง image ตอน build** → แก้โค้ดแล้วต้องรัน `docker compose up -d --build` ใหม่ ถึงจะเห็นผล

---

## 3) โครงสร้างไฟล์ (tree ของ repo นี้)

```
m-travel-docker-jenkins/
├── index.html                ← หน้าแรก (โค้ดเดิม ไม่แก้)
├── trip.html                 ← หน้ารายละเอียดทริป
├── about.html                ← หน้าเกี่ยวกับฉัน
├── admin.html                ← หน้าผู้ดูแล (ล็อกอิน / จัดการทริป)
├── supabase-schema.sql       ← สคริปต์สร้างตารางใน Supabase
├── README.md                 ← คู่มือระบบเว็บต้นฉบับ (จาก repo เดิม)
│
├── assets/
│   ├── css/style.css         ← ธีมเว็บทั้งหมด
│   └── js/
│       ├── config.js         ⚠️ ใส่ URL + key ของ Supabase (มีค่าแล้ว)
│       ├── demo-data.js      ← (โหมดตัวอย่าง) ใช้ตอนยังไม่เชื่อม Supabase
│       └── app.js index.js trip.js about.js admin.js
│
├── ──── ส่วนที่เพิ่มในโปรเจกต์นี้ ────
│
├── Dockerfile                ← สร้าง image (nginx + ไฟล์เว็บ)
├── docker-compose.yml        ← ประกาศ service + mapping พอร์ท
├── .env.example              ← ตัวแปรตั้งต้น (copy เป็น .env เมื่อต้องการแก้)
├── .dockerignore             ← ตัดไฟล์ไม่จำเป็นออกจาก build context
├── .gitignore                ← กันไฟล์ .env หลุดขึ้น Git
├── deploy/
│   └── nginx/default.conf    ← ค่าตั้ง nginx (gzip + cache + routing)
├── Jenkinsfile               ← Pipeline สำหรับ Jenkins (step ถัดไป)
├── README-DOCKER.md          ← คู่มือย่อ (รัน local + ตั้ง Jenkins)
└── PROJECT-SUMMARY.md        ← (ไฟล์นี้)
```

### บทบาทของไฟล์ชุด Docker แบบเจาะลึกนิด ๆ

| ไฟล์ | บทบาท |
|---|---|
| `Dockerfile` | เริ่มจาก `nginx:1.27-alpine` แล้ว copy 2 ชิ้น: `deploy/nginx/default.conf` ไปแทน config เดิมของ nginx และไฟล์เว็บทั้งหมด (HTML + `assets/`) ลง `/usr/share/nginx/html` |
| `docker-compose.yml` | service `web`: build จาก folder นี้, image `m-travel:local`, mapping พอร์ต 8080 → 80 (ปรับที่ `PORT`), restart `unless-stopped` |
| `deploy/nginx/default.conf` | เปิด gzip; ไฟล์ static (css/js/รูป/ฟอนต์) cache 7 วัน; routing ปกติ `try_files $uri $uri/ =404` |
| `.dockerignore` | ไม่ให้ `.git`, README, sql ฯลฯ เข้า build context → build เร็ว + image สะอาด |
| `.env.example` | `PORT=8080`, `IMAGE_NAME=m-travel`, `IMAGE_TAG=local` |
| `Jenkinsfile` | Pipeline 3 stage: **Build image → Deploy → Smoke test** (ดู section 6) |

### ความสัมพันธ์กับ repo อื่น

| Repo | หน้าที่ในระบบนี้ | ทางเข้า |
|---|---|---|
| `m-travel` (repo เดิม) | ระบบเว็บต้นฉบับ / เปิดแบบ serverless ปกติ | github.com/nattawutvisayataksin/m-travel |
| `m-travel-docker-jenkins` (repo นี้) | ตัวนี้จะเอาไว้ทำ Docker image และ deploy ผ่าน Jenkins | github.com/nattawutvisayataksin/m-travel-docker-jenkins |

> 🧵 เผื่อต้องการอัปเดตโค้ดจาก repo เดิมมาที่ repo นี้ ทำได้ด้วย:
> ```bash
> git remote add m-travel https://github.com/nattawutvisayataksin/m-travel.git
> git fetch m-travel
> git merge m-travel/main
> ```

---

## 4) งานที่ทำแล้ว → ผลตามจริง

ลำดับงานที่ทำไปแล้ว:

| ขั้น | สิ่งที่ทำ | ผลลัพธ์ |
|---|---|---|
| 1 | สำรวจระบบเดิม (`README.md`, config.js) | ยืนยันว่าเป็น static + Supabase Cloud ตั้งค่าไว้แล้ว |
| 2 | ถามผู้ใช้ 3 ข้อ (Cloud Supabase / Jenkinsfile / ชื่อ folder) | ได้คำตอบครบทั้ง 3 ข้อ: **cloud ✅ ทำเลย ✅ m-travel-docker-jenkins ✅** |
| 3 | `git clone` repo เดิม → folder ใหม่ + ตั้ง `origin` ใหม่ | สำเร็จ |
| 4 | เขียนไฟล์ชุด Docker 7 ไฟล์ + README ต่อมา | สำเร็จ |
| 5 | `docker compose up -d --build` | Build สำเร็จ · image `m-travel:local` (73.9 MB) · container `m-travel-web` **Up** |
| 6 | ทดสอบด้วย `curl.exe` | `/` → 200 · `/assets/css/style.css` → 200 · `/trip.html?p=kyoto` → 200 · `/admin.html` → 200 |
| 7 | `git add -A` commit `42d2776` → `git push -u origin main` | Push สำเร็จ (`* [new branch] main -> main`) |

> 💡 ข้อสังเกตเพิ่มเติม: `exit code 1` จาก `git push` บน PowerShell เป็นเพียง PowerShell ตีความข้อความ progress ของ git ผิด — ผลจริง push สำเร็จ

---

## 5) 🐳 คู่มือคำสั่ง Docker / Compose (แล้วใช้จริงได้ทุกวัน)

> ⚠️ คำสั่งต้องรันจาก **folder โปรเจกต์นี้** (ที่มี `docker-compose.yml`)
> ⚠️ บน PowerShell (Windows) ต้องระบุคำสั่งเป็น `curl.exe` (ไม่ใช่ `curl` เพราะ `curl` ใน PowerShell เป็น alias ของ Invoke-WebRequest)

### คำสั่งประจำวัน

```bash
docker compose up -d --build     # 🟢 หลังแก้โค้ด: สร้าง image ใหม่ + รัน container
docker compose ps                # 👀 ดูสถานะ container ของโปรเจกต์นี้
docker compose logs -f web       # 📄 ดู log แบบติดตามสด จาก nginx (Ctrl+C ออก)
docker compose down              # 🛑 หยุด + ลบ container กับ network (image ยังคงอยู่)
docker compose restart           # 🔄 รีสตาร์ท container เดิมอีกครั้ง
```

### คำสั่งเปลี่ยนพอร์ท / ชื่อ image

```bash
copy .env.example .env           # (Windows) สร้าง .env ในเครื่อง — Linux ใช้: cp .env.example .env
notepad .env                     # แก้ค่า PORT= / IMAGE_NAME= / IMAGE_TAG=
docker compose up -d             # ใช้ค่าใหม่ (ไม่ต้อง --build ถ้าโค้ดเดิม)
```

### คำสั่ง troubleshoot

```bash
docker compose down && docker compose up -d --build  # เริ่มใหม่ทั้งวง ใช้แก้ปัญหาบ่อย ๆ
docker exec -it m-travel-web sh                      # เข้าไปใน nginx container
docker inspect m-travel-web                          # ดูรายละเอียด container ละเอียดสุด
docker images m-travel                               # ดูรายการ image ในเครื่อง
docker image prune -f                                # ลบ image ขยะ (dangling)
docker system prune -f                               # ⚠️ ลบทุกอย่างที่ไม่ได้ใช้ — ใช้เมื่อจำเป็นจริงเท่านั้น
docker stats                                         # ดู RAM / CPU ของ container
```

### อาการที่เจอบ่อย → วิธีแก้

| อาการ | วิธีแก้ |
|---|---|
| `port is already allocated` | เปลี่ยนค่า `PORT` ใน `.env` → หรือปิดตัวเก่า (`docker compose down`) |
| แก้โค้ดแล้วหน้าเว็บไม่เปลี่ยน | ต้อง `docker compose up -d --build` (โค้ดถูกฝังตอน build) |
| เข้า admin ล็อกอินไม่ได้ / บันทึกไม่ได้ | เป็นเรื่องฝั่ง Supabase (ไม่เกี่ยว Docker) → อีเมลที่ใช้ต้องอยู่ตาราง `admins` |
| build หรือ pull image ไม่ได้ | ส่วนใหญ่เป็น network / Docker Hub มีปัญหาชั่วคราว → `docker pull nginx:1.27-alpine` ทดลองซ้ำ |

---

## 6) ⏳ ขั้นตอนถัดไป — Deploy ผ่าน Jenkins (เมื่อกลับมาทำต่อ)

### Jenkins จะทำอะไรให้เรา (จาก `Jenkinsfile` ที่เตรียมไว้แล้ว)

```
Build image ────► Deploy ────► Smoke test
docker compose     docker compose      curl http://localhost:8080
build              up -d --no-build    ต้องได้ HTTP 200 ถึงจะผ่าน
```

ค่า environment ปรับได้ใน Jenkinsfile เช่น:

```groovy
environment {
    APP_NAME = 'm-travel'
    APP_PORT = '8080'   // พอร์ทที่ Jenkins เปิด
}
```

### สิ่งที่ Jenkins agent ต้องเตรียม

- ✅ **Docker Engine + docker compose (v2)** ติดตั้งไว้ที่ agent
- ✅ มี `curl` (Linux agent default มีอยู่แล้ว)
- ✅ agent ต้อง **เชื่อมอินเทอร์เน็ตเพื่อ pull nginx** ครั้งแรก (Private Cloud อาจต้องขออนุมัติในเรื่อง outbound)
- ⚠️ ถ้า agent เป็น **Windows** → เปลี่ยน `sh` เป็น `bat` ใน Jenkinsfile (เขียนแบบ Linux ไว้ตอนนี้)
- ✅ ได้รับอนุญาตให้ใช้ **port 8080** หรือปรับค่า `APP_PORT` ใน Jenkinsfile

### ขั้นตอนตั้ง Jenkins Job

1. เข้าเว็บ Jenkins → **New Item** → ประเภท **Pipeline** → OK
2. ในส่วน **Pipeline** → Definition: **Pipeline script from SCM**
3. **SCM:** Git → Repo URL: `https://github.com/nattawutvisayataksin/m-travel-docker-jenkins.git`
4. Branch Specifier: `*/main` · **Script Path:** `Jenkinsfile`
5. กด Save → **Build Now** ได้เลย
6. Build สำเร็จ → ทดสอบเว็บจาก PC ใดก็ได้ ผ่าน `http://<IP ของเครื่อง>:8080/`
7. (ทางเลือก) ตั้งให้ build อัตโนมัติ: ใช้ **Poll SCM** หรือ GitHub webhook

### แนวทางเพิ่มเติมสำหรับ step ต่อจากนี้

- ถ้าอยาก rollback ได้: กำหนดให้ `IMAGE_TAG` ใช้ `BUILD_NUMBER` เพื่อแยก image แต่ละ build
- ถ้าต้องการเก็บ image กลางหรือ deploy หลายเครื่อง: ค่อยเพิ่ม **private registry** (เช่น Nexus หรือ Harbor ใน Private Cloud) ภายหลัง
- ถ้ามีหลายสภาพแวดล้อม (Dev / Prod): ให้ต่างกันแค่ค่า `APP_PORT` กับ `APP_NAME` (ใช้กับ `--project-name`)

---

## 7) ข้อมูลสำหรับกลับมาทำต่อ (ดูด่วน)

| ข้อ | รายการ |
|---|---|
| 📁 Folder ทำงานของเรา | `C:\Users\Administrator\Desktop\opencode\m-travel-docker-jenkins` |
| 🌐 เว็บ demo Local | `http://localhost:8080` |
| 🔐 หน้า Admin | `http://localhost:8080/admin.html` |
| 🗃️ ระบบ Database | Supabase Cloud (ตาม `assets/js/config.js`) |
| 🔗 Repo ต้นฉบับเดิม | `github.com/nattawutvisayataksin/m-travel` |
| 🔗 Repo ปัจจุบัน (มี Docker) | `github.com/nattawutvisayataksin/m-travel-docker-jenkins` |
| ⚙️ ไฟล์สำคัญสำหรับทำต่อ | **Section 8 (checkpoint รอบ 2)** + `ansible/README.md` + `Jenkinsfile` |

### คำสั่งเริ่มใหม่เมื่อกลับมา

```bash
cd C:\Users\Administrator\Desktop\opencode\m-travel-docker-jenkins
docker compose up -d --build
```

### เมื่อกลับมาหลังรีสตาร์ทเครื่อง

1. เปิด Docker Desktop แล้วรอให้สถานะ Running
2. สั่ง `docker compose ps` — ปกติ container จะกลับมาเอง เพราะ compose ตั้ง restart เป็น unless-stopped ไว้ (ถ้า Docker Desktop ตั้งให้เปิดอัตโนมัติตอนล็อกอิน)
3. ถ้ายังไม่รัน ให้รันคำสั่งด้านบนอีกครั้ง แล้วเปิด `http://localhost:8080`
4. เมื่อมาทำ Jenkins ต่อ ให้อ่าน PROJECT-SUMMARY.md ตั้งแต่ section 1 ไปจนถึง section 6 ก่อนลงมือ

---

*จบไฟล์สรุป — เมื่อกลับมาทำ step Jenkins อ่าน section 6 และไฟล์ `Jenkinsfile` ประกอบ แล้วทำได้เลย เป็นก้าวแรกสู่การ deploy ใน Private Cloud 🚀*

---

## 8) 🧊 Checkpoint รอบที่ 2 — Cert + Vault + Ansible/AWX (24–26 ต.ค. 2026)

> อ่าน section นี้ก่อนทุกอย่างเมื่อกลับมาทำต่อ

### ไฟล์ที่เพิ่ม/แก้ในรอบนี้ (commit `2a86f56` และ `31df060` push แล้ว)

| ไฟล์ | หน้าที่ |
|---|---|
| `ansible/inventory.ini` | inventory สำหรับรัน CLI — `[vault-deploy]` = **10.119.16.205 (เครื่องใหม่, เป้าปัจจุบัน)** · `[legacy]` = **10.119.16.105** (Docker server เครื่องเก่า) |
| `ansible/deploy-cert.yml` | ⭐ playbook หลัก: อ่าน `certificate`+`private_key` จาก Vault KV v2 → เขียน `m-travel.crt/.key` บน server → ตรวจคู่ด้วย openssl → git clone repo → `docker compose` โปรไฟล์ SSL → smoke test ต้อง 200 · ติดตั้ง curl/git/openssl/Docker ให้เองถ้าเป้าหมายไม่มี · override ผ่าน host var/extra var ชื่อ `_vault_version` `_cert_dir` `_repo_dir` `_https_port` ฯลฯ |
| `ansible/README.md` | คู่มือรัน CLI + ขั้นตอนตั้ง **AWX 24.6.1** ครบ 6 ขั้น (Project / Vault Token Credential Type / Machine credential / Inventory host variables / Job Template / Launch) |
| `docker-compose.ssl.yml` | โปรไฟล์ HTTPS: เพิ่ม port 443 + bind `default-ssl.conf` ทับ default + bind ไฟล์ cert จาก `${CERT_DIR}` (local เดิมไม่กระทบ — ยังรัน HTTP 8080 ได้ตามปกติ) |
| `deploy/nginx/default-ssl.conf` | nginx HTTPS: `listen 443 ssl` + TLSv1.2/1.3 + http2 + `return 301 https://$host$request_uri` (จาก 80) |
| `.gitignore` | เพิ่ม `m-travel-cert/` — โฟลเดอร์ cert/key ห้ามขึ้น Git เด็ดขาด |

> ผ่านการ validate แล้ว: YAML parse ✅ · `docker compose config` merge ✅ · `nginx -t` syntax ok ✅

### บันทึกเรื่อง certificate (กันลืม)

| หัวข้อ | ข้อเท็จจริง |
|---|---|
| ไฟล์ที่ใช้จริง | `BU.crt` (fullchain 3 ใบ) + `BU.key` — **เป็นคู่กันถูกต้อง**ตรวจด้วย public-key hash |
| โดเมน / ผู้ออก | `*.bu.ac.th` / GoDaddy (G2) · ใช้ได้ถึง **15 ธ.ค. 2026** → เตือนตัวเอง renew ก่อน ~15 พ.ย. 2026 |
| ไฟล์เก่าซ้ำ | `BU2024.crt/.key` = เนื้อหาเดียวกับ `BU.crt/.key` · `BU.pfx` = แพ็กเกจ PFX (password `B@ngk0kUni` ระบุไว้ในตัว secret ของ Vault) |
| Vault | mount `secret` (KV v2) path `certificates/bu.ac.th` — **v3** มี cert/key ชุดเดียวกับไฟล์ต้นฉบับ (ตรวจด้วย serial + modulus) · ฟิลด์ `expires_at` ใน v3 เป็น "2027-01-3" **ผิด** (ค่าจริงคือ 2026-12-15) |
| ไฟล์ cert ที่ server | ดึงมาผ่าน **WinSCP** จาก `/home/me/m-travel-cert/` บน .105 มาเก็บที่ `m-travel-cert\m-travel-cert\` ที่เครื่องนี้ |

### SSH config ที่เพิ่มไว้ที่เครื่องนี้

- เพิ่ม `node3` (alias `docker`) = `10.119.16.105`, user `root`, ใช้ key `id_ed25519` เดิม — แต่ **ยัง authorize ไม่สำเร็จ** (เปิด password ครั้งเดียวก็ไม่ได้ทำ) จึงใช้ WinSCP ไปทางนั้นเมื่อต้องการ หรือกลับมาทำตามคำแนะนำในบทสนทนา (ssh-copy-id ครั้งเดียว)

### ⚠️ ปมความปลอดภัยที่ค้างไว้ (ต้องเดินต่อเมื่อกลับมา)

- เกิดการ paste **private key + pfx_password** เข้าบทสนทนาหลายครั้ง → ถือว่าค่าดังกล่าว **leaked** แล้ว (ทั้งฝั่งผู้ให้บริการโมเดล และ log ฝั่งเครื่อง)
- 📌 **ทางแก้จริงจัง (เลือกอย่างน้อย 1 ทางเมื่อกลับมา):**
  - **A. GoDaddy rekey (แนะนำสุด)** — ออก CSR/key ใหม่ → reissue ใน GoDaddy (ฟรีใน validity) → ทิ้ง key เดิมทุกแหล่งที่หาได้
  - **B. Rotate `pfx_password`** — reconstruct `BU.pfx` ด้วย password ใหม่ (generate ตอนจอด + เก็บใน Vault ด้วย API ไม่ผ่านแชท)
  - **C. ตัด field `pfx_base64`/`pfx_password` ออกจาก schema v4** — ถ้า Ansible/AWX ใช้แค่ crt+key (nginx ใช้แค่นี้ แนะนำมาก)
- กติกา: **กลับมาทำไม่ว่าอะไร ห้าม paste ค่าลับลงแชทอีก** — ให้อ่านจาก path ไฟล์เช่น `m-travel-cert/` (gitignored) หรือให้ AWX/Ansible อ่านจาก Vault โดยตรง

### ✅ ลำดับงานสำหรับกลับมาทำต่อ (แนะนำ)

1. ตั้งค่า AWX ตามไฟล์ `ansible/README.md` (Project Git sync → Credential Type "Vault Token" → Machine credential ของ root@.205 → Inventory host variables ของ host `.205` → Job Template)
2. เลือกทางแก้ความปลอดภัย (A/B/C ข้างบน) อย่างน้อยทาง A หรือ B
3. (ถ้าจะดูแลให้ต่อ) สร้าง **Vault v4** ผ่าน UI หรือ API — ผ่าน API ให้ใส่ `options: {cas: 3}` เพื่อรับประกันเกิดเป็น version 4 แน่นอน
4. รัน Job Template ใน AWX — default playbook อ่านเวอร์ชันล่าสุด... หากอยาก pin v4 ให้ใส่ extra var `_vault_version: "4"`
5. ทดสอบผ่านโดเมนจริง: แนะนำ DNS `m-travel.bu.ac.th → 10.119.16.205` แล้วเข้าโดเมนตรง ๆ (cert เป็น wildcard `*.bu.ac.th` พอเรียกผ่าน IP browser จะฟ้อง mismatch)
6. แล้วจึงกลับไปทำแผน **Jenkins** ตาม Section 6 เดิมต่อได้

### สภาพแวดล้อมตอนหยุดพัก (ไม่ต้องทำอะไร)

- container `m-travel-web` ยังรันอยู่บนเครื่องนี้ (`restart: unless-stopped`) — ปล่อยไว้ได้
- กลับมาต่อ: เปิดโปรเจกต์ที่โฟลเดอร์นี้อีกครั้ง อ่าน Section 8 → ลงมือต่อทันที 💪
