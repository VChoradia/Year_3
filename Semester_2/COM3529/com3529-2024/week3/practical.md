# Better Unit Testing

In the `code` directory, the package
[`uk.ac.shef.com3529.forum`](../code/lib/src/main/java/uk/ac/shef/com3529/forum/)
represents an online forum, with users and posts. There are three classes to
represent each of these aspects
– [`Forum`](../code/lib/src/main/java/uk/ac/shef/com3529/forum/Forum.java),
[`User`](../code/lib/src/main/java/uk/ac/shef/com3529/forum/User.java), and
[`Post`](../code/lib/src/main/java/uk/ac/shef/com3529/forum/Post.java)
respectively.

The
[`ForumTest`](../code/lib/src/test/java/uk/ac/shef/com3529/forum/ForumTest.java)
class exists to test the `Forum` class. However, the tests suffer from a number
of problems, including:

* Potential brittleness
* Lack of clarity
* Lack of conciseness
* A focus on testing implementation, as opposed to behaviour.

## What you need to do

Take each test in `ForumTest`. Based on what you have learnt in lectures:

1. Identify each of the potential problems with it, stating why it is/could be a
   problem.

2. Rewrite the test to remove the problems you have identified. 

3. Review your test according to the criteria you listed for (1), ensuring you
   have remedied the problems with it that you originally identified.
