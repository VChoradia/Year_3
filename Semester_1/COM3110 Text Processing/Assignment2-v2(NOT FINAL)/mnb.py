import numpy as np

class MultinomialNaiveBayes:
    def fit(self, X, y):
        m, n = X.shape
        self.classes = np.unique(y)
        n_classes = len(self.classes)

        # Initialize likelihoods and priors
        self.likelihoods = np.zeros((n_classes, n))
        self.priors = np.zeros(n_classes)

        # Calculate likelihoods and priors
        for idx, c in enumerate(self.classes):
            X_c = X[y == c]
            self.likelihoods[idx, :] = (X_c.sum(axis=0) + 1) / (np.sum(X_c.sum(axis=0) + 1))
            self.priors[idx] = X_c.shape[0] / float(m)

    def predict(self, X):
        m, n = X.shape
        y_pred = np.zeros(m)

        # Calculate posterior probability for each class
        for i in range(m):
            posteriors = np.zeros(len(self.classes))
            for idx, c in enumerate(self.classes):
                prior = np.log(self.priors[idx])
                likelihood = np.sum(np.log(self.likelihoods[idx, :]) * X[i, :])
                posteriors[idx] = prior + likelihood
            y_pred[i] = self.classes[np.argmax(posteriors)]

        return y_pred
