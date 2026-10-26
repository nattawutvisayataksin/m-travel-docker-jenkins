# 📦 ansible — ดึง cert จาก Vault แล้ว deploy nginx HTTPS

Playbook หลัก: **`deploy-cert.yml`** · Target: **Ubuntu Docker Server 10.119.16.105**

## ขั้นตอนรัน

```bash
# 0) เตรียมเครื่อง controller (Linux/WSL):
#    sudo apt install ansible          # หรือ pip install ansible-core
#    ssh key ต้องเข้าถึง server ได้ (id_ed25519 ที่ authorize ที่ server หรือจะใช้ winSCP/จองแบบที่ไม่ต้องใช้ password)

# 1) export token (ห้ามใส่ลงไฟล์!):
export VAULT_ADDR="https://hashiva.bu.ac.th"
export VAULT_TOKEN="hvs.xxxxxxxxxxxxx"

# 2) รัน playbook:
cd ansible
ansible-playbook -i inventory.ini deploy-cert.yml

# ตัวเลือกเพิ่มเติม:
#   pin รุ่น Vault เป็น v4:   -e vault_version=4
#   ส่ง token ทาง args:       -e "vault_token_arg=hvs.xxxx"
#   เปลี่ยนพอร์ต HTTPS:      -e https_port=8443
#   เปลี่ยนเป้า repo ที่ server: -e repo_dir=/srv/m-travel-docker-jenkins
```

## Playbook ทำอะไร (โดยลำดับ)

1. อ่าน `certificate` + `private_key` จาก Vault KV v2 (`secret/data/certificates/bu.ac.th`)
2. เขียนเป็น `m-travel.crt` (0644) / `m-travel.key` (0600) ที่ `/home/me/m-travel-cert/`
3. ตรวจว่า cert & key เป็นคู่เดียวกันด้วย openssl + แจ้งวันหมดอายุจากใบ cert จริง
4. git clone/update repo บน server (มี `docker-compose.ssl.yml` + `deploy/nginx/default-ssl.conf`)
5. รัน `docker compose -f docker-compose.yml -f docker-compose.ssl.yml up -d --build`
   → nginx รับ traffic 443/TLS + รีไดเรกต์ 80→443
6. Smoke test HTTPS ต้องได้ 200

## ข้อควรรู้

- **ไม่ใช้** ฟิลด์ `pfx_base64`/`pfx_password` ใน v4 เลย — nginx ต้องการแค่ crt+key (ตัดความลับซ้ำซ้อน)
- ให้ try `validate_certs: true` บน smoke test ก็จริง แต่ภายในทดสอบด้วย IP จะ fail เพราะ cert ผูกกับ `*.bu.ac.th`
- แนะนำตั้ง DNS: `m-travel.bu.ac.th` → `10.119.16.105` แล้วเรียกผ่านโดเมนโดยตรงตั้งแต่แรก (browser จะแสดงกุญแจถูกต้องเอง)
- token ของ Vault ควรสร้างเป็น **short-lived token** / policy จำกัดเฉพาะ read ที่ `secret/data/certificates/bu.ac.th`
