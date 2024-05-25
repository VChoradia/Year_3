# Week 2 Practical – Defects, Infections and Failures – Answers

See the classes [`DIFFixed.java`](../code/lib/src/main/java/uk/ac/shef/com3529/DIFFixed.java) and 
[`DIFTest.java`](../code/lib/src/test/java/uk/ac/shef/com3529/DIFTest.java) for implementations of 
the answers below.

## findLast

1. (a) The loop termination criterion is `i > 0`, it should be `i >= 0`. 

   (b) This causes the first element of the array to be ignored. So when `y` is
   equal to the first element of the array `x`, the method fails. 

   (c) See `findLast_failure`

2. (a) Yes, when `x` is `null`.

   (b) See `findLast_defectNotExecuted`.

3. (a) An infection occurs when the first element of the array is missed, for a
   non-empty array. Therefore, the defect is executed and an infection does not
   occur – when either (1) `x` is empty (zero-length) OR (2) `y` is in `x`, but `y` is
   not the first element of `x`. 

   (b) See `findLast_defectExecuted_noInfection`, based on the second reason above.

4. (a) Yes, when `y` is not in `x`. While the first element of the array is
   missed (hence an infection), y is not in x anyway, so the method
   returns the correct result and there is no failure.

   (b) See `findLast_defectExecuted_infectionCaused_noFailure`.

5. See [`DIFFixed.java`](../code/lib/src/main/java/uk/ac/shef/com3529/DIFFixed.java).


## countPositive

1. (a) The method counts zero numbers as positive. This defect is on the third
   line of the method, as part of the if condition. It should be `if (x[i] > 0)`
   not `if (x[i] >= 0)`

   (b) Zero values in the array x are included in the count, so that the method
   returns the wrong value .

   (c) See `countPositive_failure`.

2. (a) Yes, when the inputted array is null or of zero length. This means the if
   condition is never executed.

   (b) See `countPositive_defectNotExecuted`.

3. (a) The infection occurs as soon as the array has a zero value for one
   of its elements. So, when the array contains non-zero values, the defect
   is indeed executed, but there is no infection.

   (b) See `countPositive_defectExecuted_noInfection`.

4. (a) No. The state is infected when an element of `x` equals 0, but
   always leads to the `count` variable being incremented. Since `count` is
   returned by the method, this infection always propagates to the output.
   (Note: the assignment doesn't explicitly ask for a reason in the "no" case, 
   so one mark is awardable just for saying "no". If their reason is incorrect, 
   still feedback why, however.)

   (b) No JUnit test possible, in keeping with 4(a).
   
5. See [`DIFFixed.java`](../code/lib/src/main/java/uk/ac/shef/com3529/DIFFixed.java).


## lastZero

1. (a) The method returns the first zero, not the last. There is a mistake
       in that elements are being considered in reverse order. This means
       the "defect" could be interpreted to be in one of multiple places, for example:
   
      (1) the for loop header, which should start with `i = x.length - 1` 
      and count down to `i = 0` (i.e., the complete loop header should
      be `for (int i = x.length-1; i >= 0; i--)`)

      (2) in the if condition, where instead of `x[i]`, it could be `x[x.length - i - 1]`, 
      and the return statement in the true part would then be `return i+1`

      Other interpretations are possible. 

   (b) Where there is more than one zero in the array `x`. The index of the first
   zero is returned, rather than the last. 

   (c) See `lastZero_failure`.

2. (a) If we say the defect is (1) then the defect cannot be avoided, since at
   least part of the loop header (`int i=0`) is always executed.

   If the defect is (2) then a null inputted array would never execute the
   defect.

   (b) See `lastZero_defectNotExecuted`, necessarily based on defect 2.

3. (a) An infection occurs when the loop starts considering array values in
   the wrong order. If the defect is (1) the defect is executed but there
   is no infection if array has one value.  

   If the defect is (2) the defect is executed but there is no infection so
   long as the array has at least one value. If the array has one value, it
   is of no importance as to whether it is zero or not.

   (b) See `lastZero_defectExecuted_noInfection`, based on defect 2. A test
   based on defect 1 is also allowable (where the inputted array is null).

4. (a) Since an infection occurs when the loop starts considering array values
   in the wrong order, an infection would occur when the array has two values. A
   failure would _not_ occur if one or fewer of
   these elements is zero. 

   (b) See `lastZero_defectExecuted_infectionCaused_noFailure`.

5. See [`DIFFixed.java`](../code/lib/src/main/java/uk/ac/shef/com3529/DIFFixed.java).

## oddOrPos

1. (a) In the method, `x[i] % 2` should be `Math.abs(x[i] % 2)`, as the
   condition `"x[i] % 2 == 1"`  alone will not include negative numbers to be
   counted as odd  (since `x[i] % 2` of a negative odd number is -1).

   (b) The method will fail when an odd negative number, e.g. -1, is in the
   array, since the returned count will be incorrect.

   (c) See `oddOrPoss_failure`.

2. (a) A null or zero-length array will not executed the defect.

   (b) See `oddOrPoss_defectNotExecuted`.

3. (a) An infection occurs when the condition `x[i] % 2 == 1` evaluates to false for a
   negative number, since the correct condition should evaluate true
   according to the specification of the method.
   So any array with one or more elements that is *not* negative and odd will
   execute the defect but not cause an infection.

   (b) See `oddOrPos_defectExecuted_noInfection`.

4. (a) No, as soon as the state is infected, count takes on the wrong value
   which is always propagated to the output.    
   (Note: the assignment doesn't explicitly ask for a reason in the "no" case, 
   so one mark is awardable just for saying "no". If their reason is incorrect, 
   still feedback why, however.)

   (b) No answer possible. 

5. See [`DIFFixed.java`](../code/lib/src/main/java/uk/ac/shef/com3529/DIFFixed.java).

