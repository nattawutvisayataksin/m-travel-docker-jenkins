// Pipeline สำหรับ Build + Deploy เว็บ M-Travel บนเครื่อง Jenkins agent
// ข้อกำหนด: agent ต้องมี Docker และ docker compose (v2) ติดตั้งไว้
// แก้ค่าตั้งต้นได้ที่ environment ด้านล่าง (หรือใส่ผ่าน Environment Variables ของ Jenkins)

pipeline {
    agent any

    environment {
        APP_NAME = 'm-travel'
        APP_PORT = '8080'   // พอร์ทที่เปิดให้เรียกใช้งาน
    }

    options {
        timestamps()
        timeout(time: 15, unit: 'MINUTES')
    }

    stages {
        stage('Build image') {
            steps {
                sh "docker compose --project-name ${APP_NAME} build"
            }
        }

        stage('Deploy') {
            steps {
                sh "docker compose --project-name ${APP_NAME} up -d --no-build"
            }
        }

        stage('Smoke test') {
            steps {
                sh "curl -fsS http://localhost:${APP_PORT}/ -o /dev/null && echo 'Web is up'"
            }
        }
    }

    post {
        always {
            echo "Deploy ${APP_NAME} : ${currentBuild.currentResult}"
        }
    }
}
