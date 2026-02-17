pipeline {
  agent { label params.AGENT_LABEL }

  options {
    timestamps()
    timeout(time: 20, unit: 'MINUTES')
  }

  parameters {
    string(name: 'AGENT_LABEL', defaultValue: 'Nikita_Alecsentsev', description: 'Jenkins agent label')
    choice(name: 'DASH_MODE', choices: ['test', 'prod'], description: 'Which Dash UI to run')
    string(name: 'DASH_PORT', defaultValue: '8050', description: 'Dash port (test=8050, prod=8051)')
  }

  environment {
    VENV = ".venv"
    LOG_LEVEL = "INFO"

    // Network assumptions for single-host smoke test
    WEBSOCKET_HOST = "127.0.0.1"
    BUSINESS_HTTP_BASE = "http://127.0.0.1:8000"
    BUSINESS_BIND_HOST = "127.0.0.1"
    BUSINESS_BIND_PORT = "8000"
    DASH_HOST = "0.0.0.0"
  }

  stages {
    stage('Checkout') {
      steps { 
        checkout scm 
      }
    }

    stage('Prepare venv + deps') {
      steps {
        sh '''
          set -e
          python3 -V
          python3 -m venv "$VENV"
          . "$VENV/bin/activate"
          pip install -U pip
          pip install -r requirements.txt
        '''
      }
    }

    stage('Clean ports') {
      steps {
        sh '''
          set +e
          for p in 8000 8050 8051 8092 8093 8094 8095; do
            fuser -k ${p}/tcp 2>/dev/null || true
          done
          set -e
        '''
      }
    }

    stage('Run stack + healthchecks') {
      steps {
        sh '''
          set -e
          mkdir -p run_output
          . "$VENV/bin/activate"

          export LOG_LEVEL="$LOG_LEVEL"
          export WEBSOCKET_HOST="$WEBSOCKET_HOST"
          export BUSINESS_HTTP_BASE="$BUSINESS_HTTP_BASE"
          export BUSINESS_BIND_HOST="$BUSINESS_BIND_HOST"
          export BUSINESS_BIND_PORT="$BUSINESS_BIND_PORT"
          export DASH_HOST="$DASH_HOST"
          export DASH_PORT="$DASH_PORT"

          # Start Simulator
          python Simulator/simulator.py > run_output/simulator.log 2>&1 &
          echo $! > run_output/simulator.pid
          sleep 3

          # Start Receiver
          python Reciever/reciever.py > run_output/reciever.log 2>&1 &
          echo $! > run_output/reciever.pid
          sleep 3

          # Start Business
          python Business/business.py > run_output/business.log 2>&1 &
          echo $! > run_output/business.pid
          sleep 3

          # Start Dash
          if [ "$DASH_MODE" = "test" ]; then
            python GUI/dash_app_test.py > run_output/dash.log 2>&1 &
          else
            python GUI/dash_app_prod.py > run_output/dash.log 2>&1 &
          fi
          echo $! > run_output/dash.pid
          sleep 5

          # Health checks (если /healthz реально есть)
          curl -fsS "http://127.0.0.1:${BUSINESS_BIND_PORT}/healthz" | tee run_output/health_business.json
          curl -fsS "http://127.0.0.1:${DASH_PORT}/healthz" | tee run_output/health_dash.json

          # Let it run a bit to produce CSV/outputs
          sleep 30
        '''
      }
    }

    stage('Manual verification window (5 min)') {
      steps {
        echo "Окно ручной проверки: 5 минут. Сервисы НЕ останавливаются, порты открыты."
        sh 'sleep 300'
      }
    }

    stage('Stop processes + pack artifacts') {
      steps {
        sh '''
          set +e

          kill $(cat run_output/dash.pid) 2>/dev/null || true
          kill $(cat run_output/business.pid) 2>/dev/null || true
          kill $(cat run_output/reciever.pid) 2>/dev/null || true
          kill $(cat run_output/simulator.pid) 2>/dev/null || true
          sleep 2

          set -e
          tar -czf artifacts.tgz run_output Reciever/*.csv Business/*.csv 2>/dev/null || tar -czf artifacts.tgz run_output
        '''
      }
    }
  }

  post {
    success {
      echo 'Build succeeded;'
    }

    always {
      sh '''
        set +e
        for p in 8000 8050 8051 8092 8093 8094 8095; do
          fuser -k ${p}/tcp 2>/dev/null || true
        done
        set -e
      '''
      archiveArtifacts artifacts: 'artifacts.tgz, run_output/*.log, run_output/*.json, Reciever/*.csv, Business/*.csv', fingerprint: true
    }
  }
}
