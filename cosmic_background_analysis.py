
# -*- coding: utf-8 -*-
"""
Cosmic Microwave Background (CMB) Analysis Pipeline
Author: Enrique A. Alcantara
Description: 
    Full pipeline analysis of COBE/FIRAS public data.
    1. Ingestion: Fetches data directly from NASA servers (Remote ETL).
    2. Fallback: Uses local data if connection fails.
    3. Modeling: Fits Planck's Black Body radiation law.
    
    Data Source: NASA Legacy Archive (LAMBDA).
    URL: https://lambda.gsfc.nasa.gov/product/cobe/firas_monopole_get.html
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit
import pandas as pd
import io
import requests

# --- CONSTANTS ---
NASA_URL = "https://lambda.gsfc.nasa.gov/data/cobe/firas/monopole_spec/firas_monopole_spec_v1.txt"

# --- PART 1: ROBUST DATA INGESTION ---
def fetch_cobe_data():
    """
    Attempts to download data from NASA. 
    Parses the 5-column raw format described in the documentation.
    """
    print("[Ingestion] Attempting to fetch data from NASA LAMBDA...")
    try:
        headers = {'User-Agent': 'Mozilla/5.0'}
        response = requests.get(NASA_URL, headers=headers, timeout=10)
        
        if response.status_code == 200:
            print("[Success] Connection established. Parsing raw data...")
            
            # NASA Raw Format:
            # Col 1: Freq (cm^-1)
            # Col 2: Intensity (MJy/sr)
            # Col 3: Residuals (kJy/sr)
            # Col 4: Uncertainty (kJy/sr) 
            # Col 5: Galaxy Model (kJy/sr)
            
            # 'comment=#' tells pandas to ignore lines starting with #
            # 'usecols=[0, 1, 3]' grabs only Freq, Intensity, and Uncertainty
            df = pd.read_csv(
                io.StringIO(response.text), 
                sep='\s+', 
                comment='#', 
                header=None, 
                usecols=[0, 1, 3], 
                names=['nu', 'I', 'sigma']
            )
            return df
            
        else:
            print(f"[Warning] Server returned status code: {response.status_code}")
            raise ConnectionError("Server unavailable")
            
    except Exception as e:
        print(f"[Error] Could not fetch remote data: {e}")
        print("[Fallback] Switching to hardcoded local backup data...")
        return get_local_backup_data()

def get_local_backup_data():
    """
    Hardcoded backup of the COBE dataset. 
    Ensures the script runs even without internet connection.
    """
    raw_data = """
    2.27   200.723   14
    2.72   249.508   19
    3.18   293.024   25
    3.63   327.770   23
    4.08   354.081   22
    4.54   372.079   21
    4.99   381.493   18
    5.45   383.478   18
    5.90   378.901   16
    6.35   368.833   14
    6.81   354.063   13
    7.26   336.278   12
    7.71   316.076   11
    8.17   293.924   10
    8.62   271.432   11
    9.08   248.239   12
    9.53   225.940   14
    9.98   204.327   16
    10.44  183.262   18
    10.89  163.830   22
    11.34  145.750   22
    11.80  128.835   23
    12.25  113.568   23
    12.71  99.451    23
    13.16  87.036    22
    13.61  75.876    21
    14.07  65.766    20
    14.52  57.008    19
    14.97  49.223    19
    15.43  42.267    19
    15.88  36.352    21
    16.34  31.062    23
    16.79  26.580    26
    17.24  22.644    28
    17.70  19.255    30
    18.15  16.391    32
    18.61  13.811    33
    19.06  11.716    35
    19.51  9.921     41
    19.97  8.364     55
    20.42  7.087     88
    20.87  5.801     155
    21.33  4.523     282
    """
    return pd.read_csv(io.StringIO(raw_data), sep='\s+', header=None, names=['nu', 'I', 'sigma'])

# --- PART 2: PHYSICS MODEL ---
def planck_law(nu_cm, T, A):
    """Theoretical Planck's Law for Black Body Radiation."""
    h = 6.626e-34   # J s
    c = 2.998e10    # cm/s
    k_B = 1.381e-23 # J/K
    
    nu_hz = nu_cm * c 
    exponent = (h * nu_hz) / (k_B * T)
    
    with np.errstate(over='ignore'):
        denominator = np.expm1(exponent)
    
    denominator[denominator == 0] = np.inf
    I = A * (nu_hz**3) / denominator
    return I

# --- PART 3: ANALYSIS PIPELINE ---
def run_pipeline():
    # 1. Ingest Data
    df = fetch_cobe_data()
    
    nu_data = df['nu'].values
    I_data = df['I'].values
    
    # Documentation says Uncertainty (Col 4) is in kJy/sr.
    # Intensity (Col 2) is in MJy/sr.
    # We must convert Uncertainty to MJy/sr to match scales (divide by 1000).
    sigma_data = df['sigma'].values / 1000.0

    print(f"[Processing] Fitting Planck's Law to {len(df)} observational points...")
    
    # 2. Model Fitting
    p0 = [3, 1e-15] 
    
    popt, pcov = curve_fit(
        planck_law, 
        nu_data, 
        I_data, 
        p0=p0, 
        sigma=sigma_data, 
        absolute_sigma=True
    )
    
    T_fit, A_fit = popt
    perr = np.sqrt(np.diag(pcov))
    
    print("\n" + "="*40)
    print("ANALYSIS RESULTS")
    print("="*40)
    print(f"Calculated CMB Temperature: {T_fit:.4f} +/- {perr[0]:.2e} K")
    print("Literature Value (Mather):  2.7250 K")
    print("-" * 40)
    
    # 3. Visualization
    plt.figure(figsize=(10, 8))
    
    # Top plot: Spectrum
    ax1 = plt.subplot2grid((3, 1), (0, 0), rowspan=2)
    ax1.errorbar(nu_data, I_data, yerr=sigma_data, fmt='ko', markersize=3, label='COBE Data', alpha=0.6)
    
    nu_smooth = np.linspace(min(nu_data), max(nu_data), 500)
    ax1.plot(nu_smooth, planck_law(nu_smooth, *popt), 'r-', linewidth=2, label=f'Planck Fit (T={T_fit:.4f}K)')
    ax1.set_ylabel("Intensity [MJy/sr]")
    ax1.set_title("Cosmic Microwave Background Spectrum Analysis (NASA Data)")
    ax1.legend()
    ax1.grid(True, linestyle='--', alpha=0.5)
    
    # Bottom plot: Residuals
    ax2 = plt.subplot2grid((3, 1), (2, 0), rowspan=1, sharex=ax1)
    residuals = I_data - planck_law(nu_data, *popt)
    ax2.plot(nu_data, residuals, 'b-o', markersize=4, linewidth=1)
    ax2.axhline(0, color='k', linestyle='--', linewidth=1)
    ax2.set_ylabel("Residuals")
    ax2.set_xlabel("Frequency [1/cm]")
    ax2.grid(True, alpha=0.5)
    
    plt.tight_layout()
    plt.savefig('cobe_analysis_result.png', dpi=100)
    print("[Output] Graph saved as 'cobe_analysis_result.png'")
    
    plt.show()

if __name__ == "__main__":
    run_pipeline()