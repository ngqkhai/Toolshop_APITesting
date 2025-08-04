# GitHub Actions Workflow Validation Checklist

## ✅ Pre-Validation Steps

### 1. File Structure Validation
- [x] `docker-compose.yml` exists
- [x] `API/.env.example` exists  
- [x] `Toolshop_APITesting.postman_collection.json` exists
- [x] `_docker/` directory with Dockerfiles exists
- [x] `.github/workflows/api-tests.yml` exists

### 2. Configuration Validation
- [x] Docker Compose configuration is valid
- [x] Postman collection is valid JSON
- [x] All Docker build contexts exist

## 🔍 GitHub Actions Workflow Validation Steps

### Step 1: Syntax Validation
```bash
# Check YAML syntax locally
python -c "import yaml; yaml.safe_load(open('.github/workflows/api-tests.yml'))"
```

### Step 2: Workflow File Analysis
```bash
# Count workflow steps
grep -c "name:" .github/workflows/api-tests.yml
```

### Step 3: Environment Variables Check
- [x] `SPRINT_DIR` is set to `sprint5-with-bugs`
- [x] `BASE_URL` is set to `http://localhost:8091`
- [x] Database credentials are properly configured

### Step 4: Job Dependencies
- [x] `api-tests` depends on `setup-environment`
- [x] `full-regression-test` depends on `setup-environment`
- [x] `cleanup` depends on both test jobs

### Step 5: Docker Configuration in Workflow
- [x] Working directory is set correctly (`${{ env.SPRINT_DIR }}`)
- [x] Environment file creation is correct
- [x] Laravel .env configuration is complete

## 🚀 Testing the Workflow

### Local Testing (Before GitHub Actions)

1. **Test Docker Compose locally:**
```bash
cd sprint5-with-bugs
docker compose up -d --build
docker compose ps
```

2. **Test Database Connection:**
```bash
docker compose exec -T laravel-api php artisan migrate:status
```

3. **Test API Endpoints:**
```bash
curl http://localhost:8091/products
```

4. **Test Authentication:**
```bash
curl -X POST http://localhost:8091/users/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@practicesoftwaretesting.com","password":"welcome01"}'
```

5. **Test Newman Execution:**
```bash
newman run Toolshop_APITesting.postman_collection.json \
  --env-var "baseUrl=http://localhost:8091"
```

### GitHub Actions Testing

1. **Push to trigger workflow:**
```bash
git add .
git commit -m "Test workflow"
git push origin main
```

2. **Check workflow status on GitHub:**
   - Go to repository → Actions tab
   - Check latest workflow run
   - Review logs for each job

3. **Monitor specific steps:**
   - Environment setup logs
   - Database connection logs
   - API test execution logs

## 🐛 Common Issues and Solutions

### Issue 1: Database Connection Timeout
**Symptoms:** "Database not ready, waiting 10 seconds..."
**Solutions:**
- Increase wait time in Docker setup
- Check MariaDB service status
- Verify database credentials

### Issue 2: Authentication Token Failure
**Symptoms:** "Failed to get admin/user token"
**Solutions:**
- Verify seeded user credentials
- Check API endpoint availability
- Validate Laravel application startup

### Issue 3: Newman Test Failures
**Symptoms:** Newman exits with error code
**Solutions:**
- Verify Postman collection folder names
- Check API endpoint responses
- Validate environment variables

### Issue 4: Docker Build Failures
**Symptoms:** Docker compose up fails
**Solutions:**
- Check Dockerfile syntax
- Verify build context paths
- Review Docker logs

## 📊 Workflow Success Indicators

### ✅ Successful Run Indicators:
- All Docker services start successfully
- Database migrations run without errors
- API endpoints respond correctly
- Authentication tokens are obtained
- Newman tests execute and generate reports
- Test artifacts are uploaded

### ❌ Failure Indicators:
- Services fail to start within timeout
- Database connection failures
- API endpoints return errors
- Authentication failures
- Newman test failures
- Missing test reports

## 🔧 Workflow Optimization Tips

1. **Parallel Execution:**
   - Matrix strategy for test suites
   - Independent test execution

2. **Caching:**
   - Docker layer caching
   - Node.js dependencies caching

3. **Artifact Management:**
   - Test reports retention
   - Cleanup of old artifacts

4. **Error Handling:**
   - Proper error reporting
   - Conditional step execution
   - Cleanup on failure

## 📝 Next Steps After Validation

1. **If validation passes:**
   - Commit and push changes
   - Monitor first workflow run
   - Review test reports

2. **If validation fails:**
   - Fix identified issues
   - Re-run local tests
   - Validate again before pushing

3. **Ongoing monitoring:**
   - Set up workflow status badges
   - Monitor workflow performance
   - Regular maintenance and updates
