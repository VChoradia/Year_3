# Test Doubles

Take a look at the
[`uk.ac.shef.com3529.calculator`](../code/lib/src/main/java/uk/ac/shef/com3529/calculator)
package, paying attention to the
[`Calculator`](../code/lib/src/main/java/uk/ac/shef/com3529/calculator/Calculator.java)
class.

When constructed with a
[`Reader`](../code/lib/src/main/java/uk/ac/shef/com3529/calculator/Reader.java)
and a
[`Writer`](../code/lib/src/main/java/uk/ac/shef/com3529/calculator/Writer.java),
the `calculate` method reads in two numbers and an operator – one of `+` (plus),
`-` (minus), `*` (times), or `/` (divide), and writes the result. The sources of
the reads and writes depend on how the `Reader` and `Writer` interfaces are
implemented. 

The
[`CommandLineCalculator`](../code/lib/src/main/java/uk/ac/shef/com3529/calculator/CommandLineCalculator.java)
implements `Reader` and `Writer` to use the keyboard as input and the console as
output, respectively. With a terminal open in the `code` directory of the
repository, you can build and run this example:

```
./gradlew build
java -cp ./lib/build/classes/java/main uk.ac.shef.com3529.calculator.CommandLineCalculator
```

An example run looks as follows:

```
Enter a number:
500
Enter an operator (+, -, *, or /):
/
Enter a number:
5
500.0 / 5.0 = 100.0
```

## What you need to do

**The aim of this exercise is to write a JUnit test suite for
[`Calculator`](../code/lib/src/main/java/uk/ac/shef/com3529/calculator/Calculator.java)
that gets full coverage of the class.**

You can check coverage with JaCoCo, as demonstrated in lectures.
You'll need to write test doubles for the Reader and Writer
interfaces. You can do this manually, or with Mockito. 

Note that with Mockito, you can make a stub return different values in sequence,
e.g.:

```
when(mock.getGreatestFootballTeams()).thenReturn("Everton", "Sheffield United");
```

That is, the `getGreatestFootballTeams()` method will return `"Everton"` the first time it is
called, and then `"Sheffield United"` the second time. You can achieve the same
effect by chaining `thenReturn` calls, as follows:

```
when(mock.getGreatestFootballTeams()).thenReturn("Everton").thenReturn("Sheffield United");
```

You can make a stub throw an exception with `thenThrow`, used as follows:

```
when(mock.getFootballTeam("Liverpool")).thenThrow(new ObjectionalTeamException());
```

Calls to `thenThrow` can be chained with `thenReturn`.

