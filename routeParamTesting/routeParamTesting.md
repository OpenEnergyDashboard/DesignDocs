# Systematic testing of parameters for routes

## Introduction

Many routes in OED accept parameters to know what should be done. In general, OED validates the values, which are JSON, using [jsonschema](https://www.npmjs.com/package/jsonschema). The validation is important for several reasons:

- It makes sure that OED requests are correct so it helps find coding errors.
- It can stop incorrect requests to the routes outside the OED software due to mistakes or malicious attacks.

The current code does a reasonable job in testing values but it is not complete. In particular, it is not careful to avoid requests that are malicious attacks. Furthermore, there is no systematic testing to verify that the validation performs as desired. The goal is to address these limitations via systematic testing using our standard Chai/Mocha frameworks.

[issue 1497](https://github.com/OpenEnergyDashboard/OED/issues/1497) covers this work.

## Current status

A developer has worked (and might still be working) to create a route parameter testing methodology and used it to test the units route. This is a similar idea to the OED testing of getting graphic data from readings or systematic UI testing. The code may already be in as a pull request or merged when people do this work so please check with the project to find the best place to start.

This code will need review to determine how it should be expanded and applied to other routes.

## Details of changes needed

OED uses a number of types of parameters. Each one needs to be tested for valid and invalid values to make sure that they are handled correctly. Here are a number of types with the validation needed:

- array
  - type of values supplied
  - min length: mainly if needs to have any values
  - max length: mostly to avoid maliciously large arrays
  - uniqueness: duplicate values may not be allowed
- boolean
- enum (as a string)
  - That only the allowed enum values can be used
- integer
  - min value
  - max value
- number/float
  - similar to integer but floating point
  - OED needs to become systematic in which it uses based on what is best
- object
  - These are special values such as gps. In many circumstances the testing will be unique.
- string
  - min length: mostly to see if an empty string is allowed
  - max length: due to limits set by OED and to avoid maliciously large strings
  - some strings are only allowed to have certain patterns. Fro some string, such as dates, it needs to be determined if they can easily be tested by jsonschema, another method or if it needs to wait until a failure occurs in usage.

A few notes:

- Not all parameters of a given type have all the validation needed so the code needs to deal with that.
- Some parameters can have multiple types. For example, it might be a string or null.
- Some parameters are required and some are optional so testing needs to verify the correct usage.
- The code should verify that extra parameters are not included.

Every route in src/server/routes needs to be analyzed and implemented.

## Status of OED parameter checking

There are issues with the current usage of jsonschema checking:

- The limits on the required and total parameters are not done in some cases.
- The way that parameter validation is done varies across files but should be systematic/same.
- Validation is not done for parameters that should be done.
- Probably others.

Given this, part of this effort is to find these limits and fix them. Tests are likely to fail without this and tests may indicate places where improvements need to be made. Developers could either document issues found or patch the routes with issues. A comment with a TODO could indicate issues and the failing test commented out for now. If patches or TODOs are not given, the merge of the parameter testing cannot happen until someone does the patch since OED does not want failing tests.

## Determining valid parameter values

Here are a few ideas to figure out what should be allowed:

- The client code may give clues via how the route is used. Another way is to look at the web pages while OED is running and see what values are allowed - in some circumstances OED validates and makes bad values in red.
- The database may impose limits. Looking at the checks in the SQL creation for a table can indicate usage limits.
- Use common sense. For example, if there is no logical limit on a string length then limiting to 1024 would probably avoid malicious usage.
- Ask the OED project. We are happy to verify what you think or help in determining limits.

## Thoughts on proceeding

Earlier work will need to continue to enhance the general methodology/code for doing parameter testing. It would be good to discuss changes with the project so we can all know this is a good way forward before using new features to do a lot of tests.

Knowing correct values and where more validation is needed for the many routes may be difficult for a developer. As mentioned above, OED is here to help with any uncertainty.
