# COM3529 – Software Testing and Analysis <br /> Spring Semester 2024

Welcome! This repository code examples, practical sheets, and slides to support the Spring Semester module COM3529 "Software Testing and Analysis" at the University of Sheffield.

Jump to:
- [COM3529 – Software Testing and Analysis  Spring Semester 2024](#com3529-software-testing-and-analysis--spring-semester-2024)
  - [1. Teaching Staff](#1-teaching-staff)
  - [2. Schedule and Materials](#2-schedule-and-materials)
    - [Lectures](#lectures)
    - [Practical Sessions (Labs)](#practical-sessions-labs)
  - [3. Assessment](#3-assessment)

## 1. Teaching Staff

  |<img src="misc/images/phil.jpg" width="150"/> | <img src="misc/images/jose.jpg" width="150"/> | <img src="misc/images/islam.jpg" width="150"/> | <img src="misc/images/megan.jpg" width="150"/> | <img src="misc/images/rui.jpg" width="150"/> |
  |:-:|:-:|:-:|:-:|:-:|
  | **[Phil McMinn](https://mcminn.info)** <br /> Lecturer <br /> Weeks 1-5 | **[José Rojas](https://jmrojas.github.io)** <br /> Lecturer <br /> Weeks 6-11 | **Islam Elgendy** <br /> Teaching Assistant | **Megan Maton** <br /> Demonstrator | **Ruizhen (Rui) Gu** <br /> Demonstrator|

## 2. Schedule and Materials

| Week | Lecture | Practical Session |
|-:|-|-|
|1 | **[Introduction](week1/1-introduction.pdf)**<ul><li>Beizer's Maturity Model</li><li>Why finding all bugs is impossible</li><li>How software failures happen (the RIPR model)</li></ul>| [Getting Started](week1/practical-session-background-information.pdf) |
|2 | **Testing Big and Small Part 1**<ul><li>[Test Automation](week2/2-test-automation.pdf)</li><li>[Testing Scope (The Test Triangle)](week2/3-test-scope.pdf)</li><li>[Unit Testing Part 1](week2/4-1-unit-testing-part-1.pdf)<ul><li>Avoiding Brittle Tests</li></ul></li></ul> | [Defects, Infections and Failures](week2/practical.md) ([Solutions](week2/practical-solutions.md)) | 
|3 | **Testing Big and Small Part 2**<ul><li>[Unit Testing Part 2](week3/4-2-unit-testing-part-2.pdf)<ul><li>Writing Clear Unit Tests</li></ul><li>[Test Doubles](week3/5-test-doubles.pdf)</li></ul> | [Better Unit Testing](week3/practical.md) ([Solutions](week3/practical-solutions.md)) | 
|4 | **Testing Big and Small Part 3**<ul><li>[Larger Tests](week4/6-larger-tests.pdf)</li></ul>**Coverage Criteria, Part 1**<ul><li>[Introduction to Coverage Criteria](week4/7-coverage-criteria.pdf)</li></ul> | [Test Doubles](week4/practical.md) ([Solutions](week4/practical-solutions.md)) |
|5 | **Coverage Criteria, Part 2**<ul><li>[Control Flow Analysis and Testing](week5/8-control-flow-analysis-and-testing.pdf)</li><li>[Data Flow Analysis and Testing](week5/9-data-flow-analysis-and-testing.pdf)</li><li>[Conclusions on Coverage](week5/10-coverage-criteria-conclusions.pdf)</li></ul> | [Test Coverage](week5/coverage.md) ([Solutions](week5/coverage-solutions.md)) and [Control Flow Graphs](week5/cfgs.md) ([Solutions](week5/cfgs-solutions.md)) |
|6 | **[Mutation Testing](week6/w6-mutation.pdf)** | [Code Defenders](week6/CodeDefenders.pdf) |
|7 | **[Regression Testing (Test Suite Selection, Minimisation and Prioritisation)](week7/w7-regression.pdf)** | [Regression Testing](week7/regression-testing.md) ([Solution](week7/regression-testing-solutions.md)) |
|Easter| | |
|8 | *No lecture* | *No practical session* |
|9 | **[Fuzzing](week9/w9-fuzzing.pdf)** | [Your first fuzzer](week9/practical/Fuzzing.md) ([Solution](week9/practical/solution/)) |
|10| **[Search-based Test Generation](week10/w10-sbst.pdf)** | [EvoSuite Tutorial](week10/evosuite-demo/evosuite-demo.md) |
|11| **[Model-Based Testing](week11/w11-MBT.pdf)** (Last year's recordings: [Intro](https://drive.google.com/file/d/1Fa_47Nd5KaMsfZLTi9dXXcZ5qj36i6RL/view?usp=sharing), [FSM Properties](https://drive.google.com/file/d/1F_CZAG1JthjXx5i6U6NolxMyo0f40asR/view?usp=sharing), [Transition Tours](https://drive.google.com/file/d/1FcOVa8uuN6Cax35W2kgEPVsukoIsd3S8/view?usp=sharing), [Checking States](https://drive.google.com/file/d/1Fc3uRjIT88gKvThEXpcKO979r5QY3fnQ/view?usp=sharing), [W Method](https://drive.google.com/file/d/1FeKXXhw-lfN3cpd-JcyJIkDzz_j-Ydle/view?usp=drive_link)) | [Exercises](week11/MBT-practical.md) (Solution [.md](week11/MBT-practical-solutions.md)[.pdf](week11/MBT-practical-solutions.pdf)) |

### Lectures

Lectures will be held on **Tuesdays 1-2pm in the [Sir Henry Stephenson Building](https://www.sheffield.ac.uk/acse/department/facilities/sir-henry-stephenson-building), Lecture Theatre 2**. 

### Practical Sessions (Labs)

Practical Sessions (Labs) will be held on **Thursdays 1-2pm in Computer Room 3 on level 2 of the [Diamond](https://www.sheffield.ac.uk/engineering/diamond-engineering/floor-plans)**. These sessions will be a mix of coding and paper/pen exercises that are designed to help you prepare for the exam, based on that week's lecture materials. You'll need to bring your own laptop to the session, and have Java 11 or better installed on it. More information can be found in the [Getting Started](week1/practical-session-background-information.pdf) slides from week 1's practical session. You can use the laptop loan facility if you wish.


## 3. Assessment

COM3529 is assessed 100% by an exam, to be scheduled sometime in Weeks 13, 14 or 15.

**The practical sessions are designed to prepare you with exercises that will be similar to questions asked in the exam**. 

The exam may feature questions **requiring you to write Java code**. This code
needs to be **syntactically correct** and may involve writing JUnit tests that
call methods in libraries studied in the module (e.g., mocking libraries).

