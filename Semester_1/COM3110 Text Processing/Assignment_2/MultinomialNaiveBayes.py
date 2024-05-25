from collections import defaultdict, Counter

import nltk
import numpy as np
import pandas as pd


class MultinomialNaiveBayes:

    def __init__(self, alpha=1.0):
        self.alpha = alpha  # Laplace Smoothing Factor
        self.class_probabilities = {}
        self.feature_probabilities = {}
        self.len_vocabulary = 0

    def fit(self, x_train: pd.Series, y_train: pd.Series):
        """
        To calculate class and feature probabilities.
        :param x_train: List of tokenized phrases
        :param y_train: List of corresponding sentiment labels
        """
        self._calculate_class_probabilities(y_train)
        self._create_vocabulary(x_train)
        self._count_features_per_class(x_train, y_train)
        self._calculate_feature_probabilities()

    def predict(self, x_test: pd.Series) -> pd.Series:
        """

        :param x_test:
        :return:
        """

        predictions = []
        for doc in x_test:
            predicted_probs = {label: np.log(prob) for label, prob in self.class_probabilities.items()}

            for label in predicted_probs:
                for word in doc:
                    if word in self.feature_probabilities[label]:
                        predicted_probs[label] += np.log(self.feature_probabilities[label][word])
                    else:
                        # Smoothing for unknown words
                        predicted_probs[label] += np.log(self.alpha / (
                                sum(self.feature_counts_per_class[label].values()) + self.alpha * self.len_vocabulary))

            predicted_label = max(predicted_probs, key=predicted_probs.get)
            predictions.append(predicted_label)

        return pd.Series(predictions)

    def _calculate_class_probabilities(self, y_train: pd.Series):
        total_samples = len(y_train)
        class_counts = Counter(y_train)
        num_classes = len(set(y_train))

        for label, count in class_counts.items():
            self.class_probabilities[label] = (count + self.alpha) / (total_samples + num_classes * self.alpha)

    def _create_vocabulary(self, x_train: pd.Series):
        vocabulary = set()
        for phrases in x_train:
            vocabulary.update(phrases)
        self.len_vocabulary = len(vocabulary)

    def _count_features_per_class(self, x_train: pd.Series, y_train: pd.Series):
        self.feature_counts_per_class = {label: defaultdict(int) for label in set(y_train)}

        for phrase, label in zip(x_train, y_train):
            for word, count in Counter(phrase).items():
                self.feature_counts_per_class[label][word] += count

    def _calculate_feature_probabilities(self):
        for label, feature_counts in self.feature_counts_per_class.items():
            total_words_in_class = sum(feature_counts.values())
            self.feature_probabilities[label] = {
                word: (count + self.alpha) / (total_words_in_class + self.alpha * self.len_vocabulary)
                for word, count in feature_counts.items()
            }