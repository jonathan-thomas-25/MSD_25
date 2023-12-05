import random

def generate_random_data(n):
    # Initialize variables to store previous values
    prev_row = None
    prev_bank_group = None
    prev_bank = None

    # Set to store used values for the first element
    used_values = set()

    # List to store generated lines
    lines = []

    for i in range(1, n + 1):
        # Generate a unique random value for the first element
        while True:
            element1 = str(random.randint(1, n)).zfill(9)
            if element1 not in used_values:
                used_values.add(element1)
                break

        # Use the same bank group and bank for all elements in the group
        if i % 3 == 1:
            # Generate a random 34-bit binary number
            binary_number = bin(random.randint(0, 2**34-1))[2:].zfill(34)
            byte_select = hex(int(binary_number[-2:], 2))[2:].zfill(1)
            col_low = hex(int(binary_number[-6:-2], 2))[2:].zfill(1)
            row = hex(int(binary_number[-33:-18], 2))[2:].zfill(4)
            bank_group = hex(int(binary_number[-9:-6], 2))[2:].zfill(3)
            bank = hex(int(binary_number[-11:-10], 2))[2:].zfill(1)
        else:
            # Use the same bank group and bank as the previous element
            byte_select = prev_byte_select
            col_low = hex((int(prev_col_low, 16) + 1) % 16)[2:].zfill(1)
            row = prev_row
            bank_group = prev_bank_group
            bank = prev_bank

        # Format the extracted values as a single 32-bit hexadecimal number
        element4 = f"{byte_select}{col_low}{bank_group}{bank}{row}".upper()
        element2 = str(random.randint(1, 11))
        element3 = str(random.randint(0, 2))

        # Update previous values
        prev_row = row
        prev_bank_group = bank_group
        prev_bank = bank
        prev_byte_select = byte_select
        prev_col_low = col_low

        # Append the line to the list
        lines.append((element1, element2, element3, element4))

    return lines

# Get the value of n from user input
try:
    n = int(input("Enter the value of n: "))
except ValueError:
    print("Please provide a valid integer for n.")
    exit(1)

# Generate n lines of data
lines = generate_random_data(n)

# Sort lines based on the integer value of element1 (without leading zeros)
lines.sort(key=lambda x: int(x[0]))

# Specify the output file name
output_file_name = "output.txt"

# Open the file in write mode
try:
    with open(output_file_name, "w") as output_file:
        # Write each element separately to the file
        for line in lines:
            element1, element2, element3, element4 = line
            output_file.write(f"{int(element1)} {element2} {element3} {element4}\n")

    print(f"Data has been written to {output_file_name}")

    # Print extracted values
    for line in lines:
        i, element2, element3, element4 = line
        byte_select = element4[0]
        col_low = element4[1]
        bank_group = element4[2:5]
        bank = element4[5]
        row = element4[6:]
        print(f"{i} {element2} {element3} Byte Select: {byte_select} Column Low: {col_low} Bank Group: {bank_group} Bank: {bank} Row: {row}")

except Exception as e:
    print(f"Error: {e}")
finally:
    # Ensure the file is closed even if an exception occurs
    output_file.close()

