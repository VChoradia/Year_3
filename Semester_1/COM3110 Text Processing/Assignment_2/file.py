def calculate_product_of_highest_stresses(stress_values):
    """
    Calculate the product of the two highest distinct stress values in a given list.

    Args:
    stress_values (list of int/float): A list of stress values from material testing.

    Returns:
    int/float: The product of the two highest distinct stress values. Returns None if the
               list does not contain at least two distinct values.

    Raises:
    ValueError: If the input is not a list or is an empty list.
    """
    if not stress_values or not isinstance(stress_values, list):
        raise ValueError("Input must be a non-empty list of stress values.")

    # Initialize variables to hold the two highest values
    max_stress = float('-inf')
    second_max_stress = float('-inf')

    # Single pass to find the two highest distinct stress values
    for stress in stress_values:
        if stress > max_stress:
            second_max_stress, max_stress = max_stress, stress
        elif max_stress > stress > second_max_stress:
            second_max_stress = stress

    # Check if we have found at least two distinct values
    if second_max_stress == float('-inf'):
        return None  # Indicates not enough distinct values were found

    return max_stress * second_max_stress

# Example usage
def main():
    try:
        # Example stress values from material testing
        stress_values = [150, 200, 150, 300, 250, 300]
        product = calculate_product_of_highest_stresses(stress_values)
        if product is not None:
            print(f"The product of the two highest distinct stress values is: {product}")
        else:
            print("The list must contain at least two distinct stress values.")
    except ValueError as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
