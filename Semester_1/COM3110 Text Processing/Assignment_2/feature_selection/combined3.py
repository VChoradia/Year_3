import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from nltk.sentiment.vader import SentimentIntensityAnalyzer
from sklearn.feature_selection import SelectKBest, mutual_info_classif

def combined_features(sentences, feature_selector=None, labels=None, fit_selector=False):
    """
    Extract combined features and apply feature selection if a selector is provided.

    :param sentences: List of sentences.
    :param feature_selector: SelectKBest object for feature selection.
    :param labels: training labels
    :param fit_selector: Boolean, True if the selector needs to be fitted.
    :return: Combined features with/without feature selection.
    """
    # TF-IDF Vectorization
    tfidf = TfidfVectorizer()
    X_tfidf = tfidf.fit_transform(sentences).toarray()

    # VADER Sentiment Analysis
    sia = SentimentIntensityAnalyzer()
    vader_scores = [sia.polarity_scores(sentence)['compound'] for sentence in sentences]
    vader_scores = np.array(vader_scores).reshape(-1, 1)

    # Concatenating Features
    combined_features = np.concatenate((X_tfidf, vader_scores), axis=1)

    # Apply feature selection if a selector is provided
    if feature_selector is not None:
        if fit_selector:
            return feature_selector.fit_transform(combined_features, labels)
        else:
            return feature_selector.transform(combined_features)

    return combined_features


def combination3(train, dev, test, n_features=200):
    """
    Process train, dev, and test sets to extract and select features.

    :param train: Training DataFrame.
    :param dev: Development DataFrame.
    :param test: Test DataFrame.
    :param n_features: Number of features to select.
    :return: DataFrames with combined features.
    """
    train_sentences = train['Phrase'].tolist()
    train_labels = train['Sentiment'].tolist()
    dev_sentences = dev['Phrase'].tolist()
    test_sentences = test['Phrase'].tolist()

    # Define the feature selector
    feature_selector = SelectKBest(mutual_info_classif, k=n_features)

    # Get combined features for the training dataset and fit the selector
    train_combined = combined_features(train_sentences, feature_selector, train_labels, fit_selector=True)

    # Get combined features for dev and test datasets
    dev_combined = combined_features(dev_sentences, feature_selector, fit_selector=False)
    test_combined = combined_features(test_sentences, feature_selector, fit_selector=False)

    # Assign combined features back to the respective DataFrame columns
    train['combined_features'] = train_combined.tolist()
    dev['combined_features'] = dev_combined.tolist()
    test['combined_features'] = test_combined.tolist()

    return train, dev, test

# Example usage:
# train, dev, test = combination(train_df, dev_df, test_df)
