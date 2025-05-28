#!/usr/bin/env python3
from PIL import Image
import os

def convert_to_1bit_bmp(input_dir, output_dir, target_size=(136, 136)):
    """
    Convert PNG images to 1-bit BMP format with specified size for Even Realities G1 glasses.
    
    Args:
        input_dir: Directory containing PNG images
        output_dir: Directory to save converted BMP images
        target_size: Target size for the images (width, height)
    """
    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)
    
    # Get all PNG files in the input directory
    png_files = [f for f in os.listdir(input_dir) if f.endswith('.png')]
    
    for png_file in png_files:
        input_path = os.path.join(input_dir, png_file)
        output_filename = os.path.splitext(png_file)[0] + '.bmp'
        output_path = os.path.join(output_dir, output_filename)
        
        # Open and process the image
        with Image.open(input_path) as img:
            # Resize to target size
            img_resized = img.resize(target_size, Image.LANCZOS)
            
            # Convert to grayscale
            img_gray = img_resized.convert('L')
            
            # Convert to 1-bit using dithering
            img_1bit = img_gray.convert('1')
            
            # Save as BMP
            img_1bit.save(output_path, 'BMP')
            
        print(f"Converted {png_file} to {output_filename}")

if __name__ == "__main__":
    input_directory = "/home/ubuntu/even_realities_project/design/images"
    output_directory = "/home/ubuntu/even_realities_project/design/bmp_images"
    
    convert_to_1bit_bmp(input_directory, output_directory)
    print("All images converted successfully!")
