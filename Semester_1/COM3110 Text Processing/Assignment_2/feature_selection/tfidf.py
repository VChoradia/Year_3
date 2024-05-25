import math
from collections import defaultdict
import pandas as pd

class TFIDFFeatureSelector:
    def __init__(self, ngram_range=(1, 1)):
        """
        Initialize the TFIDF feature selector with n-gram range.

        :param ngram_range: Tuple (min_n, max_n) representing the lower and upper boundary of the range of n-values.
        """
        self.ngram_range = ngram_range
        self.document_count = 0
        self.word_idf_values = defaultdict(float)
        self.tf_values = []

    def _generate_ngrams(self, text):
        """
        Generate n-grams from text based on the specified n-gram range.

        :param text: A string from which n-grams are to be generated.
        :return: List of n-grams.
        """
        words = text.split()
        ngrams = []
        for n in range(self.ngram_range[0], self.ngram_range[1] + 1):
            for i in range(len(words) - n + 1):
                ngrams.append(' '.join(words[i:i + n]))
        return ngrams

    def _calculate_tf(self, documents):
        """
        Calculate term frequency for each document.

        :param documents: List of text documents.
        """
        self.tf_values = []
        for doc in documents:
            ngrams = self._generate_ngrams(doc)
            tf_counter = defaultdict(int)
            for ngram in ngrams:
                tf_counter[ngram] += 1

            total_ngrams = len(ngrams)
            self.tf_values.append({ngram: count / total_ngrams for ngram, count in tf_counter.items()})

    def _calculate_idf(self, documents):
        """
        Calculate inverse document frequency for each term.

        :param documents: List of text documents.
        """
        self.document_count = len(documents)
        word_document_count = defaultdict(int)

        for doc in documents:
            ngrams = set(self._generate_ngrams(doc))
            for ngram in ngrams:
                word_document_count[ngram] += 1

        for ngram, count in word_document_count.items():
            self.word_idf_values[ngram] = math.log(self.document_count / (1 + count))

    def fit_transform(self, documents):
        """
        Fit the model on the documents and transform them into TF-IDF features.

        :param documents: List of text documents.
        :return: DataFrame with TF-IDF features.
        """
        self._calculate_tf(documents)
        self._calculate_idf(documents)

        tfidf_values = []
        for doc_tf in self.tf_values:
            tfidf_scores = {ngram: tf * self.word_idf_values[ngram] for ngram, tf in doc_tf.items()}
            tfidf_values.append(tfidf_scores)

        return pd.DataFrame(tfidf_values).fillna(0)

# Example usage
if __name__ == "__main__":
    documents = [
        "This is the first document.",
        "This document is the second document.",
        "And this is the third one.",
        "Is this the first document?"
    ]

    tfidf_selector = TFIDFFeatureSelector(ngram_range=(1, 1))
    tfidf_features = tfidf_selector.fit_transform(documents)

    print(tfidf_features)
#
# from sklearn.feature_extraction.text import TfidfVectorizer
#
# def tfidf_transform(texts):
#     """
#     Transform texts using a TF-IDF vectorizer.
#
#     :param texts: List of text documents.
#     :return: Transformed TF-IDF feature matrix.
#     """
#     # Create and fit a TF-IDF vectorizer
#     tfidf_vectorizer = TfidfVectorizer()
#     tfidf_matrix = tfidf_vectorizer.fit_transform(texts)
#
#     return tfidf_matrix, tfidf_vectorizer
#
# def apply_vectorizer_to_data(vectorizer, texts):
#     """
#     Apply a fitted TF-IDF vectorizer to texts.
#
#     :param vectorizer: Fitted TF-IDF vectorizer.
#     :param texts: List of text documents to transform.
#     :return: Transformed TF-IDF feature matrix.
#     """
#     return vectorizer.transform(texts)
#
# import numpy as np
# from sklearn.feature_extraction.text import TfidfVectorizer
# from nltk.sentiment.vader import SentimentIntensityAnalyzer
#
# def tfidf_vader_transform(texts):
#     """
#     Transform texts using a TF-IDF vectorizer and append VADER sentiment scores.
#
#     :param texts: List of text documents.
#     :return: Combined TF-IDF and VADER feature matrix, and the fitted TF-IDF vectorizer.
#     """
#     # Create and fit a TF-IDF vectorizer
#     tfidf_vectorizer = TfidfVectorizer()
#     tfidf_matrix = tfidf_vectorizer.fit_transform(texts)
#
#     # VADER Sentiment Analysis
#     sia = SentimentIntensityAnalyzer()
#     vader_scores = [(sia.polarity_scores(sentence)['compound'] + 1) for sentence in texts]
#     vader_scores = np.array(vader_scores).reshape(-1, 1)
#
#     # Concatenating TF-IDF features with VADER scores
#     combined_features = np.hstack((tfidf_matrix.toarray(), vader_scores))
#
#     return combined_features, tfidf_vectorizer
#
# def apply_vectorizer_and_vader(vectorizer, texts):
#     """
#     Apply a fitted TF-IDF vectorizer to texts and append VADER sentiment scores.
#
#     :param vectorizer: Fitted TF-IDF vectorizer.
#     :param texts: List of text documents to transform.
#     :return: Combined TF-IDF and VADER feature matrix.
#     """
#     tfidf_matrix = vectorizer.transform(texts)
#
#     # VADER Sentiment Analysis
#     sia = SentimentIntensityAnalyzer()
#     vader_scores = [sia.polarity_scores(sentence)['compound'] for sentence in texts]
#     vader_scores = np.array(vader_scores).reshape(-1, 1)
#
#     # Concatenating TF-IDF features with VADER scores
#     combined_features = np.hstack((tfidf_matrix.toarray(), vader_scores))
#
#     return combined_features
#
#
#
# def tfidf(train, dev, test):
#     train_tfidf, tfidf_vectorizer = tfidf_vader_transform(train['Phrase'])
#
#     # Apply the same vectorizer to dev and test sets
#     dev_tfidf = apply_vectorizer_and_vader(tfidf_vectorizer, dev['Phrase'])
#     test_tfidf = apply_vectorizer_and_vader(tfidf_vectorizer, test['Phrase'])
#
#     return train_tfidf, dev_tfidf, test_tfidf
