# 🚀 Setting Up Toolshop API CI/CD in Your Own GitHub Repository

This guide helps you set up the complete CI/CD pipeline for Toolshop API testing in your own GitHub repository.

## 📋 Prerequisites

- Your own GitHub account
- Git installed on your machine
- Docker Desktop installed

## 🔧 Step-by-Step Setup

### 1. Create Your Repository

1. **Go to GitHub** and create a new repository (e.g., `toolshop-api-testing`)
2. **Initialize** with README (optional)
3. **Clone** to your local machine:
   ```bash
   git clone https://github.com/YOUR_USERNAME/toolshop-api-testing.git
   cd toolshop-api-testing
   ```

### 2. Copy Project Files

Copy these essential files from your `sprint5-with-bugs` folder to your new repository:

```
your-repo/
├── .github/
│   └── workflows/
│       ├── api-tests.yml
│       ├── nightly-tests.yml
│       ├── manual-testing.yml
│       └── validate-collection.yml
├── docker-compose.yml
├── Toolshop_APITesting.postman_collection.json
├── test.case.csv
├── CI_CD_GUIDE.md
└── API/ (entire folder with Laravel application)
```

### 3. Update GitHub Actions Workflows

Since the folder structure might be different, you may need to update the workflow files:

#### Update Working Directory References

In each workflow file (`.github/workflows/*.yml`), check the `env` section:

```yaml
env:
  SPRINT_DIR: .  # Change this if files are in root
  # OR
  SPRINT_DIR: sprint5-with-bugs  # Keep if you maintain folder structure
```

#### For Root Level Setup

If you place files in the repository root, update all workflow files:

**Replace this in all workflow files:**
```yaml
env:
  SPRINT_DIR: sprint5-with-bugs
```

**With this:**
```yaml
env:
  SPRINT_DIR: .
```

### 4. Repository Structure Options

Choose one of these structures:

#### Option A: Root Level (Recommended)
```
your-repo/
├── .github/workflows/
├── docker-compose.yml
├── Toolshop_APITesting.postman_collection.json
├── test.case.csv
├── API/
└── README.md
```

#### Option B: Keep Sprint Folder Structure
```
your-repo/
├── sprint5-with-bugs/
│   ├── .github/workflows/
│   ├── docker-compose.yml
│   ├── Toolshop_APITesting.postman_collection.json
│   ├── test.case.csv
│   └── API/
└── README.md
```

### 5. Environment Configuration

#### Docker Compose Updates

Ensure your `docker-compose.yml` has correct port mappings:

```yaml
version: '3.8'
services:
  api:
    build: ./API
    ports:
      - "8081:80"  # Make sure port 8081 is available
    # ... rest of configuration
```

#### API Configuration

Update API configuration if needed:
- Database connection strings
- JWT secret keys
- CORS settings

### 6. Push to Your Repository

```bash
# Add all files
git add .

# Commit changes
git commit -m "Add Toolshop API testing CI/CD pipeline"

# Push to GitHub
git push origin main
```

### 7. Enable GitHub Actions

1. **Go to your repository** on GitHub
2. **Click Actions tab**
3. **Enable workflows** if prompted
4. **Workflows will appear** after first push

### 8. Test the Setup

#### Manual Test
1. Go to **Actions** → **Manual Testing Environment**
2. Click **Run workflow**
3. Select action: `start`
4. Monitor execution

#### Automatic Test
1. Make any small change to a file
2. Commit and push
3. Check **Actions** tab for automatic execution

## ⚙️ Configuration Adjustments

### Port Conflicts

If port 8081 is already in use:

1. **Update docker-compose.yml:**
   ```yaml
   ports:
     - "8082:80"  # Use different port
   ```

2. **Update workflow files** to use new port:
   ```yaml
   env:
     API_BASE_URL: http://localhost:8082
   ```

### Database Configuration

Update API environment variables in `docker-compose.yml`:

```yaml
environment:
  - DB_HOST=mariadb
  - DB_DATABASE=toolshop
  - DB_USERNAME=toolshop_user
  - DB_PASSWORD=toolshop_password
```

### Custom Environment Variables

Add repository secrets in GitHub:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Add secrets:
   - `API_ADMIN_EMAIL`: Admin login email
   - `API_ADMIN_PASSWORD`: Admin password
   - `NOTIFICATION_WEBHOOK`: For alerts

## 🚨 Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Windows
   netstat -an | findstr :8081
   
   # Kill process if needed
   taskkill /PID <PID> /F
   ```

2. **Docker Permission Issues**
   ```bash
   # Ensure Docker Desktop is running
   docker version
   ```

3. **GitHub Actions Failing**
   - Check repository permissions
   - Verify file paths in workflows
   - Check Docker compose syntax

### Validation Commands

```bash
# Test docker compose locally
docker-compose up -d

# Validate Postman collection
newman run Toolshop_APITesting.postman_collection.json --delay-request 1000

# Check API health
curl http://localhost:8081/brands
```

## 📊 Monitoring Your CI/CD

### Dashboard Access

After setup, monitor your API testing:

1. **Actions Tab**: View all workflow runs
2. **Test Reports**: Download HTML reports from workflow artifacts
3. **Notifications**: Set up email notifications for failures

### Key Metrics to Track

- ✅ Test pass/fail rates
- ⏱️ Test execution time
- 🔄 Deployment frequency
- 🚨 Mean time to recovery

## 🎯 Next Steps

1. **Customize** test cases for your specific needs
2. **Add** additional API endpoints
3. **Configure** notifications and monitoring
4. **Set up** staging/production environments
5. **Integrate** with other tools (Slack, JIRA, etc.)

## 🤝 Best Practices

- ✅ Keep secrets in GitHub repository secrets
- ✅ Use descriptive commit messages
- ✅ Review pull requests before merging
- ✅ Monitor test results regularly
- ✅ Update test cases when API changes

---

**You're all set! Your own Toolshop API testing CI/CD pipeline is ready to go! 🎉**
