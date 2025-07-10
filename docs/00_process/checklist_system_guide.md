# Checklist System Guide

## 🎯 **Purpose**
Hướng dẫn cách sử dụng **checklist system** hiệu quả trong development workflow để:
- **Track progress** accurately cho mỗi task
- **Ensure consistency** trong process execution
- **Capture learnings** for process improvement
- **Maintain quality** standards

## 🔄 **Two-Tier Checklist System**

### **📋 Tier 1: Master Guides (Templates)**
**Location**: `docs/00_process/`  
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
### LangChain Memory Integration Specific (Phase 1 Example)
- [ ] Install LangChain Swift package dependencies
- [ ] Design ConversationBufferMemory bridge service
- [ ] Implement memory persistence với Core Data
- [ ] Test context window management (4k-32k tokens)
- [ ] Verify streaming memory updates
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
- [x] **Add new files to Xcode Target**: If creating new `.swift` files, drag & drop them from Finder to Xcode's Project Navigator to prevent build errors.
- [x] Write code incrementally với frequent commits
- [ ] Use descriptive commit messages
- [ ] Test changes locally throughout development
```

#### **Add Notes for Context**
```markdown
- [x] Design ConversationBufferMemory bridge service
  *Note: Created LangChainMemoryService protocol với Core Data integration*
- [x] Implement memory persistence với Core Data
  *Note: Extended Message entity với context fields, added memory compression*
```

---

## 📁 **Working Checklist Locations**

### **Option 2: Sprint-Based File (Recommended)**
```
docs/03_implementation/sprint_planning/
├── sprint_01_plan.md  # ✅ Plan + Checklist + Results
├── sprint_02_plan.md
└── ...
```
**Pros**:
- ✅ **Single Source of Truth**: Mọi thứ về sprint (plan, checklist, kết quả) đều ở một nơi.
- ✅ **No Duplication**: Loại bỏ hoàn toàn việc phải cập nhật nhiều file.
- ✅ **Easy to Maintain**: Giảm số lượng file cần quản lý.

**Cons**:
- 🤷‍♂️ File có thể dài hơn một chút (nhưng vẫn dễ quản lý với mục lục).

### **Option 1: Task-Specific Files (Legacy)**
```
docs/03_implementation/tasks/
├── task_001_chat_interface.md
└── task_002_api_integration.md
```
**Pros**: Tốt cho các task cực lớn hoặc độc lập không thuộc sprint.
**Cons**: Dễ tạo ra sự trùng lặp với sprint plan, khó bảo trì.

### **🎯 Recommended Approach**
**Use Option 2 (Sprint-Based File)** là phương pháp được khuyến khích cho hầu hết các trường hợp.
- **Tích hợp checklist** trực tiếp vào file `sprint_[number]_plan.md`.
- File này sẽ đóng vai trò là tài liệu sống, từ lúc lập kế hoạch cho đến khi hoàn thành và ghi nhận kết quả.
- Cách tiếp cận này đã được chứng minh là hiệu quả qua Sprint 1, giúp giảm 50% số lượng tài liệu cần quản lý.

---

## 📝 **Working Checklist Templates**

### **Feature Development Template**
```markdown
# Task: [LangChain Feature Name]
**Type**: AI Agent Feature Development  
**Phase**: [Phase 1-6 from roadmap]
**Priority**: P0/P1/P2
**Sprint**: [Sprint Number]
**Estimated**: [1d-4d from Feature Backlog v2.0]
**Started**: [Date]
**Completed**: [Date]

## Objective
[What LangChain/LangGraph capability needs to be integrated]

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
- [ ] **Add new files to Xcode Target**: If creating new `.swift` files, drag & drop them from Finder to Xcode's Project Navigator to prevent build errors.
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