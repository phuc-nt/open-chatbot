# Task Management Guide

## 🎯 **Mục Đích**
Quy trình làm việc chuẩn cho **mỗi task** từ planning đến completion, đảm bảo:
- **Code quality**: Consistent và maintainable
- **Documentation**: Always up-to-date
- **Progress tracking**: Transparent và accurate
- **Knowledge sharing**: Lessons learned được capture

## 🔄 **Task Lifecycle Overview**

```
📋 BEFORE Task    →    💻 DURING Task    →    ✅ AFTER Task
├── Planning           ├── Development        ├── Review & Update
├── Setup              ├── Documentation      ├── Knowledge Capture
└── Preparation        └── Progress Tracking  └── Cleanup
```

---

## 📋 **BEFORE Task - Planning & Setup**

### **1. Task Definition & Planning**
#### **Task Analysis**
- [ ] **Define** clear task objective và success criteria
- [ ] **Estimate** effort (Small: <2h, Medium: 2-8h, Large: >8h)
- [ ] **Identify** dependencies và blockers
- [ ] **Check** if task aligns với current sprint goals

#### **Technical Planning**
- [ ] **Review** related code areas cần modify
- [ ] **Identify** potential architecture impacts
- [ ] **Plan** testing approach
- [ ] **Consider** performance implications

### **2. Environment Setup**
#### **Development Environment**
- [ ] **Pull** latest code từ main branch
- [ ] **Create** feature branch với naming convention: `feature/task-description`
- [ ] **Verify** development environment working
- [ ] **Run** existing tests để ensure baseline

#### **Documentation Setup**
- [ ] **Check** current documentation related to task area
- [ ] **Identify** docs sẽ cần update
- [ ] **Plan** new documentation nếu cần

### **3. Context Preparation**
#### **AI Context Setup**
- [ ] **Attach** relevant context files to AI conversation
- [ ] **Review** previous related tasks/decisions
- [ ] **Prepare** specific questions for AI assistance

#### **Knowledge Review**
- [ ] **Read** related code và documentation
- [ ] **Understand** existing patterns và conventions
- [ ] **Note** any unclear areas cần clarification

---

## 💻 **DURING Task - Active Development**

### **1. Development Workflow**
#### **Code Development**
- [ ] **Follow** established coding standards (.cursorrules)
- [ ] **Write** code incrementally với frequent commits
- [ ] **Use** descriptive commit messages
- [ ] **Test** changes locally throughout development
- [ ] **CRITICAL**: If creating new files, **add them to Xcode project target immediately** (drag & drop from Finder to Xcode). This prevents build failures
  > 📖 **Lý do & Cách làm**: [Xem chi tiết tại đây](../0_knowledge/02_swift_app_dev/02_swift_app_dev.md#phần-5-xử-lý-lỗi-build-phổ-biến---file-not-found)

#### **Documentation Updates**
- [ ] **Update** inline code comments for complex logic
- [ ] **Modify** relevant documentation files as code changes
- [ ] **Add** new docs for new features/components
- [ ] **Keep** documentation in sync với code changes

### **2. Progress Tracking**
#### **Daily Updates**
> 📖 **Documentation process**: [Documentation Maintenance Guide](documentation_maintenance_guide.md#daily-after-each-development-session)
> 📖 **Working checklists**: [Checklist System Guide](checklist_system_guide.md) - How to create và use task-specific checklists

- [ ] **Update** `docs/00_context/current_status.md` với progress
- [ ] **Log** significant decisions made
- [ ] **Note** any blockers encountered
- [ ] **Record** time spent on task

#### **Session Documentation**
- [ ] **Capture** key learnings từ each coding session
- [ ] **Document** any architecture decisions made
- [ ] **Record** problems solved và solutions used
- [ ] **Note** areas needing future attention

### **3. Quality Assurance**
#### **Code Quality**
- [ ] **Review** code for adherence to standards
- [ ] **Run** linters và fix issues
- [ ] **Ensure** proper error handling
- [ ] **Verify** performance considerations

#### **Testing**
- [ ] **Write** unit tests for new functionality
- [ ] **Run** full test suite
- [ ] **Test** edge cases và error scenarios
- [ ] **Verify** integration với existing features
- [ ] **CRITICAL**: Khi test trên thiết bị thật, tuân thủ theo **[Quy trình Build & Deploy chính thức](../02_development/ios_app_development_guide.md#phần-7-quy-trình-build-run-test-official)** để đảm bảo bạn đang chạy code mới nhất.

---

## ✅ **AFTER Task - Review & Completion**

### **1. Code Review & Integration**
#### **Pre-Merge Checklist**
- [ ] **Review** all code changes
- [ ] **Ensure** all tests pass
- [ ] **Verify** no breaking changes
- [ ] **Check** performance impact

#### **Documentation Validation**
> 📖 **Documentation review process**: [Documentation Maintenance Guide](documentation_maintenance_guide.md#weekly-end-of-sprint)

- [ ] **Verify** all documentation updated
- [ ] **Check** links work correctly
- [ ] **Ensure** consistent formatting
- [ ] **Validate** information accuracy

### **2. Knowledge Capture**
#### **Lessons Learned**
- [ ] **Document** key insights gained
- [ ] **Record** problems encountered và solutions
- [ ] **Note** better approaches for future
- [ ] **Update** best practices if applicable

#### **Architecture Updates**
- [ ] **Document** any architectural decisions made
- [ ] **Update** architecture diagrams nếu cần
- [ ] **Record** rationale for technical choices
- [ ] **Note** future considerations

### **3. Acceptance Testing**
#### **Mục đích**
- [ ] **Verify** that completed features meet all specified requirements from the sprint plan.
- [ ] **Ensure** the end-user experience is correct, intuitive, and bug-free.
- [ ] **Confirm** the application is stable and production-ready before merging or deploying.

#### **Quy trình**
- [ ] **Yêu cầu AI tạo Test Cases**: Sau khi các task chính của sprint hoàn thành, developer yêu cầu AI tạo test cases.
  > **Prompt mẫu**: "Hãy tạo các acceptance test cases cho Sprint 2."
- [ ] **Lưu trữ Test Cases**: AI sẽ tạo một file Markdown mới (ví dụ: `docs/03_implementation/sprint_02_acceptance_tests.md`) chứa bảng test case chi tiết.
- [ ] **Thực hiện Test**: Developer thực hiện các test case theo file đã tạo trên simulator hoặc thiết bị thật.
- [ ] **Báo cáo & Sửa lỗi**:
  - Nếu một test case **Fail**, developer báo cáo ID của test case đó cho AI.
  - AI tiến hành phân tích, debug và sửa lỗi.
  - Quá trình lặp lại cho đến khi tất cả các test case trong file đều **Pass**.

### **4. Project Updates**
#### **Progress Documentation**
- [ ] **Update** feature status trong Feature Backlog v2.0
- [ ] **Mark** task as completed trong `sprint_xx_plan.md`
- [ ] **Update** `current_status.md` nếu có phase milestone hoặc major achievement
- [ ] **Note** any scope changes affects roadmap phases

#### **Communication**
- [ ] **Share** significant learnings với team
- [ ] **Update** stakeholders on progress
- [ ] **Document** any changes to timeline
- [ ] **Prepare** demo materials nếu cần

---

## 🔧 **Task-Specific Workflows**

### **LangChain/AI Agent Feature Tasks**
#### **Additional Steps**
- [ ] **Document** LangChain/LangGraph integration approach
- [ ] **Update** technical guide với new patterns
- [ ] **Plan** progressive feature rollout for AI capabilities
- [ ] **Consider** feature compatibility với existing chat foundation

### **Bug Fix Tasks**
#### **Additional Steps**
- [ ] **Document** root cause analysis
- [ ] **Update** troubleshooting guides
- [ ] **Add** regression tests
- [ ] **Verify** fix doesn't introduce new issues

### **Refactoring Tasks**
#### **Additional Steps**
- [ ] **Document** refactoring rationale
- [ ] **Ensure** backward compatibility
- [ ] **Update** related documentation
- [ ] **Verify** no functionality changes

---

## 📊 **Task Tracking Templates**

### **Task Planning Template**
```markdown
## Task: [Task Name]
**Type**: Feature/Bug/Refactor/Documentation
**Priority**: P0/P1/P2
**Estimate**: Small/Medium/Large
**Sprint**: [Sprint Number]

### Objective
[Clear description of what needs to be accomplished]

### Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

### Technical Approach
[High-level approach to solving the task]

### Dependencies
- [List any blocking dependencies]

### Risks/Concerns
- [Any potential issues or unknowns]
```

### **Daily Progress Template**
```markdown
## [Date] - [Task Name] Progress

### Work Completed
- [Specific accomplishments]

### Key Decisions Made
- [Important technical/design decisions]

### Blockers/Issues
- [Any obstacles encountered]

### Next Steps
- [What to work on next]

### Time Spent
[Actual time spent on task]
```

---

## 🚨 **Common Pitfalls & Solutions**

### **Documentation Debt**
**Problem**: Documentation falls behind code changes
**Solution**: Update docs trong same commit as code changes

### **Scope Creep**
**Problem**: Task grows beyond original scope
**Solution**: Document scope changes và get approval before proceeding

### **Technical Debt**
**Problem**: Quick fixes without proper documentation
**Solution**: Always document workarounds và plan proper fixes

### **Knowledge Silos**
**Problem**: Important decisions not shared
**Solution**: Use templates to capture và share learnings

---

## 🔗 **Integration với Other Processes**

### **Documentation Maintenance**
> 📖 **Full documentation process**: [Documentation Maintenance Guide](documentation_maintenance_guide.md)

**Task workflow integrates với**:
- Daily documentation updates
- Weekly quality reviews
- Monthly strategic reviews

### **Sprint Planning**
> 📖 **Sprint planning process**: [Sprint Planning](03_implementation/sprint_planning/) (when available)

**Task workflow supports**:
- Sprint goal alignment
- Velocity tracking
- Retrospective insights

### **Code Review Process**
**Task workflow includes**:
- Self-review checklist
- Documentation review
- Knowledge sharing requirements

---

## 🎯 **Success Metrics**

### **Task Completion Quality**
- **Code quality**: No major issues in review
- **Documentation**: All related docs updated
- **Testing**: Full test coverage for changes
- **Knowledge**: Lessons learned captured

### **Process Efficiency**
- **Planning accuracy**: Estimates vs actual time
- **Scope stability**: Minimal scope changes
- **Rework rate**: Low number of follow-up fixes
- **Knowledge sharing**: Insights documented và shared

### **Team Alignment**
- **Consistency**: All team members follow same process
- **Transparency**: Progress visible to all stakeholders
- **Continuous improvement**: Process evolves based on feedback

---

## 🔄 **Process Evolution**

### **Weekly Review Questions**
1. **Efficiency**: Are task workflows smooth và efficient?
2. **Quality**: Are we maintaining code và documentation quality?
3. **Learning**: Are we capturing và sharing knowledge effectively?
4. **Alignment**: Are tasks aligned với project goals?

### **Monthly Optimization**
- **Analyze** task completion metrics
- **Identify** bottlenecks trong workflow
- **Update** templates based on experience
- **Refine** integration với other processes

---

*This guide evolves with team experience và project needs. Update based on retrospective feedback.* 