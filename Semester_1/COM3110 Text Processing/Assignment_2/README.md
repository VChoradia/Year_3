---
# COM3110 Text Processing Assignment
## Sentiment Analysis of Movie Reviews
Author: Vivek V Choradia
---
## Overview
This project implements a multinomial Naive Bayes classifier 
for sentiment analysis using the Rotten Tomatoes movie review dataset. 
It aims to categorize sentiments of movie reviews into two different settings:
3-Value and 5-Value Sentiment Scale.

## Prerequisites
- Python 3.9.x or above
- Additional libraries: 
  - NLTK (Natural Language Toolkit) version 3.8.1 or higher
  - Pandas version 1.5.0 or higher
  - NumPy version 1.23.3 or higher
  - Seaborn version 0.13.0 or higher
  - Matplotlib version 3.8.2 or higher
  - Scikit-learn version 1.3.2 or higher
  - Imbalanced-learn (imblearn) latest version

## Installation
- Clone/download the repository to your local machine.
- Install required libraries using the `requirements.txt` file:
  ```bash
  pip install -r requirements.txt
  ```

## Files Description
- `NB_sentiment_analyser.py`: Main script for running the sentiment analysis model.
- `macro_f1_score.py`: Script to calculate the macro-F1 score.
- `MutlinomialNaiveBayes.py`: Implementation of the multinomial Naive Bayes classifier with laplace smoothing.
- `helper.py`: Contains auxiliary functions that support other scripts.
- `preprocessing.py`: Contains preprocessing functions applied to the data.
- `train_and_predict.py`:  Script that trains the model and makes predictions where different feature selections are called.
- `dev_predictions_*.tsv` & `test_predictions_*.tsv`:  Prediction files for the development and test sets.
- `/moviereviews`: Data directory containing the train, dev, and test sets in .tsv format.
- `/feature_selection`: Directory containing various feature selection scripts:
  - `adjectives.py`: Feature selection based on adjectives.
  - `handle_negation.py`: Processes negated phrases within the data.
  - `sentiment_shifter.py`: Adjusts sentiment scores based on contextual cues. 
  - `vader.py`: Feature extraction using the VADER sentiment analysis tool.
  - `combined.py`: Combination of feature extractions using VADER sentiment analysis tool (NLTK) and TFIDF (Scikit-learn).
  - `...`: Other feature selection strategies.

## Running the Code
To run the sentiment analysis, use the following command:
```bash
python NB_sentiment_analyser.py <TRAINING_FILE> <DEV_FILE> <TEST_FILE> -classes <NUMBER_CLASSES> -features <FEATURES_OPTION> -preprocessing <PREPROCESSING_OPTION> [-output_files] [-confusion_matrix]
```
Where:
- `<TRAINING_FILE>`, `<DEV_FILE>`, `<TEST_FILE>` are paths to the data files.
- `<NUMBER_CLASSES>` should be either 3 or 5, depending on the classification scheme.
- `<FEATURES_OPTION>` is to specify the feature selection strategy (`all_words` or custom features).
- `<PREPROCESSING_OPTION` is to specify which preprocessing strategy to apply (`np`, `p1`, `p2`)
  - np - No Preprocessing
  - p1 - Preprocessing Setting 1 - Lowercasing and Stop Word Removal 
  - p2 - Preprocessing Setting 2 - Lowercasing, handling contractions, tokenisation, stopwords removal, stemming and lemmatization
- `-output_files` and `-confusion_matrix` are optional flags.

---



