# Checklist System Guide

## 🎯 **Purpose**
Hướng dẫn cách sử dụng **checklist system** hiệu quả trong development workflow để:
- **Track progress** accurately cho mỗi task
- **Ensure consistency** trong process execution
- **Capture learnings** for process improvement
- **Maintain quality** standards

## 🔄 **Two-Tier Checklist System**

### **📋 Tier 1: Master Guides (Templates)**
**Location**: `docs/00_guides/`  
**Purpose**: Reference templates và complete processes

```
Master Guides = Complete Process Documentation
├── All possible checklist items
├── Best practices và guidelines
├── Templates for different task types
└── Process improvement insights
```

### **✅ Tier 2: Working Checklists (Task-Specific)**
**Location**: Task-specific locations  
**Purpose**: Actual progress tracking cho specific tasks

```
Working Checklists = Customized Task Tracking
├── Subset of relevant checklist items
├── Task-specific customizations
├── Progress checkmarks
└── Task-specific notes
```

---

## 🚀 **Working Checklist Workflow**

### **Step 1: Generate Working Checklist**
#### **From Task Management Guide**
```markdown
## Task: [Implement Chat Interface]
**Type**: Feature Development
**Sprint**: Sprint 1
**Estimated**: Medium (4-6 hours)

### BEFORE Task Checklist
- [ ] Define clear task objective: Create basic chat interface
- [ ] Estimate effort: Medium (4-6 hours)
- [ ] Review related code: Chat components, message handling
- [ ] Create feature branch: `feature/chat-interface`
- [ ] Pull latest code from main branch
- [ ] Verify development environment working
```

#### **From Documentation Guide**
```markdown
## Documentation Tasks for Chat Interface
- [ ] Update current_status.md với progress
- [ ] Document architecture decisions made
- [ ] Update feature documentation
- [ ] Verify all links work correctly
```

### **Step 2: Customize for Specific Task**
#### **Add Task-Specific Items**
```markdown
### Chat Interface Specific
- [ ] Design message bubble UI components
- [ ] Implement message input field
- [ ] Add send button functionality
- [ ] Test keyboard handling
- [ ] Verify accessibility features
```

#### **Remove Irrelevant Items**
```markdown
// Remove items not applicable to this task
// ❌ Plan feature rollout strategy (not needed for MVP)
// ❌ Consider feature flags (not needed for core feature)
```

### **Step 3: Work Through Checklist**
#### **Check Off Completed Items**
```markdown
### DURING Task Progress
- [x] Follow established coding standards (.cursorrules)
- [x] Write code incrementally với frequent commits
- [ ] Use descriptive commit messages
- [ ] Test changes locally throughout development
```

#### **Add Notes for Context**
```markdown
- [x] Design message bubble UI components
  *Note: Used SwiftUI Card style với rounded corners*
- [x] Implement message input field
  *Note: Added character limit of 1000 chars*
```

---

## 📁 **Working Checklist Locations**

### **Option 1: Task-Specific Files**
```
docs/03_implementation/tasks/
├── task_001_chat_interface.md
├── task_002_api_integration.md
└── task_003_file_upload.md
```

**Pros**: Dedicated space, easy to find, permanent record  
**Cons**: More files to manage

### **Option 2: Sprint-Based Files**
```
docs/03_implementation/sprint_planning/
├── sprint_01_tasks.md
├── sprint_02_tasks.md
└── current_sprint_checklist.md
```

**Pros**: Grouped by sprint, easier overview  
**Cons**: Harder to find specific task later

### **Option 3: Single Working File**
```
docs/03_implementation/current_work_checklist.md
```

**Pros**: Simple, always know where to look  
**Cons**: Gets long, harder to track history

### **🎯 Recommended Approach**
**Use Option 1** - Task-specific files với naming convention:
- `task_[number]_[short_description].md`
- Archive completed tasks to `completed/` subfolder
- Keep current tasks in main folder

---

## 📝 **Working Checklist Templates**

### **Feature Development Template**
```markdown
# Task: [Feature Name]
**Type**: Feature Development
**Priority**: P0/P1/P2
**Sprint**: [Sprint Number]
**Estimated**: [Small/Medium/Large]
**Started**: [Date]
**Completed**: [Date]

## Objective
[What needs to be accomplished]

## Success Criteria
- [ ] [Specific measurable outcome 1]
- [ ] [Specific measurable outcome 2]
- [ ] [Specific measurable outcome 3]

## BEFORE Task
### Planning & Setup
- [ ] Define clear task objective
- [ ] Estimate effort
- [ ] Identify dependencies
- [ ] Review related code areas
- [ ] Create feature branch: `feature/[task-name]`
- [ ] Pull latest code from main
- [ ] Verify development environment

### Context Preparation
- [ ] Attach relevant context files to AI
- [ ] Review previous related decisions
- [ ] Read related documentation

## DURING Task
### Development
- [ ] Follow coding standards (.cursorrules)
- [ ] Write code incrementally
- [ ] Use descriptive commit messages
- [ ] Test changes locally

### Documentation
- [ ] Update inline code comments
- [ ] Modify relevant documentation files
- [ ] Add new docs for new features
- [ ] Update current_status.md

### Progress Tracking
- [ ] Log significant decisions
- [ ] Note any blockers
- [ ] Record time spent

## AFTER Task
### Review & Integration
- [ ] Review all code changes
- [ ] Ensure all tests pass
- [ ] Verify no breaking changes
- [ ] Check performance impact

### Documentation
- [ ] Verify all documentation updated
- [ ] Check links work correctly
- [ ] Ensure consistent formatting

### Knowledge Capture
- [ ] Document key insights
- [ ] Record problems và solutions
- [ ] Update best practices if needed
- [ ] Update feature status trong backlog

## Task-Specific Items
[Add customized items for this specific task]

## Notes & Learnings
[Add notes during task execution]

## Time Tracking
**Estimated**: [Hours]
**Actual**: [Hours]
**Variance**: [Difference và reason]
```

### **Bug Fix Template**
```markdown
# Bug Fix: [Bug Description]
**Type**: Bug Fix
**Priority**: P0/P1/P2
**Sprint**: [Sprint Number]
**Issue**: [Link to issue if applicable]

## Bug Description
[What is the problem]

## Root Cause Analysis
[Why did this happen]

## Solution Approach
[How to fix it]

## BEFORE Task
- [ ] Reproduce the bug
- [ ] Understand root cause
- [ ] Plan fix approach
- [ ] Create fix branch: `fix/[bug-description]`

## DURING Task
- [ ] Implement fix
- [ ] Add regression tests
- [ ] Test fix thoroughly
- [ ] Document solution

## AFTER Task
- [ ] Verify fix works
- [ ] Update troubleshooting guides
- [ ] Document lessons learned
- [ ] Close related issues

## Testing Checklist
- [ ] Test happy path
- [ ] Test edge cases
- [ ] Test error scenarios
- [ ] Verify no new bugs introduced
```

---

## 🔄 **Checklist Lifecycle Management**

### **Creating Working Checklists**
1. **Start với master guide template**
2. **Copy relevant sections** to working checklist
3. **Customize for specific task**
4. **Add task-specific items**
5. **Remove irrelevant items**

### **During Task Execution**
1. **Check off completed items**
2. **Add notes for context**
3. **Update estimates if needed**
4. **Document blockers encountered**
5. **Record key decisions made**

### **After Task Completion**
1. **Review checklist completeness**
2. **Capture lessons learned**
3. **Identify process improvements**
4. **Archive completed checklist**
5. **Update master guides if needed**

---

## 🎯 **Best Practices**

### **Checklist Creation**
- **Be specific**: Vague items don't help
- **Be actionable**: Each item should be doable
- **Be measurable**: Clear completion criteria
- **Be relevant**: Only include applicable items

### **Checklist Usage**
- **Check off immediately**: When item is done
- **Add notes**: For context và learnings
- **Update estimates**: If scope changes
- **Document blockers**: Don't skip, note why

### **Checklist Maintenance**
- **Review regularly**: Are items still relevant?
- **Update templates**: Based on experience
- **Share learnings**: With team members
- **Archive completed**: Keep history but declutter

---

## 📊 **Success Metrics**

### **Process Compliance**
- **Completion rate**: % of checklist items completed
- **Quality metrics**: Bugs found in review
- **Time accuracy**: Estimated vs actual time
- **Documentation coverage**: All docs updated

### **Process Improvement**
- **Template evolution**: How often templates updated
- **Common blockers**: Patterns in obstacles
- **Efficiency gains**: Time saved through process
- **Team adoption**: Consistent usage across team

---

## 🔧 **Tools & Automation**

### **Manual Approach**
- **Markdown files**: Easy to edit, version control
- **Checkboxes**: Native GitHub/markdown support
- **File organization**: Clear folder structure

### **Future Automation Ideas**
- **Template generation**: Scripts to create working checklists
- **Progress tracking**: Automated status updates
- **Metrics collection**: Track completion rates
- **Integration**: Link với project management tools

---

## 🚨 **Common Pitfalls**

### **Checklist Bloat**
**Problem**: Too many items, becomes overwhelming
**Solution**: Keep focused, remove irrelevant items

### **Checklist Neglect**
**Problem**: Create checklist but don't use it
**Solution**: Make it part of workflow, not optional

### **Template Staleness**
**Problem**: Templates become outdated
**Solution**: Regular review và update cycle

### **One-Size-Fits-All**
**Problem**: Same checklist for different task types
**Solution**: Customize for each task type

---

*Working checklists are living documents - adapt them to your needs và improve them based on experience.* 