# ELT with Firebolt using dbt

This guide provides a step-by-step primer on setting up an ELT (Extract, Load, Transform) pipeline using Firebolt and dbt. We will use the Atomic Adtech sample dataset, configure Firebolt for database management, and demonstrate how to handle external tables and transform data effectively.

## Prerequisites

Before you begin, ensure you have the following:

- A functional Python environment with internet access.
- An existing Firebolt organization and account. If you do not have a Firebolt account, you can easily [register](https://go.firebolt.io/signup) for a free account.

## Sample Dataset

For this exercise, we will work with the Atomic Adtech sample dataset. Atomic is a fictitious ad tech company, and we will be dealing with several data elements, turning them into internal tables in Firebolt. The objective is to mirror the source system's state at any point in time by sorting through exports, as well as inserting and updating records as needed. 

### Dataset Overview

The source dataset includes:

- **One large fact table**: `session_log` – Tracks user engagement events such as 'request', 'impression', 'click', and 'conversion'.
- **Four dimension tables**: 
  - `advertiser` 
  - `campaigns` 
  - `publisher` 
  - `publisher_channel`

These tables provide additional context on user engagement. The complete models for this dataset can be found in Firebolt's sample dataset S3 bucket. This is documented in the detailed [ELT with Firebolt using dbt](http://www.firebolt.io/blog/elt-with-firebolt-using-dbt) blog.

## Objective

Our goal is to replicate all the data from the source system as of the last dump in Firebolt, ensuring it is optimized for efficient reporting. This will be accomplished through moving data from S3 into Firebolt.

## Getting Started
- Clone this repo to download all the dbt model files that are provided as a part of this tutorial
- Follow step-by-step instructions in the [ELT with Firebolt using dbt](http://www.firebolt.io/blog/elt-with-firebolt-using-dbt) blog to setup dbt with Firebolt 


### Additional Resources

- [Firebolt Documentation](https://docs.firebolt.io/)
- [dbt Documentation](https://docs.getdbt.com/)
- [GitHub Repository](#) - Complete models and SQL scripts.

---

We hope this guide helps you efficiently set up your ELT pipeline using Firebolt and dbt. Happy data transforming!

