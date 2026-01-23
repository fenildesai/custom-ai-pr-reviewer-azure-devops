# 🏏 AI-Powered PR Reviewer for Azure DevOps

[![Azure DevOps](https://img.shields.io/badge/Azure_DevOps-0078D7?style=for-the-badge&logo=azure-devops&logoColor=white)](https://dev.azure.com)
[![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://github.com/PowerShell/PowerShell)
[![Azure OpenAI](https://img.shields.io/badge/Azure_OpenAI-00A4EF?style=for-the-badge&logo=openai&logoColor=white)](https://azure.microsoft.com/en-us/products/ai-services/openai-service)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

## 📋 Summary
An automated Pull Request review system integrated directly into **Azure DevOps pipelines** using **PowerShell**, leveraging **Azure OpenAI** to provide intelligent implementation feedback and code quality checks.

---

## 🚩 Problem
Manual code reviews are essential but face significant challenges:
*   **Time Consuming:** Delays in feedback loops slow down the entire development cycle.
*   **Human Fatigue:** Reviewers miss subtle bugs or style violations after long hours.
*   **Context Switching:** Architectural standards documented in markdown files are frequently overlooked.
*   **Inconsistency:** Different reviewers apply different standards.

## 💡 Solution
We introduce a **"Direct Pipeline"** integration:
*   **Runtime:** A lightweight PowerShell script running within the PR validation build.
*   **Context Aware:** Automatically reads `project_context.md` to understand *your* specific architectural rules.
*   **Smart Analysis:** Identifies changes via `git diff` and queries Azure OpenAI with a tailored prompt.
*   **Automated Feedback:** Posts constructive comments directly to the Azure DevOps PR threads.

---

## 🏗️ High Level Architecture

1.  **Trigger:** 👤 Developer raises a Pull Request in Azure DevOps.
2.  **Pipeline:** 🚀 The PR Build Pipeline triggers (YAML).
3.  **Checkout:** 📥 Agent checks out source code & documentation.
4.  **Analysis:** 🧠 PowerShell script reads context & diffs.
5.  **AI:** 🤖 Payload sent to Azure OpenAI API.
6.  **Loop:** 💬 Comments posted back to PR via ADO REST API.

![High Level Architecture](architecture.png)

---

## 🚀 Business Benefits

| Benefit | Impact |
| :--- | :--- |
| **Speed** | ⚡ **~30% faster** approval cycles via instant feedback. |
| **Quality** | 🛡️ **Consistent** application of architectural standards. |
| **Cost** | 💰 **Low Cost** - uses existing pipeline minutes, no extra Azure resources. |
| **Context** | 📚 **Smarter than Linting** - understands documentation intent. |
