import nltk
import numpy as np
import pandas as pd
from nltk.tokenize import word_tokenize
from feature_selection.combined2 import combined_sentiment

# nltk.download('punkt')

from MultinomialNaiveBayes import MultinomialNaiveBayes
from feature_selection.adjectives import adjectives
from feature_selection.combined import combination
from feature_selection.combined3 import combination3
from feature_selection.handle_negation import negation
from feature_selection.sentiment_shifter import sentiment_shifters
from feature_selection.sentiwordnet import sentiwordnet
# from feature_selection.tfidf import tfidf
from feature_selection.vader import vader_sentiment


def train_and_predict(feature: str, number_classes: int, train: pd.DataFrame,
                      dev: pd.DataFrame, test: pd.DataFrame, alpha: float) -> (pd.Series, pd.Series):
    if feature == "all_words":
        # Extracting features and labels
        x_train = train['Phrase']
        y_train = train['Sentiment']
        x_dev = dev['Phrase']
        x_test = test['Phrase']

    else:

        if number_classes == 3:
            # VADER (Valence Aware Dictionary and sEntiment Reasoner)
            x_train, x_dev, x_test = vader_sentiment(train, dev, test)
            y_train = train['Sentiment']

        else:
            # Combined:TFIDF, VADER - reduces the score because TFIDF dilutes sentiment specific information
            x_train, x_dev, x_test = combination(train, dev, test)
            y_train = train['Sentiment']


        # Adjectives - reduces the score & doesn't take sentiment relations into account
        # x_train, y_train, x_dev, x_test = adjectives(train, dev, test)

        # negation marker - explicit negation markers not helpful
        # x_train, y_train, x_dev, x_test = negation(train, dev, test)

        # sentiment shifters
        # x_train, y_train, x_dev, x_test = sentiment_shifters(train, dev, test)

        # combining - adjectives, negation marker and sentiment shifters? no need already covered by VADER

        # TFIDF
        # x_train, x_dev, x_test = tfidf(train, dev, test)
        # y_train = train['Sentiment']

        # Combined: TFIDF, VADER and Mutual Information
        # train, dev, test = combination3(train, dev, test)
        # x_train = train['combined_features']
        # y_train = train['Sentiment']
        # x_dev = dev['combined_features']
        # x_test = test['combined_features']

        # Combined TFIDF, VADER with oversampling using SMOTE - takes longer than expected
        # x_train, y_train, x_dev, x_test = combined_sentiment('Sentiment', train, dev, test)

    # MultinomialNaiveBayes classifier
    naive_bayes_classifier = MultinomialNaiveBayes(alpha=alpha)
    naive_bayes_classifier.fit(x_train, y_train)
    dev_predictions = naive_bayes_classifier.predict(x_dev)
    test_predictions = naive_bayes_classifier.predict(x_test)

    return dev_predictions, test_predictions
