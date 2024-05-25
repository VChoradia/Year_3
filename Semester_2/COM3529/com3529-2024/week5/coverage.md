# Test Coverage

Recall the Forum example from last week, in the
[`uk.ac.shef.com3529.forum`](../code/lib/src/main/java/uk/ac/shef/com3529/forum/)
package.

Create a JaCoCo coverage report for it by issuing the following commands (on
Windows you may not need the `./` suffix). You'll need to ensure you're in the
`code` directory in your terminal shell:

```
./gradlew clean
./gradlew compileJava
./gradlew test --tests uk.ac.shef.com3529.forum.ForumTest
./gradlew jacocoTestReport
```

You should have a `build` directory in `code/lib/`, and within that a further
`reports/jacoco/test/html` subdirectory. From here, you can load the HTML files
in a web browser. Locate the test report for `ForumTest` that highlights code
lines in green, yellow, and red, as shown in lectures. 

## What you need to do

1. For each line in red, identify the __behaviour__ of `Forum` not tested by `ForumTest`.

2. Write a test for the behaviour. Ensure it is suffixed with `should` and has a
   clear Given/When/Then structure.

3. Assuming every line is now green in the JaCoCo test report for `ForumTest`
   are there other behaviours you could additionally test? Or did your test
   suite test all possible behaviours?

4. To what extent did you write tests to execute code, rather than to actually
   test the behaviour of the `Forum` class. 

## Discussion Questions

Have a think about the following questions, discussing them with a coursemate if
you can:

1. Do you think statement coverage is a useful concept in practice? 

2. What do you think statement coverage says about:
   
   a) how many bugs will be found?

   b) how many bugs will be left, if you get full coverage?

   c) how much testing has been done? 

   d) when to stop testing? 

2. Do you think 100% statement coverage is a realistic and useful goal?
