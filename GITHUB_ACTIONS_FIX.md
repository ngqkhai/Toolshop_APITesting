# 🔧 Fixed GitHub Actions Workflow

## Issue: `docker-compose: command not found`

The error occurs because GitHub Actions runners use the newer `docker compose` (space) command instead of `docker-compose` (hyphen).

## 🚀 Updated Main CI/CD Pipeline

Create `.github/workflows/api-tests-fixed.yml`:

```yaml
name: API Testing Pipeline (Fixed)

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
      fail-fast: false
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Free up disk space
        run: |
          sudo rm -rf /usr/share/dotnet
          sudo rm -rf /opt/ghc
          sudo rm -rf "/usr/local/share/boost"
          sudo rm -rf "$AGENT_TOOLSDIRECTORY"

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Start Testing Environment
        run: |
          echo "🐳 Starting Docker environment..."
          
          # Check Docker version and available commands
          docker --version
          docker compose version
          
          # Start services
          docker compose up -d --build
          
          echo "⏳ Waiting for services to initialize..."
          sleep 60
          
          # Check container status
          echo "📋 Container status:"
          docker compose ps
          
          # Check if containers are healthy
          echo "🏥 Health check:"
          docker compose logs --tail=20 api
          
          # Wait for API to be responsive with better error handling
          echo "🔍 Testing API connectivity..."
          for i in {1..30}; do
            if curl -f -s http://localhost:8081/brands > /dev/null 2>&1; then
              echo "✅ API is ready!"
              break
            elif [ $i -eq 30 ]; then
              echo "❌ API failed to start after 30 attempts"
              echo "🔍 Final container status:"
              docker compose ps
              echo "🔍 API container logs:"
              docker compose logs api
              echo "🔍 Database container logs:"
              docker compose logs mariadb
              exit 1
            else
              echo "⏳ Waiting for API... (attempt $i/30)"
              sleep 10
            fi
          done
          
          # Test basic API endpoints
          echo "🧪 Testing basic endpoints:"
          curl -v http://localhost:8081/brands || echo "Brands endpoint failed"
          curl -v http://localhost:8081/users || echo "Users endpoint might require auth"

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
          
          # Try to get admin token with detailed error handling
          ADMIN_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST http://localhost:8081/users/login \
            -H "Content-Type: application/json" \
            -d '{
              "email": "admin@practicesoftwaretesting.com",
              "password": "welcome01"
            }')
          
          # Extract body and status
          ADMIN_BODY=$(echo $ADMIN_RESPONSE | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
          ADMIN_STATUS=$(echo $ADMIN_RESPONSE | tr -d '\n' | sed -E 's/.*HTTPSTATUS:([0-9]{3})$/\1/')
          
          echo "Admin login status: $ADMIN_STATUS"
          echo "Admin response: $ADMIN_BODY"
          
          if [ "$ADMIN_STATUS" -eq 200 ]; then
            ADMIN_TOKEN=$(echo $ADMIN_BODY | jq -r '.access_token // empty')
            if [ -n "$ADMIN_TOKEN" ] && [ "$ADMIN_TOKEN" != "null" ]; then
              echo "admin_token=$ADMIN_TOKEN" >> $GITHUB_OUTPUT
              echo "✅ Admin token obtained successfully"
            else
              echo "❌ Admin token not found in response"
              exit 1
            fi
          else
            echo "❌ Admin login failed with status $ADMIN_STATUS"
            echo "Response: $ADMIN_BODY"
            exit 1
          fi

      - name: Get User Token
        id: user-token
        run: |
          echo "🔐 Getting user authentication token..."
          
          USER_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST http://localhost:8081/users/login \
            -H "Content-Type: application/json" \
            -d '{
              "email": "customer@practicesoftwaretesting.com",
              "password": "welcome01"
            }')
          
          USER_BODY=$(echo $USER_RESPONSE | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
          USER_STATUS=$(echo $USER_RESPONSE | tr -d '\n' | sed -E 's/.*HTTPSTATUS:([0-9]{3})$/\1/')
          
          echo "User login status: $USER_STATUS"
          
          if [ "$USER_STATUS" -eq 200 ]; then
            USER_TOKEN=$(echo $USER_BODY | jq -r '.access_token // empty')
            if [ -n "$USER_TOKEN" ] && [ "$USER_TOKEN" != "null" ]; then
              echo "user_token=$USER_TOKEN" >> $GITHUB_OUTPUT
              echo "✅ User token obtained successfully"
            else
              echo "❌ User token not found in response"
              exit 1
            fi
          else
            echo "❌ User login failed with status $USER_STATUS"
            echo "Response: $USER_BODY"
            exit 1
          fi

      - name: Create Newman Environment
        run: |
          echo "📝 Creating Newman environment file..."
          cat > newman-environment.json << EOF
          {
            "name": "CI Environment",
            "values": [
              {
                "key": "baseUrl",
                "value": "http://localhost:8081"
              },
              {
                "key": "admin_token",
                "value": "${{ steps.admin-token.outputs.admin_token }}"
              },
              {
                "key": "user_token",
                "value": "${{ steps.user-token.outputs.user_token }}"
              }
            ]
          }
          EOF

      - name: Run Newman Tests
        run: |
          echo "🧪 Running API tests for ${{ matrix.test-suite }}..."
          
          # Create reports directory
          mkdir -p reports
          
          # Run Newman with proper error handling
          set +e  # Don't exit on newman failure
          newman run Toolshop_APITesting.postman_collection.json \
            --folder "${{ matrix.test-suite }}" \
            --environment newman-environment.json \
            --reporters cli,htmlextra,junit \
            --reporter-htmlextra-export reports/newman-report-${{ matrix.test-suite }}.html \
            --reporter-junit-export reports/junit-report-${{ matrix.test-suite }}.xml \
            --delay-request 2000 \
            --timeout-request 15000 \
            --color on \
            --verbose
          
          NEWMAN_EXIT_CODE=$?
          set -e  # Re-enable exit on error
          
          echo "Newman exit code: $NEWMAN_EXIT_CODE"
          
          # Check if reports were generated
          if [ -f "reports/newman-report-${{ matrix.test-suite }}.html" ]; then
            echo "✅ HTML report generated"
          else
            echo "❌ HTML report not generated"
          fi
          
          if [ -f "reports/junit-report-${{ matrix.test-suite }}.xml" ]; then
            echo "✅ JUnit report generated"
          else
            echo "❌ JUnit report not generated"
          fi
          
          # Exit with Newman's exit code
          exit $NEWMAN_EXIT_CODE

      - name: Upload Test Reports
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-reports-${{ matrix.test-suite }}
          path: reports/
          retention-days: 30

      - name: Publish Test Results
        uses: dorny/test-reporter@v1
        if: always() && hashFiles('reports/junit-report-*.xml') != ''
        with:
          name: API Tests - ${{ matrix.test-suite }}
          path: reports/junit-report-${{ matrix.test-suite }}.xml
          reporter: java-junit

      - name: Container Diagnostics
        if: failure()
        run: |
          echo "🔍 Container diagnostics..."
          echo "=== Container Status ==="
          docker compose ps
          echo "=== API Container Logs ==="
          docker compose logs api
          echo "=== Database Container Logs ==="
          docker compose logs mariadb
          echo "=== System Resources ==="
          df -h
          free -h
          echo "=== Network Status ==="
          netstat -tlnp | grep :808

      - name: Cleanup
        if: always()
        run: |
          echo "🧹 Cleaning up Docker environment..."
          docker compose down -v --remove-orphans
          docker system prune -f
```

## 🔧 Additional Fixes Applied

1. **Docker Compose Command**: Changed from `docker-compose` to `docker compose`
2. **Better Error Handling**: Added HTTP status checking for API calls
3. **Resource Management**: Added disk space cleanup for GitHub runners
4. **Enhanced Logging**: More detailed container logs and diagnostics
5. **Timeout Handling**: Better timeout and retry logic
6. **Environment File**: Created proper Newman environment file
7. **Report Validation**: Check if reports are actually generated

## 🚀 Quick Fix Commands

If you want to quickly update your existing workflows:

```bash
# In your repository root
find .github/workflows -name "*.yml" -exec sed -i 's/docker-compose/docker compose/g' {} \;
```

## ✅ Testing the Fix

1. **Push the updated workflow** to your repository
2. **Monitor the Actions tab** for successful execution
3. **Check logs** for proper Docker container startup
4. **Verify reports** are generated and uploaded

This fixed version should resolve the `docker-compose: command not found` error and provide better debugging information if other issues occur.
