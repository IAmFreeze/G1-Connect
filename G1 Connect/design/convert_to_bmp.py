#!/usr/bin/env python3
from PIL import Image
import os
import numpy as np

def convert_to_1bit_bmp(input_path, output_path, threshold=128):
    """
    Convert an image to 1-bit BMP format (black and white) with dimensions 136x136
    
    Args:
        input_path: Path to the input image
        output_path: Path to save the output BMP
        threshold: Threshold for converting to black and white (0-255)
    """
    # Open the image
    img = Image.open(input_path)
    
    # Resize to 136x136 (G1 display size)
    img = img.resize((136, 136), Image.LANCZOS)
    
    # Convert to grayscale
    img = img.convert('L')
    
    # Convert to 1-bit using threshold
    img = img.point(lambda p: 255 if p > threshold else 0)
    img = img.convert('1')
    
    # Save as BMP
    img.save(output_path, 'BMP')
    
    print(f"Converted {input_path} to 1-bit BMP at {output_path}")

def process_all_images(input_dir, output_dir, threshold=128):
    """
    Process all images in the input directory and save them to the output directory
    
    Args:
        input_dir: Directory containing input images
        output_dir: Directory to save output BMPs
        threshold: Threshold for converting to black and white (0-255)
    """
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Get all image files
    image_files = [f for f in os.listdir(input_dir) if f.lower().endswith(('.png', '.jpg', '.jpeg', '.gif'))]
    
    for image_file in image_files:
        input_path = os.path.join(input_dir, image_file)
        
        # Create output filename (replace extension with .bmp)
        base_name = os.path.splitext(image_file)[0]
        output_path = os.path.join(output_dir, f"{base_name}.bmp")
        
        # Convert the image
        convert_to_1bit_bmp(input_path, output_path, threshold)

if __name__ == "__main__":
    # Paths
    input_dir = "/home/ubuntu/even_realities_project/design/images"
    output_dir = "/home/ubuntu/even_realities_project/design/bmp_images"
    
    # Process all images
    process_all_images(input_dir, output_dir, threshold=150)
    
    print("All images converted successfully!")
