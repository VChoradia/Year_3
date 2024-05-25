# Fuzzing – Practical Session

In this session, we will implement our first fuzzer for a simple Java program.

## Target Java Program

We begin by writing a very simple Java program that we will attempt to fuzz.

Create a new Java program named `Greeting.java` containing a single public class named `Greeting` with a main method.

In the main method, write a program following this specification:

- The program starts by printing `"What is your name?"` to console
- The program takes a string input from the user, for this, you can use a [Scanner](https://www.w3schools.com/java/java_user_input.asp) object.
- The program validates the input in the following ways:
  - If the input is empty, an `IllegalArgumentException` should be thrown.
  - Assume you have a maximum length for names called `BUFFER_SIZE=20`; if the input is longer than this limit, a `BufferOverflowException` should be thrown.
  - Strange characters are not allowed in a name. Use [pattern matching](https://www.w3schools.com/java/java_regex.asp) to check whether the name contains any of the characters covered in this pattern: `"[!@#$%&*()_+=|<>?{}\\[\\]~-]"`. If the input name contains any of these characters, an `IllegalArgumentException` should be thrown.
- Finally, print a greeting message to the console, e.g., `"Hi there, "`, concatenated with the valid input name.

Once you finish this, compile your Java program with `javac Greeting.java`.

If this gives you an error, you either have made some mistakes in the code or do not have Java installed in your machine. Check the output of the command `javac --version`.

Next, do a quick test by running `java Greeting` and passing your name as input – Does the program greet you? Great!

## Java Fuzzer

We will implement our simple Java fuzzer in Python, simply for convenience. Feel free to attempt this in a programming language of your choice. 

Let's start by creating a Python script named `jfuzzer.py`.

### Executing Java Program from Python

Fuzzing is a _dynamic_ testing technique, meaning that the program under test must be executed. So we need to write a function that can take a program and its parameters and execute it as a subprocess.

At this stage, the single most important thing to remember is that the fuzzer must execute the program and capture its output regardless of whether the input triggers a normal execution or a crash. **The fuzzer must never crash!**

Here is an example of a function that should work for our simple target program.

```python
from subprocess import run, PIPE

def run_program(program, input_string):
    prog_args = []
    execution = run(['java', program] + prog_args, stdout=PIPE, stderr=PIPE, input=input_string.encode("utf-8"))
    return execution
```

Notice that our `run_program` function oversimplifies the problem and _overfits_ to our target program by taking only one string as input and not taking any additional arguments. Feel free to improve this function to be able to execute more complex target programs.

You can now test that you can execute the `Greeting` Java program by running:

```shell
python3 -c "from jfuzzer import run_program; exec = run_program('Greeting', 'Jose'); print(exec.stdout.decode());"
```

### Generating Random Strings

A fuzzer is a random input generator at heart.

Write a function with the following signature:

```python
def generate_string(min_length=0, max_length=sys.maxsize):
    # your logic here
    return input_string
```

The function should:

- Define a certain alphabet, e.g., `alphabet = list("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-!@")`; notice that this example alphabet includes lowercase and uppercase letters, numbers and some special characters.
- At random, pick a length between `min_length` and `max_length` for the generated string, e.g., using [`random.randint`](https://www.w3schools.com/python/ref_random_randint.asp).
- In a loop, generate as many characters as needed by sampling from the given alphabet, e.g., using [`random.sample`](https://www.w3schools.com/python/ref_random_sample.asp), and concatenate them to your resulting string.
- Return the resulting string.

### Fuzzing driver

Now that we can run our target program and generate input strings to feed it with, let us write the actual fuzzing driver. The definition of this function will be as follows:

```python
def fuzzer(program, num_tests, max_length):
    tests = []
    # your logic here
    return tests
```

The inputs to the `fuzzer` function are the target program under test, the number of tests that we want to execute, and the maximum length we want for the input strings to be fed to the target program.

- For as many tests as needed, call the `generate_string` and the `run_program` in turn.
- Collate the execution results in a [dictionary](https://www.w3schools.com/python/python_dictionaries.asp), including the id of the test, the input used, and the output observed (i.e., what `run_program` returns).
- Return the test execution results in an array.

### Results

Finally, write one last function `print_results(tests)` to print the execution results obtained from the `fuzzer` method. This should be a straightforward loop, printing to console each of the tests run by the fuzzer. A suggested format is as follows:

```
Test #0:
    IN: jTtAahGSC
    OUT:    0
    CONSOLE:
     What's your name?
     Hi there, jTtAahGSC

Test #1:
    IN: L!peTbT
    OUT:    1
    ERROR:
     Exception in thread "main" java.lang.IllegalArgumentException
        at Greeting.main(Greeting.java:20)
```

Notice that the output of the `run_program` function is of type [CompletedProcess](https://realpython.com/python-subprocess/#the-completedprocess-object), which provides you with a `returncode` (which for Java programs is 0 only for normal executions), `stdout` which contains the output to console in case of normal executions, and `stderr` which contains the error output in the case of erroneous executions.

### Execute `jfuzzer`!

How exciting, our first fuzzer is ready!

Write the code for a main method where the required arguments are taken, i.e., the target program, number of cases, and maximum length for input strings, the `fuzzer` function is called and its results are printed.

Try different values for the number of tests and length of strings and study the results. Is your fuzzer able to reveal problems in the Java program, i.e., executions ending with an uncaught exception being thrown?

## Discussion

Discuss your implementation and results with the person sitting closer to you in the lab.

Discuss also different ways in which you could enhance your fuzzer, e.g.,

- Starting with valid names and performing [mutations](https://www.fuzzingbook.org/html/MutationFuzzer.html) instead of using completely random strings?
- Using a [grammar](https://www.fuzzingbook.org/html/Grammars.html) to drive the generation of tests?
- Supporting other Java programs besides the trivial `Greetings` program?
- Can you think of other ways?
