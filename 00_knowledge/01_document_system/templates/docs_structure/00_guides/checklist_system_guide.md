# Checklist System Guide - {{PROJECT_NAME}}

<!-- 
📝 HƯỚNG DẪN SỬ DỤNG TEMPLATE:
1. Điều chỉnh checklist types cho phù hợp với project
2. Thay thế {{PLACEHOLDER}} bằng thông tin cụ thể
3. Tạo custom checklists cho team workflow
4. AI làm việc rất hiệu quả với checklist system
-->

## 🎯 **Checklist Philosophy**

**Core Principle**: {{CHECKLIST_PHILOSOPHY}} <!-- Ví dụ: "Checklists prevent mistakes, ensure consistency, and enable delegation" -->

**AI-Friendly Approach**: Checklists cung cấp structure rõ ràng mà AI có thể follow và update.

## 📋 **Why Checklists Work**

### **For Humans**
- **Reduce cognitive load**: Don't need to remember everything
- **Ensure consistency**: Same process every time
- **Enable delegation**: Anyone can follow the steps
- **Track progress**: Visual confirmation of completion

### **For AI**
- **Clear structure**: Unambiguous steps to follow
- **Progress tracking**: Easy to update status
- **Quality assurance**: Built-in validation
- **Context switching**: Resume work easily

## 🏗️ **Checklist Types**

### **1. Process Checklists**
**Purpose**: Ensure consistent execution of repeated processes

**Example: Development Setup**
```markdown
## Development Environment Setup
- [ ] Install {{IDE_NAME}} <!-- Ví dụ: "Cursor" -->
- [ ] Configure {{LANGUAGE}} environment <!-- Ví dụ: "Swift/Xcode" -->
- [ ] Clone project repository
- [ ] Install dependencies
- [ ] Run initial build
- [ ] Verify all tests pass
- [ ] Setup {{DATABASE}} <!-- Ví dụ: "Core Data" -->
- [ ] Configure API credentials
- [ ] Test basic functionality
```

### **2. Quality Checklists**
**Purpose**: Ensure work meets standards before completion

**Example: Code Review**
```markdown
## Code Review Checklist
### Functionality
- [ ] Code does what it's supposed to do
- [ ] Edge cases are handled
- [ ] Error handling is appropriate
- [ ] Performance is acceptable

### Quality
- [ ] Code follows {{STYLE_GUIDE}} <!-- Ví dụ: "Swift style guide" -->
- [ ] No code smells or anti-patterns
- [ ] Appropriate comments and documentation
- [ ] Tests are included and passing

### Security
- [ ] No sensitive data in code
- [ ] Input validation where needed
- [ ] Authentication/authorization correct
- [ ] {{SECURITY_FRAMEWORK}} guidelines followed <!-- Ví dụ: "iOS security" -->
```

### **3. Release Checklists**
**Purpose**: Ensure safe and complete deployments

**Example: App Release**
```markdown
## {{PLATFORM}} Release Checklist <!-- Ví dụ: "iOS App Store" -->
### Pre-Release
- [ ] All features tested on {{DEVICES}} <!-- Ví dụ: "iPhone and iPad" -->
- [ ] Performance testing completed
- [ ] Security audit passed
- [ ] {{STORE_REQUIREMENTS}} met <!-- Ví dụ: "App Store guidelines" -->
- [ ] Release notes prepared
- [ ] Marketing materials ready

### Release Process
- [ ] Version number updated
- [ ] Build signed and archived
- [ ] Uploaded to {{DISTRIBUTION}} <!-- Ví dụ: "App Store Connect" -->
- [ ] Metadata and screenshots updated
- [ ] Beta testing completed
- [ ] Final review passed
```

### **4. Troubleshooting Checklists**
**Purpose**: Systematic approach to problem-solving

**Example: Bug Investigation**
```markdown
## Bug Investigation Checklist
### Information Gathering
- [ ] Reproduce the issue
- [ ] Document exact steps to reproduce
- [ ] Identify affected {{PLATFORM}} versions <!-- Ví dụ: "iOS versions" -->
- [ ] Check error logs and crash reports
- [ ] Determine impact scope

### Analysis
- [ ] Review recent changes
- [ ] Check related components
- [ ] Verify {{DEPENDENCIES}} <!-- Ví dụ: "third-party libraries" -->
- [ ] Test in different environments
- [ ] Consult {{DOCUMENTATION}} <!-- Ví dụ: "API documentation" -->

### Resolution
- [ ] Implement fix
- [ ] Write/update tests
- [ ] Verify fix works
- [ ] Test for regressions
- [ ] Update documentation
```

## 📝 **Creating Effective Checklists**

### **Design Principles**

#### **1. Specific and Actionable**
```markdown
❌ Bad: "Check the code"
✅ Good: "Verify all functions have unit tests"

❌ Bad: "Make sure it works"
✅ Good: "Test on iPhone 12, 13, and 14 with iOS 16+"
```

#### **2. Logical Order**
- **Dependencies first**: Prerequisites before dependent tasks
- **Risk-based**: High-risk items early
- **Workflow-based**: Follow natural work progression

#### **3. Right Level of Detail**
- **Not too granular**: "Type your name" is too detailed
- **Not too broad**: "Set up environment" is too vague
- **Just right**: "Install Xcode and verify Swift compiler works"

#### **4. Include Verification**
```markdown
## Good Checklist Items
- [ ] Install {{TOOL}} and verify with `{{COMMAND}}` <!-- Ví dụ: "Node.js" và "node --version" -->
- [ ] Deploy to staging and confirm {{URL}} loads <!-- Ví dụ: "https://staging.example.com" -->
- [ ] Run test suite and verify 100% pass rate
```

### **Checklist Templates**

#### **Basic Task Checklist**
```markdown
## {{TASK_NAME}}
**Goal**: {{TASK_GOAL}}
**Owner**: {{OWNER}}
**Due**: {{DUE_DATE}}

### Prerequisites
- [ ] {{PREREQUISITE_1}}
- [ ] {{PREREQUISITE_2}}

### Main Steps
- [ ] {{STEP_1}}
- [ ] {{STEP_2}}
- [ ] {{STEP_3}}

### Verification
- [ ] {{VERIFICATION_1}}
- [ ] {{VERIFICATION_2}}

### Cleanup
- [ ] {{CLEANUP_1}}
- [ ] {{CLEANUP_2}}
```

#### **Feature Development Checklist**
```markdown
## Feature: {{FEATURE_NAME}}
**Status**: {{STATUS}} <!-- pending/in_progress/completed -->
**Sprint**: {{SPRINT_NUMBER}}

### Planning
- [ ] Requirements clarified
- [ ] Design approved
- [ ] Technical approach agreed
- [ ] Dependencies identified

### Development
- [ ] {{COMPONENT_1}} implemented
- [ ] {{COMPONENT_2}} implemented
- [ ] Unit tests written
- [ ] Integration tests written

### Testing
- [ ] Manual testing completed
- [ ] {{AUTOMATED_TESTS}} passing <!-- Ví dụ: "UI tests" -->
- [ ] Performance testing done
- [ ] Security review passed

### Documentation
- [ ] Code comments added
- [ ] API documentation updated
- [ ] User guide updated
- [ ] Release notes prepared
```

## 🤖 **AI Collaboration with Checklists**

### **AI Checklist Usage**
1. **AI can create checklists** from requirements
2. **AI can update progress** as work is completed
3. **AI can verify completeness** before marking done
4. **AI can suggest improvements** to existing checklists

### **Best Practices for AI**
- **Always show current progress** when updating
- **Explain why** items are being checked off
- **Flag potential issues** if skipping items
- **Suggest next steps** based on checklist status

### **Example AI Interaction**
```markdown
## Current Progress: Feature Implementation
- [x] Requirements clarified
- [x] Design approved
- [x] Technical approach agreed
- [ ] Dependencies identified ← **Working on this now**
- [ ] Component A implemented
- [ ] Component B implemented

**Next Steps**: Complete dependency analysis, then move to implementation.
**Blockers**: None currently identified.
```

## 📊 **Checklist Management**

### **Storage and Organization**
```
docs/03_implementation/
├── checklists/
│   ├── README.md                    # Checklist index
│   ├── templates/                   # Reusable templates
│   │   ├── feature_development.md
│   │   ├── bug_fix.md
│   │   └── release_process.md
│   └── active/                      # Current checklists
│       ├── feature_{{ID}}.md
│       └── task_{{ID}}.md
```

### **Naming Convention**
- **Templates**: `{{TYPE}}_template.md`
- **Active checklists**: `{{TYPE}}_{{ID}}_{{SHORT_DESC}}.md`
- **Example**: `feature_001_user_authentication.md`

### **Lifecycle Management**
1. **Create**: Copy from template
2. **Customize**: Add specific items
3. **Execute**: Check off items as completed
4. **Review**: Verify all items complete
5. **Archive**: Move to completed folder

## 🔄 **Continuous Improvement**

### **Checklist Evolution**
- **Track completion rates**: Which items are often skipped?
- **Gather feedback**: What's missing or unclear?
- **Update regularly**: Incorporate lessons learned
- **Version control**: Track changes over time

### **Common Improvements**
- **Add verification steps** for frequently missed items
- **Break down complex items** into smaller steps
- **Add time estimates** for better planning
- **Include troubleshooting** for common issues

### **Metrics to Track**
- **Completion rate**: % of checklist items completed
- **Time accuracy**: Estimated vs actual time
- **Quality impact**: Defects found in checklist vs non-checklist work
- **Team adoption**: How consistently are checklists used?

## 🛠️ **Tools and Integration**

### **Recommended Tools**
- **{{TASK_TOOL}}** <!-- Ví dụ: "GitHub Issues with checklist templates" -->
- **{{PROJECT_TOOL}}** <!-- Ví dụ: "Notion or Trello for project tracking" -->
- **{{DOC_TOOL}}** <!-- Ví dụ: "Markdown files in repository" -->

### **Integration Points**
- **Code reviews**: Checklist in PR template
- **CI/CD**: Automated checklist verification
- **Project management**: Checklist items as tasks
- **Documentation**: Checklists embedded in guides

## 📋 **Quick Reference**

### **Creating New Checklist**
1. Choose appropriate template
2. Customize for specific task
3. Add to active checklists folder
4. Link from relevant documents
5. Assign owner and due date

### **Using Existing Checklist**
1. Review all items before starting
2. Check off items as completed
3. Add notes for complex items
4. Update status regularly
5. Archive when complete

### **Improving Checklists**
1. Note items that were missed
2. Add clarification for confusing items
3. Update templates with improvements
4. Share learnings with team
5. Version control changes

---

## 🎯 **Success Metrics**

A good checklist system should:
- [ ] **Reduce errors** by {{ERROR_REDUCTION}}% <!-- Ví dụ: "80%" -->
- [ ] **Improve consistency** across team members
- [ ] **Enable delegation** of complex tasks
- [ ] **Speed up onboarding** for new team members
- [ ] **Provide clear progress tracking**

---

*Checklists are living tools - update them as your process evolves!*

---
*Last updated: {{LAST_UPDATED}}*  
*Template version: {{TEMPLATE_VERSION}}* 