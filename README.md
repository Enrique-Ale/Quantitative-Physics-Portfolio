# Quantitative Analysis & Stochastic Modeling Portfolio

![Python](https://img.shields.io/badge/Python-3.8%2B-blue) ![MATLAB](https://img.shields.io/badge/MATLAB-R2023a-orange) ![Status](https://img.shields.io/badge/Status-Active-success)

## Overview
This repository serves as a technical portfolio demonstrating the application of **Physics-based numerical methods** to solve data-intensive problems. It bridges the gap between theoretical frameworks (Stochastic Processes, Signal Processing) and practical computational implementation.

The projects included showcase skills in **vectorized computing**, **automated data cleaning (ETL)**, and **non-linear parameter estimation**, skills directly transferable to **Quantitative Finance** and **Credit Strategy** domains.

---

## Project 1: 2D Random Walk Simulation (Vectorized)
**File:** `random_walk_vectorized.py`

### Description
A high-performance simulation of a 2D Lattice Random Walk, a fundamental stochastic process analogous to **Brownian Motion** used in financial market modeling and diffusion risk analysis.

### Technical Highlights
* **Vectorization:** Refactored procedural loops into **NumPy** matrix operations (`np.cumsum`, `fancy indexing`), optimizing memory usage and execution time for $N > 10^5$ steps.
* **Visualization:** Implemented clear data visualization using Matplotlib to map the stochastic trajectory.
* **Relevance:** Demonstrates understanding of **Markov Processes** and efficient algorithmic design.

![Random Walk Output](random_walk_results.png)
*(Example output: Stochastic trajectory for N=50,000 steps)*

---

## Project 2: Spectral Data ETL & Analysis Pipeline
**File:** `spectral_analysis_pipeline.m`

### Description
An automated pipeline developed in **MATLAB** to ingest, clean, and analyze raw spectrophotometry data from Single Crystal Silicon Thin Films.

### Key Features
* **Automated ETL:** Ingests batch data from multiple sensors automatically.
* **Advanced Despiking:** Implements statistical outlier detection (`filloutliers`) to remove cosmic ray artifacts without distorting the signal.
* **Visualization:** Generates comparative spectral analysis with auto-scaling logic.

![Silicon Spectra](silicon_thin_films_spectra.png)

---

## Project 3: Indirect Band Gap Analysis (Silicon)
**File:** `silicon_indirect_analysis.m`

### Description
A specialized algorithm implementing the **Essick Method** to analyze Silicon (Si), an indirect band gap semiconductor. Unlike direct materials, Silicon's absorption requires phonon interaction, creating a complex non-linear spectral response.

### Technical Highlights
* **Signal Decomposition:** Identifies and separates two distinct linear regions in the absorption spectrum: Phonon Absorption ($E_g - E_p$) and Phonon Emission ($E_g + E_p$).
* **Dual-Slope Regression:** Performs automated linear fitting on distinct spectral bands to solve a system of equations for Band Gap ($E_g$) and Phonon Energy ($E_p$).
* **Physics-to-Finance:** This logic parallels **seasonality decomposition** in time-series data, where a signal is split into trend and periodic components.

![Silicon Analysis](silicon_analysis.png)

---

## Project 4: Direct Band Gap & Thickness Calculation (ZnTe)
**File:** `znte_direct_gap_analysis.m`

### Description
Analysis of Zinc Telluride (ZnTe) thin films using the **Swanepoel Method**. This script utilizes the interference fringes observed in the transmission spectrum to simultaneously derive the film's thickness and its optical constants.

### Technical Highlights
* **Swanepoel Algorithm:** Implements the envelope method logic to extract refractive index ($n$) and thickness ($d$) from spectral minima/maxima.
* **Direct Gap Modeling:** Unlike Silicon, ZnTe is a direct gap semiconductor. The script applies the standard Tauc model $(\alpha h \nu)^2$ for band gap estimation.
* **Hybrid Peak Detection:** Combines automated signal processing with manual override capabilities to handle experimental artifacts in real-world data.

![Spectral Analysis](znte_analysis.png)

---

## 🛠 Tools & Technologies
* **Languages:** Python (NumPy, Matplotlib), MATLAB.
* **Concepts:** Monte Carlo Simulations, Time Series Analysis, Experimental Design, Numerical Optimization.

## Usage
To run the Python simulation locally:

```bash
# Clone the repository
git clone [https://github.com/tu-usuario/Quantitative-Physics-Portfolio.git](https://github.com/tu-usuario/Quantitative-Physics-Portfolio.git)

# Install dependencies
pip install numpy matplotlib

# Run the script
python random_walk_vectorized.py
