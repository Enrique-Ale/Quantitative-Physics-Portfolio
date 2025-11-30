# -*- coding: utf-8 -*-
"""
@author: enriq
"""

import numpy as np
import matplotlib.pyplot as plt

def simulacion_caminata_aleatoria(n_pasos=50000):
    """
    Simula una caminata aleatoria en 2D utilizando vectorización de NumPy.
    
    Args:
        n_pasos (int): Número de pasos a simular.
    
    Returns:
        tuple: Arrays de coordenadas x, y.
    """
    # 1. Definir los posibles movimientos (Arriba, Abajo, Izquierda, Derecha)
    # dx y dy representan el cambio en cada paso
    opciones = [
        [0, 1],   # Arriba
        [0, -1],  # Abajo
        [1, 0],   # Derecha
        [-1, 0]   # Izquierda
    ]
    
    # 2. Generar elecciones aleatorias para todos los pasos de una sola vez
    indices = np.random.choice(len(opciones), size=n_pasos)
    pasos = np.array(opciones)[indices]
    
    # 3. Calcular la posición acumulada (Trayectoria)
    # np.cumsum suma paso a paso: [0, 1, 1...] -> [0, 1, 2...]
    x = np.cumsum(pasos[:, 0])
    y = np.cumsum(pasos[:, 1])
    
    # Insertar el origen (0,0) al inicio
    x = np.insert(x, 0, 0)
    y = np.insert(y, 0, 0)
    
    return x, y

# --- Ejecución y Visualización ---

# Configuración de parámetros
N = 50000

# Ejecutar simulación
x, y = simulacion_caminata_aleatoria(N)

# Graficar 
plt.figure(figsize=(10, 6))
plt.plot(x, y, linewidth=0.5, alpha=0.8, color='#4c00b0') 
plt.plot(0, 0, 'go', label='Inicio (0,0)', markersize=8)
plt.plot(x[-1], y[-1], 'ro', label='Fin', markersize=8)

plt.title(f"Simulación de Caminata Aleatoria 2D (Vectorizada)\n$n = {N}$ pasos", fontsize=14)
plt.xlabel("Posición X")
plt.ylabel("Posición Y")
plt.legend()
plt.grid(True, linestyle='--', alpha=0.6)
