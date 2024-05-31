#KNN algorithm to recognise symbols on png image

import argparse
import os
from PIL import Image
import numpy as np


def setup_arg_parser():
    parser = argparse.ArgumentParser(description='Learn and classify image data.')
    parser.add_argument('train_path', type=str, help='path to the training data directory')
    parser.add_argument('test_path', type=str, help='path to the testing data directory')
    parser.add_argument('-k', type=int, 
                        help='run k-NN classifier (if k is 0 the code may decide about proper K by itself')
    parser.add_argument("-o", metavar='filepath', 
                        default='classification.dsv',
                        help="path (including the filename) of the output .dsv file with the results")
    return parser

# Calculate Euclid distance between two vector images
def calculate_distance(im1, im2):
    diff = im1 - im2
    distance = np.linalg.norm(diff)
    return distance

def most_frequent_weighted(choosen_symb):
    symbol_frequency = {}
    for symbol, distance in choosen_symb:
        # In case of distance being 0, add some small constant to avoid division by zero
        if distance == 0: 
            distance = 0.0001
        # If the symbol is already in the dictionary, add the weight
        if symbol in symbol_frequency:
            symbol_frequency[symbol] += 1/distance
        # Else, create a new key-value pair in the dictionary
        else:
            symbol_frequency[symbol] = 1/distance
    return max(symbol_frequency.items(), key=lambda x: x[1])[0]


def write_to_dsv(results, filepath, delimiter=':'):
    with open(filepath, 'w') as file:
        for key, value in results.items():
            file.write(f'{key}{delimiter}{value}\n')

def set_train_dataset(filename, train_dataset):
    with open(os.path.join(filename, 'truth.dsv'), 'r') as file:
        for line in file:
            key, value = line.strip().split(':')
            train_dataset[key] = value

def main():
    parser = setup_arg_parser()
    args = parser.parse_args()
    
    print('Training data directory:', args.train_path)
    print('Testing data directory:', args.test_path)
    print('Output file:', args.o)
    
    print(f"Running k-NN classifier with k={args.k}")
    
    train_dataset = dict()
    train_data = []
    
    # open truth file and create image -> letter dictionary
    set_train_dataset(args.train_path, train_dataset)
    
    # train data
    for entry in os.scandir(args.train_path):
        if entry.is_file() and entry.name != 'truth.dsv':
            image_vector = np.array(Image.open(entry.path)).astype(int).flatten()
            train_data.append((entry.name, image_vector))
    
    results = {}
    
    for entry in os.scandir(args.test_path):
        if entry.is_file():
            test_image_vector = np.array(Image.open(entry.path)).astype(int).flatten()
            distances = [(train_dataset[name], calculate_distance(test_image_vector, image_vector)) for name, image_vector in train_data]
            distances.sort(key=lambda x: x[1])
            
            # Get k nearest neighbors with their distances
            k_nearest = distances[:args.k]
            results[entry.name] = most_frequent_weighted(k_nearest)
        
    write_to_dsv(results, args.o)

if __name__ == "__main__":
    main()
