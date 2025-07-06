#!/bin/bash

# OpenChatbot iOS Code Quality Script
# This script runs SwiftLint and SwiftFormat on the project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project paths
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$PROJECT_DIR/OpenChatbot"

echo -e "${BLUE}🔧 OpenChatbot Code Quality Check${NC}"
echo -e "${BLUE}================================${NC}"

# Check if tools are installed
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 is not installed${NC}"
        echo -e "${YELLOW}💡 Install with: brew install $1${NC}"
        return 1
    fi
    return 0
}

# Function to run SwiftFormat
run_swiftformat() {
    echo -e "${BLUE}🎨 Running SwiftFormat...${NC}"
    
    if check_tool "swiftformat"; then
        cd "$PROJECT_DIR"
        
        # Check if there are any Swift files to format
        if find "$SOURCE_DIR" -name "*.swift" -type f | grep -q .; then
            # Run SwiftFormat with dry-run first to see what would change
            echo -e "${YELLOW}📋 Checking format changes...${NC}"
            if swiftformat --dryrun --config .swiftformat "$SOURCE_DIR"; then
                echo -e "${GREEN}✅ No formatting issues found${NC}"
            else
                echo -e "${YELLOW}⚠️  Formatting issues found, applying fixes...${NC}"
                swiftformat --config .swiftformat "$SOURCE_DIR"
                echo -e "${GREEN}✅ SwiftFormat completed${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  No Swift files found to format${NC}"
        fi
    else
        echo -e "${RED}❌ SwiftFormat check failed${NC}"
        return 1
    fi
}

# Function to run SwiftLint
run_swiftlint() {
    echo -e "${BLUE}🔍 Running SwiftLint...${NC}"
    
    if check_tool "swiftlint"; then
        cd "$PROJECT_DIR"
        
        # Check if there are any Swift files to lint
        if find "$SOURCE_DIR" -name "*.swift" -type f | grep -q .; then
            echo -e "${YELLOW}📋 Analyzing code quality...${NC}"
            
            # Run SwiftLint
            if swiftlint lint --config .swiftlint.yml; then
                echo -e "${GREEN}✅ SwiftLint passed${NC}"
            else
                echo -e "${YELLOW}⚠️  SwiftLint found issues${NC}"
                echo -e "${YELLOW}💡 Try running: swiftlint lint --fix --config .swiftlint.yml${NC}"
                return 1
            fi
        else
            echo -e "${YELLOW}⚠️  No Swift files found to lint${NC}"
        fi
    else
        echo -e "${RED}❌ SwiftLint check failed${NC}"
        return 1
    fi
}

# Function to fix SwiftLint issues automatically
fix_swiftlint() {
    echo -e "${BLUE}🔧 Auto-fixing SwiftLint issues...${NC}"
    
    if check_tool "swiftlint"; then
        cd "$PROJECT_DIR"
        swiftlint lint --fix --config .swiftlint.yml
        echo -e "${GREEN}✅ SwiftLint auto-fix completed${NC}"
    else
        echo -e "${RED}❌ SwiftLint auto-fix failed${NC}"
        return 1
    fi
}

# Function to show help
show_help() {
    echo -e "${BLUE}Usage: $0 [OPTION]${NC}"
    echo ""
    echo "Options:"
    echo "  format    Run SwiftFormat only"
    echo "  lint      Run SwiftLint only"  
    echo "  fix       Auto-fix SwiftLint issues"
    echo "  all       Run both SwiftFormat and SwiftLint (default)"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Run all checks"
    echo "  $0 format       # Format code only"
    echo "  $0 lint         # Lint code only"
    echo "  $0 fix          # Auto-fix lint issues"
}

# Main execution
case "${1:-all}" in
    "format")
        run_swiftformat
        ;;
    "lint")
        run_swiftlint
        ;;
    "fix")
        fix_swiftlint
        ;;
    "all")
        run_swiftformat
        echo ""
        run_swiftlint
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown option: $1${NC}"
        show_help
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}🎉 Code quality check completed!${NC}" 