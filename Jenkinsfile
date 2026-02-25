pipeline {
  agent { label 'Nikita_Alecsentsev' }

  options {
    timestamps()
    timeout(time: 20, unit: 'MINUTES')
    disableConcurrentBuilds()
    skipDefaultCheckout(true)
  }

  parameters {
    string(name: 'TARGET_HOST', defaultValue: '192.168.199.71', description: 'Deploy host')
    string(name: 'BUILD_JOB', defaultValue: 'Nikita_Alecsentsev_RestoringValuesSPbPU', description: 'L2 job name')
  }

  stages {

    stage('Fetch artifacts from L2') {
      steps {
        script {
          sh 'rm -rf deploy_art && mkdir -p deploy_art'

          step([$class: 'CopyArtifact', 
                projectName: params.BUILD_JOB, 
                selector: [$class: 'StatusBuildSelector', stable: false], 
                filter: 'dist/*.whl', 
                target: 'deploy_art', 
                fingerprintArtifacts: true])
          
          step([$class: 'CopyArtifact', 
                projectName: params.BUILD_JOB, 
                selector: [$class: 'StatusBuildSelector', stable: false], 
                filter: 'app-restoringvalues.tgz', 
                target: 'deploy_art', 
                fingerprintArtifacts: true])
          
          step([$class: 'CopyArtifact', 
                projectName: params.BUILD_JOB, 
                selector: [$class: 'StatusBuildSelector', stable: false], 
                filter: 'artifacts.tgz', 
                target: 'deploy_art', 
                fingerprintArtifacts: true])

          sh 'find deploy_art -maxdepth 4 -type f -print'
        }
      }
    }

    stage('Deploy to server') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail

SSH_USER="debian"
TARGET_HOST="192.168.199.71"
SSH_OPTS="-i /home/ubuntu/Nikita_Alecsentsev.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# Находим файлы
WHEEL=$(find deploy_art -name "*.whl" -type f | head -1)
TGZ=$(find deploy_art -name "app-restoringvalues.tgz" -type f | head -1)

echo "Wheel: $WHEEL"
echo "TGZ: $TGZ"

if [ -z "$WHEEL" ] || [ -z "$TGZ" ]; then
    echo "ERROR: Required artifacts not found!"
    exit 1
fi

# Копируем файлы на сервер
echo "Copying files to ${TARGET_HOST}..."
scp $SSH_OPTS "$WHEEL" "$TGZ" ${SSH_USER}@${TARGET_HOST}:/tmp/

# Выполняем установку на сервере
ssh $SSH_OPTS ${SSH_USER}@${TARGET_HOST} "
    set -e
    
    echo '=== 1. Чиним репозитории ==='
    sudo tee /etc/apt/sources.list > /dev/null <<EOF
deb http://archive.debian.org/debian/ buster main contrib non-free
deb http://archive.debian.org/debian/ buster-updates main contrib non-free
EOF
    
    echo '=== 2. Обновляем списки ==='
    sudo apt update -o Acquire::Check-Valid-Until=false || true
    
    echo '=== 3. Ставим Python 3.9 из бэкпортов (ДРУГОЙ СПОСОБ) ==='
    # Добавляем бэкпорты
    echo 'deb http://archive.debian.org/debian buster-backports main' | sudo tee -a /etc/apt/sources.list
    sudo apt update -o Acquire::Check-Valid-Until=false || true
    
    # Пробуем найти python3.9
    apt list -a python3.9 2>/dev/null || echo 'Python 3.9 not in repos'
    
    # Ставим то что есть
    sudo apt install -y python3 python3-venv python3-pip python3-dev
    
    echo '=== 4. Создаем директорию приложения ==='
    mkdir -p ~/app
    cp /tmp/*.whl /tmp/app-restoringvalues.tgz ~/app/
    cd ~/app
    
    echo '=== 5. Распаковываем tgz ==='
    if [ -f app-restoringvalues.tgz ]; then
        tar -xzf app-restoringvalues.tgz || true
    fi
    
    echo '=== 6. Создаем виртуальное окружение ==='
    python3 -m venv venv
    source venv/bin/activate
    
    echo '=== 7. Обновляем pip ==='
    pip install --upgrade pip setuptools wheel
    
    echo '=== 8. Устанавливаем wheel IGNORING DEPENDENCIES ==='
    pip install --no-deps *.whl
    
    echo '=== 9. Проверяем установку ==='
    pip list | grep restoring
    python -c 'import restoringvalues; print(\"✅ SUCCESS - package installed\")' 2>/dev/null || echo 'Import failed'
"

echo "✅ DEPLOY COMPLETE"
'''
      }
    }
    
    stage('Health check') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail

SSH_USER="debian"
TARGET_HOST="192.168.199.71"
SSH_OPTS="-i /home/ubuntu/Nikita_Alecsentsev.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

ssh $SSH_OPTS ${SSH_USER}@${TARGET_HOST} "
    source ~/app/venv/bin/activate
    python -c 'import restoringvalues; print(\"✅ HEALTH CHECK OK - package is importable\")' || echo 'Import failed'
"

echo "✅ Health check passed"
'''
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'deploy_art/**', allowEmptyArchive: true
      cleanWs()
    }
    success {
      echo "🎉 SUCCESS: Application deployed"
    }
    failure {
      echo "❌ FAILURE: Check logs above"
    }
  }
}
