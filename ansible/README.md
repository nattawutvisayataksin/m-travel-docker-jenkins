# 📦 ansible — ดึง cert จาก Vault แล้ว deploy nginx HTTPS

Playbook หลัก: **`deploy-cert.yml`**
- รันผ่าน **AWX 24.6.1** (เป้าหมายเดิมที่เพิ่มไว้: `10.119.16.205`)
- หรือรันแบบ CLI จาก Linux/WSL ก็ได้

## ▶️ รันแบบ CLI

```bash
export VAULT_TOKEN="hvs.xxxxxxxxxxxxx"     # ใส่ผ่าน env เท่านั้น ห้ามเขียนลงไฟล์
cd ansible
ansible-playbook -i inventory.ini deploy-cert.yml
# pin รุ่น Vault เป็น v4 + ตัวแปรอื่น ๆ (ชื่อที่ขึ้นต้น _):
ansible-playbook -i inventory.ini deploy-cert.yml -e "_vault_version=4"
```

## 🖥️ รันผ่าน AWX 24.6.1 (เตรียมครั้งเดียว)

### 1) Project — เชื่อม Git repo ของเรา
**Resources → Projects → Add**
- Name: `m-travel-docker-jenkins`
- Source Control Type: Git
- URL: `https://github.com/nattawutvisayataksin/m-travel-docker-jenkins.git`
- Branch: `main` → กด **Sync** ให้ playbook list ขึ้น

### 2) Custom Credential Type — ฉีด Vault Token เข้า environment
**Resources → Access → Credential Types → Add**
- Name: `Vault Token`

Input configuration (YAML):
```yaml
fields:
  - id: vault_token
    type: string
    label: Vault Token
    secret: true
required:
  - vault_token
```

Injector configuration (YAML):
```yaml
env:
  VAULT_TOKEN: "{{ vault_token }}"
```

แล้วสร้าง credential จริง: **Resources → Credentials → Add**
- Credential Type: `Vault Token` → paste token (ช่องจะถูกเก็บเป็น secret ไม่แสดงต่อ)

### 3) Machine Credential — SSH เข้า server
**Resources → Credentials → Add**
- Type: Machine → Username: `root` (+ Password หรือ SSH private key ของเครื่อง controller)
- ⚠️ ถ้าใช้ SSH key ให้ authorize key นั้นที่ `.205` ก่อน (`authorized_keys` ของ root)

### 4) Inventory — host ที่เพิ่มไว้แล้ว
แก้ Host variables ของ `10.119.16.205` ให้ครบ (ชื่อ host ตั้งเป็นอะไรก็ได้ เพราะ playbook ใช้ `hosts: all`):
```yaml
ansible_host: 10.119.16.205
ansible_user: root
ansible_ssh_common_args: '-o StrictHostKeyChecking=accept-new'
# ปรับได้เมื่อจำเป็น:
# _cert_dir: /root/m-travel-cert
# _repo_dir: /opt/m-travel-docker-jenkins
# _https_port: 443
```

### 5) Job Template — หัวใจของการรัน
**Resources → Templates → Add → Job Template**
- Name: `deploy-m-travel-tls`
- Project: `m-travel-docker-jenkins`
- Playbook: `ansible/deploy-cert.yml`
- Inventory: ขององค์กรที่มี host `.205`
- Credentials: **2 ตัว** = Machine (SSH) + `Vault Token`
- Extra Variables (ใส่เมื่ออยาก pin รุ่น):
  ```yaml
  _vault_version: "4"
  ```
- Enable "Prompt on launch" ส่วนที่อยากให้เลือกตอนกดรันได้

กด **Launch** → ดู live output → เสร็จแล้วไฟล์ `m-travel.crt/.key` ขึ้นที่ `/root/m-travel-cert/` และ nginx HTTPS รันบน 443

### 6) Vault token ควรจำกัดสิทธิ์ (สร้าง policy แยกสำหรับ AWX)
```hcl
path "secret/data/certificates/bu.ac.th"    { capabilities = ["read"] }
path "secret/metadata/certificates/bu.ac.th" { capabilities = ["read"] }
```
และควรใช้ token แบบมี TTL สั้น / renewable ตามองค์กรจัด

## ✅ สิ่งที่ playbook จัดการให้เอง

- เป้าหมายยังไม่มี `curl`/`git`/`openssl`/`Docker` → ติดตั้งให้ก่อน (get.docker.com รวม compose plugin)
- ตรวจ cert ↔ key เป็นคู่เดียวกัน (public key hash) ก่อนใช้จริง
- แจ้งวันหมดอายุจากใบ cert จริง (ไม่เชื่อฟิลด์ `expires_at` ใน Vault เพราะข้อมูลเก่าผิด)
- Smoke test HTTPS ต้องได้ 200 ท้าย job

## 📝 ข้อควรรู้

- ไม่ใช้ฟิลด์ `pfx_base64`/`pfx_password` จาก Vault — nginx ต้องการแค่ crt + key
- **Execution Environment ต้องเข้าถึงได้:** GitHub (pull repo) · SSH port 22 ของเป้าหมาย · `https://hashiva.bu.ac.th`
- ถ้า repo เป็น private ต้องเพิ่ม SCM credential ให้ Project (deploy key/PAT) — ปัจจุบันเป็น public จึงใช้ได้ตรง ๆ
