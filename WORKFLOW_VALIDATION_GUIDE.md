# 🛡️ GitHub Actions Workflow Validation Guide

This guide helps you validate your GitHub Actions workflows before pushing to GitHub to avoid deployment failures.

## ✅ **Validation Results (Current Status)**

### YAML Syntax Check
- ✅ `api-tests.yml` - Valid YAML
- ✅ `nightly-tests.yml` - Valid YAML  
- ✅ `manual-testing.yml` - Valid YAML
- ✅ `toolshop-api-tests.yml` - Valid YAML

### Docker Compose Configuration
- ✅ `docker-compose.yml` - Valid configuration
- ⚠️ Minor warnings (version field obsolete, but not breaking)

---

## 🔧 **Local Validation Methods**

### 1. **YAML Syntax Validation**

```bash
# Install YAML linter
npm install -g yaml-lint

# Validate individual workflow files
yamllint .github/workflows/api-tests.yml
yamllint .github/workflows/nightly-tests.yml
yamllint .github/workflows/manual-testing.yml
yamllint .github/workflows/toolshop-api-tests.yml
```

### 2. **Docker Compose Validation**

```bash
# Validate docker-compose.yml syntax
docker compose config

# Test if services can be built (dry run)
docker compose build --dry-run

# Check if images can be pulled
docker compose pull --ignore-pull-failures
```

### 3. **GitHub Actions Local Testing**

```bash
# Install act (GitHub Actions local runner)
# Windows (using chocolatey):
choco install act-cli

# Or download from: https://github.com/nektos/act/releases

# Run workflows locally
act -l                           # List all workflows
act push                         # Simulate push event
act workflow_dispatch            # Simulate manual trigger
```

### 4. **Newman/Postman Collection Validation**

```bash
# Install Newman globally
npm install -g newman

# Validate Postman collection syntax
newman run Toolshop_APITesting.postman_collection.json --dry-run

# Test collection without environment (basic validation)
newman run Toolshop_APITesting.postman_collection.json --reporters cli
```

---

## 🚀 **Step-by-Step Pre-Push Checklist**

### Phase 1: Syntax Validation
- [ ] YAML files pass `yamllint` validation
- [ ] Docker Compose config validates with `docker compose config`
- [ ] Postman collection validates with `newman --dry-run`

### Phase 2: Local Testing
- [ ] Docker containers build successfully: `docker compose build`
- [ ] Services start without errors: `docker compose up -d`
- [ ] API endpoints respond: `curl http://localhost:8091/products`
- [ ] Newman tests run locally: `newman run collection.json`

### Phase 3: Environment Verification
- [ ] All required environment variables are defined
- [ ] File paths in workflows match actual project structure
- [ ] Docker build contexts point to correct directories
- [ ] Port mappings don't conflict with other services

### Phase 4: GitHub-Specific Checks
- [ ] Workflow triggers are correctly configured
- [ ] Secrets and environment variables are set in GitHub repo
- [ ] Branch protection rules allow workflow execution
- [ ] Artifact upload paths are correct

---

## 🧪 **Quick Local Test Commands**

### Test 1: Full Stack Startup
```bash
# Clean start
docker compose down -v
docker compose up -d --build

# Wait for services
timeout 60

# Health check
curl -f http://localhost:8091/products
```

### Test 2: API Authentication
```bash
# Test admin login
curl -X POST http://localhost:8091/users/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@practicesoftwaretesting.com","password":"welcome01"}'
```

### Test 3: Newman Collection
```bash
# Run specific folder (e.g., Product Management)
newman run Toolshop_APITesting.postman_collection.json \
  --folder "Product Management" \
  --reporters cli,html \
  --reporter-html-export newman-report.html
```

---

## 🔍 **Common Issues & Solutions**

### Issue 1: Docker Compose V2 Compatibility
**Problem:** `docker-compose: command not found`
**Solution:** ✅ **Already Fixed** - All workflows use `docker compose` (V2 syntax)

### Issue 2: Build Context Issues
**Problem:** `COPY failed: file not found`
**Solution:** ✅ **Already Fixed** - Build contexts point to `../_docker`

### Issue 3: Port Conflicts
**Problem:** `Port already in use`
**Solution:** Check for running containers: `docker ps` and stop conflicts

### Issue 4: Authentication Failures
**Problem:** Newman tests fail with 401 errors
**Solution:** Verify test user credentials and token generation

### Issue 5: Timeout Issues
**Problem:** Services don't start in time
**Solution:** Increase sleep duration or add proper health checks

---

## 🎯 **GitHub Actions Debugging**

### Enable Debug Logging
Add to your repository secrets:
- `ACTIONS_STEP_DEBUG` = `true`
- `ACTIONS_RUNNER_DEBUG` = `true`

### Workflow File Validation Tools
- **Online:** [GitHub Actions Workflow Validator](https://rhymond.github.io/gh-actions-yaml-generator/)
- **VS Code:** GitHub Actions extension for syntax highlighting
- **CLI:** `act --dry-run` for workflow simulation

### Artifact Collection
Workflows are configured to collect:
- Newman HTML reports
- Newman JUnit XML reports  
- Docker logs on failure
- Test execution summaries

---

## 📋 **Final Pre-Push Command Sequence**

```bash
# 1. Validate all files
yamllint .github/workflows/*.yml
docker compose config

# 2. Test local environment
docker compose down -v
docker compose up -d --build
sleep 90

# 3. Verify services
curl -f http://localhost:8091/products

# 4. Test Newman collection
newman run Toolshop_APITesting.postman_collection.json \
  --folder "Product Management" \
  --reporters cli

# 5. Cleanup
docker compose down -v

# 6. If all tests pass, push to GitHub
git add .
git commit -m "Update workflows with Docker Compose V2 compatibility"
git push origin main
```

---

## ✅ **Current Workflow Status**

Your workflows are now **ready for deployment** with the following improvements:
- ✅ Docker Compose V2 compatibility
- ✅ Brand Management API removed
- ✅ Health checks updated to use `/products`
- ✅ All YAML syntax validated
- ✅ Proper error handling and logging

**Recommendation:** You can safely push to GitHub. The workflows should execute successfully.
