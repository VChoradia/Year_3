import cv2
import matplotlib.image as mpimg
import numpy as np
import matplotlib.pyplot as plt


def black_image():
    img = np.zeros((50, 40, 1), dtype=np.uint8)

    cv2.imwrite("black.png", img)

def white_image():
    img = 255 * np.ones((50, 40, 1), dtype=np.uint8)
    cv2.imwrite("white.png", img)

def rgb_gray_image():
    img = np.zeros((50, 40, 3), dtype=np.uint8)

    gray_value = 127
    img[:, :] = (gray_value, gray_value, gray_value)

    cv2.imwrite("gray.png", img)

def yellow_image():
    r = 255 * np.ones((50, 40, 1), dtype=np.uint8)
    g = 255 * np.ones((50, 40, 1), dtype=np.uint8)
    b = np.zeros((50, 40, 1), dtype=np.uint8)

    yellow = cv2.merge((b, g, r))
    cv2.imwrite("yellow.png", yellow)


def save_red():
    cam = cv2.imread("cam.png")
    b, g, r = cv2.split(cam)

    red = cv2.merge((np.zeros_like(b), np.zeros_like(g), r))
    cv2.imwrite("red.png", red)


def color_to_grayscale():
    cam = cv2.imread("cam.png")
    b, g, r = cv2.split(cam)
    y = 0.299*r + 0.587*g + 0.114*b
    y = y.astype(np.uint8)

    cv2.imshow("Grayscale Image", y)

    cv2.waitKey(0)  # waits forever for the user to hit a key
    cv2.destroyAllWindows()  # close any opened windows


def show_with_plt():
    cam = cv2.imread("cam.png")
    cam = cv2.cvtColor(cam, cv2.COLOR_BGR2RGB)
    plt.imshow(cam)
    plt.show()
    pass


def show_with_plt2():
    cam = cv2.imread("cam.png")
    cam = cv2.cvtColor(cam, cv2.COLOR_BGR2GRAY)

    plt.imshow(cam, cmap="gray")
    plt.show()

def merge_two_in_one():

    cam = cv2.imread("cam.png")

    b, g, r = cv2.split(cam)
    y = 0.299 * r + 0.587 * g + 0.114 * b
    y = y.astype(np.uint8)

    gray = cv2.merge([y,y,y])

    cam = cv2.cvtColor(cam, cv2.COLOR_BGR2RGB)
    both = np.hstack((cam, gray))

    plt.imshow(both)
    plt.show()

merge_two_in_one()




