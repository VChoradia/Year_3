# Better Unit Testing — Answers

### `shouldNotLoginBannedUser`

Problems:

* Violates "Make Tests Complete" principle – details of the forum and its users
  are hidden away in the `makeForum` helper method. They should be included in
  the test (DAMP not DRY principle).

* Violates "Make Tests Concise" principle – more users are registered in the the
  `makeForum` helper method than are needed by the test itself.

**Rewritten test:** see `shouldNotLoginBannedUser` in [`ForumTest_Better`](../code/lib/src/test/java/uk/ac/shef/com3529/forum/ForumTest_Better.java).

### `shouldGetRegisteredUser`

Problems:

* `getUser` is a package-private method, not a public method. The test is prone
  to brittleness, violating the "Test by calling public methods only" principle.

**Rewritten test:** see `shouldGetRegisteredUser` in [`ForumTest_Better`](../code/lib/src/test/java/uk/ac/shef/com3529/forum/ForumTest_Better.java).

### `testBan`

Problems:

* Violates "Make Tests Complete" principle – details of the forum and its users
  are hidden away in the `makeForum` helper method. They should be included in
  the test (DAMP not DRY principle).

* Violates "Make Tests Concise" principle – more users are registered in the the
  `makeForum` helper method than are strictly needed (we don't need register
  more than one user and ban them to test the banning behaviour).

* Violates "Don't Put Logic in Tests" principle. The test involves two `for`
  loops.

* The test is not behavior-driven because:
  
  (1) its name is `testBan`, making it seemingly targetted at the `ban` method
  of Forum – violating the "Don't Test Methods – Test Behaviours" principle. 

  (2) it checks the result of the `testBan` method by calling a package-private
  method of user – `isBanned`, violating the "Test by calling public methods
  only" principle.
  
  (3) it lacks a clear - Given X, When Y, Then Z" structure. 

**Rewritten test:** see  `shouldNotLetBannedUsersPost` in
[`ForumTest_Better`](../code/lib/src/test/java/uk/ac/shef/com3529/forum/ForumTest_Better.java).
Here we replace the original test by one that tests the behaviour of whether a
banned user can post (they should not be able to).

### `testGetMostProfilicPoster` 

* Violates "Make Tests Complete" principle – details of the forum and its users
  are hidden away in the `makeForum` and `makePosts` helper method. They should
  be included in the test (DAMP not DRY principle).

  Furthermore, the assertion checks for exactly 2 posts for the most prolific
  poster, however its unclear where the number 2 comes from. The reason is
  hidden away in the `makePosts` helper method.

* Violates "Make Tests Concise" principle – more users are registered in the the
  `makeForum` helper method and than are needed by the test itself.

* The method calls a package-private method of User - `numPostsMade` violating
  the "Test by calling public methods only" principle. This seems an unnecessary
  thing to do in this test – further violating the  "Make Tests Complete"
  principle.
  
* The test is not behavior-driven because:
  
  (1) its name is `testGetMostProfilicPoster`, making it seemingly targetted at
  the `getMostProlificUser` method of Forum – violating the "Don't Test Methods
  – Test Behaviours" principle.   

  (2) While it has a "Given X, When Y, Then Z" structure, this could be made
  more explicit in comments of the test. 

**Rewritten test:** see `shouldComputeMostProlificPoster` in [`ForumTest_Better`](../code/lib/src/test/java/uk/ac/shef/com3529/forum/ForumTest_Better.java)