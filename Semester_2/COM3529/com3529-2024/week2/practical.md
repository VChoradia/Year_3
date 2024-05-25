# Week 2 Practical – Defects, Infections and Failures

This practical involves the `DIF.java` class that is part of the Gradle
project that lives in the code directory of this repository. See
[`code/lib/src/main/java/uk/ac/shef/com3529/DIF.java`](../code/lib/src/main/java/uk/ac/shef/com3529/DIF.java).

The class contains four methods: `findLast`, `countPositive`, `lastZero`, and
`oddOrPos`.

Each method has a defect. You will need to write JUnit tests for each defect
and establish a fix.
    
Specifically, for each method in `DIF.java`, you will need to complete the following
tasks. The tests you write should be added to a class called `DIFTest.java` (NB:
When naming tests, `[methodName]` should be replaced by the name of the method
you are writing the test for.)

1. (a) What and where is the defect?

   (b) Under what condition(s) do inputs to the method cause it to fail?

   (c) Write ONE JUnit test case that causes the method to fail.
   This should be called `[methodName]_failure`. (Note that the test should also
   fail - i.e., the test should have an assertion for the _correct_ behaviour of the method.)

2. (a) Is it possible for inputs to the method to _not_ execute the defect? If so, describe
   the condition(s) necessary for the inputs to the method that would cause this to happen.

   (b) If possible (as per your answer to part (a)), write a JUnit test case that
   demonstrates the scenario of part (a) of this question. 
   This should be called `[methodName]_defectNotExecuted`.

3. (a) Is it possible for an input to execute the defect but _not_ infect the
   program's state? If so, describe
   the condition(s) necessary for the inputs to the method that would cause this to happen.

   (b) If possible (as per your answer to part (a)), write a JUnit test case that
   demonstrates the scenario of part (a) of this question. 
   Call it `[methodName]_defectExecuted_noInfection`.

4. (a) Is it possible for an input to cause an infection but _not_ cause the
   method to fail? (Note, program statements being executed when they shouldn't
   count as an infection.) If so, describe
   the condition(s) necessary for the inputs to the method that would cause this to happen.

   (b) If possible (as per your answer to part (a)), write a JUnit test case that
   demonstrates the scenario of part (a) of this question. 
   Call it `[methodName]_defectExecuted_infectionCaused_noFailure`. 

5. Fix the defect and add the fixed method to a class called
   `DIFFixed.java`. (Ensure the test you wrote as part of Question 1
   passes when run with the fixed version of the method.)
