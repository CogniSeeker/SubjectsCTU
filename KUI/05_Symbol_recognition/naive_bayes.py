import argparse
import os
from PIL import Image
from collections import defaultdict
import numpy as np

NUM_SHADES = 16

def setup_arg_parser():
    parser = argparse.ArgumentParser(description='Learn and classify image data.')
    parser.add_argument('train_path', type=str, help='path to the training data directory')
    parser.add_argument('test_path', type=str, help='path to the testing data directory')
    parser.add_argument("-o", metavar='filepath', default='classification.dsv',
                        help="path (including the filename) of the output .dsv file with the results")
    return parser

class NaiveBayesClassifier:
    def __init__(self):
        self.classes = None
        self.class_stats = None

    def fit(self, X, y):
        k = 0.06 # k coefitient for Laplace smoothing
        self.classes = set(y)
        self.class_stats = {}
        
        num_features = len(X[0]) # number of pixels in an image

        for c in self.classes:
            # Initialize 2D array for each class
            self.class_stats[c] = np.zeros((num_features, NUM_SHADES))
            
            X_c = [x for x, y_i in zip(X, y) if y_i == c]
            total = len(X_c)

            for xi in X_c:
                for i, feature in enumerate(xi):
                    self.class_stats[c][i][feature] += 1

            # Convert counts to probabilities with Laplace smoothing
            self.class_stats[c] = (self.class_stats[c] + 1*k) / (total + NUM_SHADES*k)

    def predict(self, X):
        posteriors = {}
        for c in self.classes:
            log_likelihoods = np.sum(np.log(self.class_stats[c][np.arange(len(X)), X]))
            posteriors[c] = log_likelihoods
        return max(posteriors, key=posteriors.get)

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
    train_dataset = dict()
    train_data = []
    train_labels = []
    
    # open truth file and create image -> letter dictionary
    set_train_dataset(args.train_path, train_dataset)
    
    for entry in os.scandir(args.train_path):
        if entry.is_file() and entry.name != 'truth.dsv':
                #convert image to array of vectors
                # reduce grayscale levels and flatten the image
                img_vector = np.array(Image.open(entry.path)).astype(int).flatten() // NUM_SHADES
                train_data.append(img_vector)
            
                train_labels.append(train_dataset[entry.name])
    
    classifier = NaiveBayesClassifier()
    classifier.fit(train_data, train_labels)

    results = {}
    for entry in os.scandir(args.test_path):
        if entry.is_file():
            # reduce grayscale levels and flatten the image
            test_image_vector = np.array(Image.open(entry.path)).astype(int).flatten() // NUM_SHADES
            predicted_label = classifier.predict(test_image_vector)
            results[entry.name] = predicted_label

    write_to_dsv(results, args.o)

if __name__ == "__main__":
    main()
