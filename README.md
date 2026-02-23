# project-ansible-serverless

--

# 📘 **Automation Platform — Terraform + Ansible + AWS Lambda**

A fully automated, production‑style serverless platform built with **Terraform**, **Ansible**, **AWS Lambda**, **SSM Parameter Store**, **S3**, **CloudWatch**, and **GitHub Actions CI/CD**.

This project demonstrates real‑world DevOps practices:

- Infrastructure as Code (Terraform)  
- Configuration as Code (Ansible)  
- Serverless automation (Lambda)  
- Secure configuration (SSM)  
- Observability (CloudWatch Logs + Alarms)  
- CI/CD (GitHub Actions)  
- Environment‑safe deployments  
- Zero‑drift environment variable management  

---

# 📁 **Directory Structure**

```
project-ansible-serverless/
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── lambda/
│   │   └── lambda_function.py
│   └── versions.tf
│
├── ansible/
│   ├── playbooks/
│   │   ├── configure-ssm.yml
│   │   ├── configure-lambda-env.yml
│   │   └── configure-s3.yml
│   └── inventory
│
├── .github/
│   └── workflows/
│       └── deploy.yml
│
├── README.md
└── .gitignore
```

---

# 🏗️ **Architecture Overview**

This automation platform performs the following:

### **1. Terraform (Provisioning Layer)**  
Terraform deploys:

- AWS Lambda function  
- IAM roles & policies  
- S3 bucket for reports  
- SSM Parameter Store configuration  
- CloudWatch log groups  
- EventBridge schedule (optional)

### **2. Ansible (Configuration Layer)**  
Ansible safely configures:

- SSM parameters  
- Lambda environment variables (merged, never overwritten)  
- S3 bucket settings  

### **3. Lambda Automation**  
The Lambda function:

- Reads configuration from SSM  
- Generates a JSON report  
- Uploads it to S3  
- Validates the upload  
- Emits structured logs  

### **4. CI/CD Pipeline (GitHub Actions)**  
Every push to `main` triggers:

1. Terraform init → fmt → plan → apply  
2. Ansible configuration  
3. Lambda update  
4. Full deployment to AWS  

This ensures **zero manual deployment steps**.

---

# 🚀 **Testing For Outputs**
---

# ✅ **1. Test Lambda via AWS Console**

1. Go to **AWS Console → Lambda → automation‑dev**  
2. Click **Test**  
3. Use this payload:

```json
{}
```

4. Run the test.

You should see output similar to:

```json
{
  "status": "ok",
  "validated": true,
  "report_key": "reports/123456789.json"
}
```

This confirms:

- Lambda executed  
- SSM parameters loaded  
- Report written to S3  
- Validation succeeded  

---

# ✅ **2. Test the S3 Report Output**

1. Go to **AWS Console → S3**  
2. Open the bucket:

```
debo-automation-reports-dev
```

3. Navigate to:

```
reports/
```

You should see files like:

```
1771810901.json
1771810902.json
```

Open one to confirm the JSON report.

---

# ✅ **3. Test via AWS CLI**

If the tester has AWS CLI configured:

### **Invoke Lambda**

```bash
aws lambda invoke \
  --function-name automation-dev \
  out.json
```

View the output:

```bash
cat out.json
```

Expected:

```json
{
  "status": "ok",
  "validated": true
}
```

### **List S3 Reports**

```bash
aws s3 ls s3://debo-automation-reports-dev/reports/
```

### **Fetch a report**

```bash
aws s3 cp s3://debo-automation-reports-dev/reports/<filename>.json .
```

---

# 📊 **Observability & Monitoring**

### **CloudWatch Logs**

Navigate to:

```
CloudWatch → Logs → /aws/lambda/automation-dev
```

You will see structured JSON logs such as:

```
{"action": "report_written", "key": "reports/1771810901.json"}
{"action": "report_validated", "valid": true}
```

### **CloudWatch Alarms (Optional)**

If enabled, alarms will trigger on:

- Lambda errors  
- Missing reports  
- Validation failures  

---

# 🔄 **CI/CD Pipeline (GitHub Actions)**

The pipeline runs automatically on every push to `main`.

### **Pipeline Stages**

| Stage | Description |
|-------|-------------|
| Checkout | Pulls repo code |
| AWS CLI Install | Installs AWS CLI v2 |
| AWS Credentials | Injects GitHub Secrets |
| Terraform Init | Initializes backend |
| Terraform Fmt | Enforces formatting |
| Terraform Plan | Shows changes |
| Terraform Apply | Deploys infra |
| Ansible | Configures SSM, Lambda, S3 |
| Complete | Deployment successful |


---

# 🧪 **Local Development Commands**

### **Terraform**

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### **Ansible**

```bash
cd ansible
ansible-playbook playbooks/configure-lambda-env.yml
```

---


