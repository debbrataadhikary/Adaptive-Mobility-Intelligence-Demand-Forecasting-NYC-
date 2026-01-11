# Adaptive Mobility Intelligence & Demand Forecasting (NYC)

### **Executive Summary**
This project engineers a high-performance **Adaptive Intelligence System** to analyze and forecast demand across **19M+ NYC ride records** (Uber, Lyft, and other providers). By integrating long-term baselines with short-term moving trends, the system identifies "Abnormal Momentum" and "Critical Systemic Peaks," translating raw big data into executive-grade operational insights.

---

## 🚀 Key Technical Features

### **1. Hybrid Intelligence Engine**
Developed a dual-layered statistical engine that separates:
* **Global Baselines:** Long-term seasonal norms for stable forecasting.
* **Adaptive Trends:** 30-day moving windows to detect rapid shifts in urban mobility patterns.

### **2. Model Trust Index (MTI)**
Implemented a **Governance Layer** that flags analytical outputs as either *'Learning Phase'* or *'High Reliability'* based on historical data depth, ensuring high confidence in automated decision-making.

### **3. Advanced Statistical Inference**
* **Adaptive Z-Score:** Dynamic anomaly detection that adjusts based on global standard deviation.
* **Trend Divergence %:** Identifies "Abnormal Momentum" (±25% shifts) by comparing real-time volume against recent moving averages.
* **Dynamic Surge Score:** A normalized 0–100 scale designed for operational teams to prioritize resource allocation instantly.

### **4. Big Data Optimization**
* Architected using **PostgreSQL Materialized Views** for performance tuning.
* Advanced use of **Window Functions** (`PARTITION BY`, `ROWS BETWEEN`) for multi-provider schema unification without data leakage.

---

## 🛠 Tech Stack
* **Language:** SQL (PostgreSQL)
* **Specialties:** Feature Engineering, Time-Series Analysis, ETL Pipelines, Statistical Modeling.
* **BI Ready:** Engineered with spatial keys and KPI layers for seamless **Power BI** integration.

---

## 📂 Project Architecture (SQL Flow)
1.  **Phase 1: Unified Schema** – Integrating diverse data sources (Uber, Lyft, Dial7).
2.  **Phase 2: Feature Engineering** – Extracting temporal and contextual features (Holidays vs. Workdays).
3.  **Phase 3 & 4: Stats Engine** – Generating global and 30-day windowed averages.
4.  **Phase 5: Inference Layer** – Calculating Z-Scores and Divergence percentages.
5.  **Phase 6 & 7: Governance & Output** – Final decision labels and Market Share analysis.

---

## 📊 Sample Output KPIs
* **Demand Intelligence Labels:** Categorizes every hour as *Baseline Normal*, *Abnormal Momentum*, *High Demand*, or *Critical Peak*.
* **Market Share %:** Real-time tracking of provider dominance across NYC.
* **Dynamic Surge Score:** Real-time intensity metric for fleet management.

---

## 📖 How to Use
1.  **Clone the repository.**
2.  Run the provided **`.sql`** script in a PostgreSQL environment.
3.  Access the `view_nyc_ride_intelligence` materialized view for downstream BI reporting.

---

## 🤝 Connect with Me
**Debbrata Kumar Adhikary** 🔗 **LinkedIn:** [linkedin.com/in/debbrata-adhikary](https://www.linkedin.com/in/debbrata-adhikary/)  
🌐 **Website:** [www.debadhikary.com](http://www.debadhikary.com)  
📧 **Email:** [adhikarydeb111@gmail.com](mailto:adhikarydeb111@gmail.com)
