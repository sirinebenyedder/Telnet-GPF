# Telnet-GPF

This repository contains a responsive web and mobile platform designed for enterprise project management and automated invoice tracking. Built as a comprehensive graduation project, the system combines a customized corporate workflow with AI to simplify document processing.

---

## 🏗️ Project Architecture

The ecosystem is divided into independent components to separate application responsibilities from the MLOps infrastructure:

* **Frontend (`front/`):** Mobile application developed with **Flutter**, handling the user interface and document capture.
* **Backend (`back/`):** 
  * **Node.js + Express (`back/node/`):** Main orchestration API for business logic and user management.
  * **Python + Flask (`back/ner/`):** Dedicated AI inference microservice that loads the document processing model.
* **Model (`layoutlm/`):** Standalone directory reserved for the final weights, configurations, and vocabulary tokens of the fine-tuned multimodal model. *LayoutLM is a research model developed by Microsoft Research; for more context, please refer to the official documentation and research papers.*
* **MLOps Pipeline (`Gitlab/`):** Source code from the GitLab project containing data preprocessing and training scripts. The model is integrated into a CI/CD loop for continuous improvement.

---

## ⚠️ Configuration Note

> **Notice:** This repository contains the core architectural blocks of the project. It is not a final application designed to work instantly without setup.

To connect and run these modules locally, you must manually:
1. **Adjust the server ports and API URLs** so the separate backend services can call each other.
2. **Update the local paths** to point to your files and directories.
3. **Create the `config.json` file** inside the `layoutlm/` directory to define your local `model_path` and metrics, as this environment configuration is not provided by default.

📄 **[Click here to open the complete Graduation Report](./french-report.pdf?raw=true)**
