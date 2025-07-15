# Test Suite Guide - Smart Memory System
**OpenChatbot iOS - Sprint 3**

## Overview

This guide provides comprehensive instructions for running and managing the test suite for the Smart Memory System implementation in OpenChatbot iOS.

## Prerequisites

### Development Environment
- Xcode 15.0 or later
- iOS 17.0+ deployment target
- Swift 5.9+
- macOS 14.0+ (for development)

### Project Setup
```bash
# Navigate to iOS project directory
cd ios/

# Ensure project is properly configured
open OpenChatbot.xcodeproj
```

## Test Suite Structure

### Test Files Overview
```
OpenChatbot/Tests/
├── SmartContextRelevanceTests.swift      # MEM-009: Context relevance scoring
├── ConversationSummaryMemoryTests.swift  # MEM-006: Summary memory management
├── TokenWindowManagementTests.swift      # MEM-008: Token window optimization
├── ContextCompressionTests.swift         # MEM-007: Context compression algorithms
├── MemoryServiceTests.swift              # MEM-001-005: Core memory operations
├── CoreDataTests.swift                   # MEM-002,004: Data persistence
└── SmartMemorySystemIntegrationTests.swift # End-to-end integration tests
```

### Test Coverage by Sprint 3 Tasks
- **MEM-001**: ConversationBufferMemory Integration → `MemoryServiceTests.swift`
- **MEM-002**: Memory-Core Data Bridge → `CoreDataTests.swift`
- **MEM-003**: Context-Aware Response Generation → `MemoryServiceTests.swift`
- **MEM-004**: Memory Persistence Across Sessions → `CoreDataTests.swift`
- **MEM-005**: Memory Performance Optimization → `MemoryServiceTests.swift`
- **MEM-006**: ConversationSummaryMemory → `ConversationSummaryMemoryTests.swift`
- **MEM-007**: Context Compression Algorithms → `ContextCompressionTests.swift`
- **MEM-008**: Token Window Management → `TokenWindowManagementTests.swift`
- **MEM-009**: Smart Context Relevance Scoring → `SmartContextRelevanceTests.swift`

## Running Tests

### Method 1: Xcode GUI

#### Run All Tests
1. Open `OpenChatbot.xcodeproj` in Xcode
2. Select the test target: `OpenChatbotTests`
3. Press `Cmd + U` to run all tests
4. View results in the Test Navigator

#### Run Specific Test File
1. Navigate to the test file in Project Navigator
2. Click the diamond icon next to the class name
3. Or use `Cmd + U` with the file selected

#### Run Individual Test Method
1. Open the test file
2. Click the diamond icon next to the specific test method
3. Or place cursor in method and press `Cmd + U`

### Method 2: Command Line

#### Run All Tests
```bash
cd ios/

# Run all tests
xcodebuild -project OpenChatbot.xcodeproj \
           -scheme OpenChatbot \
           -destination 'platform=iOS Simulator,name=iPhone 16' \
           test
```

#### Run Specific Test Class
```bash
# Run specific test class
xcodebuild -project OpenChatbot.xcodeproj \
           -scheme OpenChatbot \
           -destination 'platform=iOS Simulator,name=iPhone 16' \
           test -only-testing:OpenChatbotTests/MemoryServiceTests
```

#### Run Specific Test Method
```bash
# Run specific test method
xcodebuild -project OpenChatbot.xcodeproj \
           -scheme OpenChatbot \
           -destination 'platform=iOS Simulator,name=iPhone 16' \
           test -only-testing:OpenChatbotTests/MemoryServiceTests/testConversationBufferMemoryIntegration
```

### Method 3: Available Simulators

#### List Available Simulators
```bash
xcrun simctl list devices
```

#### Common Simulator Options
- `iPhone 16` (recommended)
- `iPhone 16 Pro`
- `iPad Air 11-inch (M3)`
- `iPad Pro 13-inch (M4)`

## Test Categories

### 1. Unit Tests
**Purpose**: Test individual components in isolation

#### Memory Service Tests
```bash
# Run memory service unit tests
xcodebuild test -only-testing:OpenChatbotTests/MemoryServiceTests
```

#### Core Data Tests
```bash
# Run data persistence tests
xcodebuild test -only-testing:OpenChatbotTests/CoreDataTests
```

### 2. Integration Tests
**Purpose**: Test component interactions and workflows

```bash
# Run integration tests
xcodebuild test -only-testing:OpenChatbotTests/SmartMemorySystemIntegrationTests
```

### 3. Performance Tests
**Purpose**: Validate performance requirements

#### Key Performance Metrics
- Memory operations: < 500ms
- Context generation: < 1 second
- Compression: < 5 seconds
- 500 message handling: < 10 seconds

```bash
# Run performance-focused tests
xcodebuild test -only-testing:OpenChatbotTests/MemoryServiceTests/testMemoryPerformanceOptimization
```

### 4. Error Handling Tests
**Purpose**: Validate error scenarios and edge cases

```bash
# Run error handling tests
xcodebuild test -only-testing:OpenChatbotTests/SmartMemorySystemIntegrationTests/testMemorySystemErrorHandling
```

## Test Configuration

### Environment Variables
```bash
# Set test environment
export XCTEST_ENVIRONMENT=testing
export MEMORY_TEST_MODE=enabled
```

### Test Data Setup
Tests use in-memory Core Data store to avoid affecting production data:
- Temporary conversation data
- Mock API responses
- Isolated memory contexts

## Troubleshooting

### Common Issues

#### 1. Simulator Not Found
```bash
# Error: Unable to find a device matching the provided destination
# Solution: List available simulators and use correct name
xcrun simctl list devices
```

#### 2. Build Failures
```bash
# Clean build folder
xcodebuild clean

# Or in Xcode: Product → Clean Build Folder (Cmd + Shift + K)
```

#### 3. Test Timeout
```bash
# Increase test timeout in scheme settings
# Edit Scheme → Test → Options → Test Timeout
```

#### 4. Memory Issues
```bash
# Reset simulator
xcrun simctl erase all
```

### Architecture Alignment Issues

⚠️ **Current Status**: Test suite requires architecture alignment before execution

#### Known Issues
1. **Service API Mismatches**: Some service methods have evolved
2. **Actor Isolation**: Main actor context required for some operations
3. **Async/Await Patterns**: Test implementations need updates

#### Resolution Steps
1. Update service interfaces to match test expectations
2. Implement missing service methods
3. Resolve actor isolation issues
4. Update test implementations for current APIs

## Test Results Analysis

### Success Criteria
- All tests pass ✅
- Performance benchmarks met ✅
- Code coverage > 80% ✅
- No memory leaks detected ✅

### Failure Analysis
When tests fail, check:
1. **Error Messages**: Detailed failure descriptions
2. **Stack Traces**: Identify failure location
3. **Test Logs**: Additional debugging information
4. **Performance Metrics**: Identify bottlenecks

### Reporting
Test results are available in:
- Xcode Test Navigator
- Command line output
- `*.xcresult` files in DerivedData

## Continuous Integration

### Automated Testing
```bash
# CI script example
#!/bin/bash
set -e

echo "Running Smart Memory System Test Suite..."

# Clean and build
xcodebuild clean build-for-testing \
    -project OpenChatbot.xcodeproj \
    -scheme OpenChatbot \
    -destination 'platform=iOS Simulator,name=iPhone 16'

# Run tests
xcodebuild test-without-building \
    -project OpenChatbot.xcodeproj \
    -scheme OpenChatbot \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -resultBundlePath TestResults.xcresult

echo "Test suite completed successfully!"
```

### Performance Monitoring
```bash
# Generate performance report
xcodebuild test \
    -project OpenChatbot.xcodeproj \
    -scheme OpenChatbot \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -enablePerformanceTestsDiagnostics YES
```

## Best Practices

### Test Development
1. **Isolation**: Each test should be independent
2. **Cleanup**: Proper teardown after each test
3. **Naming**: Descriptive test method names
4. **Documentation**: Clear test purpose and expectations

### Performance Testing
1. **Baseline**: Establish performance baselines
2. **Monitoring**: Track performance over time
3. **Thresholds**: Set clear performance thresholds
4. **Profiling**: Use Instruments for detailed analysis

### Maintenance
1. **Regular Updates**: Keep tests aligned with code changes
2. **Refactoring**: Maintain test code quality
3. **Coverage**: Monitor and improve test coverage
4. **Documentation**: Update guides as needed

## Support

### Resources
- [Apple XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [iOS Testing Guide](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/)
- [Sprint 3 Implementation Guide](../02_development/ios_app_development_guide.md)

### Team Contact
For test suite issues or questions:
- Review test status report: `test_suite_status_report.md`
- Check implementation progress: `sprint_03_plan.md`
- Consult architecture guides in `docs/02_development/`

---

**Last Updated**: 2025-07-12  
**Version**: 1.0  
**Sprint**: 03 (Smart Memory System)  
**Status**: Ready for architecture alignment 