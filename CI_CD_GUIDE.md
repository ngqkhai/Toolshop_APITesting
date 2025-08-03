# 🚀 Toolshop API Testing CI/CD Guide

This guide explains how to set up and use the complete CI/CD pipeline for Toolshop API testing in the `sprint5-with-bugs` environment.

## 📁 Project Structure

```
sprint5-with-bugs/
├── .github/workflows/           # GitHub Actions workflows
│   ├── api-tests.yml           # Main CI/CD pipeline
│   ├── nightly-tests.yml       # Scheduled testing
│   ├── manual-testing.yml      # Manual environment control
│   └── validate-collection.yml # Collection validation
├── Toolshop_APITesting.postman_collection.json
├── test.case.csv
├── docker-compose.yml
└── API/                        # Laravel API source code
```

## 🔧 Setup Instructions

### 1. Prerequisites

- GitHub repository with the `sprint5-with-bugs` folder
- Docker installed on your local machine
- Postman (optional, for manual testing)

### 2. Repository Setup

1. **Push the workflow files** to your GitHub repository:
   ```bash
   git add sprint5-with-bugs/.github/workflows/
   git commit -m "Add API testing CI/CD workflows"
   git push origin main
   ```

2. **Enable GitHub Actions** in your repository:
   - Go to your repository on GitHub
   - Click on the "Actions" tab
   - If prompted, click "I understand my workflows"

### 3. Environment Variables (Optional)

You can configure custom environment variables in your repository settings:

- Go to **Settings** → **Secrets and variables** → **Actions**
- Add repository secrets if needed:
  - `CUSTOM_API_URL`: Override default API URL
  - `SLACK_WEBHOOK`: For notifications (future enhancement)

## 🚦 Workflow Triggers

### 1. Automatic Testing (`api-tests.yml`)

**Triggers:**
- Push to `main` branch (affecting sprint5-with-bugs files)
- Pull requests targeting `main` branch
- Manual dispatch

**What it does:**
- ✅ Validates collection and CSV files
- 🐳 Sets up Docker environment
- 🔐 Manages authentication tokens
- 🧪 Runs comprehensive API tests
- 📊 Generates HTML and JUnit reports
- 📈 Updates test status and coverage

### 2. Scheduled Testing (`nightly-tests.yml`)

**Triggers:**
- Scheduled: Every day at 2:00 AM UTC
- Manual dispatch

**What it does:**
- 🌙 Runs full regression testing
- 📧 Generates detailed test reports
- 🚨 Provides failure notifications
- 📊 Tracks test trends over time

### 3. Manual Environment Control (`manual-testing.yml`)

**Triggers:**
- Manual dispatch only

**Actions available:**
- `start`: Start the testing environment
- `test`: Run tests on existing environment
- `restart`: Restart and test
- `stop`: Stop the environment

### 4. Collection Validation (`validate-collection.yml`)

**Triggers:**
- Changes to Postman collection
- Changes to test case CSV

**What it does:**
- ✅ Validates JSON structure
- 📊 Counts test cases
- 🔍 Cross-validates collection and CSV
- 📝 Generates validation reports

## 🎯 How to Use

### Running Manual Tests

1. **Start Environment:**
   - Go to **Actions** → **Manual Testing Environment**
   - Click **Run workflow**
   - Select action: `start`
   - Click **Run workflow**

2. **Run Tests:**
   - Go to **Actions** → **Manual Testing Environment**
   - Click **Run workflow**
   - Select action: `test`
   - Click **Run workflow**

3. **Stop Environment:**
   - Select action: `stop`
   - Click **Run workflow**

### Viewing Test Results

1. **Go to Actions tab** in your GitHub repository
2. **Click on a workflow run** to see details
3. **Check the Summary** for:
   - Test execution status
   - HTML reports (downloadable)
   - JUnit results
   - Coverage information

### Test Reports

The workflows generate several types of reports:

- **HTML Report**: Detailed Newman HTML report with request/response details
- **JUnit XML**: Machine-readable test results for CI/CD integration
- **Summary Report**: GitHub Actions summary with key metrics

## 📊 Test Coverage

### Current API Coverage (32 endpoints)

| Module | Endpoints | Test Cases |
|--------|-----------|------------|
| **Brand Management** | 5 | 7 |
| **User Management** | 8 | 8 |
| **Product Management** | 8 | 7 |
| **Favorites Management** | 3 | 3 |
| **Other Endpoints** | 8 | 2 |

### Test Types

- ✅ **Functional Tests**: API endpoint functionality
- 🔐 **Authentication Tests**: JWT token validation
- ❌ **Error Handling**: Invalid input validation
- 📊 **Data Validation**: Response schema validation
- 🚀 **Performance**: Response time checks

## 🛠️ Troubleshooting

### Common Issues

1. **Environment Startup Fails**
   ```bash
   # Check if ports are available
   docker ps
   netstat -an | findstr :8081
   ```

2. **Authentication Fails**
   - Check if admin/user accounts exist in database
   - Verify JWT token generation
   - Check token expiration

3. **Test Collection Invalid**
   - Validate JSON format
   - Check endpoint URLs
   - Verify variable usage

### Debug Commands

```bash
# Check container logs
docker logs sprint5-with-bugs-api-1

# Verify database connection
docker exec -it sprint5-with-bugs-mariadb-1 mysql -u root -p

# Test API manually
curl -X GET http://localhost:8081/brands
```

## 🔄 Workflow Customization

### Modifying Test Triggers

Edit the workflow files to change triggers:

```yaml
on:
  push:
    branches: [ main, develop ]  # Add more branches
  schedule:
    - cron: '0 6 * * *'          # Change schedule
```

### Adding New Test Environments

1. **Copy existing workflow**
2. **Modify environment variables**
3. **Update Docker compose file reference**
4. **Adjust port mappings**

### Custom Notifications

Add notification steps to workflows:

```yaml
- name: Notify on Failure
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: failure
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## 📈 Best Practices

### Development Workflow

1. **Feature Development:**
   - Create feature branch
   - Update API endpoints
   - Update Postman collection
   - Update CSV test cases
   - Create pull request

2. **Testing:**
   - Automatic validation on PR
   - Manual testing before merge
   - Regression testing after merge

3. **Monitoring:**
   - Check nightly test results
   - Monitor test trends
   - Update tests for new features

### Collection Maintenance

- ✅ Keep collection and CSV synchronized
- ✅ Use descriptive test case names
- ✅ Include both positive and negative tests
- ✅ Validate response schemas
- ✅ Test error conditions

## 🚀 Future Enhancements

- [ ] Integration with external monitoring tools
- [ ] Performance testing automation
- [ ] Load testing scenarios
- [ ] Security testing integration
- [ ] Multi-environment testing
- [ ] Test data management
- [ ] Advanced reporting dashboards

## 📞 Support

For issues or questions:

1. Check the **Actions** logs for detailed error messages
2. Review the **troubleshooting** section above
3. Validate your collection using the validation workflow
4. Check Docker container logs for environment issues

---

**Happy Testing! 🎉**
