import cv2
import numpy as np
import matplotlib.pyplot as plt


def some_stats():
    img = cv2.imread("tree_dark_small.png", cv2.IMREAD_GRAYSCALE)
    print(f" Original Image: Min Intensity: {np.min(img)} \n Max Intensity: { np.max(img)}\n Average Intensities: {np.mean(img)}")
    norm_img = np.zeros((800, 800))
    final_img = cv2.normalize(img, norm_img, 0, 255, cv2.NORM_MINMAX)
    # cam = cv2.cvtColor(final_img, cv2.COLOR_BGR2RGB)
    # plt.imshow(cam)
    # plt.show()

    print(f" Normalised Image: Min Intensity: {np.min(final_img)} \n Max Intensity: {np.max(final_img)}\n Average "
          f"Intensities: {np.mean(final_img)}")

    # find frequency of pixels in range 0-255
    img_histr = cv2.calcHist([img], [0], None, [256], [0, 256])

    # show the plotting graph of an image
    # plt.plot(histr)
    # plt.show()

    # find frequency of pixels in range 0-255
    img_norm_histr = cv2.calcHist([final_img], [0], None, [256], [0, 256])

    # show the plotting graph of an image
    # plt.plot(histr)
    # plt.show()

    # fig, axes = plt.subplots(2, 2)  # creates 4 plotting axes
    # axes[0, 0].imshow(img, cmap="gray", vmin=0, vmax=255)  # shows img as is
    # axes[0, 1].plot(img_histr)
    # axes[1, 0].imshow(final_img, cmap="gray", vmin=0, vmax=255)  # shows img_norm as is
    # axes[1, 1].plot(img_norm_histr)
    #
    # plt.show()

    brighter = np.power((final_img/255), (1/2)) * 255
    # cam = cv2.cvtColor(brighter)
    # plt.imshow(brighter, cmap="gray")
    # plt.show()

    both = np.hstack((final_img, brighter))
    plt.imshow(both, cmap="gray")
    plt.show()

def threshold_fingerprint():
    img = cv2.imread("fingerprint.png", cv2.IMREAD_GRAYSCALE)
    inverted_img = cv2.bitwise_not(img)
    # cv2.imshow("inverted", inverted_img)

    threshold_level = 140
    _, thresholded_image = cv2.threshold(inverted_img, threshold_level, 255, cv2.THRESH_BINARY)

    # Save the thresholded image
    cv2.imwrite('thresholded_fingerprint.png', thresholded_image)

    # Present the thresholded image
    cv2.imshow('Thresholded Fingerprint', thresholded_image)

    cv2.waitKey(0)
    cv2.destroyAllWindows()


def advert():
    pass

































some_stats()
