# M-Travel เป็นเว็บ static ล้วน จึงเสิร์ฟด้วย nginx ตัวเล็ก ๆ ได้เลย
FROM nginx:1.27-alpine

# ใช้ config ของเราแทน default ของ nginx
COPY deploy/nginx/default.conf /etc/nginx/conf.d/default.conf

# คัดลอกเฉพาะไฟล์ที่จำเป็นเข้าคอนเทนเนอร์
COPY index.html trip.html about.html admin.html /usr/share/nginx/html/
COPY assets/ /usr/share/nginx/html/assets/
