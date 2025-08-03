# 🚀 CI/CD Setup Guide for Toolshop API Testing Repository

This guide assumes you have pushed the `sprint5-with-bugs` folder as a **separate repository** to GitHub and want to set up CI/CD.

## 📁 Repository Structure (Assumed)

```
your-toolshop-repo/
├── .github/workflows/           # GitHub Actions (we'll create these)
├── API/                        # Laravel API application
├── docker-compose.yml          # Docker environment
├── Toolshop_APITesting.postman_collection.json
├── test.case.csv
└── README.md
```

## 🔧 Step-by-Step CI/CD Setup

### Step 1: Enable GitHub Actions

1. **Go to your repository** on GitHub
2. **Click the "Actions" tab**
3. **Click "Set up a workflow yourself"** or choose a template
4. We'll create custom workflows below

### Step 2: Create Workflow Directory Structure

In your repository, create the `.github/workflows/` directory and add these 4 workflow files:

---

## 📄 Workflow File 1: Main CI/CD Pipeline

Create `.github/workflows/api-tests.yml`:

```yaml
name: API Testing Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

env:
  API_BASE_URL: http://localhost:8081

jobs:
  validate:
    name: Validate Collection
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Install Newman
        run: npm install -g newman newman-reporter-htmlextra

      - name: Validate Collection Structure
        run: |
          echo "🔍 Validating Postman collection..."
          if ! command -v jq &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y jq
          fi
          
          if ! jq empty Toolshop_APITesting.postman_collection.json; then
            echo "❌ Invalid JSON format"
            exit 1
          fi
          
          echo "✅ Collection is valid JSON"
          
          # Count test cases
          TOTAL_REQUESTS=$(jq '[.. | objects | select(has("request")) | .request] | length' Toolshop_APITesting.postman_collection.json)
          echo "📊 Total test cases: $TOTAL_REQUESTS"

  test:
    name: Run API Tests
    runs-on: ubuntu-latest
    needs: validate
    strategy:
      matrix:
        test-suite: [brands, users, products, favorites]
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Docker
        uses: docker/setup-buildx-action@v3

      - name: Start Testing Environment
        run: |
          echo "🐳 Starting Docker environment..."
          
          # Use docker compose (newer syntax) instead of docker-compose
          docker compose up -d --build
          
          echo "⏳ Waiting for services to be ready..."
          sleep 45
          
          # Check if containers are running
          docker compose ps
          
          # Wait for API to be responsive
          for i in {1..30}; do
            if curl -f http://localhost:8081/brands > /dev/null 2>&1; then
              echo "✅ API is ready!"
              break
            fi
            echo "⏳ Waiting for API... (attempt $i/30)"
            sleep 10
          done
          
          # If API is still not ready, show logs for debugging
          if ! curl -f http://localhost:8081/brands > /dev/null 2>&1; then
            echo "❌ API failed to start. Checking logs..."
            docker compose logs api
            exit 1
          fi

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Install Newman
        run: npm install -g newman newman-reporter-htmlextra

      - name: Get Admin Token
        id: admin-token
        run: |
          echo "🔐 Getting admin authentication token..."
          
          ADMIN_RESPONSE=$(curl -s -X POST http://localhost:8081/users/login \
            -H "Content-Type: application/json" \
            -d '{
              "email": "admin@practicesoftwaretesting.com",
              "password": "welcome01"
            }')
          
          ADMIN_TOKEN=$(echo $ADMIN_RESPONSE | jq -r '.access_token // empty')
          
          if [ -z "$ADMIN_TOKEN" ]; then
            echo "❌ Failed to get admin token"
            echo "Response: $ADMIN_RESPONSE"
            exit 1
          fi
          
          echo "admin_token=$ADMIN_TOKEN" >> $GITHUB_OUTPUT
          echo "✅ Admin token obtained"

      - name: Get User Token
        id: user-token
        run: |
          echo "🔐 Getting user authentication token..."
          
          USER_RESPONSE=$(curl -s -X POST http://localhost:8081/users/login \
            -H "Content-Type: application/json" \
            -d '{
              "email": "customer@practicesoftwaretesting.com",
              "password": "welcome01"
            }')
          
          USER_TOKEN=$(echo $USER_RESPONSE | jq -r '.access_token // empty')
          
          if [ -z "$USER_TOKEN" ]; then
            echo "❌ Failed to get user token"
            echo "Response: $USER_RESPONSE"
            exit 1
          fi
          
          echo "user_token=$USER_TOKEN" >> $GITHUB_OUTPUT
          echo "✅ User token obtained"

      - name: Run Newman Tests
        run: |
          echo "🧪 Running API tests for ${{ matrix.test-suite }}..."
          
          newman run Toolshop_APITesting.postman_collection.json \
            --folder "${{ matrix.test-suite }}" \
            --environment <(echo '{
              "name": "CI Environment",
              "values": [
                {"key": "baseUrl", "value": "http://localhost:8081"},
                {"key": "admin_token", "value": "${{ steps.admin-token.outputs.admin_token }}"},
                {"key": "user_token", "value": "${{ steps.user-token.outputs.user_token }}"}
              ]
            }') \
            --reporters cli,htmlextra,junit \
            --reporter-htmlextra-export reports/newman-report-${{ matrix.test-suite }}.html \
            --reporter-junit-export reports/junit-report-${{ matrix.test-suite }}.xml \
            --delay-request 1000 \
            --timeout-request 10000 \
            --color on

      - name: Upload Test Reports
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-reports-${{ matrix.test-suite }}
          path: reports/
          retention-days: 30

      - name: Publish Test Results
        uses: dorny/test-reporter@v1
        if: always()
        with:
          name: API Tests - ${{ matrix.test-suite }}
          path: reports/junit-report-${{ matrix.test-suite }}.xml
          reporter: java-junit

      - name: Check Container Logs
        if: failure()
        run: |
          echo "🔍 Checking container logs for debugging..."
          docker compose logs api
          docker compose logs mariadb

      - name: Cleanup
        if: always()
        run: |
          echo "🧹 Cleaning up Docker environment..."
          docker compose down -v
```

---

## 📄 Workflow File 2: Nightly Regression Tests

Create `.github/workflows/nightly-tests.yml`:

```yaml
name: Nightly Regression Tests

on:
  schedule:
    - cron: '0 2 * * *'  # Run at 2 AM UTC daily
  workflow_dispatch:

env:
  API_BASE_URL: http://localhost:8081

jobs:
  full-regression:
    name: Full API Regression Suite
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Docker
        uses: docker/setup-buildx-action@v3

      - name: Start Environment
        run: |
          echo "🐳 Starting full testing environment..."
          docker compose up -d --build
          sleep 60  # Extra time for nightly tests
          
          # Check container status
          docker compose ps
          
          # Health check with better error handling
          for i in {1..40}; do
            if curl -f http://localhost:8081/brands > /dev/null 2>&1; then
              echo "✅ Environment ready!"
              break
            fi
            if [ $i -eq 40 ]; then
              echo "❌ Environment failed to start. Checking logs..."
              docker compose logs api
              docker compose logs mariadb
              exit 1
            fi
            echo "⏳ Waiting for environment... (attempt $i/40)"
            sleep 10
          done

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Install Tools
        run: npm install -g newman newman-reporter-htmlextra

      - name: Authenticate Users
        id: auth
        run: |
          # Get admin token
          ADMIN_RESPONSE=$(curl -s -X POST http://localhost:8081/users/login \
            -H "Content-Type: application/json" \
            -d '{"email": "admin@practicesoftwaretesting.com", "password": "welcome01"}')
          
          ADMIN_TOKEN=$(echo $ADMIN_RESPONSE | jq -r '.access_token // empty')
          echo "admin_token=$ADMIN_TOKEN" >> $GITHUB_OUTPUT
          
          # Get user token
          USER_RESPONSE=$(curl -s -X POST http://localhost:8081/users/login \
            -H "Content-Type: application/json" \
            -d '{"email": "customer@practicesoftwaretesting.com", "password": "welcome01"}')
          
          USER_TOKEN=$(echo $USER_RESPONSE | jq -r '.access_token // empty')
          echo "user_token=$USER_TOKEN" >> $GITHUB_OUTPUT

      - name: Run Complete Test Suite
        run: |
          echo "🌙 Running full nightly regression tests..."
          
          newman run Toolshop_APITesting.postman_collection.json \
            --environment <(echo '{
              "name": "Nightly Environment",
              "values": [
                {"key": "baseUrl", "value": "http://localhost:8081"},
                {"key": "admin_token", "value": "${{ steps.auth.outputs.admin_token }}"},
                {"key": "user_token", "value": "${{ steps.auth.outputs.user_token }}"}
              ]
            }') \
            --reporters cli,htmlextra,junit \
            --reporter-htmlextra-export reports/nightly-regression-report.html \
            --reporter-junit-export reports/nightly-junit-report.xml \
            --delay-request 2000 \
            --timeout-request 15000 \
            --bail

      - name: Generate Summary
        if: always()
        run: |
          echo "## 🌙 Nightly Regression Test Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          
          if [ -f "reports/nightly-junit-report.xml" ]; then
            TOTAL=$(grep -o 'tests="[0-9]*"' reports/nightly-junit-report.xml | cut -d'"' -f2)
            FAILURES=$(grep -o 'failures="[0-9]*"' reports/nightly-junit-report.xml | cut -d'"' -f2)
            ERRORS=$(grep -o 'errors="[0-9]*"' reports/nightly-junit-report.xml | cut -d'"' -f2)
            
            echo "| Metric | Value |" >> $GITHUB_STEP_SUMMARY
            echo "|--------|-------|" >> $GITHUB_STEP_SUMMARY
            echo "| Total Tests | $TOTAL |" >> $GITHUB_STEP_SUMMARY
            echo "| Failures | $FAILURES |" >> $GITHUB_STEP_SUMMARY
            echo "| Errors | $ERRORS |" >> $GITHUB_STEP_SUMMARY
            
            if [ "$FAILURES" -eq 0 ] && [ "$ERRORS" -eq 0 ]; then
              echo "| Status | ✅ All tests passed |" >> $GITHUB_STEP_SUMMARY
            else
              echo "| Status | ❌ Some tests failed |" >> $GITHUB_STEP_SUMMARY
            fi
          fi

      - name: Upload Reports
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: nightly-test-reports
          path: reports/
          retention-days: 90

      - name: Cleanup
        if: always()
        run: docker compose down -v
```

---

## 📄 Workflow File 3: Manual Environment Control

Create `.github/workflows/manual-testing.yml`:

```yaml
name: Manual Testing Environment

on:
  workflow_dispatch:
    inputs:
      action:
        description: 'Action to perform'
        required: true
        default: 'start'
        type: choice
        options:
        - start
        - test
        - restart
        - stop

jobs:
  manual-control:
    name: ${{ github.event.inputs.action }} Environment
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Docker
        if: github.event.inputs.action != 'stop'
        uses: docker/setup-buildx-action@v3

      - name: Start Environment
        if: github.event.inputs.action == 'start' || github.event.inputs.action == 'restart'
        run: |
          echo "🚀 Starting testing environment..."
          docker compose up -d --build
          
          echo "⏳ Waiting for services..."
          sleep 45
          
          # Check container status
          docker compose ps
          
          # Health check with timeout
          for i in {1..25}; do
            if curl -f http://localhost:8081/brands > /dev/null 2>&1; then
              echo "✅ Environment is ready!"
              echo "🌐 API available at: http://localhost:8081"
              exit 0
            fi
            echo "⏳ Checking API health... (attempt $i/25)"
            sleep 5
          done
          
          echo "❌ Environment failed to start properly"
          echo "🔍 Container status:"
          docker compose ps
          echo "🔍 API logs:"
          docker compose logs api
          exit 1

      - name: Run Tests
        if: github.event.inputs.action == 'test' || github.event.inputs.action == 'restart'
        run: |
          if [ "${{ github.event.inputs.action }}" == "test" ]; then
            echo "🧪 Running tests on existing environment..."
          else
            echo "🧪 Running tests on restarted environment..."
          fi
          
          # Setup Node.js and Newman
          curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
          sudo apt-get install -y nodejs
          npm install -g newman
          
          # Get tokens
          ADMIN_RESPONSE=$(curl -s -X POST http://localhost:8081/users/login \
            -H "Content-Type: application/json" \
            -d '{"email": "admin@practicesoftwaretesting.com", "password": "welcome01"}')
          
          ADMIN_TOKEN=$(echo $ADMIN_RESPONSE | jq -r '.access_token // empty')
          
          # Run quick test
          newman run Toolshop_APITesting.postman_collection.json \
            --folder "Brand Management" \
            --environment <(echo '{
              "name": "Manual Test Environment",
              "values": [
                {"key": "baseUrl", "value": "http://localhost:8081"},
                {"key": "admin_token", "value": "'$ADMIN_TOKEN'"}
              ]
            }') \
            --delay-request 1000

      - name: Stop Environment
        if: github.event.inputs.action == 'stop'
        run: |
          echo "🛑 Stopping testing environment..."
          docker compose down -v
          echo "✅ Environment stopped and cleaned up"

      - name: Environment Status
        if: github.event.inputs.action == 'start'
        run: |
          echo "## 🚀 Environment Status" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "✅ Testing environment is **RUNNING**" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "### 🔗 Access Information" >> $GITHUB_STEP_SUMMARY
          echo "- **API Base URL**: http://localhost:8081" >> $GITHUB_STEP_SUMMARY
          echo "- **Admin Login**: admin@practicesoftwaretesting.com / welcome01" >> $GITHUB_STEP_SUMMARY
          echo "- **User Login**: customer@practicesoftwaretesting.com / welcome01" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "### 🧪 Quick Test Commands" >> $GITHUB_STEP_SUMMARY
          echo '```bash' >> $GITHUB_STEP_SUMMARY
          echo "curl http://localhost:8081/brands" >> $GITHUB_STEP_SUMMARY
          echo "curl http://localhost:8081/products" >> $GITHUB_STEP_SUMMARY
          echo '```' >> $GITHUB_STEP_SUMMARY
```

---

## 📄 Workflow File 4: Collection Validation

Create `.github/workflows/validate-collection.yml`:

```yaml
name: Validate Collection

on:
  push:
    paths:
      - 'Toolshop_APITesting.postman_collection.json'
      - 'test.case.csv'
  pull_request:
    paths:
      - 'Toolshop_APITesting.postman_collection.json'
      - 'test.case.csv'

jobs:
  validate:
    name: Validate Test Assets
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Install Dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y jq

      - name: Validate JSON Structure
        run: |
          echo "🔍 Validating Postman collection JSON..."
          
          if ! jq empty Toolshop_APITesting.postman_collection.json; then
            echo "❌ Invalid JSON format"
            exit 1
          fi
          
          echo "✅ Valid JSON structure"

      - name: Analyze Collection
        run: |
          echo "📊 Analyzing collection structure..."
          
          COLLECTION_NAME=$(jq -r '.info.name' Toolshop_APITesting.postman_collection.json)
          TOTAL_FOLDERS=$(jq '[.item[] | select(.item)] | length' Toolshop_APITesting.postman_collection.json)
          TOTAL_REQUESTS=$(jq '[.. | objects | select(has("request")) | .request] | length' Toolshop_APITesting.postman_collection.json)
          
          echo "Collection: $COLLECTION_NAME"
          echo "Folders: $TOTAL_FOLDERS"
          echo "Test Cases: $TOTAL_REQUESTS"
          
          echo "## 📊 Collection Analysis" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Metric | Value |" >> $GITHUB_STEP_SUMMARY
          echo "|--------|-------|" >> $GITHUB_STEP_SUMMARY
          echo "| Collection Name | $COLLECTION_NAME |" >> $GITHUB_STEP_SUMMARY
          echo "| Total Folders | $TOTAL_FOLDERS |" >> $GITHUB_STEP_SUMMARY
          echo "| Total Test Cases | $TOTAL_REQUESTS |" >> $GITHUB_STEP_SUMMARY

      - name: Validate CSV
        run: |
          echo "🔍 Validating test case CSV..."
          
          if [ ! -f "test.case.csv" ]; then
            echo "❌ test.case.csv not found"
            exit 1
          fi
          
          CSV_LINES=$(tail -n +3 test.case.csv | grep -c '^[0-9]' || echo "0")
          echo "CSV Test Cases: $CSV_LINES"
          
          echo "| CSV Test Cases | $CSV_LINES |" >> $GITHUB_STEP_SUMMARY
```

---

## 🚀 How to Implement This CI/CD

### Step 3: Create the Workflow Files

1. **Create the directory structure**:
   ```bash
   mkdir -p .github/workflows
   ```

2. **Copy each workflow** (above) into separate `.yml` files in `.github/workflows/`

3. **Commit and push**:
   ```bash
   git add .github/workflows/
   git commit -m "Add comprehensive CI/CD pipeline"
   git push origin main
   ```

### Step 4: Configure Repository (Optional)

1. **Go to Repository Settings** → **Actions** → **General**
2. **Enable Actions** if not already enabled
3. **Set permissions** for GITHUB_TOKEN if needed

### Step 5: Test Your CI/CD

1. **Automatic Test**: Make any change and push to trigger workflows
2. **Manual Test**: Go to Actions → "Manual Testing Environment" → Run workflow

## 📊 What You Get

- ✅ **Automated testing** on every push/PR
- ✅ **Parallel test execution** across different test suites
- ✅ **Nightly regression testing**
- ✅ **Manual environment control**
- ✅ **HTML and JUnit reports**
- ✅ **Collection validation**
- ✅ **Comprehensive logging and debugging**

## 🎯 Next Steps

1. **Push workflows** to your repository
2. **Monitor the Actions tab** for execution
3. **Download reports** from workflow artifacts
4. **Customize** as needed for your specific requirements

Your Toolshop API testing repository now has **enterprise-grade CI/CD**! 🎉
