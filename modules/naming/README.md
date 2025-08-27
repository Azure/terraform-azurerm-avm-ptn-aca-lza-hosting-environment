# Naming module

This module computes consistent Azure resource names based on workload, environment, region, and a uniqueness token.

## Inputs
- workload_name (string, 2-10 chars)
- spoke_resource_group_name (string, optional; default "")
- environment (string, <=8 chars)
- location (string)
- unique_id (string)

## Outputs
- resources_names (object): computed resource names
- resource_type_abbreviations (object): abbreviation map used for naming

## Notes
- Region and resource type abbreviations are defined in the module for reproducibility.
