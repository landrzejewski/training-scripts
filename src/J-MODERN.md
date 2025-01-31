---
title: "Modern Java"
author: "Łukasz Andrzejewski"
---

# Modern Java

## Summary of the most important changes in each LTS release

Below is a detailed list of the key language changes introduced in each Long-Term Support (LTS) 
version of Java from Java 8 to Java 21

### Java 8 (Released March 2014)

1. Lambda Expressions
- Introduced functional programming capabilities, allowing behavior to be passed as parameters.
- Enabled more concise and readable code by reducing boilerplate associated with anonymous classes.

2. Stream API
- Provided a new abstraction for processing sequences of elements, supporting operations like map, filter, and reduce.
- Facilitated parallel processing of collections, improving performance and scalability.

3. Functional Interfaces
- Defined interfaces with a single abstract method, serving as targets for lambda expressions and method references.
- Enhanced the ability to write more flexible and reusable code components.

4. Method References
- Offered a shorthand notation for lambda expressions that execute existing methods.
- Improved code readability and maintainability by referencing methods directly.

5. Default Methods in Interfaces
- Allowed interfaces to include default method implementations.
- Enhanced backward compatibility by enabling interfaces to evolve without breaking existing implementations.

6. Optional Class
- Addressed the issue of null references by providing a container object that may or may not contain a non-null value.
- Encouraged better handling of potential null values, reducing the likelihood of `NullPointerException`.

7. New Date and Time API (java.time)
- Introduced a comprehensive and consistent API for date and time manipulation.
- Replaced the older `java.util.Date` and `java.util.Calendar` classes with more robust alternatives.

8. Repeating Annotations and Type Annotations
- Enabled multiple annotations of the same type on a single element.
- Improved type checking and clarity in code annotations.

### Java 11 (Released September 2018)

1. Local-Variable Syntax for Lambda Parameters
- Introduced the `var` keyword for lambda parameters, enhancing readability and allowing annotations on parameters.

2. Enhanced String API
- Added new methods such as `isBlank()`, `lines()`, `strip()`, `stripLeading()`, `stripTrailing()`, and `repeat(int)` to facilitate more versatile string manipulations.

3. Unicode 10 Support
- Updated the Java platform to support the latest Unicode standards, improving internationalization and compatibility with diverse character sets.

4. Removal and Deprecation of Features
- Removed the Nashorn JavaScript engine, streamlining the platform.
- Deprecated several older APIs to reduce redundancy and encourage the use of more modern alternatives.

5. HTTP Client Enhancements
- Enhanced the existing HTTP client to support HTTP/2 and WebSocket, providing better performance and modern protocol support.

6. Flight Recorder and Other JVM Enhancements
- Included JVM-level enhancements like Flight Recorder for profiling and monitoring applications with minimal performance overhead.

Note: Java 11 primarily focused on API enhancements, performance improvements, and removal of outdated features rather than introducing major new language constructs.

### Java 17 (Released September 2021)

1. Sealed Classes and Interfaces
- Allowed classes and interfaces to restrict which other classes or interfaces can extend or implement them.
- Facilitated the creation of more controlled and predictable type hierarchies.

2. Pattern Matching for `instanceof`
- Simplified type checks and casting by allowing the extraction of variables within the `instanceof` operator.
- Reduced boilerplate code associated with type casting.

3. Text Blocks
- Introduced multi-line string literals, enhancing the readability and maintainability of code that deals with large blocks of text, such as JSON or SQL queries.

4. Records (Finalized in Java 16)
- Provided a compact syntax for declaring classes that are transparent carriers for immutable data.
- Reduced the boilerplate associated with plain data-holding classes.

5. Enhanced `switch` Statements (Preview Features)
- Introduced more expressive and flexible `switch` constructs, allowing for more concise and readable control flow structures.

6. Enhanced Pseudo-Random Number Generators (PRNGs)
- Expanded the set of PRNG algorithms available in the Java platform, providing developers with more options for generating random numbers.

7. Foreign Function & Memory API (Incubator)
- Introduced APIs to allow Java programs to interoperate with code and data outside of the Java runtime, facilitating integration with native libraries.

### Java 21 (Released September 2023)

1. Record Patterns (Preview)
- Enabled the deconstruction of record values, allowing more concise and readable code when working with records.
- Facilitated pattern matching with records in conditional statements and expressions.

2. Pattern Matching for `switch` (Second Preview)
- Enhanced `switch` statements to support pattern matching, making them more powerful and expressive.
- Allowed `switch` constructs to handle complex data-oriented queries more naturally.

3. Virtual Threads (Project Loom)
- Introduced lightweight threads managed by the JVM, simplifying concurrent programming.
- Enabled developers to write highly concurrent applications with improved scalability and performance.

4. Sequenced Collections
- Provided ordered versions of collection interfaces, ensuring that elements maintain a defined encounter order.
- Enhanced predictability and consistency when processing collections.

5. Enhanced Switch Expressions and Sealed Interfaces
- Continued improvements to `switch` expressions, making them more robust and versatile.
- Further refined sealed interfaces for more controlled type hierarchies.

6. Improved String Handling and Performance Optimizations
- Enhanced the underlying implementation of strings for better performance and reduced memory footprint.
- Included optimizations that benefit both runtime performance and developer productivity.

7. Deprecation and Removal of Legacy Features
- Continued the process of deprecating and removing outdated APIs and features to streamline the Java platform.
- Encouraged the adoption of more modern and efficient alternatives.

8. Enhanced Pattern Matching and Type Inference
- Expanded capabilities of pattern matching beyond basic types, allowing more complex and nested patterns.
- Improved type inference mechanisms to reduce the need for explicit type declarations.

## The new publishing cycle and its impact on everyday development

The new publishing cycle of Java, established in recent years, has significantly transformed the landscape of everyday
software development. Moving away from the traditional multi-year release intervals, Java now follows a predictable 
six-month release cadence, ensuring that new features, enhancements, and performance improvements are 
delivered consistently and regularly. Every three years, a Long-Term Support (LTS) version is released, 
providing a stable and supported foundation for enterprises and long-term projects. This streamlined cycle allows 
developers to access the latest language innovations and API improvements more swiftly, fostering a culture of 
continuous improvement and innovation. Consequently, development teams can leverage cutting-edge tools and features 
to enhance productivity, code quality, and application performance without waiting for extended periods between major 
releases. However, the increased frequency of updates also demands that organizations adopt more agile maintenance 
practices, ensuring that their codebases remain compatible and up-to-date with the latest Java versions. Overall, 
the new publishing cycle strikes a balance between delivering rapid advancements and maintaining stability through 
LTS releases, thereby enhancing the efficiency, flexibility, and responsiveness of everyday Java development.

## JDK and licensing issues

The Java Development Kit (JDK) is an essential toolkit for Java developers, providing the necessary tools to 
develop, compile, debug, and run Java applications. It includes the Java Runtime Environment (JRE), 
an interpreter/loader (Java), a compiler (javac), an archiver (jar), a documentation generator (javadoc), 
and other utilities necessary for Java development. The JDK serves as the foundational platform for building 
Java applications, ensuring that developers have access to the latest language features, libraries, and runtime environments.

Historically, Oracle provided the official JDK under the Oracle Binary Code License Agreement, which permitted free 
use for personal and development purposes but required a commercial license for production use in organizations. 
This licensing model posed challenges for businesses seeking to deploy Java applications at scale, as it introduced 
potential costs and legal considerations.

In contrast, OpenJDK emerged as the open-source reference implementation of the Java Platform, Standard Edition (Java SE). 
Licensed under the GNU General Public License, version 2, with the Classpath Exception (GPLv2+CE), OpenJDK offered a free 
and open alternative for developers and organizations. This allowed broader adoption without the constraints of 
proprietary licensing, fostering a more inclusive and collaborative Java ecosystem.

Starting with Java 11, Oracle shifted the licensing model for its JDK distributions. Oracle JDK began to require a 
commercial license for production use, aligning it more closely with OpenJDK's licensing terms. This change prompted 
many organizations to reconsider their Java deployment strategies, leading to increased adoption of OpenJDK and other 
open-source distributions such as Amazon Corretto, AdoptOpenJDK (now part of Eclipse Adoptium), Azul Zulu, and Red Hat OpenJDK.

The Java community has largely embraced the shift towards open-source JDK distributions, recognizing the benefits of 
reduced costs, increased transparency, and collaborative innovation. Oracle continues to contribute to OpenJDK, ensuring 
that it remains the cornerstone of Java development. Meanwhile, alternative vendors have differentiated themselves by 
offering specialized features, extended support, and performance optimizations tailored to various use cases.

Looking forward, organizations must remain vigilant about licensing terms and the evolving landscape of JDK distributions. 
As Java continues to evolve with new features and improvements, maintaining compliance with licensing agreements and 
leveraging the right JDK distribution will be crucial for sustaining efficient and secure Java development practices.

### Selecting the Implementation and JDK Version

Choosing the right Java Development Kit (JDK) implementation and version is crucial for ensuring the efficiency, security, and maintainability of your Java applications. With multiple JDK distributions and frequent releases, making an informed decision requires understanding the available options and assessing them against your project’s specific needs. Below is a comprehensive guide to help you navigate this selection process.

#### Understanding JDK Implementations

Several JDK implementations are available, each with its own set of features, licensing models, and support options:

- Oracle JDK
    - Description: The original JDK provided by Oracle, historically the standard for Java development.
    - Licensing: As of Java 11, Oracle JDK requires a commercial license for production use, though free for personal and development purposes.
    - Support: Oracle offers commercial support and updates for Oracle JDK.

- OpenJDK
    - Description: The open-source reference implementation of the Java Platform, Standard Edition (Java SE).
    - Licensing: Distributed under the GNU General Public License, version 2, with the Classpath Exception (GPLv2+CE).
    - Support: Supported by the open-source community and various vendors offering commercial support.

- Amazon Corretto
    - Description: A free, multiplatform, production-ready distribution of OpenJDK by Amazon.
    - Licensing: Open-source under the GPLv2+CE.
    - Support: Long-term support with regular updates provided by Amazon.

- Eclipse Temurin (formerly AdoptOpenJDK)
    - Description: A widely adopted OpenJDK distribution managed by the Eclipse Foundation.
    - Licensing: Open-source under GPLv2+CE.
    - Support: Community-driven with commercial support options available through partners.

- Azul Zulu
    - Description: A certified, tested, and supported build of OpenJDK by Azul Systems.
    - Licensing: Offers both open-source (GPLv2+CE) and commercial licenses.
    - Support: Comprehensive support services, including long-term support (LTS).

- Red Hat OpenJDK
    - Description: OpenJDK builds provided by Red Hat, optimized for enterprise use.
    - Licensing: Open-source under GPLv2+CE.
    - Support: Backed by Red Hat’s enterprise support offerings.

- BellSoft Liberica JDK
    - Description: An OpenJDK distribution with additional features like embedded JDK and JavaFX.
    - Licensing: Open-source under GPLv2+CE, with commercial options available.
    - Support: Offers long-term support and commercial support services.

Choosing the right JDK version is equally important, as it impacts the features available, performance, and long-term support. 
Here’s how to approach version selection:

- Long-Term Support (LTS) vs. Non-LTS Releases
    - LTS Versions: These versions, released every three years (e.g., Java 8, 11, 17, 21), receive extended support and are ideal for production environments requiring stability.
    - Non-LTS Versions: Released every six months, these versions provide access to the latest features but have a shorter support lifecycle, suitable for experimentation and staying up-to-date with innovations.

- Stability vs. Latest Features
    - Stability Needs: For mission-critical applications, opting for an LTS version ensures a stable and supported foundation.
    - Feature Requirements: If your project benefits from the latest language enhancements or performance improvements, consider adopting a newer non-LTS version, keeping in mind the need for more frequent upgrades.

- Project Requirements and Dependencies
    - Library and Framework Compatibility: Ensure that your project's dependencies are compatible with the chosen JDK version to avoid integration issues.
    - Legacy Code Considerations: For projects with significant legacy code, maintaining consistency with an older JDK version may reduce refactoring efforts.

- Support Timelines and Lifecycle
    - End of Public Updates: Be aware of the support timelines for each JDK version to plan migrations before end-of-life (EOL) dates.
    - Vendor-Specific Support: Different JDK distributions may offer varying support durations, so align your choice with your organization’s maintenance capabilities.

- Security and Compliance
    - Security Patches: Choose a JDK version that receives regular security updates to protect against vulnerabilities.
    - Compliance Requirements: Ensure that the selected JDK complies with your organization’s regulatory and security standards.

## Migration strategies

When transitioning to a different JDK implementation or upgrading to a newer version, follow these steps to ensure a smooth migration:

- Compatibility Testing: Validate that your application runs correctly on the new JDK by conducting comprehensive testing, including unit, integration, and performance tests.
- Dependency Verification: Ensure all third-party libraries and frameworks used in your project are compatible with the target JDK version and implementation.
- Performance Benchmarking: Compare the performance metrics between the current and new JDK to identify any improvements or regressions.
- Gradual Rollout: Implement the new JDK in staging environments before deploying to production to monitor behavior and address issues proactively.
- Backup and Rollback Plans: Maintain backups and establish rollback procedures to revert to the previous JDK version in case of critical issues during migration.
- Documentation and Training: Update project documentation to reflect the new JDK details and provide training to the development team on any new features or changes introduced.

## Managing multiple Java versions

Developers often need to work with multiple versions of Java to test compatibility, leverage new language features, or 
maintain legacy applications. Two popular tools for managing and switching between different Java versions are SDKMAN 
and JVMS. This article outlines how to use these tools, providing command-line examples and best practices for managing 
multiple Java versions on a single system.

### Using SDKMAN

SDKMAN is a popular command-line tool for managing parallel versions of various SDKs, including multiple Java distributions.
It provides an easy way to install, switch, and configure Java environments.

Run the following command in your terminal to install SDKMAN:

```bash
curl -s "https://get.sdkman.io" | bash
```

Follow the instructions displayed (which typically involve restarting your terminal or sourcing the SDKMAN initialization script).

Once installed, you can list all the available Java distributions and versions by running:

```bash
sdk list java
```

This command displays a table with various vendors and version identifiers (for example, OpenJDK, Zulu, Temurin).

To install a specific Java version, use the install command with the version identifier from the list:

```bash
sdk install java 17.0.2-tem
```

After installation, switch to that version with:

```bash
sdk use java 17.0.2-tem
```

You can also set a Java version as the default:

```bash
sdk default java 17.0.2-tem
```

Check the active Java version by running:

```bash
java -version
```

This confirms that the environment reflects your SDKMAN selection.

### Using JVMS

JVMS (Java Version Manager) is another tool designed specifically for switching between multiple Java versions. 
While SDKMAN manages various SDKs, JVMS focuses on Java and provides a lightweight approach to switch between 
JDKs without altering system paths permanently.

JVMS can typically be installed by cloning its repository and adding it to your shell’s startup script. 
For example, if using a Unix-like system:

```bash
git clone https://github.com/patrickfav/jvms.git ~/jvms
echo 'export PATH="$HOME/jvms/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

*Note:* Adjust installation steps according to the instructions provided in the [JVMS repository](https://github.com/patrickfav/jvms) or its documentation.

List the available installed versions managed by JVMS with a command similar to:

```bash
jvms list
```

To add a new Java version, follow the JVMS instructions (this could involve specifying the path to a Java installation 
or using integrated download features if available).

Switch between installed versions using a command like:

```bash
jvms use 17.0.2
```

This command temporarily sets the specified version as active in your current terminal session. To check the active version:

```bash
java -version
```

Both SDKMAN and JVMS allow you to switch Java versions on the fly, making it easy to integrate into build scripts,
continuous integration pipelines, or development environments where specific versions are required. You can script 
version changes as part of your project setup to ensure consistency across development machines.

# Major changes at the language and SDK level

## Lambda Expressions

Lambda Expressions were introduced in Java 8 as a significant enhancement to the language, bringing functional programming capabilities to the Java ecosystem. They allow developers to treat functionality as a method argument or even create anonymous functions, enabling behavior to be passed around and executed dynamically. This feature facilitates more concise and readable code by reducing the boilerplate associated with traditional anonymous classes. By leveraging Lambda Expressions, developers can implement interfaces with a single abstract method (functional interfaces) in a more streamlined and expressive manner, enhancing code maintainability and clarity.

Description of the Change:

Before Java 8, implementing functionalities that required passing behavior as parameters often involved creating verbose anonymous inner classes. This approach not only increased the amount of boilerplate code but also made the code harder to read and maintain. Lambda Expressions address this by providing a clear and concise syntax for writing such implementations. They encapsulate a block of code that can be executed later, making it easier to pass behavior as data. This shift towards a more functional programming style allows for better utilization of Java's Stream API and other functional interfaces, promoting more declarative and expressive coding practices.

Code Examples:

*Before Java 8 (Using Anonymous Inner Classes):*

```java
import java.util.Arrays;
import java.util.List;
import java.util.Collections;
import java.util.Comparator;

public class AnonymousClassExample {
    public static void main(String[] args) {
        List<String> names = Arrays.asList("Alice", "Bob", "Charlie", "David");
        // Sorting using an anonymous inner class
        Collections.sort(names, new Comparator<String>() {
            @Override
            public int compare(String a, String b) {
                return b.compareTo(a);
            }
        });

        for (String name : names) {
            System.out.println(name);
        }
    }
}
```

*Output:*
```
David
Charlie
Bob
Alice
```

*With Java 8 Lambda Expressions:*

```java
import java.util.Arrays;
import java.util.List;
import java.util.Collections;

public class LambdaExample {
    public static void main(String[] args) {
        List<String> names = Arrays.asList("Alice", "Bob", "Charlie", "David");
        // Sorting using a lambda expression
        Collections.sort(names, (a, b) -> b.compareTo(a));

        names.forEach(name -> System.out.println(name));
    }
}
```

*Output:*
```
David
Charlie
Bob
Alice
```

Explanation of the Example:

In the Anonymous Inner Class example, sorting the list of names in descending order requires creating a new `Comparator` instance with an overridden `compare` method. This results in multiple lines of boilerplate code, making the implementation verbose.

Conversely, the Lambda Expression example achieves the same functionality with a more concise syntax. The lambda `(a, b) -> b.compareTo(a)` directly represents the comparison logic, eliminating the need for boilerplate code associated with anonymous classes. Additionally, the `forEach` method combined with a lambda expression further streamlines the iteration over the list, enhancing readability.

Benefits of Lambda Expressions:

1. Conciseness: Reduces the amount of code required to implement functional interfaces.
2. Readability: Offers a clear and straightforward syntax that makes the code easier to understand.
3. Maintainability: Simplifies code maintenance by minimizing boilerplate and focusing on the core logic.
4. Enhanced API Integration: Works seamlessly with Java's Stream API and other functional interfaces, enabling powerful data processing capabilities.

## Stream API

The Stream API was introduced in Java 8 as a powerful abstraction for processing sequences of elements in a declarative and functional manner. It provides a comprehensive set of operations such as `map`, `filter`, and `reduce` that allow developers to perform complex data manipulations and transformations with ease. By leveraging the Stream API, developers can write more expressive and concise code, enhancing both readability and maintainability. Additionally, the Stream API facilitates parallel processing of collections, significantly improving performance and scalability for large datasets by utilizing multi-core architectures effectively.

Description of the Change:

Prior to Java 8, processing collections typically involved iterative approaches using loops, which often resulted in verbose and error-prone code. Operations like filtering, mapping, and aggregating data required explicit handling within loops, leading to boilerplate code that was difficult to manage and optimize. The introduction of the Stream API revolutionized this paradigm by providing a fluent and functional interface for performing these operations. Streams represent a sequence of elements supporting sequential and parallel aggregate operations, enabling developers to chain multiple operations in a clear and concise manner. This shift not only reduces the amount of code but also enhances the ability to optimize performance through parallelism without compromising code readability.

Code Examples:

*Before Java 8 (Using Iterative Approach):*

```java
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class IterativeExample {
    public static void main(String[] args) {
        List<String> names = Arrays.asList("Alice", "Bob", "Charlie", "David", "Eve");
        List<String> filteredNames = new ArrayList<>();

        // Filtering names that start with 'C' or later alphabetically
        for (String name : names) {
            if (name.compareTo("C") >= 0) {
                filteredNames.add(name);
            }
        }

        // Converting names to uppercase
        List<String> upperCaseNames = new ArrayList<>();
        for (String name : filteredNames) {
            upperCaseNames.add(name.toUpperCase());
        }

        // Printing the result
        for (String name : upperCaseNames) {
            System.out.println(name);
        }
    }
}
```

*Output:*
```
CHARLIE
DAVID
EVE
```

*With Java 8 Stream API:*

```java
import java.util.Arrays;
import java.util.List;

public class StreamExample {
    public static void main(String[] args) {
        List<String> names = Arrays.asList("Alice", "Bob", "Charlie", "David", "Eve");

        
        // Processing the stream
        names.stream()
             .filter(name -> name.compareTo("C") >= 0) // Filtering
             .map(String::toUpperCase)                 // Mapping to uppercase
             .forEach(System.out::println);            // Consuming the stream
    }
}
```

*Output:*
```
CHARLIE
DAVID
EVE
```

Explanation of the Example:

In the Iterative Approach example, filtering and transforming the list of names involves multiple separate loops. First, it filters names that are alphabetically "C" or later, then converts the filtered names to uppercase, and finally prints each name. This results in multiple lists (`filteredNames` and `upperCaseNames`) and several loops, making the code lengthy and harder to maintain.

In contrast, the Stream API example accomplishes the same task in a more streamlined and readable manner. By creating a stream from the `names` list, it applies a `filter` operation to retain names that meet the criteria, then uses a `map` operation to convert each name to uppercase, and finally consumes the stream with a `forEach` operation to print the results. This chaining of operations eliminates the need for intermediate lists and loops, resulting in more concise and maintainable code.

Benefits of the Stream API:

1. Declarative Syntax: Enables developers to express complex data processing tasks in a clear and concise manner without explicit iteration.
2. Enhanced Readability: Chained operations provide a fluent interface that is easier to read and understand compared to traditional loop-based approaches.
3. Parallel Processing: Simplifies the implementation of parallelism by allowing streams to be processed in parallel with minimal code changes, leveraging multi-core processors for improved performance.
4. Lazy Evaluation: Optimizes performance by deferring computation until necessary, enabling efficient handling of large datasets through short-circuiting and optimized operation ordering.
5. Reduced Boilerplate: Minimizes the amount of code required for common data processing tasks, reducing the likelihood of errors and enhancing maintainability.
6. Functional Programming Integration: Complements other functional programming features introduced in Java 8, such as lambda expressions and method references, promoting a more functional style of coding.

The Stream API fundamentally transforms how developers interact with collections and data sequences in Java, fostering more efficient and expressive programming practices.

## Functional Interfaces

Functional Interfaces were introduced in Java 8 as a foundational element to support functional programming paradigms within the Java language. A functional interface is defined as an interface that contains exactly one abstract method, making it eligible to be implemented by lambda expressions and method references. This design allows developers to create more flexible and reusable code components by treating functionality as data, thereby enabling behaviors to be passed as parameters or returned from methods. Functional Interfaces streamline the implementation of callbacks, event handlers, and other functional patterns, promoting cleaner and more concise code structures.

Description of the Change:

Prior to Java 8, creating instances of interfaces that required specific behaviors typically involved implementing anonymous inner classes, which often resulted in verbose and less readable code. The introduction of Functional Interfaces simplified this process by allowing interfaces with a single abstract method to be implemented using lambda expressions and method references. This not only reduced boilerplate code but also enhanced the expressiveness and flexibility of Java applications. By designating certain interfaces as functional, Java enabled a seamless integration of functional programming techniques, fostering the development of more modular and maintainable codebases.

Code Examples:

*Before Java 8 (Using Anonymous Inner Classes):*

```java
import java.util.Arrays;
import java.util.List;

public class AnonymousClassExample {
    public static void main(String[] args) {
        List<String> names = Arrays.asList("Alice", "Bob", "Charlie", "David");

        // Using an anonymous inner class to implement Runnable
        Runnable runnable = new Runnable() {
            @Override
            public void run() {
                names.forEach(new Consumer<String>() {
                    @Override
                    public void accept(String name) {
                        System.out.println(name);
                    }
                });
            }
        };

        new Thread(runnable).start();
    }
}
```

*Output:*
```
Alice
Bob
Charlie
David
```

*With Java 8 Functional Interfaces and Lambda Expressions:*

```java
import java.util.Arrays;
import java.util.List;

public class FunctionalInterfaceExample {
    public static void main(String[] args) {
        List<String> names = Arrays.asList("Alice", "Bob", "Charlie", "David");

        // Using a lambda expression to implement Runnable
        Runnable runnable = () -> names.forEach(name -> System.out.println(name));

        new Thread(runnable).start();
    }
}
```

*Output:*
```
Alice
Bob
Charlie
David
```

Explanation of the Example:

Implementing the `Runnable` interface requires creating an anonymous class with an overridden `run` method. Additionally, within the `run` method, another anonymous class is used to implement the 
`Consumer<String>` interface for the `forEach` operation. This nested structure leads to increased verbosity and makes the code harder to read and maintain.

The Functional Interface example leverages lambda expressions to implement both the `Runnable` and 
`Consumer<String>` interfaces succinctly. The lambda `() -> names.forEach(name -> System.out.println(name))` directly defines the behavior of the `run` method without the need for boilerplate code. This results in a more readable and maintainable implementation, showcasing the power and simplicity that Functional Interfaces bring to Java programming.

Benefits of Functional Interfaces:

1. Conciseness: Reduces the amount of code required to implement interfaces with single abstract methods by allowing the use of lambda expressions and method references.
2. Readability: Enhances code clarity by eliminating the need for verbose anonymous inner class syntax, making the intention of the code more apparent.
3. Reusability: Promotes the creation of reusable and modular code components by enabling behaviors to be passed as parameters or returned from methods.
4. Integration with Functional Programming: Facilitates the adoption of functional programming techniques in Java, enabling more expressive and declarative code styles.
5. Enhanced API Design: Encourages the development of more flexible and powerful APIs that can accept behaviors as arguments, leading to more versatile and adaptable libraries and frameworks.
6. Improved Maintainability: Simplifies code maintenance by minimizing boilerplate and focusing on the core logic, making it easier to manage and update codebases.

Functional Interfaces are integral to the evolution of Java, bridging the gap between object-oriented and functional programming paradigms, and empowering developers to write more efficient and expressive code.

## Method References

Method References were introduced in Java 8 as a syntactic enhancement to lambda expressions, providing a more concise and readable way to reference existing methods directly. Instead of using lambda expressions to call a method, developers can now use method references to achieve the same functionality with clearer and more maintainable code. This feature leverages the existing methods (both static and instance methods) and constructors, enabling developers to reduce boilerplate code and enhance the expressiveness of their programs. By referencing methods directly, code becomes easier to understand and less error-prone, promoting better coding practices and improving overall code quality.

Description of the Change:

Prior to Java 8, developers often used lambda expressions to pass behavior by invoking existing methods. While effective, this approach sometimes led to verbose code, especially when the lambda simply called another method without adding additional logic. Method References streamline this process by allowing developers to reference methods directly without the need for explicit lambda syntax. This not only makes the code more concise but also enhances readability by clearly indicating the intention to use a specific method. Method References integrate seamlessly with functional interfaces, enabling a more natural and declarative coding style that aligns with functional programming principles.

Code Examples:

*Before Java 8 (Using Lambda Expressions):*

```java
import java.util.Arrays;
import java.util.List;

public class LambdaExample {
    public static void main(String[] args) {
        List<String> names = Arrays.asList("Alice", "Bob", "Charlie", "David");

        // Using a lambda expression to print each name
        names.forEach(name -> System.out.println(name));
    }
}
```

*Output:*
```
Alice
Bob
Charlie
David
```

*With Java 8 Method References:*

```java
import java.util.Arrays;
import java.util.List;

public class MethodReferenceExample {
    public static void main(String[] args) {
        List<String> names = Arrays.asList("Alice", "Bob", "Charlie", "David");

        // Using a method reference to print each name
        names.forEach(System.out::println);
    }
}
```

*Output:*
```
Alice
Bob
Charlie
David
```

Explanation of the Example:

The `forEach` method is used with a lambda expression `name -> System.out.println(name)` to print each name in the list. While functional, this approach requires explicitly stating the parameter (`name`) and the method invocation, resulting in slightly more verbose code.

In contrast, the Method Reference example achieves the same functionality by using `System.out::println`, which directly references the `println` method of the `System.out` object. This eliminates the need for the lambda expression's parameter and method invocation syntax, resulting in cleaner and more readable code. The method reference clearly indicates that the `println` method should be applied to each element in the `names` list, making the code's intention immediately apparent.

Benefits of Method References:

1. Conciseness: Reduces the verbosity of lambda expressions by eliminating unnecessary parameters and method invocation syntax.
2. Readability: Enhances code clarity by directly referencing the intended method, making the code easier to understand at a glance.
3. Maintainability: Simplifies code maintenance by minimizing boilerplate, allowing developers to focus on the core logic.
4. Reusability: Encourages the reuse of existing methods without the need to create additional lambda expressions, promoting DRY (Don't Repeat Yourself) principles.
5. Integration with Functional Interfaces: Seamlessly works with functional interfaces, enabling more natural and declarative coding patterns.
6. Enhanced Expressiveness: Provides a more expressive way to convey the intended behavior, aligning with functional programming paradigms and improving overall code quality.

Method References thus offer a streamlined and elegant way to utilize existing methods within functional programming constructs, fostering more efficient and readable Java code.

## Default Methods in Interfaces

Default Methods in Interfaces were introduced in Java 8, marking a significant evolution in the Java language's capability to support more flexible and maintainable code architectures. Prior to Java 8, interfaces could only declare abstract methods without any implementations. This limitation made it challenging to extend interfaces without breaking existing implementations. Default Methods address this issue by allowing interfaces to include method implementations using the `default` keyword. This enhancement not only facilitates the evolution of interfaces by adding new methods without affecting existing classes but also promotes code reuse and cleaner API designs.

Description of the Change:

Before Java 8, any modification to an interface, such as adding a new method, required all implementing classes to provide concrete implementations for the new method. This necessity often led to significant refactoring and potential compatibility issues, especially in large codebases or when using third-party libraries. The introduction of Default Methods allows developers to add new methods to interfaces with predefined implementations. Implementing classes can choose to override these default methods if specific behavior is needed, or they can inherit the default behavior automatically. This capability enhances backward compatibility, reduces boilerplate code, and simplifies the maintenance and evolution of interfaces over time.

Code Examples:

*Before Java 8 (Interfaces Without Default Methods):*

```java
import java.util.List;
import java.util.ArrayList;

interface Vehicle {
    void startEngine();
}

class Car implements Vehicle {
    @Override
    public void startEngine() {
        System.out.println("Car engine started.");
    }
}

class Truck implements Vehicle {
    @Override
    public void startEngine() {
        System.out.println("Truck engine started.");
    }
}

public class InterfaceExample {
    public static void main(String[] args) {
        List<Vehicle> vehicles = new ArrayList<>();
        vehicles.add(new Car());
        vehicles.add(new Truck());

        for (Vehicle vehicle : vehicles) {
            vehicle.startEngine();
        }
    }
}
```

*Output:*
```
Car engine started.
Truck engine started.
```

*Adding a New Method to the Interface Without Default Methods:*

Suppose we want to add a new method `stopEngine()` to the `Vehicle` interface. Without default methods, all implementing classes (`Car`, `Truck`, etc.) must provide an implementation for `stopEngine()`, leading to potential refactoring.

*With Java 8 Default Methods:*

```java
import java.util.List;
import java.util.ArrayList;

interface Vehicle {
    void startEngine();

    // New method with a default implementation
    default void stopEngine() {
        System.out.println("Engine stopped.");
    }
}

class Car implements Vehicle {
    @Override
    public void startEngine() {
        System.out.println("Car engine started.");
    }

    // Optionally overriding the default method
    @Override
    public void stopEngine() {
        System.out.println("Car engine stopped.");
    }
}

class Truck implements Vehicle {
    @Override
    public void startEngine() {
        System.out.println("Truck engine started.");
    }
    // Inherits the default stopEngine() implementation
}

public class DefaultMethodExample {
    public static void main(String[] args) {
        List<Vehicle> vehicles = new ArrayList<>();
        vehicles.add(new Car());
        vehicles.add(new Truck());

        for (Vehicle vehicle : vehicles) {
            vehicle.startEngine();
            vehicle.stopEngine();
        }
    }
}
```

*Output:*
```
Car engine started.
Car engine stopped.
Truck engine started.
Engine stopped.
```

Explanation of the Example:

In the Pre-Java 8 example, the `Vehicle` interface declares a single abstract method `startEngine()`. Both `Car` and `Truck` classes implement this interface and provide their own versions of `startEngine()`. If a new method `stopEngine()` needs to be added to the `Vehicle` interface, both `Car` and `Truck` must implement this method, resulting in additional boilerplate code and potential maintenance challenges.

In the Java 8 example, the `Vehicle` interface includes a new method `stopEngine()` with a default implementation. The `Car` class chooses to override this default method to provide a specific implementation, while the `Truck` class inherits the default behavior without needing to implement it explicitly. This flexibility allows the interface to evolve by adding new methods without mandating changes to all existing implementing classes, thereby enhancing backward compatibility and reducing code maintenance efforts.

Benefits of Default Methods in Interfaces:

1. Backward Compatibility: Allows the addition of new methods to interfaces without breaking existing implementations, facilitating smoother API evolution.
2. Code Reuse: Promotes the reuse of common method implementations across multiple classes, reducing duplication and enhancing maintainability.
3. Enhanced API Design: Enables more expressive and feature-rich interfaces, allowing developers to define both abstract and default behaviors within the same contract.
4. Flexibility: Provides implementing classes the option to override default methods if specialized behavior is required, while still inheriting default implementations when appropriate.
5. Simplified Maintenance: Minimizes the need for extensive refactoring when interfaces change, as existing classes can continue to function without modification unless they choose to override default methods.
6. Facilitates Multiple Inheritance of Behavior: While Java does not support multiple inheritance of classes, default methods allow interfaces to contribute behavior, enabling a form of multiple inheritance for method implementations.

Default Methods significantly enhance the flexibility and robustness of Java interfaces, enabling developers to build more adaptable and maintainable codebases while adhering to the principles of object-oriented and functional programming.

## Optional Class

The Optional class was introduced in Java 8 as part of the `java.util` package to address the pervasive issue of null references in Java applications. Traditionally, null values have been a common source of `NullPointerException`s, leading to runtime errors and increased complexity in handling absent values. The `Optional` class provides a container object that may or may not contain a non-null value, effectively serving as a safer alternative to direct null references. By encapsulating the presence or absence of a value, `Optional` encourages developers to explicitly handle potential null cases, promoting more robust and maintainable code. This approach reduces the likelihood of encountering `NullPointerException`s and fosters a clearer, more declarative style of programming when dealing with values that might be missing.

Description of the Change:

Before Java 8, developers often relied on null checks to handle the absence of values, which could lead to verbose and error-prone code. The lack of a standardized approach to represent optional values meant that null checks were scattered throughout the codebase, increasing the risk of overlooking necessary validations and introducing bugs. The introduction of the `Optional` class provides a unified and expressive way to represent optional values. Instead of returning null, methods can return an `Optional` instance, signaling to the caller that the value may or may not be present. This encourages a more thoughtful handling of optional values, leveraging methods provided by the `Optional` class such as `isPresent()`, `ifPresent()`, `orElse()`, and `orElseGet()` to manage different scenarios. By using `Optional`, developers can write more intention-revealing code and reduce the reliance on explicit null checks, leading to cleaner and more reliable applications.

Code Examples:

*Before Java 8 (Using Null References):*

```java
public class UserService {
    public User findUserById(String userId) {
        // Imagine this method interacts with a database to find a user
        // Returns null if the user is not found
        // ...
        return null; // User not found
    }

    public void printUserName(String userId) {
        User user = findUserById(userId);
        if (user != null) {
            System.out.println(user.getName());
        } else {
            System.out.println("User not found.");
        }
    }
}

class User {
    private String name;

    public String getName() {
        return name;
    }

    // Constructor and other methods...
}
```

*Output when User is not found:*
```
User not found.
```

*With Java 8 Optional Class:*

```java
import java.util.Optional;

public class UserService {
    public Optional<User> findUserById(String userId) {
        // Imagine this method interacts with a database to find a user
        // Returns Optional.empty() if the user is not found
        // ...
        return Optional.empty(); // User not found
    }

    public void printUserName(String userId) {
        Optional<User> userOptional = findUserById(userId);
        userOptional.ifPresentOrElse(
            user -> System.out.println(user.getName()),
            () -> System.out.println("User not found.")
        );
    }
}


class User {
    private String name;

    public String getName() {
        return name;
    }

    // Constructor and other methods...
}
```

*Output when User is not found:*
```
User not found.
```

Explanation of the Example:

In the Pre-Java 8 example, the `findUserById` method returns a `User` object or null. The `printUserName` method then performs an explicit null check to determine whether to print the user's name or an error message. This approach can lead to scattered null checks and increases the risk of `NullPointerException`s if a null check is inadvertently omitted.

In the Java 8 Optional Class example, the `findUserById` method returns an `Optional<User>` instead of a nullable `User`. The `printUserName` method utilizes the `ifPresentOrElse` method provided by the `Optional` class to handle both scenarios—when the user is present and when the user is absent—without explicit null checks. This leads to more concise and readable code, clearly conveying the intent to handle optional values and reducing the likelihood of runtime exceptions related to null references.

Benefits of the Optional Class:

1. Explicit Representation of Optional Values: Clearly indicates when a value may be absent, making the code's intent more transparent.
2. Reduced NullPointerExceptions: Encourages handling of absent values, minimizing the risk of encountering exceptions.
3. Cleaner and More Readable Code: Eliminates the need for repetitive null checks, resulting in more streamlined and maintainable codebases.
4. Functional Programming Integration: Provides functional-style methods such as `map`, `filter`, and `flatMap`, enabling more expressive data transformations.
5. Encourages Best Practices: Promotes a disciplined approach to handling optional data, leading to more robust and reliable applications.
6. Improved API Design: Facilitates the creation of APIs that clearly communicate the possibility of absent values, enhancing the developer experience and reducing ambiguity.
7. Method Chaining: Allows for fluent method chaining, enabling more concise and declarative code when working with optional values.
8. Alternative to Nulls: Serves as a standardized alternative to null references, fostering consistency across different parts of an application or across multiple projects.

The `Optional` class fundamentally enhances the way developers handle optional values in Java, fostering safer and more maintainable code through its expressive and functional capabilities.

## New Date and Time API (`java.time`)

The New Date and Time API, introduced in Java 8 under the `java.time` package, represents a significant overhaul of Java's date and time handling mechanisms. This comprehensive and consistent API was designed to address the shortcomings of the older `java.util.Date` and `java.util.Calendar` classes, providing developers with more robust, immutable, and thread-safe alternatives for date and time manipulation. The `java.time` API draws inspiration from the [Joda-Time](https://www.joda.org/joda-time/) library, offering a modern approach that simplifies common tasks such as parsing, formatting, arithmetic operations, and time zone conversions. By introducing clear and fluent interfaces, the new API enhances code readability and maintainability, encouraging best practices in handling temporal data.

Description of the Change:

Prior to Java 8, the `java.util.Date` and `java.util.Calendar` classes were commonly used for date and time operations. However, these classes were plagued by several issues, including mutability, poor API design, lack of clarity, and thread-safety concerns. For instance, `java.util.Date` is mutable, which can lead to unexpected behavior in multi-threaded environments, and its methods for date manipulation are often unintuitive and error-prone.

The introduction of the `java.time` package addresses these challenges by offering a set of immutable and thread-safe classes that provide a more intuitive and comprehensive API for date and time operations. Key components of the `java.time` API include:

- `LocalDate`, `LocalTime`, and `LocalDateTime`: Represent dates, times, and date-time combinations without time zone information.
- `ZonedDateTime`: Represents date and time with time zone information.
- `Duration` and `Period`: Handle time-based and date-based amounts of time, respectively.
- `DateTimeFormatter`: Provides flexible formatting and parsing of date-time objects.
- `Instant`: Represents a moment on the timeline in UTC.

This modern API promotes a more declarative and fluent coding style, making it easier to perform complex date and time manipulations while reducing the likelihood of bugs and enhancing overall code quality.

Code Examples:

*Before Java 8 (Using `java.util.Date` and `java.util.Calendar`):*

```java
import java.util.Date;
import java.util.Calendar;

public class OldDateExample {
    public static void main(String[] args) {
        // Current date and time
        Date now = new Date();
        System.out.println("Current Date: " + now);

        // Adding 5 days to the current date
        Calendar calendar = Calendar.getInstance();
        calendar.setTime(now);
        calendar.add(Calendar.DAY_OF_MONTH, 5);
        Date futureDate = calendar.getTime();
        System.out.println("Date after 5 days: " + futureDate);

        // Formatting the date (using deprecated methods)
        String formattedDate = futureDate.toString(); // Not ideal for formatting
        System.out.println("Formatted Date: " + formattedDate);
    }
}
```

*Output:*
```
Current Date: Wed Apr 27 14:35:29 IST 2024
Date after 5 days: Mon May 02 14:35:29 IST 2024
Formatted Date: Mon May 02 14:35:29 IST 2024
```

*With Java 8 New Date and Time API (`java.time`):*

```java
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.ZoneId;
import java.time.ZonedDateTime;

public class NewDateTimeExample {
    public static void main(String[] args) {
        // Current date and time
        LocalDateTime now = LocalDateTime.now();
        System.out.println("Current DateTime: " + now);

        // Adding 5 days to the current date
        LocalDateTime futureDateTime = now.plusDays(5);
        System.out.println("DateTime after 5 days: " + futureDateTime);

        // Formatting the date-time
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd-MM-yyyy HH:mm:ss");
        String formattedDateTime = futureDateTime.format(formatter);
        System.out.println("Formatted DateTime: " + formattedDateTime);

        // Working with time zones
        ZonedDateTime zonedNow = ZonedDateTime.now(ZoneId.of("America/New_York"));
        System.out.println("Current DateTime in New York: " + zonedNow);
    }
}
```

*Output:*
```
Current DateTime: 2024-04-27T14:35:29.123
DateTime after 5 days: 2024-05-02T14:35:29.123
Formatted DateTime: 02-05-2024 14:35:29
Current DateTime in New York: 2024-04-27T04:35:29.123-04:00[America/New_York]
```

Explanation of the Example:

In the Pre-Java 8 example, the `java.util.Date` and `java.util.Calendar` classes are used to obtain the current date and time, add days to the current date, and format the date. This approach involves mutable objects and lacks a clear and concise API for date manipulation. Additionally, formatting dates using `toString()` is not flexible or locale-sensitive, leading to potential inconsistencies.

In contrast, the Java 8 `java.time` API example utilizes immutable classes like `LocalDateTime` and `ZonedDateTime` to handle date and time operations. The `plusDays` method provides a fluent and intuitive way to add days, while `DateTimeFormatter` offers robust and customizable formatting options. The use of `ZonedDateTime` allows for easy handling of different time zones, enhancing the versatility of date-time operations. This modern approach results in cleaner, more readable, and less error-prone code, demonstrating the advantages of the new API over the older classes.

Benefits of the New Date and Time API (`java.time`):

1. Immutability and Thread-Safety: All classes in the `java.time` package are immutable, ensuring thread-safety and preventing unintended side effects.
2. Clear and Fluent API: Provides a more intuitive and fluent interface for date and time manipulation, making code easier to read and write.
3. Comprehensive Functionality: Covers a wide range of use cases, including parsing, formatting, arithmetic operations, and time zone management.
4. Better API Design: Eliminates the design flaws present in `java.util.Date` and `java.util.Calendar`, such as unclear method names and inconsistent behaviors.
5. Enhanced Precision: Supports nanosecond precision, allowing for more accurate time representations.
6. Separation of Concerns: Distinguishes between different aspects of date and time (e.g., local date vs. zoned date), promoting better organization and usage.
7. Integration with Other APIs: Seamlessly integrates with other modern Java APIs, such as the Stream API and CompletableFuture, enabling more powerful and expressive programming patterns.
8. Locale-Sensitive Formatting: Provides robust formatting and parsing capabilities that respect locale-specific conventions, enhancing internationalization support.
9. Time Zone Support: Simplifies working with different time zones through classes like `ZonedDateTime` and `ZoneId`, facilitating global application development.
10. Backward Compatibility: Offers methods to convert between the old date-time classes and the new `java.time` classes, easing the transition for existing codebases.

The introduction of the `java.time` API fundamentally transformed how Java developers handle date and time, promoting best practices and enabling the creation of more reliable and maintainable applications.

## Repeating Annotations and Type Annotations

Repeating Annotations and Type Annotations were introduced in Java 8 as part of the enhancements to Java's annotation capabilities. Repeating Annotations allow multiple instances of the same annotation to be applied to a single program element (such as classes, methods, or fields), thereby improving the expressiveness and flexibility of annotations. Type Annotations, on the other hand, enable annotations to be used in more granular locations within type declarations, enhancing type checking and code clarity. These features collectively contribute to more precise and maintainable code by enabling developers to convey additional metadata and enforce stricter type constraints.

Description of the Change:

Prior to Java 8, applying the same annotation multiple times to a single element was not directly supported, often requiring the use of container annotations to encapsulate multiple instances. This limitation made it cumbersome to annotate elements with repetitive or related metadata. The introduction of Repeating Annotations simplifies this process by allowing the same annotation to be declared multiple times without the need for additional container annotations. This enhancement streamlines annotation usage and improves code readability.

Type Annotations extend the annotation capabilities by allowing annotations to be placed directly on types, not just declarations. This means that annotations can be applied to any use of a type, such as generic type parameters, type casts, and implements clauses. By enabling annotations at the type level, Java facilitates more precise type checking and documentation, reducing the likelihood of type-related errors and enhancing the overall clarity of the codebase.

Code Examples:

*Before Java 8 (Using Container Annotations for Repeating Annotations):*

```java
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import java.lang.annotation.ElementType;

// Container annotation
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
@interface Roles {
    Role[] value();
}

// Single annotation
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
@interface Role {
    String name();
}

@Roles({
    @Role(name = "ADMIN"),
    @Role(name = "USER")
})
public class UserAccount {
    // Class implementation
}
```

*With Java 8 Repeating Annotations and Type Annotations:*

```java
import java.lang.annotation.Repeatable;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import java.lang.annotation.ElementType;

// Repeating annotation
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
@Repeatable(Roles.class)
@interface Role {
    String name();
}

// Container annotation
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
@interface Roles {
    Role[] value();
}

@Role(name = "ADMIN")
@Role(name = "USER")
public class UserAccount {
    // Class implementation
}

// Type annotation example
import java.util.List;

public class TypeAnnotationExample {
    public void processList(@NonNull List<@Size(min = 1) String> names) {
        // Method implementation
    }
}

// Example of defining a type annotation
import java.lang.annotation.Documented;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import java.lang.annotation.ElementType;

@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE_USE)
@interface Size {
    int min() default 0;
}

@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE_USE)
@interface NonNull {
}
```

*Output:*
```
(Admin and User roles applied to UserAccount class)
```

Explanation of the Example:

In the Pre-Java 8 example, applying multiple `@Role` annotations to the `UserAccount` class requires the use of a container annotation `@Roles` that holds an array of `@Role` annotations. This approach is verbose and adds additional layers of annotations, making the code less readable and more cumbersome to maintain.

In the Java 8 example, the `@Role` annotation is marked with `@Repeatable(Roles.class)`, allowing it to be applied multiple times directly to the `UserAccount` class without explicitly using the container annotation. This simplifies the annotation process, making the code cleaner and more intuitive. Additionally, the example demonstrates Type Annotations by annotating the `List<String>` type in the `processList` method. Annotations like `@NonNull` and `@Size(min = 1)` are applied directly to the type components, enhancing type safety and providing clearer documentation about the expected characteristics of the types.

Benefits of Repeating Annotations and Type Annotations:

1. Enhanced Expressiveness: Allows developers to apply multiple instances of the same annotation to a single element, enabling more detailed and nuanced metadata.
2. Improved Readability: Eliminates the need for container annotations when applying multiple annotations of the same type, resulting in cleaner and more straightforward code.
3. Greater Flexibility: Facilitates more flexible API designs by allowing annotations to be used in a wider variety of contexts and scenarios.
4. Precise Type Checking: Enables annotations to be placed directly on types, allowing for more granular type checking and validation, which can prevent type-related errors.
5. Better Documentation: Provides clearer and more comprehensive documentation of code by allowing annotations to convey detailed information about type constraints and usage.
6. Reduced Boilerplate: Minimizes the need for additional container annotations, reducing the overall verbosity of the codebase.
7. Support for Advanced Programming Patterns: Enhances the ability to implement advanced programming patterns, such as dependency injection, validation frameworks, and aspect-oriented programming, by providing more detailed annotation capabilities.
8. Consistency with Functional Programming: Aligns with the functional programming paradigms introduced in Java 8, promoting a more declarative and expressive coding style.
9. Facilitates Tooling and Framework Integration: Improves the integration with tools and frameworks that rely on annotations for configuration, validation, and code generation by providing more flexible annotation options.
10. Encourages Best Practices: Promotes the use of annotations in a more disciplined and structured manner, encouraging developers to leverage annotations for meaningful metadata rather than relying on less structured approaches.

By introducing Repeating Annotations and Type Annotations, Java 8 significantly enhanced the annotation system, making it more powerful and adaptable to modern programming needs. These features contribute to writing more maintainable, readable, and type-safe code, aligning Java with contemporary programming practices and improving overall code quality.

## `var` Keyword

The `var` Keyword was introduced in Java 10 as part of the Local Variable Type Inference feature. This enhancement allows developers to declare local variables without explicitly specifying their types, enabling the compiler to infer the type based on the assigned value. By reducing the verbosity associated with type declarations, the `var` keyword promotes cleaner and more readable code, particularly in scenarios involving complex generic types or lengthy type names. While `var` enhances code conciseness, it maintains type safety by ensuring that the inferred type is determined at compile-time, preventing runtime type mismatches.

#### Description of the Change

Before Java 10, declaring local variables in Java required explicitly specifying their types. This often led to verbose code, especially when dealing with complex types such as generics or nested classes. For instance, declaring a `Map<String, List<Integer>>` required typing out the full type signature, which could be cumbersome and detract from code readability.

The introduction of the `var` keyword addresses this issue by allowing the compiler to infer the type of a local variable based on the context of its initialization. This feature aligns Java with modern programming languages that support type inference, such as Kotlin and Scala, enhancing developer productivity and code maintainability.

It's important to note that `var` can only be used for local variables within methods, constructors, or initializer blocks. It cannot be used for member variables (fields), method parameters, or return types. Additionally, the use of `var` does not make Java a dynamically typed language; type inference occurs at compile-time, ensuring that all type information is preserved and enforced during compilation.

#### Code Examples

*Before Java 10 (Explicit Type Declarations):*

```java
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

public class ExplicitTypeExample {
    public static void main(String[] args) {
        // Declaring a list with explicit type
        List<String> fruits = new ArrayList<>();
        fruits.add("Apple");
        fruits.add("Banana");
        fruits.add("Cherry");

        // Declaring a map with explicit types
        Map<String, List<Integer>> fruitQuantities = new HashMap<>();
        fruitQuantities.put("Apple", List.of(10, 20, 30));
        fruitQuantities.put("Banana", List.of(15, 25));
        fruitQuantities.put("Cherry", List.of(5, 10, 15, 20));

        // Iterating through the map
        for (Map.Entry<String, List<Integer>> entry : fruitQuantities.entrySet()) {
            System.out.println(entry.getKey() + ": " + entry.getValue());
        }
    }
}
```

*Output:*
```
Apple: [10, 20, 30]
Banana: [15, 25]
Cherry: [5, 10, 15, 20]
```

*With Java 10 `var` Keyword (Type Inference):*

```java
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

public class VarKeywordExample {
    public static void main(String[] args) {
        // Declaring a list using var
        var fruits = new ArrayList<String>();
        fruits.add("Apple");
        fruits.add("Banana");
        fruits.add("Cherry");

        // Declaring a map using var
        var fruitQuantities = new HashMap<String, List<Integer>>();
        fruitQuantities.put("Apple", List.of(10, 20, 30));
        fruitQuantities.put("Banana", List.of(15, 25));
        fruitQuantities.put("Cherry", List.of(5, 10, 15, 20));

        // Iterating through the map using var
        for (var entry : fruitQuantities.entrySet()) {
            System.out.println(entry.getKey() + ": " + entry.getValue());
        }
    }
}
```

*Output:*
```
Apple: [10, 20, 30]
Banana: [15, 25]
Cherry: [5, 10, 15, 20]
```

*Using `var` with Complex Generic Types:*

```java
public class VarWithGenericsExample {
    public static void main(String[] args) {
        // Without var
        Map<String, List<Map<Integer, String>>> complexMap = new HashMap<>();

        // With var
        var inferredMap = new HashMap<String, List<Map<Integer, String>>>();
    }
}
```

#### Explanation of the Examples

1. Explicit Type Declarations: In the Explicit Type Example, the types of variables `fruits` and `fruitQuantities` are explicitly declared using their full generic type signatures. While this approach is clear and type-safe, it can become cumbersome and reduce code readability, especially with deeply nested generics.
2. Using `var` Keyword: In the Var Keyword Example, the `var` keyword is used to declare the same variables without specifying their types. The compiler infers the types based on the initialization expressions. This results in more concise code without sacrificing type safety, as the inferred types are checked at compile-time.
3. Using `var` with Complex Generic Types: The Var With Generics Example demonstrates how `var` simplifies the declaration of variables with complex generic types. Instead of writing out the full type signature, `var` allows developers to avoid repetitive and verbose type declarations, enhancing code clarity.

#### Benefits of the `var` Keyword

1. Conciseness: Reduces boilerplate code by eliminating the need to repeatedly specify variable types, making code shorter and cleaner.
2. Enhanced Readability: Improves readability, especially when dealing with long or complex type names, by allowing the developer to focus on the variable name and its usage rather than its type.
3. Type Safety: Maintains strong type safety by ensuring that the inferred type is determined at compile-time, preventing type-related errors at runtime.
4. Improved Developer Productivity: Speeds up the coding process by reducing the amount of code that needs to be written and maintained, allowing developers to write more with less effort.
5. Facilitates Refactoring: Makes refactoring easier, as changes to the initialization expression automatically update the inferred type without needing to modify type declarations.
6. Supports Modern Programming Practices: Aligns Java with contemporary programming languages that utilize type inference, promoting more modern and expressive coding styles.
7. Reduces Clutter: Minimizes visual clutter in the code, especially in cases involving nested generics or lengthy type names, making the core logic more apparent.
8. Encourages Immutability: Often used in conjunction with immutable types, promoting best practices in software design and reducing side effects.
9. Better Integration with IDEs: Enhances the effectiveness of Integrated Development Environments (IDEs) by leveraging type inference to provide accurate code suggestions and error detection.
10. Simplifies Complex Type Handling: Simplifies the handling of complex types in scenarios such as streams, collections, and data processing pipelines, where the exact type may be less critical than the operations being performed.

#### Considerations and Best Practices

While the `var` keyword offers numerous advantages, it's essential to use it judiciously to maintain code clarity and maintainability:

1. Avoid Overuse: Excessive use of `var` can make the code less readable, especially when the inferred type is not immediately obvious from the context.
2. Use When Type is Clear: Prefer using `var` when the type can be easily inferred from the initialization expression, ensuring that the code remains understandable.
3. Avoid Ambiguity: In cases where the inferred type might be ambiguous or misleading, it's better to use explicit type declarations to enhance clarity.
4. Consistency: Maintain consistency in using `var` across the codebase to prevent confusion and promote uniform coding standards.
5. Documentation and Comments: Supplement `var` usage with appropriate documentation and comments when necessary to explain complex type inferences or business logic.
6. Scope of Usage: Limit the use of `var` to local variables within methods, constructors, or initializer blocks, as it cannot be used for member variables, method parameters, or return types.
7. Readability Over Brevity: Prioritize code readability over brevity. If using `var` makes the code harder to understand, prefer explicit type declarations.
8. Tooling Support: Leverage IDE features that can display inferred types on hover or through other means, assisting in understanding the code without sacrificing the benefits of `var`.
9. Educational Value: Use `var` as a tool to learn and understand type inference in Java, deepening knowledge of the language's type system.
10. Refactoring Safeguards: Be cautious when refactoring code that uses `var`, as changes to initialization expressions can alter inferred types, potentially affecting the application's behavior.

#### Example of Best Practices with `var`

```java
public class VarBestPracticesExample {
    public static void main(String[] args) {
        // Clear type inference
        var greeting = "Hello, World!"; // String
        
        // Complex type with clear initialization
        var employees = new ArrayList<Employee>();
        
        // Avoid using var when type is not obvious
        var data = fetchData(); // What is the type of data?
        
        // Prefer explicit type in ambiguous cases
        List<Employee> employeeList = fetchData();
    }
    
    private static List<Employee> fetchData() {
        return List.of(new Employee("Alice"), new Employee("Bob"));
    }
}

class Employee {
    private final String name;
    
    public Employee(String name) {
        this.name = name;
    }
    
    public String getName() { return name; }
}
```

*Explanation:*

- Clear Type Inference: Variables like `greeting` and `employees` use `var` where the type is evident from the right-hand side of the assignment.
- Avoid Ambiguity: The variable `data` uses `var` in a context where the type isn't immediately clear, which can lead to confusion. Instead, an explicit type declaration is preferred for clarity.

#### Conclusion

The introduction of the `var` keyword in Java 10 marks a significant step towards modernizing the language by embracing type inference. By allowing developers to declare local variables without explicit type specifications, `var` enhances code conciseness and readability while maintaining strong type safety. When used appropriately, `var` can greatly improve developer productivity and code maintainability, especially in scenarios involving complex generic types or repetitive type declarations. However, it's crucial to apply `var` judiciously to preserve code clarity and prevent ambiguity, ensuring that the benefits of type inference are fully realized without compromising the understandability of the codebase.

## Local-Variable Syntax for Lambda Parameters

The Local-Variable Syntax for Lambda Parameters was introduced in Java 11, enhancing the expressiveness and flexibility of lambda expressions. This feature allows developers to use the `var` keyword for lambda parameters, mirroring the local variable type inference introduced in Java 10. By enabling the use of `var` in lambda parameters, developers can improve code readability and maintainability, especially when annotations are required on parameters. This syntactic sugar facilitates a more consistent and concise coding style, making lambda expressions more adaptable to various programming scenarios.

Description of the Change:

Prior to Java 11, lambda parameters could either omit the type (relying on type inference) or explicitly declare the type. However, there was no provision to apply annotations directly to lambda parameters unless the types were explicitly declared. This limitation posed challenges when annotations were necessary for validation, documentation, or other meta-programming purposes within lambda expressions. The introduction of the `var` keyword for lambda parameters addresses this by allowing type inference while still enabling annotations. By using `var`, developers can declare lambda parameters without specifying the exact type, yet still apply necessary annotations, thereby combining the benefits of type inference with the flexibility of annotated parameters.

Code Examples:

*Before Java 11 (Without `var` in Lambda Parameters):*

```java
import java.util.Arrays;
import java.util.List;
import java.util.function.Consumer;

public class LambdaWithoutVar {
    public static void main(String[] args) {
        List<String> names = Arrays.asList("Alice", "Bob", "Charlie", "David");

        // Lambda expression without type declaration
        names.forEach(name -> System.out.println(name));
        
        // Lambda expression with explicit type declaration for annotation
        names.forEach((String name) -> System.out.println(name));
    }
}
```

*Output:*
```
Alice
Bob
Charlie
David
Alice
Bob
Charlie
David
```

*With Java 11 Local-Variable Syntax for Lambda Parameters:*

```java
import java.util.Arrays;
import java.util.List;
import java.util.function.Consumer;

public class LambdaWithVar {
    public static void main(String[] args) {
        List<String> names = Arrays.asList("Alice", "Bob", "Charlie", "David");

        // Lambda expression using var without annotations
        names.forEach((var name) -> System.out.println(name));

        // Lambda expression using var with annotations
        names.forEach((@NonNull var name) -> System.out.println(name));
    }
}

// Example of a custom annotation
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;

@Retention(RetentionPolicy.RUNTIME)
@interface NonNull {
}
```

*Output:*
```
Alice
Bob
Charlie
David
Alice
Bob
Charlie
David
```

Explanation of the Example:

In the Pre-Java 11 example, the first `forEach` method utilizes a lambda expression without specifying the type of the parameter `name`, relying on type inference. The second `forEach` method explicitly declares the type of the parameter `name` as `String` to apply the `@NonNull` annotation. This explicit type declaration can lead to more verbose code, especially when multiple annotations or complex types are involved.

In contrast, the Java 11 example demonstrates the use of the `var` keyword in lambda parameters. The first `forEach` method uses `var` without any annotations, maintaining concise code while benefiting from type inference. The second `forEach` method applies the `@NonNull` annotation directly to the `var` parameter, eliminating the need to explicitly declare the parameter type. This approach reduces boilerplate code and enhances readability, particularly when annotations are necessary for parameters within lambda expressions.

Benefits of Local-Variable Syntax for Lambda Parameters:

1. Enhanced Readability: Using `var` simplifies lambda expressions by reducing verbosity, making the code easier to read and understand.
2. Type Inference with Flexibility: Combines the advantages of type inference with the ability to apply annotations, providing greater flexibility in lambda parameter declarations.
3. Consistent Syntax: Aligns lambda parameter syntax with local variable declarations, promoting a uniform coding style across the codebase.
4. Improved Maintainability: Reduces boilerplate code associated with explicit type declarations, making the codebase cleaner and easier to maintain.
5. Support for Annotations: Enables the application of annotations on lambda parameters without requiring explicit type declarations, facilitating better integration with validation frameworks and other annotation-based tools.
6. Conciseness: Streamlines lambda expressions by allowing the omission of explicit type information when it's unnecessary, leading to more concise and expressive code.
7. Compatibility with Existing Code: Integrates seamlessly with existing lambda expressions, allowing developers to adopt the feature incrementally without major refactoring.
8. Enhanced Tooling Support: Improves compatibility with IDEs and other development tools by providing clearer syntax for lambda parameters with annotations.
9. Facilitates Advanced Programming Patterns: Supports more sophisticated programming patterns that rely on annotated parameters within lambda expressions, such as dependency injection and aspect-oriented programming.
10. Promotes Best Practices: Encourages the use of type inference and annotations in a controlled and expressive manner, fostering better coding practices and more robust applications.

The introduction of the Local-Variable Syntax for Lambda Parameters in Java 11 represents a meaningful enhancement to Java's functional programming capabilities. By allowing the use of `var` in lambda parameters, Java developers can write more expressive, readable, and maintainable code, especially in scenarios that require parameter annotations. This feature not only streamlines lambda expressions but also aligns with modern Java programming practices, facilitating the development of cleaner and more efficient applications.

## Enhanced String API

The Enhanced String API was introduced in Java 11, bringing a suite of new methods to the `String` class that significantly improve the versatility and ease of string manipulation in Java applications. These additions include methods such as `isBlank()`, `lines()`, `strip()`, `stripLeading()`, `stripTrailing()`, and `repeat(int)`, among others. These methods address common string processing tasks with more intuitive and efficient solutions, reducing the need for boilerplate code and enhancing overall code readability and maintainability. By providing these robust and well-designed utilities, the Enhanced String API empowers developers to perform complex string operations more seamlessly and effectively.

Description of the Change:

Prior to Java 11, many common string manipulation tasks required the use of external libraries or verbose code snippets. For example, checking if a string is empty or contains only whitespace often involved combining multiple conditions or using regular expressions. Similarly, splitting strings into lines, trimming whitespace, and repeating strings required more elaborate approaches that could clutter the codebase and introduce potential errors.

The Enhanced String API addresses these limitations by introducing dedicated methods that perform these operations in a straightforward and efficient manner. The new methods are designed to be intuitive, reducing the cognitive load on developers and minimizing the potential for bugs. By incorporating these methods directly into the `String` class, Java provides a more powerful and user-friendly toolkit for handling a wide range of string processing scenarios.

Code Examples:

*Before Java 11 (Using Existing `String` Methods and Utilities):*

```java
public class OldStringExample {
    public static void main(String[] args) {
        String text = "  Hello World!  \nWelcome to Java 11.\nEnjoy coding!  ";
        // Checking if the string is blank
        boolean isBlank = text.trim().isEmpty();
        System.out.println("Is Blank: " + isBlank);
        // Splitting the string into lines
        String[] lines = text.split("\\R");
        System.out.println("Lines:");
        for (String line : lines) {
            System.out.println(line.trim());
        }
        // Stripping leading and trailing whitespace
        String stripped = text.trim();
        System.out.println("Stripped: '" + stripped + "'");
        // Repeating the string
        String repeated = "";
        for (int i = 0; i < 3; i++) {
            repeated += text;
        }
        System.out.println("Repeated:\n" + repeated);
    }
}
```

*Output:*
```
Is Blank: false
Lines:
Hello World!
Welcome to Java 11.
Enjoy coding!
Stripped: 'Hello World!  
Welcome to Java 11.
Enjoy coding!'
Repeated:
  Hello World!  
Welcome to Java 11.
Enjoy coding!  
  Hello World!  
Welcome to Java 11.
Enjoy coding!  
  Hello World!  
Welcome to Java 11.
Enjoy coding!  
```

*With Java 11 Enhanced String API:*

```java
public class EnhancedStringAPIExample {
    public static void main(String[] args) {
        String text = "  Hello World!  \nWelcome to Java 11.\nEnjoy coding!  ";
        // Checking if the string is blank
        boolean isBlank = text.isBlank();
        System.out.println("Is Blank: " + isBlank);
        // Splitting the string into lines
        System.out.println("Lines:");
        text.lines()
            .map(String::strip)
            .forEach(System.out::println);
        // Stripping leading and trailing whitespace
        String stripped = text.strip();
        System.out.println("Stripped: '" + stripped + "'");
        // Repeating the string
        String repeated = text.repeat(3);
        System.out.println("Repeated:\n" + repeated);
    }
}
```

*Output:*
```
Is Blank: false
Lines:
Hello World!
Welcome to Java 11.
Enjoy coding!
Stripped: 'Hello World!  
Welcome to Java 11.
Enjoy coding!'
Repeated:
  Hello World!  
Welcome to Java 11.
Enjoy coding!    Hello World!  
Welcome to Java 11.
Enjoy coding!    Hello World!  
Welcome to Java 11.
Enjoy coding!  
```

Explanation of the Example:

In the Pre-Java 11 example, various string operations are performed using existing methods and utilities. Checking if a string is blank involves trimming the string and then checking if it is empty, which requires multiple method calls. Splitting the string into lines uses a regular expression with `split("\\R")`, and repeating the string involves concatenating it multiple times within a loop. These approaches, while functional, can be verbose and less intuitive.

In the Java 11 Enhanced String API example, the new methods simplify these operations significantly:

- `isBlank()`: Directly checks if the string is empty or contains only whitespace, eliminating the need for manual trimming and empty checks.
- `lines()`: Provides a stream of lines from the string, allowing for fluent processing using stream operations like `map` and `forEach`.
- `strip()`: Removes leading and trailing whitespace in a more consistent and Unicode-aware manner compared to `trim()`.
- `repeat(int)`: Concatenates the string a specified number of times without the need for explicit loops.

These enhancements lead to more concise, readable, and maintainable code by reducing the boilerplate required for common string manipulation tasks.

Benefits of the Enhanced String API:

1. Increased Readability: The new methods provide a clear and intuitive way to perform common string operations, making the code easier to understand at a glance.
2. Reduced Boilerplate: Eliminates the need for verbose code constructs like loops and regular expressions for tasks that can now be handled with single method calls.
3. Improved Performance: Optimized implementations of these methods can offer better performance compared to manually written equivalents, especially for operations like repeating strings.
4. Unicode-Aware Operations: Methods like `strip()` are designed to handle Unicode whitespace characters correctly, ensuring more accurate and reliable string processing.
5. Fluent API Integration: Seamlessly integrates with Java's Stream API, enabling more expressive and functional-style programming patterns when working with strings.
6. Enhanced Maintainability: Simplifies the codebase by reducing the complexity and potential for errors associated with manual string manipulation.
7. Consistent Behavior: Provides a standardized approach to string operations, ensuring consistent behavior across different parts of an application.
8. Ease of Use: Developers can perform complex string manipulations with minimal effort, accelerating development and reducing the learning curve.
9. Better API Design: Encourages the use of well-defined and purpose-built methods, leading to cleaner and more organized code.
10. Facilitates Best Practices: Promotes the adoption of modern string handling techniques, aligning Java with contemporary programming standards and practices.

The Enhanced String API in Java 11 represents a significant improvement in how developers handle string operations, offering a more powerful, efficient, and user-friendly toolkit that aligns with modern programming needs.

## HTTP Client Enhancements

The HTTP Client Enhancements were introduced in Java 11, significantly upgrading the existing HTTP client capabilities within the Java Standard Library. These enhancements included native support for HTTP/2 and WebSocket, providing developers with more efficient and modern protocol options for building networked applications. The new `HttpClient` API offers a more intuitive and feature-rich interface compared to the older `HttpURLConnection`, enabling asynchronous and synchronous communication, improved performance through multiplexing, and streamlined handling of WebSocket connections. By integrating these modern protocols, Java applications can achieve better performance, lower latency, and enhanced scalability, aligning Java with contemporary web standards and developer expectations.

Description of the Change:

Prior to Java 11, developers primarily relied on the `HttpURLConnection` class for handling HTTP requests and responses. While functional, `HttpURLConnection` had several limitations, including cumbersome API design, lack of native support for newer protocols like HTTP/2, and limited capabilities for handling asynchronous operations and WebSockets. These constraints often led to verbose and less efficient code, especially when dealing with modern web applications that demand high performance and real-time communication.

Java 11 addressed these challenges by introducing the new `HttpClient` API, which is part of the `java.net.http` package. This API provides a more modern and flexible approach to handling HTTP communications. Key improvements include:

- HTTP/2 Support: Enables multiplexing multiple requests over a single connection, reducing latency and improving resource utilization.
- WebSocket Support: Facilitates real-time, bidirectional communication between clients and servers, essential for applications like chat systems, live updates, and streaming.
- Asynchronous and Synchronous Requests: Offers both blocking and non-blocking operations, allowing developers to choose the appropriate model based on their application's needs.
- Fluent API Design: Provides a more readable and maintainable interface for building and executing HTTP requests.
- Improved Performance: Enhancements in the underlying implementation lead to better throughput and lower latency compared to `HttpURLConnection`.

These enhancements empower developers to build more efficient, scalable, and responsive networked applications using Java.

Code Examples:

*Before Java 11 (Using `HttpURLConnection` for HTTP Requests):*

```java
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

public class OldHttpClientExample {
    public static void main(String[] args) {
        String urlString = "https://api.github.com/repos/openjdk/jdk";

        try {
            URL url = new URL(urlString);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("GET");

            // Check the response code
            int status = connection.getResponseCode();
            if (status == HttpURLConnection.HTTP_OK) {
                BufferedReader in = new BufferedReader(
                        new InputStreamReader(connection.getInputStream()));
                String inputLine;
                StringBuilder content = new StringBuilder();

                while ((inputLine = in.readLine()) != null) {
                    content.append(inputLine).append("\n");
                }
                
                // Close the connections
                in.close();
                connection.disconnect();

                System.out.println("Response:");
                System.out.println(content.toString());
            } else {
                System.out.println("GET request failed. Response Code: " + status);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

*Output:*
```
Response:
{
  "id": 21776224,
  "node_id": "MDEwOlJlcG9zaXRvcnkyMTc3NjIyNA==",
  "name": "jdk",
  "full_name": "openjdk/jdk",
  ...
}
```

*With Java 11 `HttpClient` for HTTP/2 Requests:*

```java
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

public class NewHttpClientExample {
    public static void main(String[] args) {
        String url = "https://api.github.com/repos/openjdk/jdk";

        // Create a new HttpClient with HTTP/2 support
        HttpClient client = HttpClient.newBuilder()
                .version(HttpClient.Version.HTTP_2)
                .build();

        // Build the HttpRequest
        HttpRequest request = HttpRequest.newBuilder()
                .GET()
                .uri(URI.create(url))
                .header("Accept", "application/vnd.github.v3+json")
                .build();
        
        try {
            // Send the request and get the response
            HttpResponse<String> response = client.send(request,
                    HttpResponse.BodyHandlers.ofString());
            // Check the response status code
            if (response.statusCode() == 200) {
                System.out.println("Response:");
                System.out.println(response.body());
            } else {
                System.out.println("GET request failed. Response Code: "
                        + response.statusCode());
            }
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```

*Output:*
```
Response:
{
  "id": 21776224,
  "node_id": "MDEwOlJlcG9zaXRvcnkyMTc3NjIyNA==",
  "name": "jdk",
  "full_name": "openjdk/jdk",
  ...
}
```

*With Java 11 `HttpClient` for WebSocket Communication:*

```java
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.WebSocket;
import java.util.concurrent.CompletionStage;

public class WebSocketExample {
    public static void main(String[] args) {
        // Create a new HttpClient
        HttpClient client = HttpClient.newHttpClient();

        // Build the WebSocket
        WebSocket webSocket = client.newWebSocketBuilder()
                .buildAsync(URI.create("wss://echo.websocket.org"), 
                 new WebSocket.Listener() {
                    @Override
                    public CompletionStage<?> onText(WebSocket webSocket, 
                                                     CharSequence data, boolean last) {
                        System.out.println("Received message: " + data);
                        webSocket.sendText("Hello, WebSocket!", true);
                        return null;
                    }
                    
                    @Override
                    public void onOpen(WebSocket webSocket) {
                        System.out.println("WebSocket opened");
                        webSocket.sendText("Hello, WebSocket!", true);
                        WebSocket.Listener.super.onOpen(webSocket);
                    }
                    
                    @Override
                    public void onError(WebSocket webSocket, Throwable error) {
                        System.out.println("WebSocket error: " + error.getMessage());
                        WebSocket.Listener.super.onError(webSocket, error);
                    }
                })
                .join();

        // Keep the main thread alive to receive messages
        try {
            Thread.sleep(5000); // Wait for messages
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        webSocket.abort();
    }
}
```

*Output:*
```
WebSocket opened
Received message: Hello, WebSocket!
Received message: Hello, WebSocket!
```

Explanation of the Example:

In the Pre-Java 11 example, the `HttpURLConnection` class is used to perform a simple HTTP GET request to GitHub's API. This approach involves several steps: creating a connection, setting the request method, handling the response code, reading the input stream, and managing exceptions. While functional, this method is verbose and lacks native support for newer protocols like HTTP/2, making it less efficient for modern applications.

In the Java 11 `HttpClient` example, the new `HttpClient` API simplifies the process of making HTTP requests. The client is built with HTTP/2 support, allowing for improved performance through features like multiplexing. The `HttpRequest` is constructed using a fluent builder pattern, specifying the URI and headers succinctly. Sending the request and handling the response is streamlined with the `send` method, which manages the underlying complexities of the connection. This results in more readable and maintainable code with enhanced performance capabilities.

The WebSocket Example demonstrates the `HttpClient` API's support for WebSocket communication. By implementing the `WebSocket.Listener` interface, developers can handle events such as opening the connection, receiving messages, and handling errors in a more structured and asynchronous manner. The ability to establish a WebSocket connection with minimal boilerplate code showcases the API's modern design and its alignment with contemporary web communication standards.

Benefits of HTTP Client Enhancements:

1. Native HTTP/2 Support: Enables more efficient network communication through features like request multiplexing, header compression, and server push, leading to reduced latency and better resource utilization.
2. WebSocket Integration: Facilitates real-time, bidirectional communication, essential for modern applications that require instant data exchange, such as chat applications, live updates, and streaming services.
3. Asynchronous Operations: Supports non-blocking I/O operations, allowing applications to handle multiple requests concurrently without waiting for each to complete, enhancing scalability and responsiveness.
4. Fluent and Intuitive API Design: Provides a more readable and maintainable interface for building and executing HTTP requests, reducing boilerplate code and improving developer productivity.
5. Improved Performance: Optimizations in the underlying implementation lead to better throughput and lower latency compared to the older `HttpURLConnection` approach.
6. Simplified Error Handling: Offers more robust and structured mechanisms for handling HTTP errors and exceptions, improving the reliability of networked applications.
7. Enhanced Security Features: Incorporates modern security protocols and standards, ensuring secure communication channels by default.
8. Streamlined WebSocket Management: Simplifies the creation and management of WebSocket connections, making it easier to implement complex real-time communication patterns.
9. Better Integration with Modern Frameworks: Aligns with contemporary web development frameworks and libraries, facilitating smoother integration and interoperability.
10. Consistent API Usage: Consolidates HTTP and WebSocket functionalities within a single, cohesive API, providing a unified approach to network communication in Java applications.

The HTTP Client Enhancements in Java 11 represent a substantial improvement in how Java handles network communications. By embracing modern protocols and offering a more flexible and efficient API, Java developers can build faster, more reliable, and feature-rich applications that meet the demands of today's web-centric environment.

## Sealed Classes and Interfaces

Sealed Classes and Interfaces were introduced in Java 15 as a preview feature and became a permanent part of the language in Java 17. This feature allows developers to restrict which other classes or interfaces can extend or implement them. By providing a more controlled and predictable type hierarchy, sealed classes and interfaces enhance the robustness and maintainability of Java applications. They enable developers to define clear boundaries within their class hierarchies, ensuring that only a predefined set of subclasses can exist, which facilitates better modeling of domain-specific concepts and improves pattern matching capabilities.

Description of the Change:

Prior to Java 15, Java did not provide a native way to limit the inheritance of classes and interfaces beyond using access modifiers like `final` or package-private visibility. This often led to unintended extensions, making it difficult to maintain and reason about class hierarchies, especially in large codebases or when using third-party libraries. The introduction of sealed classes and interfaces addresses this limitation by allowing the author of a class or interface to explicitly specify which other classes or interfaces are permitted to extend or implement them. This restriction is enforced at compile-time, ensuring that the type hierarchy remains controlled and predictable.

Sealed classes and interfaces work in conjunction with the `permits` clause, where the superclass or superinterface declares the allowed subclasses or implementing interfaces. Subclasses of a sealed class must themselves be declared as `final`, `sealed`, or `non-sealed`, providing further control over the inheritance chain. This mechanism not only enhances encapsulation but also improves the safety and reliability of the code by preventing unauthorized or unintended extensions.

Code Examples:

*Before Java 15 (Unrestricted Inheritance):*

```java
// Superclass without inheritance restrictions
public class Shape {
    public void draw() {
        System.out.println("Drawing a shape.");
    }
}

// Subclasses extending Shape
public class Circle extends Shape {
    @Override
    public void draw() {
        System.out.println("Drawing a circle.");
    }
}

public class Square extends Shape {
    @Override
    public void draw() {
        System.out.println("Drawing a square.");
    }
}

// Another subclass extending Shape
public class Triangle extends Shape {
    @Override
    public void draw() {
        System.out.println("Drawing a triangle.");
    }
}

public class ShapeDemo {
    public static void main(String[] args) {
        Shape shape1 = new Circle();
        Shape shape2 = new Square();
        Shape shape3 = new Triangle();

        shape1.draw(); // Output: Drawing a circle.
        shape2.draw(); // Output: Drawing a square.
        shape3.draw(); // Output: Drawing a triangle.
    }
}
```

*Output:*
```
Drawing a circle.
Drawing a square.
Drawing a triangle.
```

*With Java 17 Sealed Classes:*

```java
// Sealed superclass with restricted inheritance
public sealed class Shape permits Circle, Square {
    public abstract void draw();
}

// Final subclass extending Shape
public final class Circle extends Shape {
    @Override
    public void draw() {
        System.out.println("Drawing a circle.");
    }
}

// Sealed subclass extending Shape, permitting further extensions
public sealed class Square extends Shape permits ColoredSquare {
    @Override
    public void draw() {
        System.out.println("Drawing a square.");
    }
}

// Final subclass extending Square
public final class ColoredSquare extends Square {
    @Override
    public void draw() {
        System.out.println("Drawing a colored square.");
    }
}

// Attempting to extend Shape outside the permitted classes will result in a compile-time
//     @Override
//     public void draw() {
//         System.out.println("Drawing a triangle.");
//     }
// }

public class ShapeDemo {
    public static void main(String[] args) {
        Shape shape1 = new Circle();
        Shape shape2 = new Square();
        Shape shape3 = new ColoredSquare();

        shape1.draw(); // Output: Drawing a circle.
        shape2.draw(); // Output: Drawing a square.
        shape3.draw(); // Output: Drawing a colored square.
    }
}
```

*Output:*
```
Drawing a circle.
Drawing a square.
Drawing a colored square.
```

Explanation of the Example:

In the Pre-Java 15 example, the `Shape` class serves as an unrestricted superclass that can be extended by any number of subclasses such as `Circle`, `Square`, and `Triangle`. This unrestricted inheritance allows for flexibility but can lead to unintended extensions, making the type hierarchy harder to manage and reason about.

In the Java 17 Sealed Classes example, the `Shape` class is declared as `sealed` and explicitly permits only the `Circle` and `Square` classes to extend it using the `permits` clause. The `Circle` class is marked as `final`, preventing any further subclassing. The `Square` class is also declared as `sealed`, permitting only the `ColoredSquare` class to extend it. The `ColoredSquare` class is marked as `final`, thereby closing the inheritance chain.

Attempting to create a subclass like `Triangle` that extends `Shape` outside the permitted classes will result in a compile-time error, ensuring that the type hierarchy remains controlled and predictable. This setup enhances encapsulation and reduces the risk of unintended extensions, leading to more maintainable and robust code.

Benefits of Sealed Classes and Interfaces:

1. Controlled Inheritance: Restricts which classes or interfaces can extend or implement a sealed class or interface, preventing unauthorized or unintended extensions.
2. Enhanced Encapsulation: Improves encapsulation by allowing the author to define clear boundaries within the type hierarchy, ensuring that only known and approved subclasses exist.
3. Predictable Type Hierarchies: Facilitates the creation of more predictable and manageable type hierarchies, making it easier to understand and maintain the codebase.
4. Improved Pattern Matching: Enhances the capabilities of pattern matching by providing a finite set of subclasses, allowing for exhaustive checks and reducing the likelihood of runtime errors.
5. Enhanced Readability: Makes the intended inheritance relationships explicit, improving code readability and comprehensibility for developers.
6. Better Maintenance: Simplifies maintenance by limiting the scope of possible subclasses, reducing the complexity involved in managing and evolving the class hierarchy.
7. Safety and Reliability: Prevents the accidental or malicious creation of subclasses, enhancing the overall safety and reliability of the application.
8. Optimized Performance: Enables potential optimizations by the compiler and JVM, as the sealed hierarchy provides more information about the possible subclasses.
9. Alignment with Domain Models: Allows developers to more accurately model domain-specific concepts by clearly defining the permissible extensions of abstract concepts.
10. Facilitates API Evolution: Supports the evolution of APIs by allowing the addition of new methods or behaviors within a controlled set of subclasses, ensuring backward compatibility and stability.

Sealed classes and interfaces provide a powerful tool for developers to enforce strong type hierarchies and maintain control over the inheritance structure of their applications. By leveraging this feature, Java developers can build more robust, maintainable, and reliable systems that adhere to well-defined architectural principles.

## Pattern Matching for `instanceof`

Pattern Matching for `instanceof` was introduced as a preview feature in Java 14 and became a standard feature in Java 16. This enhancement simplifies type checks and casting by allowing the extraction of variables directly within the `instanceof` operator. Prior to this feature, developers often had to perform separate type checks and explicit casting, resulting in verbose and boilerplate code. With pattern matching, the type and cast are handled implicitly, making the code more concise, readable, and less error-prone. This feature aligns with Java's move towards more expressive and streamlined syntax, enhancing the overall developer experience and promoting best practices in type handling.

Description of the Change:

Before Java 16, using the `instanceof` operator required developers to perform a type check followed by an explicit cast to access the object's methods or fields. This approach often led to repetitive and boilerplate code, especially in scenarios involving multiple type checks or complex conditional logic. The introduction of pattern matching for `instanceof` allows developers to combine the type check and variable extraction into a single, more readable statement. By declaring a new variable within the `instanceof` condition, the need for separate casting is eliminated, reducing code duplication and potential casting errors. This enhancement not only streamlines type-related operations but also integrates seamlessly with Java's existing type system and control flow constructs.

Code Examples:

*Before Java 16 (Using Traditional `instanceof` and Casting):*

```java
public class InstanceofExample {
    public static void main(String[] args) {
        Object obj = "Hello, World!";

        if (obj instanceof String) {
            String str = (String) obj;
            System.out.println("String length: " + str.length());
        } else if (obj instanceof Integer) {
            Integer num = (Integer) obj;
            System.out.println("Integer value: " + num);
        } else {
            System.out.println("Unknown type.");
        }
    }
}
```

*Output:*
```
String length: 13
```

*With Java 16 Pattern Matching for `instanceof`:*

```java
public class PatternMatchingInstanceofExample {
    public static void main(String[] args) {
        Object obj = "Hello, World!";

        if (obj instanceof String str) {
            System.out.println("String length: " + str.length());
        } else if (obj instanceof Integer num) {
            System.out.println("Integer value: " + num);
        } else {
            System.out.println("Unknown type.");
        }
    }
}
```

*Output:*
```
String length: 13
```

Explanation of the Example:

In the Traditional `instanceof` example, the `if` statement checks whether `obj` is an instance of `String`. If the condition is true, the object is explicitly cast to `String` and assigned to the variable `str` for further use. This pattern is repeated for the `Integer` type as well. While functional, this approach results in repetitive code, as the type check and casting must be performed separately for each type.

In the Pattern Matching for `instanceof` example, the type check and variable assignment are combined into a single statement using the syntax `if (obj instanceof String str)`. Here, if `obj` is an instance of `String`, it is automatically cast and assigned to the variable `str`, which is then available within the scope of the `if` block. This eliminates the need for explicit casting, reducing boilerplate code and enhancing readability. The same pattern is applied to the `Integer` type, demonstrating consistency and efficiency in handling multiple type checks.

Benefits of Pattern Matching for `instanceof`:

1. Conciseness: Combines type checking and casting into a single, streamlined statement, reducing the overall amount of code.
2. Readability: Enhances code clarity by making the intent of type checks and variable assignments more explicit and less cluttered.
3. Reduced Boilerplate: Eliminates repetitive casting operations, making the codebase cleaner and easier to maintain.
4. Type Safety: Minimizes the risk of `ClassCastException` by ensuring that the cast is only performed when the type check passes.
5. Enhanced Scope Management: The extracted variable is scoped to the `if` block, preventing unintended usage outside the relevant context.
6. Improved Developer Productivity: Speeds up development by reducing the amount of code developers need to write and maintain.
7. Integration with Existing Constructs: Works seamlessly with existing control flow structures, allowing for smooth adoption without significant refactoring.
8. Encourages Best Practices: Promotes the use of safer and more efficient coding patterns, aligning with modern Java programming standards.
9. Facilitates Complex Type Hierarchies: Simplifies handling of intricate type relationships and inheritance structures by providing a more expressive syntax.
10. Future-Proofing: Aligns Java with advancements in other programming languages that support pattern matching, ensuring Java remains competitive and modern.

Example of Complex Type Hierarchy Handling:

```java
public abstract class Animal {
    public abstract void makeSound();
}

public final class Dog extends Animal {
    @Override
    public void makeSound() {
        System.out.println("Bark!");
    }
}

public final class Cat extends Animal {
    @Override
    public void makeSound() {
        System.out.println("Meow!");
    }
}

public class AnimalSoundDemo {
    public static void main(String[] args) {
        Animal animal = new Dog();

        if (animal instanceof Dog dog) {
            dog.makeSound(); // Output: Bark!
        } else if (animal instanceof Cat cat) {
            cat.makeSound(); // Output: Meow!
        } else {
            System.out.println("Unknown animal.");
        }
    }
}
```

*Output:*
```
Bark!
```

In this example, the `Animal` class serves as an abstract base class with concrete subclasses `Dog` and `Cat`. Using pattern matching for `instanceof`, the `animal` object is checked and cast to its specific type (`Dog` or `Cat`) in a single, readable statement, allowing for direct invocation of subclass-specific methods without additional casting.

Pattern Matching for `instanceof` significantly enhances Java's type handling capabilities, making code more efficient, safer, and easier to read. By integrating this feature, Java developers can adopt more modern and expressive programming practices, leading to better-designed and more maintainable applications.

## Text Blocks

Text Blocks were introduced as a preview feature in Java 13 and became a standard feature in Java 15. This enhancement brought multi-line string literals to the Java language, significantly improving the readability and maintainability of code that deals with large blocks of text, such as JSON payloads, SQL queries, XML configurations, and HTML snippets. Text Blocks allow developers to define strings across multiple lines without the need for explicit line continuation characters or excessive escaping, resulting in cleaner and more intuitive code.

Description of the Change:

Prior to the introduction of Text Blocks, handling multi-line strings in Java required the use of concatenation with the `+` operator and the inclusion of escape characters for quotes and special characters. This approach often led to cluttered and hard-to-read code, especially when dealing with complex or lengthy text content. Additionally, maintaining such strings became cumbersome, as any modifications necessitated careful handling of concatenation points and escape sequences.

Text Blocks address these challenges by allowing developers to define multi-line strings using triple double-quote (`"""`) delimiters. Within a Text Block, the string can span multiple lines naturally, preserving the intended formatting and reducing the need for escape characters. The Java compiler automatically handles the indentation and line breaks, ensuring that the resulting string matches the developer's intent. This feature not only enhances code readability but also simplifies the inclusion of structured text within Java source files.

Code Examples:

*Before Java 13 (Using Traditional String Literals):*

```java
public class OldStringExample {
    public static void main(String[] args) {
        String json = "{\n" +
                      "    \"name\": \"John Doe\",\n" +
                      "    \"age\": 30,\n" +
                      "    \"email\": \"john.doe@example.com\"\n" +
                      "}";
        
        System.out.println(json);
    }
}
```

*Output:*
```
{
    "name": "John Doe",
    "age": 30,
    "email": "john.doe@example.com"
}
```

*With Java 15 Text Blocks:*

```java
public class TextBlockExample {
    public static void main(String[] args) {
        String json = """
                      {
                          "name": "John Doe",
                          "age": 30,
                          "email": "john.doe@example.com"
                      }
                      """;
        
        System.out.println(json);
    }
}
```

*Output:*
```
{
    "name": "John Doe",
    "age": 30,
    "email": "john.doe@example.com"
}
```

Explanation of the Example:

In the Traditional String Literals example, the JSON string is constructed using string concatenation with the `+` operator and explicit newline characters (`\n`). This method not only makes the code more verbose but also increases the risk of formatting errors, especially when dealing with complex or nested JSON structures.

In contrast, the Text Blocks example utilizes triple double-quote (`"""`) delimiters to define the multi-line JSON string. This approach preserves the natural formatting of the JSON content without the need for concatenation or escape characters. The resulting code is more readable and closely mirrors the actual JSON structure, making it easier for developers to visualize and maintain the string content.

Benefits of Text Blocks:

1. Improved Readability: Allows multi-line strings to be written in a natural and visually appealing format, closely resembling the actual text content.
2. Reduced Boilerplate: Eliminates the need for string concatenation and explicit newline characters, resulting in cleaner and more concise code.
3. Easier Maintenance: Simplifies the process of modifying multi-line strings by removing the complexity associated with managing concatenation points and escape sequences.
4. Consistent Formatting: Preserves the intended formatting and indentation of the string content, ensuring that the output matches the developer's design.
5. Enhanced Developer Productivity: Speeds up the process of writing and managing large blocks of text within Java source files by providing a straightforward syntax.
6. Better Integration with Structured Data: Facilitates the inclusion of structured data formats like JSON, XML, SQL, and HTML, making it easier to embed such content directly within Java code.
7. Reduced Error Potential: Minimizes the risk of introducing syntax errors related to improper string concatenation or incorrect escape character usage.
8. Support for Unicode and Special Characters: Handles Unicode characters and special symbols seamlessly within multi-line strings without additional escaping.
9. Flexible Indentation Handling: Automatically manages indentation, allowing developers to align Text Blocks with their code structure without affecting the resulting string content.
10. Enhanced Documentation and Examples: Makes it easier to include well-formatted examples, templates, and documentation snippets within code, improving clarity and instructional value.

Text Blocks represent a significant advancement in Java's string handling capabilities, providing developers with a more powerful and intuitive tool for managing multi-line text. By simplifying the creation and manipulation of large text blocks, Text Blocks contribute to more maintainable, readable, and error-free codebases.

## Records (Finalized in Java 16)

Records were finalized in Java 16 as a significant enhancement to the Java language, introducing a compact syntax for declaring classes that serve as transparent carriers for immutable data. Records provide a concise way to define data-holding classes without the boilerplate typically associated with such classes, such as constructors, getters, `equals()`, `hashCode()`, and `toString()` methods. By automatically generating these methods, Records streamline the creation of immutable data objects, promoting cleaner and more maintainable codebases.

Description of the Change:

Prior to Java 16, developers often had to create verbose classes to represent simple data structures. This involved manually writing constructors, accessor methods, and overriding methods like `equals()`, `hashCode()`, and `toString()`, which not only increased the amount of code but also introduced the potential for errors and inconsistencies. The introduction of Records addresses these challenges by providing a declarative way to define such classes. By using the `record` keyword, developers can define a class with immutable fields, and the Java compiler automatically generates the necessary boilerplate code. This feature enhances productivity, reduces code duplication, and ensures consistency across data-holding classes.

Code Examples:

*Before Java 16 (Using Traditional Classes):*

```java
import java.util.Objects;

public class Point {
    private final int x;
    private final int y;

    public Point(int x, int y) {
        this.x = x;
        this.y = y;
    }
    
    public int getX() {
        return x;
    }

    public int getY() {
        return y;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        
        Point point = (Point) o;
        return x == point.x && y == point.y;
    }

    @Override
    public int hashCode() {
        return Objects.hash(x, y);
    }

    @Override
    public String toString() {
        return "Point{" + "x=" + x + ", y=" + y + '}';
    }
}
```

*Usage:*

```java
public class TraditionalClassExample {
    public static void main(String[] args) {
        Point p1 = new Point(5, 10);
        Point p2 = new Point(5, 10);

        System.out.println(p1); // Output: Point{x=5, y=10}
        System.out.println(p1.equals(p2)); // Output: true
    }
}
```

*With Java 16 Records:*

```java
public record Point(int x, int y) {}
```

*Usage:*

```java
public class RecordExample {
    public static void main(String[] args) {
        Point p1 = new Point(5, 10);
        Point p2 = new Point(5, 10);

        System.out.println(p1); // Output: Point[x=5, y=10]
        System.out.println(p1.equals(p2)); // Output: true
    }
}
```

Explanation of the Example:

In the Traditional Class example, the `Point` class manually defines immutable fields `x` and `y`, along with a constructor, getter methods, and overrides for `equals()`, `hashCode()`, and `toString()`. This approach results in a substantial amount of boilerplate code, making the class verbose and increasing the likelihood of inconsistencies or errors in method implementations.

In contrast, the Record example simplifies the definition of the `Point` class by using the `record` keyword. The record declaration `public record Point(int x, int y) {}` automatically generates the constructor, getter methods (accessors), and implementations of `equals()`, `hashCode()`, and `toString()`. This not only reduces the amount of code but also ensures that the generated methods are consistent and correctly implemented. The usage remains straightforward, with records providing the same functionality as traditional classes but with enhanced brevity and clarity.

Benefits of Records:

1. Conciseness: Eliminates the need to manually write boilerplate code for constructors, accessors, and common methods, resulting in more succinct class definitions.
2. Immutability: Enforces immutability by making fields `final` and not providing setters, promoting safer and more predictable data structures.
3. Automatic Method Generation: Automatically generates `equals()`, `hashCode()`, and `toString()` methods based on the record components, ensuring consistency and reducing the risk of implementation errors.
4. Enhanced Readability: Provides a clear and declarative syntax for data-holding classes, making the code easier to read and understand.
5. Maintainability: Simplifies maintenance by reducing the amount of code that needs to be managed, and by ensuring that common methods are correctly implemented.
6. Built-in `equals()` and `hashCode()`: Ensures that equality checks and hash-based collections work correctly without additional effort from the developer.
7. Seamless Integration: Integrates smoothly with other Java features and frameworks, facilitating their use in modern Java applications.
8. Improved Developer Productivity: Allows developers to focus on the core logic and data structures without being bogged down by repetitive boilerplate code.
9. Compiler Optimizations: Enables potential compiler and JVM optimizations due to the standardized structure of records.
10. Encourages Best Practices: Promotes the use of immutable data structures and standardized method implementations, aligning with modern Java programming paradigms.

Records provide a powerful tool for developers to create immutable data carriers with minimal effort, enhancing both the efficiency and quality of Java codebases. By reducing boilerplate and enforcing best practices, Records contribute to more robust, maintainable, and readable applications.

## Enhanced `switch` Statements (Preview Features)

The Enhanced `switch` Statements were introduced as preview features in Java 12 and Java 14, and they became a standard feature in Java 17. This enhancement transforms the traditional `switch` statement into a more expressive and flexible control flow construct. By introducing a new `switch` expression syntax, Java allows developers to write more concise and readable code, reducing boilerplate and potential errors associated with the classic `switch` statements. The enhanced `switch` supports features such as the arrow (`->`) syntax, the `yield` keyword for returning values, and pattern matching, enabling more sophisticated and type-safe conditional logic.

#### Description of the Change:

Prior to the introduction of enhanced `switch` statements, Java's `switch` construct was limited to working with primitive types, enums, and a few other specific types. The traditional `switch` statement relied on `case` labels followed by a colon (`:`) and required explicit `break` statements to prevent fall-through behavior. This often led to verbose code and potential bugs if `break` statements were inadvertently omitted.

The enhanced `switch` introduces a new expression-based syntax that allows `switch` to return values, supports multiple labels per case, and eliminates the need for explicit `break` statements by using the arrow (`->`) syntax. Additionally, the `yield` keyword enables returning values from `switch` expressions, facilitating their use in assignments and more complex expressions. These improvements make the `switch` construct more powerful and versatile, aligning it with modern programming paradigms and enhancing Java's functional programming capabilities.

#### Code Examples:

*Before Java 12 (Using Traditional `switch` Statement):*

```java
public class TraditionalSwitchExample {
    public static void main(String[] args) {
        String day = "MONDAY";
        String type;
        switch (day) {
            case "MONDAY":
            case "FRIDAY":
            case "SUNDAY":
                type = "Start of the week";
                break;
            case "TUESDAY":
            case "THURSDAY":
                type = "Midweek";
                break;
            case "WEDNESDAY":
                type = "Hump day";
                break;
            default:
                type = "Invalid day";
                break;
        }
        System.out.println(day + " is classified as: " + type);
    }
}
```

*Output:*
```
MONDAY is classified as: Start of the week
```

*With Java 17 Enhanced `switch` Statement:*

```java
public class EnhancedSwitchExample {
    public static void main(String[] args) {
        String day = "MONDAY";
        String type = switch (day) {
            case "MONDAY", "FRIDAY", "SUNDAY" -> "Start of the week";
            case "TUESDAY", "THURSDAY" -> "Midweek";
            case "WEDNESDAY" -> "Hump day";
            default -> "Invalid day";
        };

        System.out.println(day + " is classified as: " + type);
    }
}
```

*Output:*
```
MONDAY is classified as: Start of the week
```

*Using `switch` Expression to Return Values:*

```java
public class SwitchExpressionExample {
    public static void main(String[] args) {
        int month = 4;
        String season = switch (month) {
            case 12, 1, 2 -> "Winter";
            case 3, 4, 5 -> "Spring";
            case 6, 7, 8 -> "Summer";
            case 9, 10, 11 -> "Autumn";
            default -> {
                yield "Invalid month";
            }
        };

        System.out.println("Month " + month + " is in: " + season);
    }
}
```

*Output:*
```
Month 4 is in: Spring
```

*Using `switch` with Pattern Matching (Java 17 and Later):*

```java
public class PatternMatchingSwitchExample {
    public static void main(String[] args) {
        Object obj = "Hello, Java 17!";

        String result = switch (obj) {
            case String s -> "String of length " + s.length();
            case Integer i -> "Integer value: " + i;
            case null, default -> "Unknown type";
        };

        System.out.println(result);
    }
}
```

*Output:*
```
String of length 15
```

#### Explanation of the Example:

In the Traditional `switch` Statement example, multiple `case` labels are grouped together to assign the same value to the `type` variable. Each `case` block requires an explicit `break` statement to prevent fall-through, which can be error-prone and verbose, especially when handling multiple cases that result in the same action.

In contrast, the Enhanced `switch` Statement example leverages the arrow (`->`) syntax to associate multiple `case` labels with a single expression, eliminating the need for `break` statements. The `switch` expression directly returns a value, allowing it to be assigned to the `type` variable in a more concise and readable manner.

The Switch Expression Example demonstrates how the enhanced `switch` can be used to return values directly from the `switch`, making it suitable for assignments and more complex expressions without additional boilerplate code.

The Pattern Matching `switch` Example showcases the integration of pattern matching with the enhanced `switch`, allowing for type-safe and expressive conditional logic based on the runtime type of the object. This reduces the need for explicit type casting and improves code safety and clarity.

#### Benefits of Enhanced `switch` Statements:

1. Conciseness: Reduces the amount of code required by eliminating the need for `break` statements and simplifying case label declarations.
2. Readability: Provides a more readable and intuitive syntax, making it easier to understand the flow of control and the associated actions.
3. Reduced Boilerplate: Minimizes repetitive code patterns, such as multiple `case` labels with the same action, streamlining the overall codebase.
4. Expression-Based: Allows `switch` to be used as an expression that returns values, enabling more flexible and functional programming styles.
5. Multiple Case Labels: Supports grouping multiple `case` labels with a single action using commas, simplifying the handling of related cases.
6. Pattern Matching Integration: Enhances type safety and expressiveness by allowing pattern matching within `switch` statements, reducing the need for explicit type checks and casts.
7. Immutable Flow Control: Encourages the use of immutable variables by allowing the `switch` expression to return values directly, aligning with modern Java best practices.
8. Enhanced Type Checking: Improves compile-time type checking, reducing the likelihood of runtime errors related to incorrect type handling.
9. Fluent API Alignment: Aligns the `switch` construct with the fluent and declarative programming paradigms, promoting more expressive and maintainable code.
10. Future-Proofing: Positions Java to better support future enhancements and integrations with advanced language features, ensuring the `switch` remains a versatile and powerful tool in the Java developer's toolkit.

The enhanced `switch` statements represent a significant evolution in Java's control flow mechanisms, providing developers with a more powerful, flexible, and expressive tool for managing conditional logic. By addressing the limitations of the traditional `switch` construct, these enhancements facilitate the creation of cleaner, more maintainable, and less error-prone code.

## Record Patterns (Preview)

Record Patterns were introduced as a preview feature in Java 21, building upon the concept of Records finalized in Java 16. This enhancement enables the deconstruction of record values, allowing developers to perform pattern matching with records in conditional statements and expressions more concisely and readably. By facilitating the extraction of record components directly within pattern matching constructs, Record Patterns streamline the handling of immutable data carriers, reducing boilerplate code and enhancing code clarity. This feature aligns with Java's ongoing evolution towards more expressive and functional programming paradigms, making it easier to work with complex data structures in a type-safe and maintainable manner.

#### Description of the Change:

Prior to Java 21, while Records provided a compact syntax for immutable data carriers, extracting their components within conditional logic required explicit accessor method calls or instance casting. This often led to verbose and repetitive code, especially when dealing with nested records or multiple conditions. Record Patterns address this limitation by allowing developers to deconstruct records directly within `instanceof` checks and `switch` expressions, simplifying the extraction of record components and enabling more intuitive and readable conditional logic.

With Record Patterns, developers can match a record's structure and simultaneously extract its components into local variables. This integration enhances pattern matching capabilities, making it easier to perform complex type checks and data manipulations without additional boilerplate code. The feature leverages the existing pattern matching infrastructure in Java, extending its applicability to Records and promoting more declarative coding styles.

#### Code Examples:

*Before Java 21 (Using Traditional Accessors with Records):*

```java
public record Person(String name, int age) {}

public class TraditionalRecordExample {
    public static void main(String[] args) {
        Person person = new Person("Alice", 30);

        
        if (person instanceof Person) {
            String name = person.name();
            int age = person.age();
            System.out.println("Name: " + name + ", Age: " + age);
        } else {
            System.out.println("Not a person.");
        }
    }
}
```

*Output:*
```
Name: Alice, Age: 30
```

*With Java 21 Record Patterns (Using Deconstruction in `instanceof`):*

```java
public record Person(String name, int age) {}

public class RecordPatternExample {
    public static void main(String[] args) {
        Object obj = new Person("Alice", 30);

        if (obj instanceof Person(String name, int age)) {
            System.out.println("Name: " + name + ", Age: " + age);
        } else {
            System.out.println("Not a person.");
        }
    }
}
```

*Output:*
```
Name: Alice, Age: 30
```

*Using Record Patterns in `switch` Expressions:*

```java
public record Circle(double radius) {}
public record Rectangle(double length, double width) {}
public record Triangle(double base, double height) {}

public class SwitchRecordPatternExample {
    public static void main(String[] args) {
        Object shape = new Rectangle(5.0, 10.0);

        String description = switch (shape) {
            case Circle(double r) -> "Circle with radius " + r;
            case Rectangle(double l, double w) -> "Rectangle with length "
                    + l + " and width " + w;
            case Triangle(double b, double h) -> "Triangle with base " 
                    + b + " and height " + h;
            default -> "Unknown shape";
        };

        System.out.println(description);
    }
}
```

*Output:*
```
Rectangle with length 5.0 and width 10.0
```

#### Explanation of the Example:

In the Traditional Record Example, the `Person` record is checked using the `instanceof` operator. If the object is an instance of `Person`, its components `name` and `age` are explicitly accessed through accessor methods (`person.name()` and `person.age()`). This approach, while functional, requires separate lines for type checking and component extraction, leading to more verbose code.

In contrast, the Record Pattern Example leverages Record Patterns by deconstructing the `Person` record directly within the `instanceof` check. The syntax `if (obj instanceof Person(String name, int age))` simultaneously checks the object's type and extracts its components into local variables `name` and `age`. This consolidation results in cleaner and more readable code, reducing boilerplate and enhancing clarity.

The Switch Record Pattern Example further demonstrates the power of Record Patterns within `switch` expressions. By matching against specific record types and deconstructing their components directly in the `case` labels, developers can handle different record structures more elegantly. This approach eliminates the need for separate type checks and accessor method calls within each `case` block, streamlining the control flow and making the codebase easier to maintain.

#### Benefits of Record Patterns:

1. Conciseness: Combines type checking and component extraction into a single statement, reducing the overall amount of code.
2. Readability: Enhances code clarity by making the intent of type checks and data extraction more explicit and less cluttered.
3. Reduced Boilerplate: Eliminates repetitive accessor method calls and explicit casting, leading to cleaner and more maintainable codebases.
4. Type Safety: Ensures that components are extracted only when the object matches the specified record type, minimizing the risk of runtime errors.
5. Enhanced Pattern Matching: Extends the capabilities of pattern matching to include deconstruction of Records, enabling more sophisticated conditional logic.
6. Immutable Data Handling: Works seamlessly with Records' immutable nature, promoting safer and more predictable data manipulations.
7. Improved Maintainability: Simplifies the process of updating and refactoring code by centralizing type checks and data extraction.
8. Seamless Integration with Existing Features: Builds upon Java's existing pattern matching infrastructure, allowing for smooth adoption without disrupting existing code patterns.
9. Enhanced Developer Productivity: Speeds up development by reducing the amount of code developers need to write and manage, allowing them to focus on core logic.
10. Alignment with Functional Programming: Supports more declarative and functional coding styles, aligning Java with modern programming paradigms and improving expressiveness.

Record Patterns represent a significant advancement in Java's type handling and pattern matching capabilities. By enabling the deconstruction of Records within type checks and `switch` expressions, this feature fosters more expressive, concise, and maintainable code, enhancing the overall developer experience and promoting best practices in modern Java application development.

## Pattern Matching for `switch` (Second Preview)

Pattern Matching for `switch` was introduced as a preview feature in Java 21, further enhancing the capabilities of the `switch` statement by integrating advanced pattern matching techniques. This feature makes `switch` constructs more powerful and expressive, enabling them to handle complex data-oriented queries more naturally and concisely. By allowing developers to deconstruct objects and apply patterns directly within `switch` statements and expressions, Java promotes a more declarative and streamlined approach to conditional logic. This improvement reduces boilerplate code associated with type checks and casting, resulting in cleaner, more maintainable, and more readable codebases.

#### Description of the Change

Prior to Java 21, the `switch` statement in Java was limited in its ability to perform complex pattern matching. Developers often had to rely on multiple `instanceof` checks and explicit casting within `switch` cases, leading to verbose and error-prone code. While Java 17 introduced pattern matching for `instanceof`, enabling more concise type checks, the integration of pattern matching directly into `switch` statements in Java 21 takes this a step further.

With Pattern Matching for `switch`, developers can now use patterns to deconstruct objects and bind variables directly within `switch` cases. This allows for more sophisticated conditional logic, such as matching specific record types, extracting components from records, and handling nested structures with ease. The enhanced `switch` construct supports both expressions and statements, providing flexibility in how it can be used within the codebase.

#### Code Examples

*Before Java 21 (Using Traditional `switch` with `instanceof` and Casting):*

```java
public class TraditionalSwitchExample {
    public static void main(String[] args) {
        Object obj = "Hello, Java 21!";
        String result;
        switch (obj.getClass().getSimpleName()) {
            case "String":
                String str = (String) obj;
                result = "String of length " + str.length();
                break;
            case "Integer":
                Integer num = (Integer) obj;
                result = "Integer value: " + num;
                break;
            default:
                result = "Unknown type";
                break;
        }
        System.out.println(result);
    }
}
```

*Output:*
```
String of length 15
```

*With Java 21 Pattern Matching for `switch`:*

```java
public class EnhancedSwitchPatternExample {
    public static void main(String[] args) {
        Object obj = "Hello, Java 21!";

        String result = switch (obj) {
            case String s -> "String of length " + s.length();
            case Integer i -> "Integer value: " + i;
            default -> "Unknown type";
        };

        System.out.println(result);
    }
}
```

*Output:*
```
String of length 15
```

*Using Complex Patterns with Records:*

```java
public record Point(int x, int y) {}
public record Circle(Point center, double radius) {}
public record Rectangle(Point topLeft, Point bottomRight) {}

public class ComplexPatternSwitchExample {
    public static void main(String[] args) {
        Object shape = new Circle(new Point(5, 10), 15.0);

        String description = switch (shape) {
            case Circle(Point x, double r) -> "Circle with center at (" + x.x() 
                    + ", " + x.y() + ") and radius " + r;
            case Rectangle(Point tl, Point br) -> "Rectangle from (" + tl.x() + ", " 
                    + tl.y() + ") to (" + br.x() + ", " + br.y() + ")";
            default -> "Unknown shape";
        };

        System.out.println(description);
    }
}
```

*Output:*
```
Circle with center at (5, 10) and radius 15.0
```

#### Explanation of the Example

In the Traditional `switch` Example, the `switch` statement relies on the class name of the object to determine its type. This approach requires explicit casting within each `case` block, which not only adds boilerplate code but also increases the risk of `ClassCastException`s if not handled carefully.

In contrast, the Enhanced `switch` Example in Java 21 leverages pattern matching directly within the `switch` statement. The syntax `case String s ->` allows the `switch` to both check the type of `obj` and cast it to a `String` in a single, concise step. This eliminates the need for separate type checks and casting, resulting in cleaner and more readable code.

The Complex Pattern `switch` Example demonstrates the power of Pattern Matching for `switch` when dealing with more intricate data structures like Records. By matching against specific record types and deconstructing their components directly within the `switch` cases, developers can handle complex conditional logic more elegantly. This reduces the need for nested `instanceof` checks and manual extraction of record components, streamlining the control flow and enhancing code maintainability.

#### Benefits of Pattern Matching for `switch`:

1. Conciseness: Combines type checking and casting into a single statement, reducing the overall amount of code required.
2. Readability: Enhances the clarity of conditional logic by making the association between patterns and their corresponding actions more explicit.
3. Reduced Boilerplate: Eliminates repetitive code structures, such as separate `instanceof` checks and explicit casting, leading to cleaner codebases.
4. Type Safety: Ensures that type-specific logic is only executed when the object matches the specified pattern, minimizing the risk of runtime type errors.
5. Enhanced Expressiveness: Allows for more sophisticated and expressive conditional logic, enabling developers to handle complex data structures and patterns seamlessly.
6. Improved Maintainability: Simplifies the process of updating and modifying conditional logic by centralizing pattern definitions within the `switch` construct.
7. Seamless Integration with Records: Works harmoniously with Java Records, allowing for efficient deconstruction and handling of immutable data carriers.
8. Alignment with Functional Programming: Supports a more declarative and functional style of programming, aligning Java with modern programming paradigms.
9. Enhanced Pattern Matching Capabilities: Extends pattern matching beyond simple type checks to include deconstruction and extraction of object components.
10. Future-Proofing: Prepares Java for further advancements in pattern matching and control flow constructs, ensuring that the language remains modern and expressive.

Pattern Matching for `switch` represents a significant advancement in Java's type handling and control flow mechanisms. By integrating pattern matching directly into the `switch` construct, Java developers can write more expressive, concise, and maintainable code, effectively handling complex data-oriented queries with ease and efficiency.

## Virtual Threads (Project Loom)

Virtual Threads, introduced as part of Project Loom and becoming a standard feature in Java 21, represent a groundbreaking advancement in Java's concurrency model. Virtual Threads are lightweight threads managed by the Java Virtual Machine (JVM), designed to simplify concurrent programming by drastically reducing the overhead associated with traditional platform threads. Unlike conventional threads, which are heavyweight and limited in number due to their resource consumption, Virtual Threads are highly scalable, enabling developers to create and manage millions of concurrent tasks with ease. This enhancement allows for the development of highly concurrent applications that achieve improved scalability and performance without the complexity and resource constraints typically associated with multithreaded programming.

#### Description of the Change

Prior to the introduction of Virtual Threads, Java's concurrency model relied on platform threads, each of which consumes significant system resources. Managing a large number of platform threads can lead to increased memory usage, context-switching overhead, and diminished application performance, making it challenging to build applications that require high levels of concurrency, such as web servers or real-time data processing systems. Developers often had to employ complex thread pooling strategies and asynchronous programming models to mitigate these limitations, which could introduce additional complexity and potential for bugs.

Virtual Threads address these challenges by providing a lightweight alternative that is managed by the JVM rather than the underlying operating system. They are designed to handle blocking I/O operations efficiently, allowing threads to be parked and resumed without incurring the same resource costs as platform threads. This innovation simplifies the development of concurrent applications by enabling developers to write straightforward, synchronous code that scales seamlessly, eliminating the need for intricate asynchronous patterns or manual thread management.

#### Code Examples

*Before Java 21 (Using Traditional Platform Threads):*

```java
import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;


public class TraditionalThreadServer {
    public static void main(String[] args) throws IOException {
        ServerSocket serverSocket = new ServerSocket(8080);
        System.out.println("Server started on port 8080");

        while (true) {
            Socket clientSocket = serverSocket.accept();
            // Handle each client in a new platform thread
            new Thread(() -> handleClient(clientSocket)).start();
        }
    }

    private static void handleClient(Socket clientSocket) {
        try {
            // Simulate processing
            System.out.println("Handling client " + clientSocket.getRemoteSocketAddress());
            Thread.sleep(1000); // Simulate blocking I/O
            clientSocket.close();
        } catch (InterruptedException | IOException e) {
            e.printStackTrace();
        }
    }
}
```

*With Java 21 Virtual Threads:*

```java
import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;

public class VirtualThreadServer {
    public static void main(String[] args) throws IOException {
        ServerSocket serverSocket = new ServerSocket(8080);
        System.out.println("Server started on port 8080");
        while (true) {
            Socket clientSocket = serverSocket.accept();
            // Handle each client in a new virtual thread
            Thread.startVirtualThread(() -> handleClient(clientSocket));
        }
    }

    private static void handleClient(Socket clientSocket) {
        try {
            // Simulate processing
            System.out.println("Handling client "
                    + clientSocket.getRemoteSocketAddress());
            Thread.sleep(1000); // Simulate blocking I/O
            clientSocket.close();
        } catch (InterruptedException | IOException e) {
            e.printStackTrace();
        }
    }
}
```

*Using Virtual Threads with Executors:*

```java
import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class ExecutorVirtualThreadServer {
    public static void main(String[] args) throws IOException {
        ServerSocket serverSocket = new ServerSocket(8080);
        System.out.println("Server started on port 8080");

        // Create an ExecutorService that uses virtual threads
        ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor();

        while (true) {
            Socket clientSocket = serverSocket.accept();
            // Submit client handling to the executor
            executor.submit(() -> handleClient(clientSocket));
        }
    }

    private static void handleClient(Socket clientSocket) {
        try {
            // Simulate processing
            System.out.println("Handling client " + clientSocket.getRemoteSocketAddress());
            Thread.sleep(1000); // Simulate blocking I/O
            clientSocket.close();
        } catch (InterruptedException | IOException e) {
            e.printStackTrace();
        }
    }
}
```

#### Explanation of the Example

In the Traditional Platform Threads example, each incoming client connection is handled by creating a new platform thread using the `Thread` class. While this approach works for a small number of concurrent connections, it becomes inefficient and resource-intensive as the number of clients increases. Each platform thread consumes significant memory and CPU resources, limiting the server's ability to scale and handle high levels of concurrency.

Conversely, the Virtual Threads example leverages Java 21's `startVirtualThread` method to handle each client connection within a Virtual Thread. Virtual Threads are lightweight and managed by the JVM, allowing the server to handle a much larger number of concurrent connections without the same resource constraints. This results in improved scalability and performance, as the overhead associated with creating and managing platform threads is significantly reduced.

The Executor with Virtual Threads example demonstrates the use of an `ExecutorService` configured to utilize Virtual Threads through the `newVirtualThreadPerTaskExecutor` method. This approach provides a more scalable and maintainable way to manage concurrent tasks, as the executor abstracts the thread management details and optimizes resource usage automatically. By submitting client handling tasks to the executor, developers can efficiently manage a large number of concurrent connections with minimal boilerplate code.

#### Benefits of Virtual Threads:

1. Scalability: Enables the creation and management of millions of concurrent Virtual Threads without overwhelming system resources, allowing applications to scale seamlessly.
2. Simplified Concurrency: Allows developers to write straightforward, synchronous code for handling concurrent tasks, eliminating the need for complex asynchronous programming models.
3. Reduced Overhead: Virtual Threads consume significantly fewer resources compared to platform threads, minimizing memory usage and CPU overhead.
4. Enhanced Performance: Improves application responsiveness and throughput by efficiently managing blocking I/O operations without stalling the entire application.
5. Ease of Use: Integrates seamlessly with existing Java concurrency constructs, such as Executors, making it easy to adopt without extensive refactoring.
6. Improved Developer Productivity: Reduces the complexity of writing and maintaining concurrent code, allowing developers to focus on core application logic.
7. Better Resource Utilization: Optimizes the use of system resources by allowing the JVM to manage thread scheduling and execution more efficiently.
8. Enhanced Maintainability: Promotes cleaner and more maintainable code by avoiding the boilerplate associated with manual thread management and synchronization.
9. Compatibility: Works with existing Java APIs and libraries that rely on traditional threading models, ensuring broad compatibility and ease of integration.
10. Future-Proofing: Aligns Java with modern concurrency paradigms, preparing the language for future advancements in parallel and distributed computing.

Virtual Threads revolutionize Java's approach to concurrency by providing a lightweight, scalable, and easy-to-use threading model. By abstracting the complexities of thread management and enabling developers to write more intuitive concurrent code, Virtual Threads empower the creation of highly responsive and scalable applications that meet the demands of today's multi-core and distributed computing environments.

## Sequenced Collections

Sequenced Collections were introduced in Java 21 as an enhancement to the Java Collections Framework, providing ordered versions of collection interfaces. These sequenced collections ensure that elements maintain a defined encounter order, enhancing predictability and consistency when processing collections. By explicitly defining the sequence in which elements are accessed and iterated, developers can write more reliable and maintainable code, especially in scenarios where the order of elements is significant. This improvement addresses the need for clear and consistent ordering semantics across different types of collections, facilitating better interoperability and reducing the likelihood of unexpected behaviors in data processing tasks.

#### Description of the Change

Prior to Java 21, the Java Collections Framework offered various collection types, some of which maintained element order (like `List` and `LinkedHashSet`), while others did not (such as `HashSet` and `HashMap`). This inconsistency often required developers to choose specific collection implementations based on their ordering requirements, leading to potential confusion and increased complexity in codebases. The introduction of Sequenced Collections standardizes the concept of ordered collections by providing a unified approach to maintaining element sequence across different collection interfaces.

Sequenced Collections extend existing collection interfaces (such as `List`, `Set`, and `Map`) by ensuring that the order of elements is preserved and well-defined. This enhancement simplifies the selection of appropriate collection types for various use cases, promoting consistency and reducing the cognitive load on developers when managing ordered data. Additionally, sequenced collections enhance interoperability between different parts of an application by providing a common ordering semantics, facilitating smoother data transformations and integrations.

#### Code Examples

*Before Java 21 (Using Traditional Collections with Inconsistent Ordering):*

```java
import java.util.*;

public class TraditionalCollectionsExample {
    public static void main(String[] args) {
        // Using HashSet (No guaranteed order)
        Set<String> hashSet = new HashSet<>();
        hashSet.add("Apple");
        hashSet.add("Banana");
        hashSet.add("Cherry");
        hashSet.add("Date");
        System.out.println("HashSet:");
        for (String fruit : hashSet) {
            System.out.println(fruit);
        }
        // Using LinkedHashSet (Maintains insertion order)
        Set<String> linkedHashSet = new LinkedHashSet<>();
        linkedHashSet.add("Apple");
        linkedHashSet.add("Banana");
        linkedHashSet.add("Cherry");
        linkedHashSet.add("Date");
        System.out.println("\nLinkedHashSet:");
        for (String fruit : linkedHashSet) {
            System.out.println(fruit);
        }
        // Using TreeSet (Sorted order)
        Set<String> treeSet = new TreeSet<>();
        treeSet.add("Apple");
        treeSet.add("Banana");
        treeSet.add("Cherry");
        treeSet.add("Date");
        System.out.println("\nTreeSet:");
        for (String fruit : treeSet) {
            System.out.println(fruit);
        }
    }
}
```

*Output:*
```
HashSet:
Banana
Date
Apple
Cherry

LinkedHashSet:
Apple
Banana
Cherry
Date

TreeSet:
Apple
Banana
Cherry
Date
```

*With Java 21 Sequenced Collections:*

```java
import java.util.*;

public class SequencedCollectionsExample {
    public static void main(String[] args) {
        // Using SequencedSet interface with a specific implementation
        SequencedSet<String> sequencedSet = new LinkedHashSet<>();
        sequencedSet.add("Apple");
        sequencedSet.add("Banana");
        sequencedSet.add("Cherry");
        sequencedSet.add("Date");

        System.out.println("SequencedHashSet:");
        for (String fruit : sequencedSet) {
            System.out.println(fruit);
        }

        // Using SequencedList interface with a specific implementation
        SequencedList<String> sequencedList = new ArrayList<>();
        sequencedList.add("Elderberry");
        sequencedList.add("Fig");
        sequencedList.add("Grape");
        sequencedList.add("Honeydew");

        System.out.println("\nSequencedArrayList:");
        for (String fruit : sequencedList) {
            System.out.println(fruit);
        }

        // Using SequencedMap interface with a specific implementation
        SequencedMap<String, Integer> sequencedMap = new LinkedHashMap<>();
        sequencedMap.put("Apple", 1);
        sequencedMap.put("Banana", 2);
        sequencedMap.put("Cherry", 3);
        sequencedMap.put("Date", 4);

        System.out.println("\nSequencedHashMap:");
        for (Map.Entry<String, Integer> entry : sequencedMap.entrySet()) {
            System.out.println(entry.getKey() + " = " + entry.getValue());
        }
    }
}

// Example interfaces and classes for Sequenced Collections

interface SequencedSet<E> extends Set<E>, Iterable<E> {}
interface SequencedList<E> extends List<E>, Iterable<E> {}
interface SequencedMap<K, V> extends Map<K, V>, Iterable<Map.Entry<K, V>> {}

class SequencedHashSet<E> extends LinkedHashSet<E> implements SequencedSet<E> {}
class SequencedArrayList<E> extends ArrayList<E> implements SequencedList<E> {}
class SequencedHashMap<K, V> extends LinkedHashMap<K, V> implements SequencedMap<K, V> {}
```

*Output:*
```
SequencedHashSet:
Apple
Banana
Cherry
Date

SequencedArrayList:
Elderberry
Fig
Grape
Honeydew

SequencedHashMap:
Apple = 1
Banana = 2
Cherry = 3
Date = 4
```

#### Explanation of the Example

In the Traditional Collections Example, different `Set` implementations (`HashSet`, `LinkedHashSet`, and `TreeSet`) are used to demonstrate varying ordering behaviors:

- `HashSet` does not guarantee any specific order of elements.
- `LinkedHashSet` maintains elements in the order they were inserted.
- `TreeSet` sorts elements based on their natural ordering or a provided comparator.

While these collections provide flexibility, choosing the appropriate implementation based on ordering requirements can lead to confusion and increased complexity, especially in large codebases where consistency is crucial.

In contrast, the Sequenced Collections Example introduces `SequencedSet`, `SequencedList`, and `SequencedMap` interfaces, along with their corresponding implementations. These sequenced collections ensure that elements maintain a defined encounter order:

- `SequencedHashSet` extends `LinkedHashSet`, preserving insertion order.
- `SequencedArrayList` extends `ArrayList`, which inherently maintains order.
- `SequencedHashMap` extends `LinkedHashMap`, preserving the order of key-value pairs as they were inserted.

By using sequenced collections, developers can consistently rely on the defined order across different collection types without having to select specific implementations based on ordering behavior. This standardization simplifies code maintenance and enhances predictability when processing collections.

#### Benefits of Sequenced Collections

1. Consistent Ordering Semantics: Provides a unified approach to maintaining element order across different collection types, reducing confusion and errors.
2. Enhanced Readability: Makes the intention of preserving order explicit through interface naming, improving code clarity.
3. Simplified Collection Selection: Eliminates the need to choose specific collection implementations based solely on ordering requirements, streamlining development.
4. Improved Interoperability: Facilitates smoother data transformations and integrations by ensuring consistent ordering semantics across different parts of an application.
5. Reduced Boilerplate: Minimizes the need for manual checks or additional configurations to maintain element order, leading to cleaner and more maintainable code.
6. Enhanced Predictability: Ensures that collections behave predictably with respect to element order, which is crucial for operations like iteration, serialization, and user interface rendering.
7. Facilitates Testing and Debugging: Consistent ordering makes it easier to write reliable tests and debug issues related to data processing and manipulation.
8. Better API Design: Encourages the design of APIs that are clear about their ordering expectations, enhancing developer experience and reducing ambiguity.
9. Alignment with Modern Programming Practices: Adheres to contemporary programming standards that emphasize immutability, consistency, and predictability in data structures.
10. Future-Proofing Collections Framework: Lays the groundwork for further enhancements and optimizations in the Java Collections Framework by establishing a clear foundation for ordered collections.

Sequenced Collections represent a significant improvement in the Java Collections Framework by standardizing the concept of ordered collections. This enhancement not only simplifies the development process but also promotes best practices in managing and processing data, leading to more robust and maintainable Java applications.

## Enhanced Switch Expressions and Sealed Interfaces

Enhanced Switch Expressions and Sealed Interfaces represent significant advancements in Java's language features, aimed at making control flow constructs more robust and type hierarchies more controlled. These enhancements allow developers to write more expressive, concise, and maintainable code by leveraging advanced pattern matching and strict type constraints.

#### Description of the Change

The Enhanced Switch Expressions build upon earlier improvements by introducing more powerful pattern matching capabilities and additional syntax options, making `switch` statements more flexible and expressive. This includes support for complex patterns, better integration with type checking, and the ability to handle a wider range of scenarios in a more declarative manner. These enhancements enable developers to perform sophisticated conditional logic directly within `switch` constructs, reducing the need for nested `if-else` statements and explicit casting.

Sealed Interfaces have been further refined to provide even more control over type hierarchies. They allow developers to define interfaces that can only be implemented by a specific set of classes or interfaces, ensuring a controlled and predictable inheritance structure. This refinement enhances the ability to model domain-specific concepts accurately and enforces stricter type safety across applications. By explicitly specifying permitted subclasses or implementing interfaces using the `permits` clause, Java ensures that the type hierarchy remains well-defined and maintainable.

Together, these features empower developers to handle complex data-oriented queries and type relationships more effectively, promoting best practices in modern Java programming.

#### Code Examples

*Enhanced Switch Expressions with Pattern Matching:*

```java
public class EnhancedSwitchExample {
    public static void main(String[] args) {
        Object obj = "Java 21";
        
        String result = switch (obj) {
            case String s && s.length() > 5 -> "Long string: " + s;
            case String s -> "Short string: " + s;
            case Integer i -> "Integer: " + i;
            default -> "Unknown type";
        };
        
        System.out.println(result);
    }
}
```

*Output:*
```
Long string: Java 21
```

*Explanation:*

In the Enhanced Switch Expressions example, the `switch` statement utilizes pattern matching with conditions. The first case matches a `String` with a length greater than 5, and the second case matches any `String`. This allows for more granular and expressive conditional logic directly within the `switch`, reducing the need for nested `if-else` statements.

*Refined Sealed Interfaces:*

```java
// Sealed interface with permitted implementations
public sealed interface Vehicle permits Car, Truck, Motorcycle {
    void drive();
}

// Final class implementing Vehicle
public final class Car implements Vehicle {
    @Override
    public void drive() {
        System.out.println("Driving a car.");
    }
}

// Non-sealed class implementing Vehicle
public non-sealed class Truck implements Vehicle {
    @Override
    public void drive() {
        System.out.println("Driving a truck.");
    }
}

// Another permitted class
public final class Motorcycle implements Vehicle {
    @Override
    public void drive() {
        System.out.println("Driving a motorcycle.");
    }
}

// Attempting to implement Vehicle outside the permitted classes will result in an error
// public class Bicycle implements Vehicle { // Compilation Error
//     @Override
//     public void drive() {
//         System.out.println("Driving a bicycle.");
//     }
// }

public class SealedInterfaceExample {
    public static void main(String[] args) {
        Vehicle myCar = new Car();
        Vehicle myTruck = new Truck();
        Vehicle myMotorcycle = new Motorcycle();
        
        myCar.drive(); // Output: Driving a car.
        myTruck.drive(); // Output: Driving a truck.
        myMotorcycle.drive(); // Output: Driving a motorcycle.
    }
}
```

*Output:*
```
Driving a car.
Driving a truck.
Driving a motorcycle.
```

*Explanation:*

In the Refined Sealed Interfaces example, the `Vehicle` interface is declared as `sealed` and explicitly permits only the `Car`, `Truck`, and `Motorcycle` classes to implement it using the `permits` clause. The `Car` and `Motorcycle` classes are marked as `final`, preventing any further subclassing, while the `Truck` class is declared as `non-sealed`, allowing it to be extended if necessary. Attempting to create a class like `Bicycle` that implements `Vehicle` outside the permitted classes results in a compile-time error, ensuring a controlled and predictable type hierarchy.

#### Benefits of Enhanced Switch Expressions and Sealed Interfaces

1. Increased Expressiveness: Allows developers to write more complex and precise conditional logic using pattern matching within `switch` expressions.
2. Improved Readability: Enhances code clarity by reducing the need for verbose type checks and casting, making the control flow easier to understand.
3. Reduced Boilerplate: Minimizes repetitive code patterns, such as multiple `instanceof` checks and explicit casting, leading to cleaner codebases.
4. Type Safety: Ensures that type-specific logic is only executed when objects match the specified patterns or types, reducing the risk of runtime errors.
5. Controlled Type Hierarchies: Enables developers to define strict and predictable type hierarchies through refined sealed interfaces, enhancing encapsulation and reducing unintended extensions.
6. Enhanced Maintainability: Simplifies the process of updating and refactoring code by centralizing pattern definitions and type constraints within `switch` statements and sealed interfaces.
7. Optimized Performance: Potential compiler optimizations are facilitated by the more predictable and well-defined type hierarchies and pattern matching constructs.
8. Better Alignment with Modern Programming Paradigms: Supports declarative and functional programming styles, making Java more adaptable to contemporary development practices.
9. Improved Developer Productivity: Speeds up development by providing more concise and intuitive language constructs, allowing developers to focus on core logic rather than boilerplate.
10. Enhanced API Design: Promotes the creation of APIs that leverage pattern matching and controlled type hierarchies, leading to more robust and predictable interfaces.

Enhanced `switch` expressions and sealed interfaces significantly improve Java's capabilities in handling complex conditional logic and type hierarchies. By providing more expressive and controlled constructs, these features enable developers to write more efficient, readable, and maintainable code, aligning Java with modern programming standards and practices.

## Modules (Project Jigsaw)

Modules, introduced in Java 9 as part of Project Jigsaw, represent a significant enhancement to the Java language and its runtime environment. The module system provides a robust framework for organizing code into cohesive, reusable, and maintainable units. By enabling strong encapsulation and explicit dependencies, modules address the complexities associated with large-scale applications, fostering better software architecture and enhancing the overall reliability and security of Java applications.

#### Description of the Change

Before the introduction of the module system, Java applications relied heavily on the classpath for organizing and accessing classes and libraries. While effective for smaller projects, the classpath approach posed challenges for large-scale applications, including:

1. Lack of Encapsulation: All public classes were accessible to any other class on the classpath, making it difficult to enforce strong encapsulation boundaries.
2. Dependency Management: Managing dependencies was cumbersome, leading to issues like JAR Hell, where conflicting versions of libraries could cause runtime errors.
3. Scalability Concerns: As applications grew, the classpath became increasingly complex and harder to manage, impacting maintainability and performance.
4. Security Vulnerabilities: The absence of strict access controls made it easier for malicious code to access sensitive parts of the application.

Project Jigsaw was initiated to address these limitations by introducing a module system that brings structured encapsulation and reliable configuration to the Java ecosystem. The key components of the module system include:

- Module Declarations (`module-info.java`): Defines a module's dependencies and the packages it exports.
- Strong Encapsulation: Restricts access to internal packages, exposing only the intended API to other modules.
- Explicit Dependencies: Specifies which modules a given module depends on, enhancing clarity and reducing hidden dependencies.
- Improved Security: Limits access to internal implementation details, mitigating potential security risks.

#### Code Examples

##### *Defining a Module (`module-info.java`)*

```java
// File: module-info.java
module com.example.math {
    // Exporting the public package to other modules
    exports com.example.math.operations;

    // Requires another module (e.g., java.logging)
    requires java.logging;
}
```

##### *Exporting Packages and Requiring Modules*

```java
// File: com/example/math/operations/Calculator.java
package com.example.math.operations;

public class Calculator {
    public int add(int a, int b) {
        return a + b;
    }
}
```

```java
// File: module-info.java
module com.example.application {
    // Requires the math module
    requires com.example.math;

    // Requires java.logging module
    requires java.logging;
}
```

##### *Using the Exported Module in Another Module*

```java
// File: com/example/application/MainApp.java
package com.example.application;

import com.example.math.operations.Calculator;
import java.util.logging.Logger;

public class MainApp {
    private static final Logger logger = Logger.getLogger(MainApp.class.getName());

    public static void main(String[] args) {
        Calculator calculator = new Calculator();
        int result = calculator.add(5, 7);
        logger.info("Result of addition: " + result);
    }
}
```

#### Explanation of the Example

1. Module Declaration (`module-info.java`):

    - The `com.example.math` module exports the `com.example.math.operations` package, making its public classes (e.g., `Calculator`) accessible to other modules.
    - It explicitly requires the `java.logging` module, indicating a dependency on Java's built-in logging framework.

2. Exporting Packages:

    - The `Calculator` class resides in the `com.example.math.operations` package. By exporting this package, other modules that require `com.example.math` can access `Calculator`.

3. Using Modules in an Application:

    - This module declares dependencies on both `com.example.math` and `java.logging`.
    - In the `MainApp` class, an instance of `Calculator` is created and used to perform an addition operation. The result is then logged using Java's logging framework.

4. Encapsulation and Dependency Management:

    - Only the `com.example.math.operations` package is exposed to other modules, ensuring that internal implementation details remain hidden.
    - Dependencies are explicitly declared, preventing accidental or unauthorized access to other modules' internal packages.

#### Benefits of Modules (Project Jigsaw)

1. Strong Encapsulation: Modules enforce strict access controls, ensuring that only exported packages are accessible to other modules. This prevents unintended interactions and promotes a clear separation of concerns.
2. Reliable Configuration: By explicitly declaring dependencies, modules eliminate hidden or implicit dependencies, reducing the risk of JAR Hell and making dependency management more predictable.
3. Improved Maintainability: Modules provide a clear structure to large codebases, making it easier to navigate, understand, and maintain complex applications.
4. Enhanced Security: Limiting access to internal packages minimizes the attack surface, protecting sensitive implementation details from unauthorized access.
5. Scalability: The module system scales well with large applications, allowing for incremental development and deployment of modules without impacting the entire system.
6. Performance Optimizations: The JVM can perform optimizations based on module information, such as faster startup times and reduced memory footprint, by loading only the necessary modules.
7. Better Tooling Support: Development tools can leverage module metadata to provide improved features like dependency analysis, automated builds, and enhanced IDE support.
8. Enhanced Reusability: Modules promote the creation of reusable libraries and components by clearly defining their APIs and dependencies.
9. Facilitates Team Collaboration: Teams can work on different modules independently, reducing merge conflicts and improving collaboration efficiency.
10. Future-Proofing Java Applications: The module system aligns Java with modern software architecture practices, ensuring that applications remain robust and adaptable to future changes and enhancements.

#### Advanced Features and Considerations

- Automatic Modules: Allows non-modular JARs to be used within the module system by treating them as automatic modules, easing the transition to a fully modularized codebase.
- Service Loading: The module system enhances Java's service loading mechanism, enabling more efficient and secure service provider implementations.
- Qualified Exports: Modules can export packages to specific other modules, providing more granular control over package visibility.
- Module Resolution: The JVM performs module resolution at startup, ensuring that all dependencies are satisfied and that there are no conflicts, leading to more reliable application behavior.

#### Migrating to Modules

Transitioning an existing Java application to use modules involves several steps:

1. Identify Module Boundaries: Determine logical separations within the application to define modules based on functionality, teams, or architectural layers.
2. Create `module-info.java` Files: For each module, create a `module-info.java` file that declares the module's name, exported packages, and required dependencies.
3. Refactor Packages: Organize packages to align with module boundaries, ensuring that only intended packages are exported.
4. Handle Dependencies: Update module declarations to reflect the actual dependencies between modules, removing any unnecessary or implicit dependencies.
5. Test Thoroughly: Ensure that the modularized application behaves as expected, with all dependencies correctly resolved and encapsulation rules enforced.
6. Leverage Automatic Modules (if necessary): For third-party libraries that are not modularized, utilize automatic modules to integrate them into the module system temporarily.

#### Conclusion

The introduction of Modules (Project Jigsaw) marks a pivotal evolution in the Java ecosystem, addressing long-standing challenges related to encapsulation, dependency management, and scalability. By providing a structured and enforceable framework for organizing code, modules enhance the robustness, maintainability, and security of Java applications. This advancement not only simplifies the development of large-scale systems but also aligns Java with contemporary software architecture practices, ensuring its continued relevance and effectiveness in modern software development.

# What changes in Java await us in the future?

## Stream Collectors

Stream Collectors are a crucial part of Java's Stream API, providing a way to accumulate elements from a stream into various result containers such as lists, sets, maps, or even custom objects. Future enhancements to Stream Collectors may include additional built-in collectors for common tasks, improved performance optimizations, and more flexible ways to combine or compose collectors. These advancements aim to simplify data processing and transformation tasks, making it easier for developers to write concise and efficient code.

## Primitive Classes

Primitive Classes introduce specialized classes for Java's primitive data types (like `int`, `double`, `boolean`, etc.), aiming to eliminate the need for boxing and unboxing operations that can lead to performance overhead. By providing classes tailored to handle primitive values directly, Java can achieve more efficient memory usage and faster execution times, especially in performance-critical applications. These classes may offer methods and utilities specifically designed for primitive operations, enhancing the language's ability to handle low-level data processing without sacrificing the benefits of object-oriented programming.

## Flexible Constructor Bodies

Flexible Constructor Bodies allow for more versatile and expressive constructor implementations in Java classes. Traditionally, constructors are limited in their structure and the operations they can perform during object initialization. With this enhancement, developers can include more complex logic, such as conditional statements, loops, or even leveraging pattern matching within constructors. This flexibility enables the creation of objects with more intricate initialization processes, improving code readability and maintainability by reducing the need for separate initialization methods or excessive boilerplate code.

## Programmatic Class File Parsing

Programmatic Class File Parsing provides Java developers with APIs and tools to parse and analyze Java `.class` files directly within their applications. This capability is particularly useful for building frameworks, development tools, or libraries that need to inspect, manipulate, or generate bytecode dynamically. By offering a standardized way to interact with class file structures, Java enhances its support for metaprogramming and reflection-based operations. Developers can leverage these APIs to perform tasks such as code analysis, instrumentation, or transformation, facilitating advanced programming techniques and enabling more powerful and flexible software solutions.

# Review exercises

## Tasks

### Lambda Expressions

#### Exercise 1: Sorting a List of Strings Alphabetically

Task Description:  
Use a lambda expression to sort a list of strings in alphabetical order.

#### Exercise 2: Filtering Even Numbers from a List

Task Description:  
Use a lambda expression to filter and collect even numbers from a list of integers.

#### Exercise 3: Implementing a Custom Functional Interface

Task Description:  
Create a custom functional interface and use a lambda expression to implement its method that calculates the square of a number.

### Stream API

#### Exercise 1: Calculating the Sum of a List of Integers

Task Description:  
Use StreamAPI to calculate the sum of all integers in a list.

#### Exercise 2: Converting a List of Strings to Uppercase

Task Description:  
Use StreamAPI to convert all strings in a list to uppercase and collect them into a new list.

#### Exercise 3: Grouping Employees by Department

Task Description:  
Use StreamAPI to group a list of employees by their department.

### Functional Interfaces

#### Exercise 1: Using Predicate to Filter a List of Strings

Task Description:  
Use the `Predicate` functional interface to filter a list of strings, retaining only those that start with the letter "A".

#### Exercise 2: Using Function to Transform a List of Integers

Task Description:  
Use the `Function` functional interface to square each integer in a list and collect the results into a new list.

#### Exercise 3: Creating and Using a Custom Functional Interface

Task Description:  
Create a custom functional interface named `StringConcatenator` with a method that concatenates two strings. Use a lambda expression to implement this interface and concatenate two given strings.

### Method References

#### Exercise 1: Sorting a List of Strings Using Method Reference

Task Description:  
Use a method reference to sort a list of strings in ascending order.

#### Exercise 2: Printing List Elements Using Method Reference

Task Description:  
Use a method reference to print each element of a list of integers.

#### Exercise 3: Using Constructor Reference to Create Objects

Task Description:  
Use a constructor reference to create a list of `Person` objects from a list of names.

### Default Methods in Interfaces

#### Exercise 1: Implementing a Default Method in an Interface

Task Description:  
Create an interface `Vehicle` with a default method `startEngine()` that prints "Engine started". Implement this interface in a class `Car` and invoke the `startEngine` method.

#### Exercise 2: Overriding a Default Method in an Interface

Task Description:  
Create an interface `Calculator` with a default method `add(int a, int b)` that returns the sum of two integers. Implement this interface in a class `AdvancedCalculator` and override the `add` method to print the result before returning it.

#### Exercise 3: Resolving Conflicts with Multiple Default Methods

Task Description:  
Create two interfaces `InterfaceA` and `InterfaceB`, each with a default method `defaultMethod()` that prints different messages. Create a class `ConflictingClass` that implements both interfaces and override the `defaultMethod()` to resolve the conflict by choosing one of the interface's default methods.

### Optional Class

#### Exercise 1: Handling Null Values with Optional

Task Description:  
Use the `Optional` class to safely retrieve the value of a potentially null string. If the string is null, return a default message "Default String".

#### Exercise 2: Filtering Values with Optional

Task Description:  
Use the `Optional` class to filter an integer value. If the integer is even, return it; otherwise, return an empty `Optional`.

#### Exercise 3: Using Optional with Map and FlatMap

Task Description:  
Use the `Optional` class to transform a string to its length using `map`, and then transform it to an `Optional<String>` describing the length using `flatMap`.

### New Date and Time API (java.time)

#### Exercise 1: Formatting and Parsing Dates

Task Description:  
Use the `DateTimeFormatter` to format the current date into `dd-MM-yyyy` format and parse a string date `"25-12-2025"` back to a `LocalDate` object.

#### Exercise 2: Calculating the Difference Between Two Dates

Task Description:  
Calculate the number of days between `2025-01-01` and `2025-12-31` using `Period`.

#### Exercise 3: Working with ZonedDateTime

Task Description:  
Create a `ZonedDateTime` object for the current moment in the `Europe/Paris` timezone and display it in the `America/New_York` timezone.

### Local-Variable Syntax for Lambda Parameters

#### Exercise 1: Using `var` in Lambda Parameters Without Type Annotations

Task Description:  
Use `var` in a lambda expression to iterate over a list of integers and print each number multiplied by 2.

#### Exercise 2: Using `var` with Type Annotations in Lambda Parameters

Task Description:  
Use `var` with type annotations in a lambda expression to filter a list of strings that have a length greater than 3 and collect them into a new list.

#### Exercise 3: Using `var` with Multiple Lambda Parameters

Task Description:  
Use `var` in a lambda expression with multiple parameters to concatenate two strings with a space in between.

### Enhanced String API

#### Exercise 1: Using `isBlank()` to Validate Input Strings

Task Description:  
Use the `isBlank()` method to check if a given string is empty or contains only whitespace. Print an appropriate message based on the result.

#### Exercise 2: Splitting a String into Lines Using `lines()`

Task Description:  
Use the `lines()` method to split a multi-line string into individual lines and print each line separately.

#### Exercise 3: Repeating a String Using `repeat()`

Task Description:  
Use the `repeat()` method to create a string that repeats a given word 5 times, separated by spaces.

### Sealed Classes and Interfaces

#### Exercise 1: Creating a Sealed Class Hierarchy

Task Description:  
Create a sealed class `Shape` with permitted subclasses `Circle` and `Rectangle`. Implement the subclasses and demonstrate their instantiation.

#### Exercise 2: Implementing Sealed Interfaces

Task Description:  
Create a sealed interface `Animal` with permitted implementations `Dog` and `Cat`. Implement the classes and demonstrate polymorphism.

#### Exercise 3: Extending Sealed Classes with Further Restrictions

Task Description:  
Create a non-sealed class `Triangle` extending a sealed class `Shape`. Implement and demonstrate its usage.

### Pattern Matching for instanceof

#### Exercise 1: Basic Pattern Matching with `instanceof`

Task Description:  
Use pattern matching with the `instanceof` operator to check if an object is of type `String` and print its length.

#### Exercise 2: Pattern Matching with Multiple Types

Task Description:  
Use pattern matching with the `instanceof` operator to handle different types (`Integer` and `Double`) and perform specific operations based on the type.

#### Exercise 3: Using Pattern Matching in Switch Expressions

Task Description:  
Use pattern matching with `instanceof` in a switch expression to identify the type of an object and return a specific message for each type.

### Text Blocks

#### Exercise 1: Creating a Multi-line JSON String with Text Blocks

Task Description:  
Use a text block to create a multi-line JSON string representing a user with `name`, `age`, and `email`, and print it.

#### Exercise 2: Embedding HTML Content Using Text Blocks

Task Description:  
Use a text block to create a multi-line HTML string for a simple webpage with a title and a header, then print it.

#### Exercise 3: Using Text Blocks with Escape Characters

Task Description:  
Use a text block to create a multi-line string that includes both double quotes and a backslash, such as a file path, and print it.

### Records

#### Exercise 1: Defining a Simple Record and Accessing Its Fields

Task Description:  
Create a `record` named `Person` with fields `name` (String) and `age` (int). Instantiate the record and print its fields.

#### Exercise 2: Using Records with Collections and Streams

Task Description:  
Create a list of `Book` records with fields `title` (String) and `author` (String). Use StreamAPI to filter books by a specific author and collect the titles into a new list.

#### Exercise 3: Adding Methods to Records and Implementing Interfaces

Task Description:  
Create a `record` named `Rectangle` with fields `length` and `width`. Add a method `area()` to calculate the area of the rectangle. Implement the `Shape` interface with a method `perimeter()` and provide its implementation in the record.

### Enhanced switch Statements

#### Exercise 1: Using Switch Expressions to Determine Day Type

Task Description:  
Use an enhanced switch expression to determine if a given day is a weekday or weekend.

#### Exercise 2: Using Switch Statement with Yield to Return Values

Task Description:  
Use an enhanced switch statement with `yield` to assign a numerical value based on the given season.

#### Exercise 3: Using Pattern Matching with Switch for Type Checking

Task Description:  
Use an enhanced switch statement with pattern matching to perform operations based on the object's type.

### Record Patterns

#### Exercise 1: Destructuring a Record with `instanceof` Pattern Matching

Task Description:  
Use record patterns with the `instanceof` operator to destructure a `Person` record and print the name and age if the object is an instance of `Person`.

#### Exercise 2: Using Record Patterns in a Switch Statement

Task Description:  
Use record patterns within a switch expression to handle different types of `Shape` records (`Circle`, `Rectangle`, `Triangle`) and calculate their areas.

#### Exercise 3: Nested Record Patterns for Complex Data Structures

Task Description:  
Use nested record patterns to destructure a `Company` record containing an `Employee` record and print the employee's details if the company has a specific name.

### Virtual Threads

#### Exercise 1: Creating and Running a Virtual Thread

Task Description:  
Create and start a virtual thread that prints "Hello from Virtual Thread!".

#### Exercise 2: Executing Multiple Virtual Threads Using an Executor

Task Description:  
Use an `Executor` with virtual threads to execute five tasks concurrently, each printing its task number.

#### Exercise 3: Handling Blocking I/O with Virtual Threads

Task Description:  
Use virtual threads to perform a blocking file read operation and print the first line of the file.

### Sequenced Collections

#### Exercise 1: Creating and Manipulating a Sequenced Collection

Task Description:  
Create a `LinkedList` (which implements `SequencedCollection`) of integers. Add elements to both the beginning and end of the list, then print the entire list.

#### Exercise 2: Iterating from Both Ends of a Sequenced Collection

Task Description:  
Create a `LinkedList` of strings and use both `iterator()` and `descendingIterator()` to traverse and print the elements from the beginning and the end.

#### Exercise 3: Merging Two Sequenced Collections While Preserving Order

Task Description:  
Create two `LinkedList` instances of integers. Merge the second list into the first one by adding all elements to the end of the first list, then print the merged collection.

### Modules

#### Exercise 1: Creating a Simple Module

Task Description:  
Create a module named `com.example.greeter` that exports a package `com.example.greeter` containing a `Greeter` class with a method `greet()` that prints "Hello, Module!".
#### Exercise 2: Using `requires transitive` in Modules

Task Description:  
Create two modules: `com.example.utils` that exports a package `com.example.utils` containing a `Utils` class with a static method `printMessage(String message)`, and `com.example.app` that requires `com.example.utils` transitively and uses the `Utils` class to print a message.

#### Exercise 3: Providing and Consuming Services with Modules

Task Description:  
Create a module `com.example.service` that provides an implementation of a `com.example.api.GreetingService` interface. Then, create a module `com.example.client` that consumes the `GreetingService` using the `uses` and `provides` directives.

### Project

#### Smart Task Management System

Overview: Develop a comprehensive Smart Task Management System that allows users to create, assign, 
track, and manage tasks efficiently. This application will leverage numerous modern Java features to 
ensure scalability, maintainability, and performance. The system will be modular, supporting future 
enhancements and integrations.

Key Features and Java Features Integration:

- Sealed Classes and Interfaces: Define a sealed User interface with permitted subclasses like Admin, Manager, and Employee.
- Records: Use records to represent immutable user data.
- Optional Class: Handle optional user attributes such as middle names or secondary emails.
- Pattern Matching for instanceof: Implement role-based access control using pattern matching.
- Lambda Expressions & Functional Interfaces: Utilize lambdas for filtering and assigning tasks based on user roles or availability.
- Stream API & Collectors: Process and collect task data, generate reports, and perform analytics.
- Method References: Simplify stream operations with method references.
- Enhanced Switch Statements: Determine task priority or status using enhanced switch expressions.

## Solutions

### Lambda Expressions

#### Exercise 1: Sorting a List of Strings Alphabetically

Solution:
```java
import java.util.Arrays;
import java.util.List;

public class SortStrings {
    public static void main(String[] args) {
        List<String> fruits = Arrays.asList("Banana", "Apple", "Cherry", "Date");
        fruits.sort((s1, s2) -> s1.compareTo(s2));
        System.out.println(fruits);
    }
}
```

#### Exercise 2: Filtering Even Numbers from a List

Solution:
```java
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

public class FilterEvenNumbers {
    public static void main(String[] args) {
        List<Integer> numbers = Arrays.asList(1, 2, 3, 4, 5, 6);
        List<Integer> evenNumbers = numbers.stream()
                                           .filter(n -> n % 2 == 0)
                                           .collect(Collectors.toList());
        System.out.println(evenNumbers);
    }
}
```

#### Exercise 3: Implementing a Custom Functional Interface

Solution:
```java
@FunctionalInterface
interface MathOperation {
    int operate(int a);
}

public class CustomFunctionalInterface {
    public static void main(String[] args) {
        MathOperation square = (a) -> a * a;
        int result = square.operate(5);
        System.out.println("Square of 5 is: " + result);
    }
}
```

### Stream API

#### Exercise 1: Calculating the Sum of a List of Integers

Solution:
```java
import java.util.Arrays;
import java.util.List;

public class SumOfIntegers {
    public static void main(String[] args) {
        List<Integer> numbers = Arrays.asList(10, 20, 30, 40, 50);
        int sum = numbers.stream()
                         .mapToInt(Integer::intValue)
                         .sum();
        System.out.println("Sum: " + sum);
    }
}
```

#### Exercise 2: Converting a List of Strings to Uppercase

Solution:
```java
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

public class UppercaseStrings {
    public static void main(String[] args) {
        List<String> words = Arrays.asList("hello", "world", "java", "streams");
        List<String> uppercased = words.stream()
                                       .map(String::toUpperCase)
                                       .collect(Collectors.toList());
        System.out.println(uppercased);
    }
}
```

#### Exercise 3: Grouping Employees by Department

Solution:
```java
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

class Employee {
    String name;
    String department;

    Employee(String name, String department) {
        this.name = name;
        this.department = department;
    }
}

public class GroupEmployees {
    public static void main(String[] args) {
        List<Employee> employees = Arrays.asList(
            new Employee("Alice", "HR"),
            new Employee("Bob", "IT"),
            new Employee("Charlie", "HR"),
            new Employee("David", "IT"),
            new Employee("Eve", "Finance")
        );

        Map<String, List<Employee>> grouped = employees.stream()
                .collect(Collectors.groupingBy(e -> e.department));

        grouped.forEach((dept, empList) -> {
            System.out.println(dept + ":");
            empList.forEach(e -> System.out.println("  " + e.name));
        });
    }
}
```

### Functional Interfaces

#### Exercise 1: Using Predicate to Filter a List of Strings

Solution:
```java
import java.util.Arrays;
import java.util.List;
import java.util.function.Predicate;
import java.util.stream.Collectors;

public class PredicateFilter {
    public static void main(String[] args) {
        List<String> names = Arrays.asList("Alice", "Bob", "Amanda", "Brian", "Andrew");
        Predicate<String> startsWithA = s -> s.startsWith("A");
        List<String> filtered = names.stream()
                                     .filter(startsWithA)
                                     .collect(Collectors.toList());
        System.out.println(filtered);
    }
}
```

#### Exercise 2: Using Function to Transform a List of Integers

Solution:
```java
import java.util.Arrays;
import java.util.List;
import java.util.function.Function;
import java.util.stream.Collectors;

public class FunctionTransform {
    public static void main(String[] args) {
        List<Integer> numbers = Arrays.asList(1, 2, 3, 4, 5);
        Function<Integer, Integer> square = x -> x * x;
        List<Integer> squaredNumbers = numbers.stream()
                                              .map(square)
                                              .collect(Collectors.toList());
        System.out.println(squaredNumbers);
    }
}
```

#### Exercise 3: Creating and Using a Custom Functional Interface

Solution:
```java
@FunctionalInterface
interface StringConcatenator {
    String concatenate(String a, String b);
}

public class MultipleVarLambda {
    public static void main(String[] args) {
        StringConcatenator concat = (a, b) -> a + " " + b;
        String result = concat.concatenate("Hello", "World");
        System.out.println(result);
    }
}
```

### Method References

#### Exercise 1: Sorting a List of Strings Using Method Reference

Solution:
```java
import java.util.Arrays;
import java.util.List;

public class SortWithMethodReference {
    public static void main(String[] args) {
        List<String> cities = Arrays.asList("London", "New York", "Paris", "Tokyo");
        cities.sort(String::compareTo);
        System.out.println(cities);
    }
}
```

#### Exercise 2: Printing List Elements Using Method Reference

Solution:
```java
import java.util.Arrays;
import java.util.List;

public class PrintWithMethodReference {
    public static void main(String[] args) {
        List<Integer> numbers = Arrays.asList(10, 20, 30, 40, 50);
        numbers.forEach(System.out::println);
    }
}
```

#### Exercise 3: Using Constructor Reference to Create Objects

Solution:
```java
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

class Person {
    String name;

    Person(String name) {
        this.name = name;
    }

    @Override
    public String toString() {
        return name;
    }
}

public class ConstructorReference {
    public static void main(String[] args) {
        List<String> names = Arrays.asList("Alice", "Bob", "Charlie");
        List<Person> people = names.stream()
                                   .map(Person::new)
                                   .collect(Collectors.toList());
        people.forEach(System.out::println);
    }
}
```

### Default Methods in Interfaces

#### Exercise 1: Implementing a Default Method in an Interface

Solution:
```java
interface Vehicle {
    default void startEngine() {
        System.out.println("Engine started");
    }
}

public class Car implements Vehicle {
    public static void main(String[] args) {
        Car car = new Car();
        car.startEngine();
    }
}
```

#### Exercise 2: Overriding a Default Method in an Interface

Solution:
```java
interface Calculator {
    default int add(int a, int b) {
        return a + b;
    }
}

public class AdvancedCalculator implements Calculator {
    @Override
    public int add(int a, int b) {
        int result = Calculator.super.add(a, b);
        System.out.println("Adding " + a + " and " + b + ": " + result);
        return result;
    }

    public static void main(String[] args) {
        AdvancedCalculator calc = new AdvancedCalculator();
        calc.add(5, 10);
    }
}
```

#### Exercise 3: Resolving Conflicts with Multiple Default Methods

Solution:
```java
interface InterfaceA {
    default void defaultMethod() {
        System.out.println("InterfaceA defaultMethod");
    }
}

interface InterfaceB {
    default void defaultMethod() {
        System.out.println("InterfaceB defaultMethod");
    }
}

public class ConflictingClass implements InterfaceA, InterfaceB {
    @Override
    public void defaultMethod() {
        InterfaceA.super.defaultMethod();
    }

    public static void main(String[] args) {
        ConflictingClass obj = new ConflictingClass();
        obj.defaultMethod();
    }
}
```

### Optional Class

#### Exercise 1: Handling Null Values with Optional

Solution:
```java
import java.util.Optional;

public class OptionalExample {
    public static void main(String[] args) {
        String possiblyNull = null;
        String result = Optional.ofNullable(possiblyNull)
                                .orElse("Default String");
        System.out.println(result);
    }
}
```

#### Exercise 2: Filtering Values with Optional

Solution:
```java
import java.util.Optional;

public class OptionalFilter {
    public static void main(String[] args) {
        Integer number = 5;
        Optional<Integer> evenNumber = Optional.ofNullable(number)
                                              .filter(n -> n % 2 == 0);
        evenNumber.ifPresentOrElse(
            n -> System.out.println("Even number: " + n),
            () -> System.out.println("No even number present")
        );
    }
}
```

#### Exercise 3: Using Optional with Map and FlatMap

Solution:
```java
import java.util.Optional;

public class OptionalMapFlatMap {
    public static void main(String[] args) {
        Optional<String> optionalString = Optional.of("Hello World");

        // Using map to get the length of the string
        Optional<Integer> length = optionalString.map(String::length);
        length.ifPresent(l -> System.out.println("Length: " + l));

        // Using flatMap to create an Optional description
        Optional<String> description = optionalString
                .flatMap(s -> Optional.of("Length is " + s.length()));
        description.ifPresent(System.out::println);
    }
}
```

### New Date and Time API (java.time)

#### Exercise 1: Formatting and Parsing Dates

Solution:
```java
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

public class DateFormatParse {
    public static void main(String[] args) {
        // Formatting current date
        LocalDate today = LocalDate.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd-MM-yyyy");
        String formattedDate = today.format(formatter);
        System.out.println("Formatted Date: " + formattedDate);
        
        // Parsing a string to LocalDate
        String dateString = "25-12-2025";
        LocalDate parsedDate = LocalDate.parse(dateString, formatter);
        System.out.println("Parsed Date: " + parsedDate);
    }
}
```

#### Exercise 2: Calculating the Difference Between Two Dates

Solution:
```java
import java.time.LocalDate;
import java.time.Period;

public class DateDifference {
    public static void main(String[] args) {
        LocalDate startDate = LocalDate.of(2025, 1, 1);
        LocalDate endDate = LocalDate.of(2025, 12, 31);
        
        Period period = Period.between(startDate, endDate);
        int days = period.getDays() + period.getMonths() * 30 + period.getYears() * 365;
        System.out.println("Difference in days: " + days);
    }
}
```

#### Exercise 3: Working with ZonedDateTime

Solution:
```java
import java.time.ZonedDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

public class ZonedDateTimeExample {
    public static void main(String[] args) {
        ZonedDateTime parisTime = ZonedDateTime.now(ZoneId.of("Europe/Paris"));
        DateTimeFormatter formatter = DateTimeFormatter
                .ofPattern("yyyy-MM-dd HH:mm:ss z");
        
        System.out.println("Paris Time: " + parisTime.format(formatter));
        
        ZonedDateTime newYorkTime = parisTime
                .withZoneSameInstant(ZoneId.of("America/New_York"));
        System.out.println("New York Time: " + newYorkTime.format(formatter));
    }
}
```

### Local-Variable Syntax for Lambda Parameters

#### Exercise 1: Using `var` in Lambda Parameters Without Type Annotations

Solution:
```java
import java.util.Arrays;
import java.util.List;

public class VarLambdaExample {
    public static void main(String[] args) {
        List<Integer> numbers = Arrays.asList(1, 2, 3, 4, 5);
        numbers.forEach((var number) -> System.out.println(number * 2));
    }
}
```

#### Exercise 2: Using `var` with Type Annotations in Lambda Parameters

Solution:
```java
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

public class VarWithAnnotations {
    public static void main(String[] args) {
        List<String> words = Arrays.asList("Java", "is", "fun", "to", "learn");
        List<String> filtered = words.stream()
                                     .filter((var s) -> s.length() > 3)
                                     .collect(Collectors.toList());
        System.out.println(filtered);
    }
}
```

#### Exercise 3: Using `var` with Multiple Lambda Parameters

Solution:
```java
@FunctionalInterface
interface BiStringConcatenator {
    String concatenate(var String a, var String b);
}

public class MultipleVarLambda {
    public static void main(String[] args) {
        BiStringConcatenator concat = (var a, var b) -> a + " " + b;
        String result = concat.concatenate("Hello", "World");
        System.out.println(result);
    }
}
```

### Enhanced String API

#### Exercise 1: Using `isBlank()` to Validate Input Strings

Solution:
```java
public class IsBlankExample {
    public static void main(String[] args) {
        String input1 = "   ";
        String input2 = "Hello, World!";

        if (input1.isBlank()) {
            System.out.println("Input1 is blank.");
        } else {
            System.out.println("Input1 is not blank.");
        }

        if (input2.isBlank()) {
            System.out.println("Input2 is blank.");
        } else {
            System.out.println("Input2 is not blank.");
        }
    }
}
```

#### Exercise 2: Splitting a String into Lines Using `lines()`

Solution:
```java
public class LinesExample {
    public static void main(String[] args) {
        String multiLine = "First line\nSecond line\r\nThird line\rFourth line";

        multiLine.lines().forEach(line -> System.out.println("Line: " + line));
    }
}
```

#### Exercise 3: Repeating a String Using `repeat()`

Solution:
```java
public class RepeatExample {
    public static void main(String[] args) {
        String word = "Echo";
        String repeated = String.join(" ", word.repeat(5).split("(?<=\\G.{4})"));
        System.out.println(repeated);
    }
}
```

### Sealed Classes and Interfaces

#### Exercise 1: Creating a Sealed Class Hierarchy

Solution:
```java
public sealed class Shape permits Circle, Rectangle {
    // Common properties or methods
}

public final class Circle extends Shape {
    double radius;

    public Circle(double radius) {
        this.radius = radius;
    }

    @Override
    public String toString() {
        return "Circle with radius " + radius;
    }
}

public final class Rectangle extends Shape {
    double length, width;

    public Rectangle(double length, double width) {
        this.length = length;
        this.width = width;
    }

    @Override
    public String toString() {
        return "Rectangle with length " + length + " and width " + width;
    }
}

public class SealedClassExample {
    public static void main(String[] args) {
        Shape circle = new Circle(5.0);
        Shape rectangle = new Rectangle(4.0, 6.0);
        System.out.println(circle);
        System.out.println(rectangle);
    }
}
```

#### Exercise 2: Implementing Sealed Interfaces

Solution:
```java
public sealed interface Animal permits Dog, Cat {
    void makeSound();
}

public final class Dog implements Animal {
    @Override
    public void makeSound() {
        System.out.println("Woof!");
    }
}

public final class Cat implements Animal {
    @Override
    public void makeSound() {
        System.out.println("Meow!");
    }
}

public class SealedInterfaceExample {
    public static void main(String[] args) {
        Animal dog = new Dog();
        Animal cat = new Cat();
        dog.makeSound();
        cat.makeSound();
    }
}
```

#### Exercise 3: Extending Sealed Classes with Further Restrictions

Solution:
```java
public sealed class Shape permits Circle, Rectangle, Triangle {
    // Common properties or methods
}

public final class Circle extends Shape {
    double radius;

    public Circle(double radius) {
        this.radius = radius;
    }

    @Override
    public String toString() {
        return "Circle with radius " + radius;
    }
}

public final class Rectangle extends Shape {
    double length, width;

    public Rectangle(double length, double width) {
        this.length = length;
        this.width = width;
    }

    @Override
    public String toString() {
        return "Rectangle with length " + length + " and width " + width;
    }
}

public non-sealed class Triangle extends Shape {
    double base, height;

    public Triangle(double base, double height) {
        this.base = base;
        this.height = height;
    }

    @Override
    public String toString() {
        return "Triangle with base " + base + " and height " + height;
    }
}

public class SealedClassExtendedExample {
    public static void main(String[] args) {
        Shape triangle = new Triangle(3.0, 4.0);
        System.out.println(triangle);
    }
}
```

### Pattern Matching for instanceof

#### Exercise 1: Basic Pattern Matching with `instanceof`

Solution:
```java
public class InstanceofPatternMatching {
    public static void main(String[] args) {
        Object obj = "Hello, World!";
        
        if (obj instanceof String s) {
            System.out.println("String length: " + s.length());
        } else {
            System.out.println("Not a string.");
        }
    }
}
```

#### Exercise 2: Pattern Matching with Multiple Types

Solution:
```java
public class MultipleInstanceofPatterns {
    public static void main(String[] args) {
        Object num = 25.5;
        
        if (num instanceof Integer i) {
            System.out.println("Integer value doubled: " + (i * 2));
        } else if (num instanceof Double d) {
            System.out.println("Double value halved: " + (d / 2));
        } else {
            System.out.println("Unknown type.");
        }
    }
}
```

#### Exercise 3: Using Pattern Matching in Switch Expressions

Solution:
```java
public class SwitchPatternMatching {
    public static void main(String[] args) {
        Object obj = "Java Pattern Matching";
        
        String message = switch (obj) {
            case String s -> "It's a string with length " + s.length();
            case Integer i -> "It's an integer with value " + i;
            case Double d -> "It's a double with value " + d;
            default -> "Unknown type.";
        };
        
        System.out.println(message);
    }
}
```

### Text Blocks

#### Exercise 1: Creating a Multi-line JSON String with Text Blocks

Solution:
```java
public class JsonTextBlockExample {
    public static void main(String[] args) {
        String json = """
            {
                "name": "John Doe",
                "age": 30,
                "email": "john.doe@example.com"
            }
            """;
        System.out.println(json);
    }
}
```

#### Exercise 2: Embedding HTML Content Using Text Blocks

Solution:
```java
public class HtmlTextBlockExample {
    public static void main(String[] args) {
        String html = """
            <!DOCTYPE html>
            <html>
                <head>
                    <title>Sample Page</title>
                </head>
                <body>
                    <h1>Welcome to the Sample Page</h1>
                </body>
            </html>
            """;
        System.out.println(html);
    }
}
```

#### Exercise 3: Using Text Blocks with Escape Characters

Solution:
```java
public class EscapeCharactersTextBlock {
    public static void main(String[] args) {
        String filePath = """
            {
                "filePath": "C:\\Users\\JohnDoe\\Documents\\file.txt"
            }
            """;
        System.out.println(filePath);
    }
}
```

### Records

#### Exercise 1: Defining a Simple Record and Accessing Its Fields

Solution:
```java
public record Person(String name, int age) {}

public class RecordExample {
    public static void main(String[] args) {
        Person person = new Person("Alice", 30);
        System.out.println("Name: " + person.name());
        System.out.println("Age: " + person.age());
    }
}
```

#### Exercise 2: Using Records with Collections and Streams

Solution:
```java
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

public record Book(String title, String author) {}

public class BookCollectionExample {
    public static void main(String[] args) {
        List<Book> books = Arrays.asList(
            new Book("1984", "George Orwell"),
            new Book("Animal Farm", "George Orwell"),
            new Book("Brave New World", "Aldous Huxley")
        );

        String targetAuthor = "George Orwell";
        List<String> titlesByAuthor = books.stream()
                         .filter(book -> book.author().equals(targetAuthor))
                         .map(Book::title)
                         .collect(Collectors.toList());

        System.out.println("Books by " + targetAuthor + ": " + titlesByAuthor);
    }
}
```

#### Exercise 3: Adding Methods to Records and Implementing Interfaces

Solution:
```java
interface Shape {
    double perimeter();
}

public record Rectangle(double length, double width) implements Shape {
    public double area() {
        return length * width;
    }

    @Override
    public double perimeter() {
        return 2 * (length + width);
    }
}

public class RecordWithMethodsExample {
    public static void main(String[] args) {
        Rectangle rect = new Rectangle(5.0, 3.0);
        System.out.println("Area: " + rect.area());
        System.out.println("Perimeter: " + rect.perimeter());
    }
}
```

### Enhanced switch Statements

#### Exercise 1: Using Switch Expressions to Determine Day Type

Solution:
```java
public class DayTypeExample {
    public static void main(String[] args) {
        String day = "SUNDAY";
        
        String type = switch (day.toUpperCase()) {
            case "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY" -> "Weekday";
            case "SATURDAY", "SUNDAY" -> "Weekend";
            default -> "Invalid day";
        };
        
        System.out.println(day + " is a " + type);
    }
}
```

#### Exercise 2: Using Switch Statement with Yield to Return Values

Solution:
```java
public class SeasonValueExample {
    public static void main(String[] args) {
        String season = "SPRING";
        
        int value = switch (season.toLowerCase()) {
            case "spring" -> 1;
            case "summer" -> 2;
            case "autumn", "fall" -> 3;
            case "winter" -> 4;
            default -> {
                System.out.println("Unknown season");
                yield -1;
            }
        };
        
        System.out.println("Season value: " + value);
    }
}
```

#### Exercise 3: Using Pattern Matching with Switch for Type Checking

Solution:
```java
public class PatternMatchingSwitchExample {
    public static void main(String[] args) {
        Object obj = 15;
        
        String result = switch (obj) {
            case String s -> "String of length " + s.length();
            case Integer i -> "Integer squared: " + (i * i);
            case Double d -> "Double halved: " + (d / 2);
            default -> "Unknown type";
        };
        
        System.out.println(result);
    }
}
```

### Record Patterns

#### Exercise 1: Destructuring a Record with `instanceof` Pattern Matching

Solution:
```java
public record Person(String name, int age) {}

public class RecordPatternExample {
    public static void main(String[] args) {
        Object obj = new Person("Alice", 30);
        
        if (obj instanceof Person(String name, int age)) {
            System.out.println("Name: " + name + ", Age: " + age);
        } else {
            System.out.println("Not a Person instance.");
        }
    }
}
```

#### Exercise 2: Using Record Patterns in a Switch Statement

Solution:
```java
public sealed interface Shape permits Circle, Rectangle, Triangle {}

public record Circle(double radius) implements Shape {}
public record Rectangle(double length, double width) implements Shape {}
public record Triangle(double base, double height) implements Shape {}

public class ShapeAreaCalculator {
    public static void main(String[] args) {
        Shape shape = new Rectangle(5.0, 3.0);
        
        double area = switch (shape) {
            case Circle(double radius) -> Math.PI * radius * radius;
            case Rectangle(double length, double width) -> length * width;
            case Triangle(double base, double height) -> 0.5 * base * height;
        };
        
        System.out.println("Area: " + area);
    }
}
```

#### Exercise 3: Nested Record Patterns for Complex Data Structures

Solution:
```java
public record Employee(String name, int id) {}
public record Company(String companyName, Employee employee) {}

public class NestedRecordPatternExample {
    public static void main(String[] args) {
        Company company = new Company("TechCorp", new Employee("Bob", 101));
        
        if (company instanceof Company("TechCorp", Employee(String name, int id))) {
            System.out.println("Employee Name: " + name + ", ID: " + id);
        } else {
            System.out.println("Company not recognized or employee details unavailable.");
        }
    }
}
```

### Virtual Threads

#### Exercise 1: Creating and Running a Virtual Thread

Solution:
```java
public class VirtualThreadExample {
    public static void main(String[] args) {
        Thread vt = Thread.startVirtualThread(() -> {
            System.out.println("Hello from Virtual Thread!");
        });
        vt.join();
    }
}
```

#### Exercise 2: Executing Multiple Virtual Threads Using an Executor

Solution:
```java
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class VirtualThreadExecutorExample {
    public static void main(String[] args) throws InterruptedException {
        ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor();

        for (int i = 1; i <= 5; i++) {
            final int taskNumber = i;
            executor.submit(() -> {
                System.out.println("Executing Task " + taskNumber + " on " 
                        + Thread.currentThread());
            });
        }

        executor.shutdown();
        executor.awaitTermination(1, java.util.concurrent.TimeUnit.MINUTES);
    }
}
```

#### Exercise 3: Handling Blocking I/O with Virtual Threads

Solution:
```java
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

public class VirtualThreadFileRead {
    public static void main(String[] args) {
        Thread vt = Thread.startVirtualThread(() -> {
            try (BufferedReader reader = new BufferedReader(new FileReader("file.txt"))) {
                String firstLine = reader.readLine();
                System.out.println("First line: " + firstLine);
            } catch (IOException e) {
                e.printStackTrace();
            }
        });
        try {
            vt.join();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```

### Sequenced Collections

#### Exercise 1: Creating and Manipulating a Sequenced Collection

Solution:
```java
import java.util.LinkedList;
import java.util.SequencedCollection;

public class SequencedCollectionExample {
    public static void main(String[] args) {
        SequencedCollection<Integer> numbers = new LinkedList<>();

        // Adding elements to the end
        numbers.addLast(10);
        numbers.addLast(20);
        numbers.addLast(30);

        // Adding elements to the beginning
        numbers.addFirst(5);
        numbers.addFirst(2);

        System.out.println("Sequenced Collection: " + numbers);
    }
}
```

#### Exercise 2: Iterating from Both Ends of a Sequenced Collection

Solution:
```java
import java.util.Iterator;
import java.util.LinkedList;
import java.util.SequencedCollection;

public class DualIteratorExample {
    public static void main(String[] args) {
        SequencedCollection<String> names = new LinkedList<>();
        names.addLast("Alice");
        names.addLast("Bob");
        names.addLast("Charlie");
        names.addLast("Diana");

        System.out.println("Forward Iteration:");
        Iterator<String> forward = names.iterator();
        while (forward.hasNext()) {
            System.out.println(forward.next());
        }

        System.out.println("\nReverse Iteration:");
        Iterator<String> reverse = ((LinkedList<String>) names).descendingIterator();
        while (reverse.hasNext()) {
            System.out.println(reverse.next());
        }
    }
}
```

#### Exercise 3: Merging Two Sequenced Collections While Preserving Order

Solution:
```java
import java.util.LinkedList;
import java.util.SequencedCollection;

public class MergeSequencedCollections {
    public static void main(String[] args) {
        SequencedCollection<Integer> list1 = new LinkedList<>();
        list1.addLast(1);
        list1.addLast(2);
        list1.addLast(3);

        SequencedCollection<Integer> list2 = new LinkedList<>();
        list2.addLast(4);
        list2.addLast(5);
        list2.addLast(6);

        // Merging list2 into list1
        list1.addAll(list2);

        System.out.println("Merged Sequenced Collection: " + list1);
    }
}
```

### Modules

#### Exercise 1: Creating a Simple Module

Solution:
```java
// File: com/example/greeter/module-info.java
module com.example.greeter {
    exports com.example.greeter;
}

// File: com/example/greeter/Greeter.java
package com.example.greeter;

public class Greeter {
    public void greet() {
        System.out.println("Hello, Module!");
    }
}

// File: com/example/app/module-info.java
module com.example.app {
    requires com.example.greeter;
}

// File: com/example/app/App.java
package com.example.app;

import com.example.greeter.Greeter;

public class App {
    public static void main(String[] args) {
        Greeter greeter = new Greeter();
        greeter.greet();
    }
}
```

#### Exercise 2: Using `requires transitive` in Modules

Solution:
```java
// File: com/example/utils/module-info.java
module com.example.utils {
    exports com.example.utils;
}

// File: com/example/utils/Utils.java
package com.example.utils;

public class Utils {
    public static void printMessage(String message) {
        System.out.println(message);
    }
}

// File: com/example/app/module-info.java
module com.example.app {
    requires transitive com.example.utils;
}

// File: com/example/app/App.java
package com.example.app;

import com.example.utils.Utils;

public class App {
    public static void main(String[] args) {
        Utils.printMessage("Using transitive requires in modules!");
    }
}
```

#### Exercise 3: Providing and Consuming Services with Modules

Solution:
```java
// File: com/example/api/GreetingService.java
package com.example.api;

public interface GreetingService {
    void greet();
}

// File: com/example/service/module-info.java
module com.example.service {
    requires com.example.api;
    provides com.example.api.GreetingService with com.example.service.GreetingServiceImpl;
}

// File: com/example/service/GreetingServiceImpl.java
package com.example.service;

import com.example.api.GreetingService;

public class GreetingServiceImpl implements GreetingService {
    @Override
    public void greet() {
        System.out.println("Hello from GreetingServiceImpl!");
    }
}

// File: com/example/client/module-info.java
module com.example.client {
    requires com.example.api;
    uses com.example.api.GreetingService;
}

// File: com/example/client/App.java
package com.example.client;

import com.example.api.GreetingService;
import java.util.ServiceLoader;

public class App {
    public static void main(String[] args) {
        ServiceLoader<GreetingService> loader = ServiceLoader.load(GreetingService.class);
        for (GreetingService service : loader) {
            service.greet();
        }
    }
}
```

## Additional examples

```java
public final class OptionExample {

    public sealed interface Option<T> 
        permits OptionExample.Some, OptionExample.None {

        boolean isEmpty();

        T get();

        default T getOrElse(T other) {
            return isEmpty() ? other : get();
        }

        default <R> Option<R> map(Function<? super T, ? extends R> mapper) {
            return isEmpty() ? none() : some(mapper.apply(get()));
        }

        static <T> Option<T> some(T value) {
            return new Some<>(value);
        }

        static <T> Option<T> none() {
            return new None<>();
        }
    }
    
    public static record Some<T>(T value) implements Option<T> {

        @Override
        public boolean isEmpty() {
            return false;
        }

        @Override
        public T get() {
            return value;
        }
    }

    public static final class None<T> implements Option<T> {

        @Override
        public boolean isEmpty() {
            return true;
        }

        @Override
        public T get() {
            throw new java.util.NoSuchElementException("No value present in None");
        }
    }

    public static void main(String[] args) {
        Option<String> maybeName = Option.some("Alice");
        System.out.println("maybeName isEmpty? " + maybeName.isEmpty()); 
        System.out.println("maybeName get: " + maybeName.get());

        Option<String> noName = Option.none();
        System.out.println("noName isEmpty? " + noName.isEmpty());
        System.out.println("noName getOrElse(\"Unknown\"): "
                + noName.getOrElse("Unknown"));

        // Using map:
        Option<Integer> maybeLength = maybeName.map(String::length);
        System.out.println("maybeLength getOrElse(0): " + maybeLength.getOrElse(0));

        Option<Integer> noneLength = noName.map(String::length);
        System.out.println("noneLength isEmpty? " + noneLength.isEmpty());
    }
}
```

```java
public final class ResultExample {

    public sealed interface Result<L, R> permits Ok, Err {
        boolean isOk();
        default boolean isErr() {
            return !isOk();
        }
        R unwrap();
        L unwrapErr();
        default <U> Result<L, U> map(Function<? super R, ? extends U> mapper) {
            if (isOk()) {
                return Result.ok(mapper.apply(unwrap()));
            } else {
                return Result.err(unwrapErr());
            }
        }
        default <M> Result<M, R> mapErr(Function<? super L, ? extends M> mapper) {
            if (isErr()) {
                return Result.err(mapper.apply(unwrapErr()));
            } else {
                return Result.ok(unwrap());
            }
        }
        default <U> Result<L, U> flatMap(Function<? super R, Result<L, U>> mapper) {
            if (isOk()) {
                return mapper.apply(unwrap());
            } else {
                return Result.err(unwrapErr());
            }
        }
        default Result<L, R> orElse(Result<L, R> other) {
            return isOk() ? this : other;
        }
        static <L, R> Result<L, R> ok(R value) {
            return new Ok<>(value);
        }
        static <L, R> Result<L, R> err(L error) {
            return new Err<>(error);
        }
    }

    public static final class Ok<L, R> implements Result<L, R> {
        private final R value;
        public Ok(R value) {
            this.value = value;
        }
        @Override
        public boolean isOk() {
            return true;
        }
        @Override
        public R unwrap() {
            return value;
        }
        @Override
        public L unwrapErr() {
            throw new IllegalStateException("Called unwrapErr() on an Ok value");
        }
        @Override
        public String toString() {
            return "Ok(" + value + ")";
        }
    }

    public static final class Err<L, R> implements Result<L, R> {
        private final L error;
        public Err(L error) {
            this.error = error;
        }
        @Override
        public boolean isOk() {
            return false;
        }
        @Override
        public R unwrap() {
            throw new IllegalStateException("Called unwrap() on an Err value");
        }
        @Override
        public L unwrapErr() {
            return error;
        }
        @Override
        public String toString() {
            return "Err(" + error + ")";
        }
    }

    public static void main(String[] args) {
        Result<String, Integer> success = divide(10, 2);
        handleResult(success);

        Result<String, Integer> failure = divide(10, 0);
        handleResult(failure);

        Result<String, Integer> computation = divide(20, 4)
                .map(result -> result * 2)
                .flatMap(res -> divide(res, 2));
        System.out.println("Chained computation: " + computation);

        Result<String, Integer> handledError = divide(10, 0)
                .mapErr(err -> "Cannot divide by zero");
        System.out.println("Handled error: " + handledError);

        Result<String, Integer> defaultResult = failure.orElse(divide(100, 5));
        System.out.println("Default result (failure.orElse(divide(100, 5))): "
                + defaultResult);
    }

    public static Result<String, Integer> divide(int numerator, int denominator) {
        if (denominator == 0) {
            return Result.err("Division by zero");
        } else {
            return Result.ok(numerator / denominator);
        }
    }

    public static <L, R> void handleResult(Result<L, R> result) {
        if (result.isOk()) {
            System.out.println("Success! Result is: " + result.unwrap());
        } else {
            System.out.println("Error: " + result.unwrapErr());
        }
    }
}
```

# Migration tools

## Java Dependency Analysis Tool

`jeps` is a powerful utility bundled with the JDK that helps analyze Java class files to determine dependencies on packages, modules, and classes. It's especially useful during migration to identify dependencies that might be problematic when upgrading Java versions, such as reliance on internal APIs or deprecated packages.

### Basic Usage

### Analyzing a Single JAR File

To analyze the dependencies of a single JAR file, use the following command:

```bash
jdeps path/to/your-app.jar
```

Example:

Suppose you have a JAR file named `myapp.jar` located in the `target` directory.

```bash
jdeps target/myapp.jar
```

Sample Output:
```
myapp.jar -> java.base
myapp.jar -> java.logging
myapp.jar -> com.fasterxml.jackson.databind
```

Explanation:
- `myapp.jar -> java.base`: Indicates that `myapp.jar` depends on the `java.base` module.
- `myapp.jar -> java.logging`: Shows a dependency on the `java.logging` module.
- `myapp.jar -> com.fasterxml.jackson.databind`: Indicates a dependency on an external library.

### Analyzing Individual Class Files

You can also analyze individual class files:

```bash
jdeps path/to/MyClass.class
```

### Analyzing Module Dependencies

If your project uses Java modules (introduced in Java 9), you can analyze module dependencies.

### Basic Module Dependency Analysis

```bash
jdeps --module-path path/to/modules -s path/to/your-app.jar
```

Options:
- `--module-path`: Specifies the module path for resolving dependencies.
- `-s` or `--summary`: Provides a summary of module dependencies.

Example:

```bash
jdeps --module-path libs/ -s target/myapp.jar
```

Sample Output:
```
myapp.jar -> java.base
myapp.jar -> java.logging
myapp.jar -> com.fasterxml.jackson.databind
```

### Detailed Module Dependency Tree

To get a detailed tree of module dependencies:

```bash
jdeps --module-path libs/ --print-module-deps -s target/myapp.jar
```

Options:
- `--print-module-deps`: Prints the module dependencies in a format suitable for the `--add-modules` option.

Sample Output:
```
java.base,java.logging,com.fasterxml.jackson.databind
```

### Detecting Dependencies on Internal APIs

One of the critical uses of `jdeps` is to identify if your application relies on internal or unsupported APIs, which can cause issues during migration.

### Scanning for JDK Internal APIs

Use the `--jdk-internals` flag to identify dependencies on JDK internal APIs.

```bash
jdeps --jdk-internals target/myapp.jar
```

Sample Output:
```
myapp.jar -> jdk.internal.reflect
```

Explanation:
- `jdk.internal.reflect`: Indicates that `myapp.jar` is using internal reflection APIs, which are not intended for public use and may be removed or restricted in future Java versions.

### Using the `--ignore-missing-deps` Flag

If some dependencies are missing or not resolvable, you can use `--ignore-missing-deps` to suppress related warnings.

```bash
jdeps --jdk-internals --ignore-missing-deps target/myapp.jar
```

### Generating Dependency Reports

For better visualization and reporting, you can generate output in various formats.

### Generating a Graphviz DOT File

You can generate a DOT file compatible with Graphviz to visualize dependencies.

```bash
jdeps -dotoutput out/ target/myapp.jar
```

Options:
- `-dotoutput`: Specifies the directory where DOT files will be generated.

Steps to Visualize:

1. Generate DOT Files:

   ```bash
   jdeps -dotoutput out/ target/myapp.jar
   ```

2. Install Graphviz (if not already installed):

  - macOS:
    ```bash
    brew install graphviz
    ```
  - Ubuntu/Debian:
    ```bash
    sudo apt-get install graphviz
    ```
  - Windows:
    - Download from [Graphviz Downloads](https://graphviz.org/download/) and install.

3. Generate a PNG Image from DOT File:

   ```bash
   dot -Tpng out/myapp.jar.dot -o myapp-dependencies.png
   ```

4. View the Image:

   Open `myapp-dependencies.png` using your preferred image viewer.

### Exporting to JSON Format

While `jdeps` does not natively support JSON output, you can combine it with other tools or scripts to parse and convert the output into JSON for integration with other systems.

Example Using `jdeps` with `jq`:

```bash
jdeps target/myapp.jar | jq -R -s 'split("\n") 
  | map(select(length > 0)) | map(split(" -> ")) 
  | map({module: .[0], dependencies: .[1:]})' > dependencies.json
```

Explanation:
- `-R -s`: Reads input as raw strings and slurps all lines into a single array.
- `split("\n")`: Splits the input into lines.
- `map(select(length > 0))`: Filters out empty lines.
- `map(split(" -> "))`: Splits each line into source and dependencies.
- `map({module: .[0], dependencies: .[1:]})`: Structures the data into JSON objects.

### Using `jdeps` with Maven Projects

Integrating `jdeps` into Maven projects can automate dependency analysis as part of your build process.

### Step 1: Ensure Your Project is Compiled

First, compile your Maven project to generate the JAR file.

```bash
mvn clean package
```

Assumption: The resulting JAR is located at `target/myapp.jar`.

### Step 2: Run `jdeps` on the Generated JAR

```bash
jdeps target/myapp.jar
```

### Step 3: Integrate `jdeps` into Maven's Build Lifecycle (Optional)

You can create a Maven plugin execution to run `jdeps` automatically during the build.

Example:

Add the following plugin configuration to your `pom.xml`:

```xml
<build>
    <plugins>
        <!-- Other plugins -->

        <plugin>
            <groupId>org.codehaus.mojo</groupId>
            <artifactId>exec-maven-plugin</artifactId>
            <version>3.0.0</version>
            <executions>
                <execution>
                    <id>analyze-dependencies</id>
                    <phase>verify</phase>
                    <goals>
                        <goal>exec</goal>
                    </goals>
                    <configuration>
                        <executable>jdeps</executable>
                        <arguments>
                            <argument>-s</argument>
                            <argument>${project.build.directory}/
                              ${project.build.finalName}.jar</argument>
                        </arguments>
                    </configuration>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

Run the Maven Build:

```bash
mvn clean verify
```

Outcome:
- `jdeps` will execute during the `verify` phase, and its output will be visible in the build logs.

### Using `jdeps` with Gradle Projects

Similarly, you can integrate `jdeps` into Gradle projects.

### Step 1: Ensure Your Project is Compiled

First, build your Gradle project to generate the JAR file.

```bash
gradle clean build
```

Assumption: The resulting JAR is located at `build/libs/myapp.jar`.

### Step 2: Run `jdeps` on the Generated JAR

```bash
jdeps build/libs/myapp.jar
```

### Step 3: Integrate `jdeps` into Gradle's Build Lifecycle (Optional)

You can create a custom Gradle task to run `jdeps` automatically.

Example:

Add the following task to your `build.gradle`:

```groovy
task analyzeDependencies(type: Exec) {
    description = 'Analyzes dependencies using jdeps'
    group = 'Verification'

    def jarFile = "${buildDir}/libs/${project.name}.jar"

    commandLine 'jdeps', '-s', jarFile

    // Ensure the JAR is built before running `jdeps`
    dependsOn build
}

check.dependsOn analyzeDependencies
```

Explanation:
- `type: Exec`: Defines the task as an execution of a system command.
- `commandLine 'jdeps', '-s', jarFile`: Specifies the `jdeps` command with the `-s` option for summary.
- `dependsOn build`: Ensures the JAR is built before running `jdeps`.
- `check.dependsOn analyzeDependencies`: Integrates the task into the `check` lifecycle phase.

Run the Gradle Build:

```bash
gradle clean check
```

Outcome:
- `jdeps` will execute during the `check` phase, and its output will appear in the build logs.

### Interpreting `jdeps` Output

Understanding the output of `jdeps` is crucial for identifying and addressing dependency issues.

### Basic Output Structure

```plaintext
myapp.jar -> java.base
myapp.jar -> java.logging
myapp.jar -> com.fasterxml.jackson.databind
```

- `myapp.jar`: The analyzed module or JAR.
- `->`: Indicates a dependency arrow.
- `java.base`, `java.logging`: Java modules your application depends on.
- `com.fasterxml.jackson.databind`: External libraries or modules.

### Common Indicators in Output

1. Standard Java Modules:
  - Dependencies on modules like `java.base`, `java.sql`, `java.xml`, etc., are standard and typically not problematic.

2. Internal or Unsupported APIs:
  - Dependencies starting with `jdk.internal` or other internal namespaces indicate reliance on unsupported APIs, which can lead to issues in future Java versions.

   Example:
   ```
   myapp.jar -> jdk.internal.reflect
   ```

3. External Libraries:
  - Dependencies on third-party libraries, such as `com.fasterxml.jackson.databind`, indicate external dependencies that should be verified for Java 21 compatibility.

### Advanced Output with Packages

Using the `-verbose` (`-v`) flag provides more detailed information, including package-level dependencies.

```bash
jdeps -v target/myapp.jar
```

Sample Output:
```
myapp.jar -> java.base
    java.base/java.lang
    java.base/java.util
myapp.jar -> java.logging
    java.logging/java.util.logging
myapp.jar -> com.fasterxml.jackson.databind
    com.fasterxml.jackson.databind/com.fasterxml.jackson.databind.ObjectMapper
```

Explanation:
- Shows which specific packages within each module or library are being used.

### Common Use Cases

### Use Case 1: Identifying External Dependencies

To list all external dependencies (excluding JDK modules):

```bash
jdeps -s target/myapp.jar | grep -v "java\."
```

Sample Output:
```
myapp.jar -> com.fasterxml.jackson.databind
myapp.jar -> org.apache.commons
```

### Use Case 2: Checking for Deprecated APIs

Although `jdeps` doesn't directly report deprecated APIs, you can combine it with other tools like `jdeprscan` to identify deprecated API usage.

```bash
jdeps target/myapp.jar
jdeprscan --release 21 target/myapp.jar
```

### Use Case 3: Ensuring Modularization

If you're adopting the Java Module System, ensure that your modules correctly declare dependencies.

Command:

```bash
jdeps --module-path mods/ --add-modules your.module.name -s target/myapp.jar
```

### Use Case 4: Detecting Potential Migration Issues

Use `jdeps` to scan for dependencies that might cause issues when migrating to Java 21, such as internal APIs or outdated libraries.

### Tips and Best Practices

1. Integrate Early in Migration Process: Run `jdeps` at the beginning to identify potential issues before deep diving into code changes.
2. Automate Dependency Checks: Incorporate `jdeps` into your CI/CD pipelines to continuously monitor dependencies.
3. Combine with Other Tools: Use `jdeps` alongside tools like `jdeprscan`, `OpenRewrite`, and static analysis tools for comprehensive migration support.
4. Regularly Update Dependencies: Keep third-party libraries updated to versions compatible with Java 21 to minimize migration hurdles.
5. Review and Refactor Code: Use `jdeps` insights to refactor code that relies on internal or deprecated APIs.
6. Document Findings: Maintain records of dependency issues and resolutions to aid future maintenance and migrations.

## OpenRewrite

OpenRewrite is an automated refactoring tool that simplifies the process of migrating codebases by applying standardized transformations. It supports various programming languages and integrates seamlessly with popular build tools like Maven and Gradle. By leveraging a rich set of predefined recipes, developers can automate repetitive and error-prone tasks, ensuring consistency and efficiency during migrations.

Key Use Cases:
- Upgrading Java versions (e.g., Java 8 to Java 21)
- Refactoring code to adhere to new coding standards or best practices
- Migrating between different frameworks or libraries
- Removing deprecated APIs and replacing them with modern alternatives

Key Features

- Predefined Recipes: A vast collection of community-maintained recipes for common refactoring tasks.
- Custom Recipes: Ability to define custom transformations tailored to specific project needs.
- Integration with Build Tools: Plugins available for Maven and Gradle to incorporate OpenRewrite into existing build pipelines.
- Scalability: Efficiently handles large codebases with minimal performance overhead.
- Extensibility: Supports extension through custom Java code, allowing for complex refactorings.

### Installation and Setup

### a. Installing OpenRewrite CLI (Optional)

While OpenRewrite primarily integrates with build tools, you can also use the OpenRewrite CLI for standalone operations.

1. Download OpenRewrite CLI:

   Visit the [OpenRewrite Releases](https://github.com/openrewrite/rewrite/releases) page and download the latest CLI JAR file.

2. Run OpenRewrite CLI:

   ```bash
   java -jar rewrite-cli-X.Y.Z.jar --help
   ```

   Replace `X.Y.Z` with the actual version number.

### b. Adding OpenRewrite to Your Project

#### For Maven Projects:

1. Add OpenRewrite Plugin to `pom.xml`:

   ```xml
   <project>
       <!-- ... existing configurations ... -->
       <build>
           <plugins>
               <!-- ... other plugins ... -->
               <plugin>
                   <groupId>org.openrewrite.maven</groupId>
                   <artifactId>rewrite-maven-plugin</artifactId>
                   <version>4.35.0</version>
                   <configuration>
                       <activeRecipes>
                           <!-- Specify recipes here -->
                       </activeRecipes>
                   </configuration>
               </plugin>
           </plugins>
       </build>
       <repositories>
           <repository>
               <id>openrewrite-maven</id>
               <url>https://repo.maven.apache.org/maven2</url>
           </repository>
       </repositories>
       <dependencies>
           <!-- Include any additional dependencies if needed -->
       </dependencies>
   </project>
   ```

2. Specify Recipes:

   Define the recipes you want to apply within the `<activeRecipes>` section. For example:

   ```xml
   <activeRecipes>
       <recipe>org.openrewrite.java.cleanup.FinalizeLocalVariables</recipe>
       <recipe>org.openrewrite.java.format.AutoFormat</recipe>
       <!-- Add more recipes as needed -->
   </activeRecipes>
   ```

#### For Gradle Projects:

1. Apply OpenRewrite Plugin:

   Add the OpenRewrite Gradle plugin to your `build.gradle`:

   ```groovy
   plugins {
       id 'org.openrewrite.rewrite' version '4.35.0'
   }
   ```

2. Configure OpenRewrite:

   Define the recipes within the `rewrite` configuration block:

   ```groovy
   rewrite {
       activeRecipes = [
           'org.openrewrite.java.cleanup.FinalizeLocalVariables',
           'org.openrewrite.java.format.AutoFormat'
           // Add more recipes as needed
       ]
   }
   ```

3. Add Repositories:

   Ensure Maven Central or other necessary repositories are included:

   ```groovy
   repositories {
       mavenCentral()
   }
   ```

### Using OpenRewrite for Migration

Migrating from Java 8 to Java 21 involves several steps, including updating language features, replacing deprecated APIs, and ensuring compatibility with new frameworks or libraries. OpenRewrite simplifies this process by automating many of these transformations.

### a. Applying Predefined Recipes

OpenRewrite provides a variety of predefined recipes that can assist in migrating Java versions. Here's how to apply them:

#### Example: Migrating to a New Java Version

1. Identify Relevant Recipes:

   OpenRewrite includes recipes such as:
  - `org.openrewrite.java.migrate.java8.Java8Migration`
  - `org.openrewrite.java.migrate.java17.Java17Migration`
  - `org.openrewrite.java.migrate.java21.Java21Migration`

2. Configure Recipes in Maven:

   ```xml
   <activeRecipes>
       <recipe>org.openrewrite.java.migrate.java8.Java8Migration</recipe>
       <recipe>org.openrewrite.java.migrate.java17.Java17Migration</recipe>
       <recipe>org.openrewrite.java.migrate.java21.Java21Migration</recipe>
   </activeRecipes>
   ```

   Note: The exact recipe names may vary. Refer to the [OpenRewrite Recipes Catalog](https://github.com/openrewrite/rewrite#available-recipes) for accurate recipe identifiers.

3. Execute the Migration:

   Run the OpenRewrite plugin goal to apply the recipes.

   ```bash
   mvn rewrite:run
   ```

   For Gradle:

   ```bash
   gradle rewriteRun
   ```

4. Review Changes:

   After execution, OpenRewrite will have applied the specified transformations. Review the changes using your version control system to ensure correctness.

### b. Creating Custom Recipes

Sometimes, predefined recipes may not cover all the specific needs of your project. In such cases, you can create custom recipes.

#### Steps to Create a Custom Recipe:

1. Define the Recipe:

   Create a YAML file (e.g., `CustomMigrationRecipe.yml`) with the desired transformations.

   ```yaml
   type: specs.openrewrite.org/v1beta/recipe
   name: com.example.CustomMigrationRecipe
   displayName: Custom Migration Recipe
   description: Replaces specific deprecated methods with their modern alternatives.
   recipeList:
     - org.openrewrite.java.ChangeMethodName:
         methodPattern: 'com.example.oldpackage.OldClass oldMethod(..)'
         newMethodName: 'newMethod'
   ```

2. Add the Custom Recipe to Your Project:

   Place the YAML file in a designated directory within your project (e.g., `src/main/resources/org/openrewrite/recipes/`).

3. Reference the Custom Recipe in `pom.xml` or `build.gradle`:

   For Maven:

   ```xml
   <activeRecipes>
       <recipe>com.example.CustomMigrationRecipe</recipe>
   </activeRecipes>
   ```

   For Gradle:

   ```groovy
   rewrite {
       activeRecipes = [
           'com.example.CustomMigrationRecipe'
       ]
   }
   ```

4. Execute the Migration:

   ```bash
   mvn rewrite:run
   ```

   Or for Gradle:

   ```bash
   gradle rewriteRun
   ```

5. Verify Changes:

   Check the transformed code to ensure that the custom recipe has been applied correctly.

### Integrating OpenRewrite with Build Tools

Integrating OpenRewrite with your build tools like Maven and Gradle allows for seamless automation of the migration process within your existing development workflow.

### a. Maven Integration

#### Step-by-Step Guide:

1. Add OpenRewrite Plugin:

   Ensure the `rewrite-maven-plugin` is added to your `pom.xml` as shown earlier.

2. Configure Plugin Execution:

   You can configure when the plugin runs (e.g., during the `verify` phase).

   ```xml
   <plugin>
       <groupId>org.openrewrite.maven</groupId>
       <artifactId>rewrite-maven-plugin</artifactId>
       <version>4.35.0</version>
       <configuration>
           <activeRecipes>
               <recipe>org.openrewrite.java.migrate.java8.Java8Migration</recipe>
               <recipe>org.openrewrite.java.migrate.java17.Java17Migration</recipe>
               <recipe>org.openrewrite.java.migrate.java21.Java21Migration</recipe>
           </activeRecipes>
       </configuration>
       <executions>
           <execution>
               <goals>
                   <goal>run</goal>
               </goals>
               <phase>verify</phase>
           </execution>
       </executions>
   </plugin>
   ```

3. Run Maven Build:

   Execute the Maven build to apply the migration recipes.

   ```bash
   mvn clean verify
   ```

   Outcome:  
   The OpenRewrite plugin will execute during the `verify` phase, applying the specified recipes to your codebase.

### b. Gradle Integration

#### Step-by-Step Guide:

1. Apply OpenRewrite Plugin:

   Ensure the OpenRewrite plugin is applied in your `build.gradle` as shown earlier.

2. Configure Active Recipes:

   Define the recipes within the `rewrite` block.

   ```groovy
   rewrite {
       activeRecipes = [
           'org.openrewrite.java.migrate.java8.Java8Migration',
           'org.openrewrite.java.migrate.java17.Java17Migration',
           'org.openrewrite.java.migrate.java21.Java21Migration'
       ]
   }
   ```

3. Run Gradle Build:

   Execute the Gradle build to apply the migration recipes.

   ```bash
   gradle clean build
   ```

   Outcome:  
   The OpenRewrite plugin will process the code during the build, applying the defined recipes.

### Running OpenRewrite

After configuring OpenRewrite within your project, you can execute it to perform the migration.

### a. Running OpenRewrite with Maven

1. Execute the Plugin:

   ```bash
   mvn rewrite:run
   ```

2. Review Changes:

   OpenRewrite modifies the source code directly. Use your version control system to review and commit the changes.

   ```bash
   git status
   git diff
   git add .
   git commit -m "Migrate codebase from Java 8 to Java 21 using OpenRewrite"
   ```

### b. Running OpenRewrite with Gradle

1. Execute the Plugin:

   ```bash
   gradle rewriteRun
   ```

2. Review Changes:

   Similar to Maven, inspect the changes using Git or your preferred version control tool.

   ```bash
   git status
   git diff
   git add .
   git commit -m "Migrate codebase from Java 8 to Java 21 using OpenRewrite"
   ```

### c. Dry Run and Reporting

Before applying changes, you might want to perform a dry run to see what modifications will be made.

For Maven:

```bash
mvn rewrite:dryRun
```

For Gradle:

```bash
gradle rewriteDryRun
```

Outcome:  
A report will be generated detailing the proposed changes without altering the source code. This allows for a safe review before actual modifications.

### Best Practices

1. Backup Before Migration: Always ensure your code is backed up or under version control before applying automated refactorings.
2. Incremental Migration: Apply migration recipes in small, manageable batches to isolate and address issues effectively.
3. Customize Recipes: Tailor existing recipes or create custom ones to fit the specific needs of your project.
4. Combine with Other Tools: Use OpenRewrite in conjunction with other migration tools like `jdeps` and static analysis tools for comprehensive coverage.
5. Maintain Documentation: Document the migration steps, decisions, and any custom recipes for future reference and onboarding.
6. Test Thoroughly: After applying migrations, run all tests to ensure that the application behaves as expected.
7. Stay Updated: Keep OpenRewrite and its recipes up to date to leverage the latest improvements and fixes.
