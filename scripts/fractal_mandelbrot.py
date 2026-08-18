#! /usr/bin/env python3

import numpy as np
import matplotlib.pyplot as plt

def generate_mandelbrot(width, height, max_iter=100):
    # Create a 2D grid of complex numbers
    # The Mandelbrot set is typically explored in the range [-2, 1] on real axis
    # and [-1.5, 1.5] on the imaginary axis
    x = np.linspace(-2.0, 0.5, width)
    y = np.linspace(-1.2, 1.2, height)
    x_grid, y_grid = np.meshgrid(x, y)
    c = x_grid + 1j * y_grid

    # Initialize the z values and a count grid
    z = np.copy(c)
    fractal = np.zeros((height, width))
    
    # Iteratively compute the Mandelbrot set
    for i in range(max_iter):
        # Create a mask for points that haven't "escaped" yet
        mask = np.abs(z) <= 2
        # Only update points within the boundary
        z[mask] = z[mask]**2 + c[mask]
        # Update counts where the point is still within bounds
        fractal[np.logical_not(mask)] = i

    return fractal

def main():
    width, height = 1000, 1000
    max_iterations = 256
    
    print("Generating Mandelbrot set...")
    img = generate_mandelbrot(width, height, max_iterations)
    
    plt.figure(figsize=(10, 10))
    plt.imshow(img, cmap='magma', extent=[-2.0, 0.5, -1.2, 1.2])
    plt.colorbar(label='Iterations to escape')
    plt.title("Mandelbrot Set")
    plt.axis('off')
    
    print("Displaying result...")
    plt.show()

if __name__ == "__main__":
    main()
