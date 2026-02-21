# VPC Network Access Analyzer - Architecture

## Overview

This document provides detailed technical explanations of the three VPC architectures, Network Access Analyzer concepts, and the automated reasoning algorithms used for network path analysis.

## Three VPC Architectures

### VPC 1: Isolated Private Network

```
┌─────────────────────────────────────────────────────────────┐
│                    VPC 1 (10.1.0.0/16)                      │
│                   Isolated Private Network                  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
